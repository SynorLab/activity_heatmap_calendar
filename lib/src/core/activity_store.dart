import 'dart:collection';

import 'package:flutter/material.dart' show DateTimeRange;

import '../models/activity.dart';
import '../models/activity_type.dart';
import '../models/heatmap_date_utils.dart';

/// The in-memory index behind the calendar.
///
/// The store keeps activities bucketed by local calendar day so that both the
/// heatmap (which needs a count per day over a range) and the detail sheet
/// (which needs the activities of a single day) are cheap to build.
///
/// This class is pure data: it knows nothing about widgets. Application code
/// normally interacts with `ActivityHeatmapCalendar` instead, which wraps a
/// store and adds change notification.
class ActivityStore {
  /// Insertion-ordered list of every activity in the store.
  final List<Activity> _all = <Activity>[];

  /// Day key (`yyyyMMdd`) to the activities of that day, in insertion order.
  final Map<int, List<Activity>> _byDay = <int, List<Activity>>{};

  /// Type id to the set of day keys on which that type occurs.
  final Map<String, Set<int>> _daysByTypeId = <String, Set<int>>{};

  /// Type id to the last seen instance, so callers get labels and colours back
  /// from [knownTypes] even when they filter with a bare `ActivityType(id)`.
  final Map<String, ActivityType> _typesById = <String, ActivityType>{};

  /// Identity map from an activity to the day key it was indexed under, so
  /// removal stays correct even if the caller mutated `activity.date`.
  final Map<Activity, int> _dayKeyOf = HashMap<Activity, int>.identity();

  final Map<String, Map<int, int>> _countsCache = <String, Map<int, int>>{};

  List<int>? _sortedDayKeys;
  int _version = 0;

  /// Increments on every mutation. Useful as a cache key.
  int get version => _version;

  /// The number of activities in the store.
  int get length => _all.length;

  /// Whether the store holds no activities.
  bool get isEmpty => _all.isEmpty;

  /// Whether the store holds at least one activity.
  bool get isNotEmpty => _all.isNotEmpty;

  /// Every activity, in insertion order, as an unmodifiable view.
  List<Activity> get all => List<Activity>.unmodifiable(_all);

  /// Every type seen so far, including [ActivityType.all] if any uncategorised
  /// activity was inserted.
  Set<ActivityType> get knownTypes => Set<ActivityType>.of(_typesById.values);

  /// The span from the earliest to the latest activity, or `null` when the
  /// store is empty. Both ends are local midnight.
  DateTimeRange? get dataBounds {
    final List<int> keys = _sorted();
    if (keys.isEmpty) {
      return null;
    }
    return DateTimeRange(
      start: HeatmapDateUtils.dateFromKey(keys.first),
      end: HeatmapDateUtils.dateFromKey(keys.last),
    );
  }

  // ---------------------------------------------------------------- mutation

  /// Adds [activity] to the index.
  ///
  /// Inserting the same instance twice adds it twice; the store does not
  /// deduplicate.
  void insert(Activity activity) {
    _insertUnchecked(activity);
    _invalidate();
  }

  /// Adds every activity in [activities] in one pass.
  void insertAll(Iterable<Activity> activities) {
    for (final Activity activity in activities) {
      _insertUnchecked(activity);
    }
    _invalidate();
  }

  /// Removes [activity] by identity.
  ///
  /// Returns whether an activity was removed.
  bool remove(Activity activity) {
    final int? key = _dayKeyOf.remove(activity);
    if (key == null) {
      return false;
    }
    _all.removeWhere((Activity a) => identical(a, activity));
    final List<Activity>? bucket = _byDay[key];
    if (bucket != null) {
      bucket.removeWhere((Activity a) => identical(a, activity));
      if (bucket.isEmpty) {
        _byDay.remove(key);
      }
    }
    _rebuildTypeIndex();
    _invalidate();
    return true;
  }

