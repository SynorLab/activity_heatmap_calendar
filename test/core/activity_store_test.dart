import 'package:activity_heatmap_calendar/src/core/activity_store.dart';
import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

const ActivityType kWorkout = ActivityType('workout', label: 'Workout');
const ActivityType kReading = ActivityType('reading', label: 'Reading');

BaseActivity act(
  String name,
  DateTime date, {
  ActivityType type = ActivityType.all,
}) => BaseActivity(name: name, date: date, type: type);

void main() {
  late ActivityStore store;

  setUp(() => store = ActivityStore());

  group('insert', () {
    test('indexes an activity under its local calendar day', () {
      store.insert(act('A', DateTime(2026, 3, 2, 18, 30)));
      expect(store.countOn(DateTime(2026, 3, 2)), 1);
      expect(store.countOn(DateTime(2026, 3, 2, 4)), 1);
      expect(store.countOn(DateTime(2026, 3, 3)), 0);
    });

    test('keeps multiple activities on the same day in insertion order', () {
      store
        ..insert(act('first', DateTime(2026, 3, 2)))
        ..insert(act('second', DateTime(2026, 3, 2)))
        ..insert(act('third', DateTime(2026, 3, 2)));
      expect(
        store.activitiesOn(DateTime(2026, 3, 2)).map((Activity a) => a.name),
        <String>['first', 'second', 'third'],
      );
    });

    test('does not deduplicate identical instances', () {
      final BaseActivity a = act('A', DateTime(2026, 3, 2));
      store
        ..insert(a)
        ..insert(a);
      expect(store.length, 2);
    });

    test('insertAll bumps the version only once', () {
      final int before = store.version;
      store.insertAll(<Activity>[
        act('A', DateTime(2026, 3, 2)),
        act('B', DateTime(2026, 3, 3)),
      ]);
      expect(store.version, before + 1);
      expect(store.length, 2);
    });

    test('returns an unmodifiable view', () {
      store.insert(act('A', DateTime(2026, 3, 2)));
      expect(
        () => store
            .activitiesOn(DateTime(2026, 3, 2))
            .add(act('B', DateTime(2026, 3, 2))),
        throwsUnsupportedError,
      );
      expect(() => store.all.clear(), throwsUnsupportedError);
    });
  });

  group('removal', () {
    test('remove deletes by identity and reports success', () {
      final BaseActivity a = act('A', DateTime(2026, 3, 2));
      final BaseActivity b = act('A', DateTime(2026, 3, 2));
      store
        ..insert(a)
        ..insert(b);

      expect(store.remove(a), isTrue);
      expect(store.length, 1);
      expect(
        identical(store.activitiesOn(DateTime(2026, 3, 2)).single, b),
        isTrue,
      );
      expect(store.remove(a), isFalse);
    });

    test('remove drops the day bucket when it empties', () {
      final BaseActivity a = act('A', DateTime(2026, 3, 2));
      store.insert(a);
      store.remove(a);
      expect(store.dataBounds, isNull);
      expect(store.countOn(DateTime(2026, 3, 2)), 0);
    });

    test('remove keeps the type index consistent', () {
      final BaseActivity a = act('A', DateTime(2026, 3, 2), type: kWorkout);
      store
        ..insert(a)
        ..insert(act('B', DateTime(2026, 3, 3), type: kReading));

      store.remove(a);
      expect(store.knownTypes, <ActivityType>{kReading});
      expect(
        store.activitiesBetween(
          DateTime(2026, 3),
          DateTime(2026, 3, 31),
          type: kWorkout,
        ),
        isEmpty,
      );
    });

    test('removeWhere deletes every match', () {
      store.insertAll(<Activity>[
        act('keep', DateTime(2026, 3, 2), type: kReading),
        act('drop', DateTime(2026, 3, 3), type: kWorkout),
        act('drop', DateTime(2026, 3, 4), type: kWorkout),
      ]);
      store.removeWhere((Activity a) => a.type == kWorkout);
      expect(store.length, 1);
      expect(store.knownTypes, <ActivityType>{kReading});
    });

    test('removeWhere does not bump the version when nothing matches', () {
      store.insert(act('A', DateTime(2026, 3, 2)));
      final int before = store.version;
      store.removeWhere((Activity a) => a.name == 'nope');
      expect(store.version, before);
    });

    test('clear empties the store', () {
      store.insertAll(<Activity>[
        act('A', DateTime(2026, 3, 2)),
        act('B', DateTime(2026, 3, 3)),
      ]);
      store.clear();
      expect(store.isEmpty, isTrue);
      expect(store.knownTypes, isEmpty);
      expect(store.dataBounds, isNull);
    });

    test('replaceAll swaps the contents', () {
      store.insert(act('old', DateTime(2020)));
      store.replaceAll(<Activity>[act('new', DateTime(2026, 3, 2))]);
      expect(store.length, 1);
      expect(store.countOn(DateTime(2020)), 0);
      expect(store.countOn(DateTime(2026, 3, 2)), 1);
    });
  });

  group('reindex', () {
    test('picks up an in-place date change', () {
      final BaseActivity a = act('A', DateTime(2026, 3, 2));
      store.insert(a);

      a.date = DateTime(2026, 3, 9);
      expect(
        store.countOn(DateTime(2026, 3, 2)),
        1,
        reason: 'stale until reindex',
      );

      store.reindex();
      expect(store.countOn(DateTime(2026, 3, 2)), 0);
      expect(store.countOn(DateTime(2026, 3, 9)), 1);
    });

    test('picks up an in-place type change', () {
      final BaseActivity a = act('A', DateTime(2026, 3, 2), type: kWorkout);
      store.insert(a);

      a.type = kReading;
      store.reindex();
      expect(store.knownTypes, <ActivityType>{kReading});
      expect(store.countOn(DateTime(2026, 3, 2), type: kWorkout), 0);
      expect(store.countOn(DateTime(2026, 3, 2), type: kReading), 1);
    });

    test('remove still works after an in-place date change', () {
      final BaseActivity a = act('A', DateTime(2026, 3, 2));
      store.insert(a);
      a.date = DateTime(2026, 3, 9);
      expect(store.remove(a), isTrue);
      expect(store.isEmpty, isTrue);
    });
  });

  group('activitiesBetween', () {
    setUp(() {
      store.insertAll(<Activity>[
        act('dec', DateTime(2025, 12, 31), type: kWorkout),
        act('jan1', DateTime(2026), type: kReading),
        act('jan1b', DateTime(2026), type: kWorkout),
        act('mar', DateTime(2026, 3, 2), type: kReading),
        act('dec26', DateTime(2026, 12, 31), type: kWorkout),
      ]);
    });

    test('is inclusive on both ends', () {
      expect(
        store
            .activitiesBetween(DateTime(2026), DateTime(2026, 3, 2))
            .map((Activity a) => a.name),
        <String>['jan1', 'jan1b', 'mar'],
      );
    });

    test('orders by day then by insertion', () {
      expect(
        store
            .activitiesBetween(DateTime(2025), DateTime(2027))
            .map((Activity a) => a.name),
        <String>['dec', 'jan1', 'jan1b', 'mar', 'dec26'],
      );
    });

    test('spans a year boundary', () {
      expect(
        store
            .activitiesBetween(DateTime(2025, 12, 31), DateTime(2026))
            .map((Activity a) => a.name),
        <String>['dec', 'jan1', 'jan1b'],
      );
    });

    test('swaps reversed bounds', () {
      expect(
        store.activitiesBetween(DateTime(2026, 3, 2), DateTime(2026)).length,
        3,
      );
    });

    test('filters by type', () {
      expect(
        store
            .activitiesBetween(DateTime(2025), DateTime(2027), type: kReading)
            .map((Activity a) => a.name),
        <String>['jan1', 'mar'],
      );
    });

    test('treats ActivityType.all as no filter', () {
      expect(
        store
            .activitiesBetween(
              DateTime(2025),
              DateTime(2027),
              type: ActivityType.all,
            )
            .length,
        5,
      );
    });

    test('returns empty for an unknown type', () {
      expect(
        store.activitiesBetween(
          DateTime(2025),
          DateTime(2027),
          type: const ActivityType('nope'),
        ),
        isEmpty,
      );
    });

    test('ignores the time component of the bounds', () {
      expect(
        store
            .activitiesBetween(
              DateTime(2026, 1, 1, 23, 59),
              DateTime(2026, 1, 1, 0, 1),
            )
            .length,
        2,
      );
    });
  });

  group('dailyCounts', () {
    test('omits empty days and counts per day', () {
      store.insertAll(<Activity>[
        act('a', DateTime(2026, 3, 2)),
        act('b', DateTime(2026, 3, 2)),
        act('c', DateTime(2026, 3, 5)),
      ]);
      final Map<int, int> counts = store.dailyCounts(
        DateTimeRange(start: DateTime(2026, 3), end: DateTime(2026, 3, 31)),
      );
      expect(counts, <int, int>{20260302: 2, 20260305: 1});
    });

    test('clips to the requested range', () {
      store.insertAll(<Activity>[
        act('before', DateTime(2026, 2, 28)),
        act('inside', DateTime(2026, 3, 2)),
        act('after', DateTime(2026, 4)),
      ]);
      final Map<int, int> counts = store.dailyCounts(
        DateTimeRange(start: DateTime(2026, 3), end: DateTime(2026, 3, 31)),
      );
      expect(counts.keys, <int>[20260302]);
    });

    test('respects the type filter', () {
      store.insertAll(<Activity>[
        act('w', DateTime(2026, 3, 2), type: kWorkout),
        act('r', DateTime(2026, 3, 2), type: kReading),
        act('r2', DateTime(2026, 3, 3), type: kReading),
      ]);
      final DateTimeRange range = DateTimeRange(
        start: DateTime(2026, 3),
        end: DateTime(2026, 3, 31),
      );
      expect(store.dailyCounts(range, type: kWorkout), <int, int>{20260302: 1});
      expect(store.dailyCounts(range, type: kReading), <int, int>{
        20260302: 1,
        20260303: 1,
      });
    });

    test('caches by range and type, and invalidates on mutation', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime(2026, 3),
        end: DateTime(2026, 3, 31),
      );
      store.insert(act('a', DateTime(2026, 3, 2)));
      final Map<int, int> first = store.dailyCounts(range);
      expect(identical(store.dailyCounts(range), first), isTrue);

      store.insert(act('b', DateTime(2026, 3, 2)));
      final Map<int, int> second = store.dailyCounts(range);
      expect(identical(second, first), isFalse);
      expect(second[20260302], 2);
    });

    test('is unmodifiable', () {
      store.insert(act('a', DateTime(2026, 3, 2)));
      final Map<int, int> counts = store.dailyCounts(
        DateTimeRange(start: DateTime(2026, 3), end: DateTime(2026, 3, 31)),
      );
      expect(() => counts[1] = 1, throwsUnsupportedError);
    });
  });

  group('metadata', () {
    test('dataBounds spans the earliest and latest day', () {
      store.insertAll(<Activity>[
        act('mid', DateTime(2026, 3, 2)),
        act('late', DateTime(2026, 12, 31)),
        act('early', DateTime(2024, 2, 29)),
      ]);
      expect(store.dataBounds!.start, DateTime(2024, 2, 29));
      expect(store.dataBounds!.end, DateTime(2026, 12, 31));
    });

    test('knownTypes keeps the richest instance of each id', () {
      store.insert(act('a', DateTime(2026, 3, 2), type: kWorkout));
      expect(store.knownTypes.single.label, 'Workout');
    });

    test('uncategorised activities register ActivityType.all', () {
      store.insert(act('a', DateTime(2026, 3, 2)));
      expect(store.knownTypes, <ActivityType>{ActivityType.all});
    });
  });

  test('bulk insert of 100k activities stays fast', () {
    final DateTime origin = DateTime(2020);
    final List<Activity> bulk = List<Activity>.generate(
      100000,
      (int i) => act('a$i', HeatmapDateUtils.addDays(origin, i % 2000)),
    );

    final Stopwatch sw = Stopwatch()..start();
    store.insertAll(bulk);
    sw.stop();

    expect(store.length, 100000);
    expect(
      sw.elapsedMilliseconds,
      lessThan(2000),
      reason: 'insertAll took ${sw.elapsedMilliseconds}ms',
    );

    final Stopwatch query = Stopwatch()..start();
    store.dailyCounts(
      DateTimeRange(start: origin, end: HeatmapDateUtils.addDays(origin, 400)),
    );
    query.stop();
    expect(
      query.elapsedMilliseconds,
      lessThan(200),
      reason: 'dailyCounts took ${query.elapsedMilliseconds}ms',
    );
  });
}
