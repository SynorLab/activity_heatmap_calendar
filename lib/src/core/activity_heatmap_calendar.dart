import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/widgets.dart';

import '../config/activity_heatmap_config.dart';
import '../models/activity.dart';
import '../models/activity_type.dart';
import 'activity_store.dart';
import 'heatmap_data.dart';
import 'heatmap_level_resolver.dart';
import 'heatmap_view_attachment.dart';

/// A pending [ActivityHeatmapCalendar.goto] waiting for a view to attach.
@immutable
class _PendingGoto {
  const _PendingGoto(this.date, this.alignment);

  final DateTime date;
  final double alignment;
}

/// The controller and public API of the package.
///
/// `ActivityHeatmapCalendar()` always returns the same instance, so any part
/// of your app can insert activities or drive the view without passing an
/// object around:
///
/// ```dart
/// void main() {
///   ActivityHeatmapCalendar()
///     ..setConfig(const ActivityHeatmapConfig(splitMonthView: true))
///     ..insertAll(myActivities);
///   runApp(const MyApp());
/// }
/// ```
///
/// Every attached [ActivityHeatmapCalendarView] listens to this object, so
/// mutations and `filter` calls update the UI with no extra wiring.
///
/// If you need two independent data sets — say a personal and a team graph on
/// the same screen — use [ActivityHeatmapCalendar.named] instead of the
/// singleton.
class ActivityHeatmapCalendar extends ChangeNotifier {
  ActivityHeatmapCalendar._(this.name);

  /// Returns the default singleton instance.
  factory ActivityHeatmapCalendar() => instance;

  /// Returns the instance registered under [name], creating it on first use.
  ///
  /// Named instances are independent: separate data, filter and configuration.
  /// Unlike the singleton they can be disposed, which also unregisters them.
  factory ActivityHeatmapCalendar.named(String name) =>
      _instances.putIfAbsent(name, () => ActivityHeatmapCalendar._(name));

  static const String _defaultName = '__default__';

  static final Map<String, ActivityHeatmapCalendar> _instances =
      <String, ActivityHeatmapCalendar>{
        _defaultName: ActivityHeatmapCalendar._(_defaultName),
      };

  /// The default singleton, the same object [ActivityHeatmapCalendar] returns.
  static ActivityHeatmapCalendar get instance => _instances[_defaultName]!;

  /// The name this instance was registered under.
  final String name;

  final ActivityStore _store = ActivityStore();
  final List<HeatmapViewAttachment> _attachments = <HeatmapViewAttachment>[];

  /// Mirror of the listener list so [resetForTest] can detach every listener.
  ///
  /// [ChangeNotifier] offers no way to enumerate or clear its listeners, and
  /// without that a test suite sharing the singleton accumulates listeners
  /// from previous tests and miscounts notifications.
  final List<VoidCallback> _trackedListeners = <VoidCallback>[];

  ActivityHeatmapConfig _config = const ActivityHeatmapConfig();
  ActivityType? _filter;
  _PendingGoto? _pendingGoto;

  int _batchDepth = 0;
  bool _batchDirty = false;

  HeatmapData? _cachedData;
  Object? _cachedDataKey;

  /// Whether this is the default singleton.
  bool get isDefaultInstance => name == _defaultName;

  // ----------------------------------------------------------------- inserts

  /// Records [activity] so it contributes to the heatmap and appears in the
  /// detail sheet of its day.
  void insert(Activity activity) {
    _store.insert(activity);
    _changed();
  }

  /// Records every activity in [activities] in one pass, notifying once.
  void insertAll(Iterable<Activity> activities) {
    _store.insertAll(activities);
    _changed();
  }

  /// Removes [activity] by identity, returning whether it was present.
  bool remove(Activity activity) {
    final bool removed = _store.remove(activity);
    if (removed) {
      _changed();
    }
    return removed;
  }

  /// Removes every activity matching [test].
  void removeWhere(bool Function(Activity activity) test) {
    final int before = _store.length;
    _store.removeWhere(test);
    if (_store.length != before) {
      _changed();
    }
  }

  /// Replaces the entire data set.
  void replaceAll(Iterable<Activity> activities) {
    _store.replaceAll(activities);
    _changed();
  }

  /// Removes every activity.
  void clear() {
    if (_store.isEmpty) {
      return;
    }
    _store.clear();
    _changed();
  }

  /// Rebuilds the index after activities were mutated in place.
  ///
  /// Required whenever you change the `date` or `type` of an activity that is
  /// already inserted; see [Activity] for the details.
  void reindex() {
    _store.reindex();
    _changed();
  }