  /// Removes every activity matching [test].
  void removeWhere(bool Function(Activity activity) test) {
    final List<Activity> survivors = _all
        .where((Activity a) => !test(a))
        .toList(growable: true);
    if (survivors.length == _all.length) {
      return;
    }
    _resetTo(survivors);
  }

  /// Replaces the entire contents of the store with [activities].
  void replaceAll(Iterable<Activity> activities) =>
      _resetTo(activities.toList(growable: true));

  /// Removes every activity.
  void clear() {
    if (_all.isEmpty) {
      return;
    }
    _resetTo(<Activity>[]);
  }

  /// Rebuilds the index from the current `date` and `type` of every stored
  /// activity.
  ///
  /// Call this after mutating those properties in place; queries return stale
  /// results until you do.
  void reindex() => _resetTo(List<Activity>.of(_all));

  // ----------------------------------------------------------------- queries

  /// The activities recorded on the local calendar day of [date].
  ///
  /// When [type] is given and is not [ActivityType.all], only activities of
  /// that exact type are returned. The result is an unmodifiable view in
  /// insertion order, and is empty for days with no activities.
  List<Activity> activitiesOn(DateTime date, {ActivityType? type}) {
    final List<Activity>? bucket = _byDay[HeatmapDateUtils.dayKey(date)];
    if (bucket == null) {
      return const <Activity>[];
    }
    if (_isUnfiltered(type)) {
      return List<Activity>.unmodifiable(bucket);
    }
    return List<Activity>.unmodifiable(
      bucket.where((Activity a) => a.type == type),
    );
  }

  /// The activities recorded from [startDate] to [endDate], both ends
  /// inclusive at day granularity.
  ///
  /// Results are ordered by day and, within a day, by insertion order. The
  /// bounds are swapped automatically when [startDate] is after [endDate].
  List<Activity> activitiesBetween(
    DateTime startDate,
    DateTime endDate, {
    ActivityType? type,
  }) {
    final List<Activity> result = <Activity>[];
    for (final int key in _dayKeysIn(startDate, endDate, type)) {
      final List<Activity> bucket = _byDay[key]!;
      if (_isUnfiltered(type)) {
        result.addAll(bucket);
      } else {
        result.addAll(bucket.where((Activity a) => a.type == type));
      }
    }
    return List<Activity>.unmodifiable(result);
  }

  /// The number of activities on the local calendar day of [date].
  int countOn(DateTime date, {ActivityType? type}) {
    final List<Activity>? bucket = _byDay[HeatmapDateUtils.dayKey(date)];
    if (bucket == null) {
      return 0;
    }
    if (_isUnfiltered(type)) {
      return bucket.length;
    }
    int count = 0;
    for (final Activity a in bucket) {
      if (a.type == type) {
        count++;
      }
    }
    return count;
  }

  /// A map of day key to daily heat value covering [range].
  ///
  /// Days without activities are absent from the map rather than mapped to
  /// zero. This is the only data source the heatmap paint path uses, and the
  /// result is cached per (version, type, range, weight function).
  ///
  /// [weightOf] gives each activity a contribution other than 1, which lets
  /// the heat reflect duration, distance or any other magnitude. Weights below
  /// zero are treated as zero so a stray negative cannot cancel out a day.
  Map<int, int> dailyCounts(
    DateTimeRange range, {
    ActivityType? type,
    int Function(Activity activity)? weightOf,
  }) {
    final String cacheKey =
        '${type == null || type.isAll ? '*' : type.id}'
        '|${HeatmapDateUtils.dayKey(range.start)}'
        '|${HeatmapDateUtils.dayKey(range.end)}'
        '|${weightOf == null ? 0 : identityHashCode(weightOf)}';
    final Map<int, int>? cached = _countsCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final Map<int, int> counts = <int, int>{};
    for (final int key in _dayKeysIn(range.start, range.end, type)) {
      final int value = _valueOfDay(_byDay[key]!, type, weightOf);
      if (value > 0) {
        counts[key] = value;
      }
    }
    final Map<int, int> result = Map<int, int>.unmodifiable(counts);
    _countsCache[cacheKey] = result;
    return result;
  }

  int _valueOfDay(
    List<Activity> bucket,
    ActivityType? type,
    int Function(Activity activity)? weightOf,
  ) {
    final bool unfiltered = _isUnfiltered(type);
    if (weightOf == null) {
      if (unfiltered) {
        return bucket.length;
      }
      int count = 0;
      for (final Activity a in bucket) {
        if (a.type == type) {
          count++;
        }
      }
      return count;
    }

    int total = 0;
    for (final Activity a in bucket) {
      if (unfiltered || a.type == type) {
        final int weight = weightOf(a);
        if (weight > 0) {
          total += weight;
        }
      }
    }
    return total;
  }

  // ------------------------------------------------------------------ private

  bool _isUnfiltered(ActivityType? type) => type == null || type.isAll;

  void _insertUnchecked(Activity activity) {
    final int key = HeatmapDateUtils.dayKey(activity.date);
    _all.add(activity);
    (_byDay[key] ??= <Activity>[]).add(activity);
    _dayKeyOf[activity] = key;
    (_daysByTypeId[activity.type.id] ??= <int>{}).add(key);
    _typesById[activity.type.id] = activity.type;
  }

  void _resetTo(List<Activity> activities) {
    _all
      ..clear()
      ..addAll(activities);
    _byDay.clear();
    _daysByTypeId.clear();
    _typesById.clear();
    _dayKeyOf.clear();
    for (final Activity activity in _all) {
      final int key = HeatmapDateUtils.dayKey(activity.date);
      (_byDay[key] ??= <Activity>[]).add(activity);
      _dayKeyOf[activity] = key;
      (_daysByTypeId[activity.type.id] ??= <int>{}).add(key);
      _typesById[activity.type.id] = activity.type;
    }
    _invalidate();
  }

  /// Recomputes the type index after a single removal.
  void _rebuildTypeIndex() {
    _daysByTypeId.clear();
    _typesById.clear();
    for (final MapEntry<int, List<Activity>> entry in _byDay.entries) {
      for (final Activity activity in entry.value) {
        (_daysByTypeId[activity.type.id] ??= <int>{}).add(entry.key);
        _typesById[activity.type.id] = activity.type;
      }
    }
  }

  void _invalidate() {
    _version++;
    _sortedDayKeys = null;
    _countsCache.clear();
  }

  List<int> _sorted() => _sortedDayKeys ??= _byDay.keys.toList()..sort();

  /// The populated day keys within `[start, end]`, in chronological order.
  ///
  /// Because day keys are `yyyyMMdd` integers, chronological order and numeric
  /// order coincide, so the range is found with two binary searches.
  Iterable<int> _dayKeysIn(DateTime start, DateTime end, ActivityType? type) {
    int startKey = HeatmapDateUtils.dayKey(start);
    int endKey = HeatmapDateUtils.dayKey(end);
    if (startKey > endKey) {
      final int swap = startKey;
      startKey = endKey;
      endKey = swap;
    }

    if (!_isUnfiltered(type)) {
      final Set<int>? typeDays = _daysByTypeId[type!.id];
      if (typeDays == null || typeDays.isEmpty) {
        return const <int>[];
      }
      // Iterating the type's own day set beats scanning the whole calendar
      // when the type is sparse, which is the common case.
      final List<int> keys =
          typeDays.where((int key) => key >= startKey && key <= endKey).toList()
            ..sort();
      return keys;
    }

    final List<int> sorted = _sorted();
    final int lo = _lowerBound(sorted, startKey);
    final int hi = _upperBound(sorted, endKey);
    return sorted.getRange(lo, hi);
  }

  static int _lowerBound(List<int> sorted, int value) {
    int lo = 0;
    int hi = sorted.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (sorted[mid] < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  static int _upperBound(List<int> sorted, int value) {
    int lo = 0;
    int hi = sorted.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (sorted[mid] <= value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