  /// Runs [updates] as a single change, notifying listeners at most once.
  ///
  /// Use it when inserting many activities from several call sites:
  ///
  /// ```dart
  /// calendar.batch(() {
  ///   for (final row in rows) {
  ///     calendar.insert(row.toActivity());
  ///   }
  /// });
  /// ```
  ///
  /// Batches nest; only the outermost one notifies.
  void batch(VoidCallback updates) {
    _batchDepth++;
    try {
      updates();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0 && _batchDirty) {
        _batchDirty = false;
        notifyListeners();
      }
    }
  }

  // ----------------------------------------------------------------- queries

  /// The activities recorded on [date].
  ///
  /// Returns every activity of that day regardless of the active filter. Pass
  /// `respectFilter: true` to see only what the view is currently showing.
  List<Activity> showActivities(DateTime date, {bool respectFilter = false}) =>
      _store.activitiesOn(date, type: respectFilter ? _filter : null);

  /// The activities recorded from [startDate] to [endDate], both ends
  /// inclusive at day granularity.
  ///
  /// Returns every activity in the span regardless of the active filter. Pass
  /// `respectFilter: true` to see only what the view is currently showing.
  /// Bounds given in the wrong order are swapped.
  List<Activity> showActivitiesBetween(
    DateTime startDate,
    DateTime endDate, {
    bool respectFilter = false,
  }) => _store.activitiesBetween(
    startDate,
    endDate,
    type: respectFilter ? _filter : null,
  );

  /// The number of activities on [date], by default after the active filter.
  int countOn(DateTime date, {bool respectFilter = true}) =>
      _store.countOn(date, type: respectFilter ? _filter : null);

  /// Every activity, in insertion order.
  List<Activity> get activities => _store.all;

  /// Every type seen so far, useful for building a filter bar.
  Set<ActivityType> get knownTypes => _store.knownTypes;

  /// The number of stored activities.
  int get length => _store.length;

  /// Whether no activities are stored.
  bool get isEmpty => _store.isEmpty;

  /// The span from the earliest to the latest activity, or null when empty.
  DateTimeRange? get dataBounds => _store.dataBounds;

  // ------------------------------------------------------------------ filter

  /// The type currently being shown exclusively, or null when unfiltered.
  ActivityType? get activeFilter => _filter;

  /// Restricts the view to activities of [type].
  ///
  /// The heatmap redraws from the filtered data, and the intensity scale is
  /// recomputed from it too, so the colour ramp stays meaningful instead of
  /// collapsing into its lightest shade.
  ///
  /// Passing null or [ActivityType.all] clears the filter. Note that a
  /// specific type never matches activities left on [ActivityType.all]; see
  /// [ActivityType] for why.
  void filter(ActivityType? type) {
    final ActivityType? next = (type == null || type.isAll) ? null : type;
    if (next == _filter) {
      return;
    }
    _filter = next;
    _changed();
  }

  /// Removes the active filter.
  void clearFilter() => filter(null);

  // ------------------------------------------------------------------ config

  /// The active configuration.
  ActivityHeatmapConfig get config => _config;

  /// Replaces the configuration.
  void setConfig(ActivityHeatmapConfig config) {
    if (config == _config) {
      return;
    }
    _config = config;
    _changed();
  }

  /// Derives a new configuration from the current one.
  ///
  /// ```dart
  /// calendar.updateConfig((c) => c.copyWith(splitMonthView: true));
  /// ```
  void updateConfig(
    ActivityHeatmapConfig Function(ActivityHeatmapConfig config) update,
  ) => setConfig(update(_config));

  // ------------------------------------------------------------- scroll / UI

  /// Scrolls every attached view so [date] is visible.
  ///
  /// [alignment] places the day in the viewport: `0` at the leading edge,
  /// `0.5` centred — the default — and `1` at the trailing edge. Dates outside
  /// the configured range scroll as close as the range allows.
  ///
  /// Calling this before a view is laid out is fine: the request is remembered
  /// and applied without animation as soon as a view attaches, so you can call
  /// it from `initState` or even before `runApp`.
  Future<void> goto(
    DateTime date, {
    double alignment = 0.5,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (_attachments.isEmpty) {
      _pendingGoto = _PendingGoto(date, alignment);
      return;
    }
    _pendingGoto = null;
    await Future.wait(<Future<void>>[
      for (final HeatmapViewAttachment attachment
          in List<HeatmapViewAttachment>.of(_attachments))
        attachment.scrollToDate(
          date,
          alignment: alignment,
          animate: animate,
          duration: duration,
          curve: curve,
        ),
    ]);
  }

  /// Scrolls every attached view to today.
  Future<void> gotoToday({
    double alignment = 0.5,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
  }) => goto(
    _config.resolvedToday,
    alignment: alignment,
    animate: animate,
    duration: duration,
    curve: curve,
  );

  /// Registers a view so [goto] can drive it. Called by the view itself.
  void attach(HeatmapViewAttachment attachment) {
    if (!_attachments.contains(attachment)) {
      _attachments.add(attachment);
    }
  }

  /// Unregisters a view. Called by the view itself.
  void detach(HeatmapViewAttachment attachment) =>
      _attachments.remove(attachment);

  /// Consumes the queued [goto] target, if any.
  ///
  /// A view calls this during its first layout so it can land on the requested
  /// day directly instead of jumping there after a frame.
  DateTime? takePendingGoto() {
    final _PendingGoto? pending = _pendingGoto;
    _pendingGoto = null;
    return pending?.date;
  }

  /// The alignment of the queued [goto] target, or the configured initial
  /// alignment when nothing is queued.
  double get pendingGotoAlignment =>
      _pendingGoto?.alignment ?? _config.initialAlignment;

  // -------------------------------------------------------------- heat model

  /// The span of days the grid covers, resolved from `config.range`.
  DateTimeRange resolveRange() => _config.range.resolve(
    today: _config.resolvedToday,
    dataBounds: _store.dataBounds,
  );

  /// The daily values and intensity scale for [range].
  ///
  /// Recomputed only when the data, the filter or the relevant configuration
  /// changes; repeated calls within a build pass return the same object.
  ///
  /// [levelResolver] and [activityWeight] default to this controller's
  /// configuration. A view rendering with a local configuration passes its own
  /// so that the override reaches the heat model, not just the layout.
  HeatmapData heatmapData(
    DateTimeRange range, {
    int? levelCount,
    HeatmapLevelResolver? levelResolver,
    ActivityWeight? activityWeight,
  }) {
    final int levels = levelCount ?? _config.colorTheme.levelCount;
    final HeatmapLevelResolver resolver =
        levelResolver ?? _config.levelResolver;
    final ActivityWeight? weightOf = activityWeight ?? _config.activityWeight;
    final Object key = Object.hash(
      _store.version,
      _filter,
      range.start,
      range.end,
      levels,
      resolver,
      weightOf,
    );
    final HeatmapData? cached = _cachedData;
    if (cached != null && _cachedDataKey == key) {
      return cached;
    }

    final Map<int, int> values = _store.dailyCounts(
      range,
      type: _filter,
      weightOf: weightOf,
    );
    final HeatmapLevelScale scale = resolver.prepare(values.values, levels);
    final HeatmapData data = HeatmapData(dailyValues: values, scale: scale);
    _cachedData = data;
    _cachedDataKey = key;
    return data;
  }

  // ----------------------------------------------------------------- private

  void _changed() {
    _cachedData = null;
    _cachedDataKey = null;
    if (_batchDepth > 0) {
      _batchDirty = true;
      return;
    }
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    _trackedListeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _trackedListeners.remove(listener);
    super.removeListener(listener);
  }

  /// Clears data, filter, configuration, attachments and listeners.
  ///
  /// Because the singleton outlives a widget tree, tests that share it would
  /// otherwise leak state into each other. Call this from `setUp`.
  @visibleForTesting
  void resetForTest() {
    for (final VoidCallback listener in List<VoidCallback>.of(
      _trackedListeners,
    )) {
      super.removeListener(listener);
    }
    _trackedListeners.clear();
    _store.clear();
    _attachments.clear();
    _filter = null;
    _config = const ActivityHeatmapConfig();
    _pendingGoto = null;
    _batchDepth = 0;
    _batchDirty = false;
    _cachedData = null;
    _cachedDataKey = null;
  }

  /// Disposes a named instance and unregisters it.
  ///
  /// Disposing the singleton is a mistake — it is global and other parts of
  /// the app may still hold listeners — so it is a no-op in release and
  /// asserts in debug.
  @override
  void dispose() {
    if (isDefaultInstance) {
      assert(
        false,
        'The default ActivityHeatmapCalendar is a singleton and must not be '
        'disposed. Use ActivityHeatmapCalendar.named() for instances with a '
        'bounded lifetime, or resetForTest() to clear state in tests.',
      );
      return;
    }
    _instances.remove(name);
    super.dispose();
  }

  @override
  String toString() =>
      'ActivityHeatmapCalendar($name, ${_store.length} activities'
      '${_filter == null ? '' : ', filtered by ${_filter!.id}'})';
}
