import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart' show Curve, Curves, DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

const ActivityType kWorkout = ActivityType('workout', label: 'Workout');
const ActivityType kReading = ActivityType('reading', label: 'Reading');

BaseActivity act(
  String name,
  DateTime date, {
  ActivityType type = ActivityType.all,
}) => BaseActivity(name: name, date: date, type: type);

/// Records a scroll request instead of performing one.
class FakeAttachment implements HeatmapViewAttachment {
  final List<({DateTime date, double alignment, bool animate})> calls =
      <({DateTime date, double alignment, bool animate})>[];

  @override
  HeatmapGridModel? gridModel;

  @override
  double? viewportWidth;

  @override
  Future<void> scrollToDate(
    DateTime date, {
    double alignment = 0.5,
    bool animate = true,
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) async {
    calls.add((date: date, alignment: alignment, animate: animate));
  }
}

void main() {
  late ActivityHeatmapCalendar calendar;

  setUp(() {
    calendar = ActivityHeatmapCalendar()..resetForTest();
  });

  group('singleton', () {
    test('the factory always returns the same instance', () {
      expect(
        identical(ActivityHeatmapCalendar(), ActivityHeatmapCalendar()),
        isTrue,
      );
      expect(
        identical(ActivityHeatmapCalendar(), ActivityHeatmapCalendar.instance),
        isTrue,
      );
    });

    test('named instances are distinct and cached', () {
      final ActivityHeatmapCalendar a = ActivityHeatmapCalendar.named('a');
      final ActivityHeatmapCalendar b = ActivityHeatmapCalendar.named('b');
      expect(identical(a, ActivityHeatmapCalendar.named('a')), isTrue);
      expect(identical(a, b), isFalse);
      expect(identical(a, ActivityHeatmapCalendar()), isFalse);

      a.insert(act('only in a', DateTime(2026, 3, 2)));
      expect(b.length, 0);
      expect(ActivityHeatmapCalendar().length, 0);

      a.dispose();
      b.dispose();
    });

    test('disposing a named instance unregisters it', () {
      final ActivityHeatmapCalendar a = ActivityHeatmapCalendar.named('temp')
        ..insert(act('x', DateTime(2026, 3, 2)));
      a.dispose();
      expect(ActivityHeatmapCalendar.named('temp').length, 0);
      ActivityHeatmapCalendar.named('temp').dispose();
    });

    test('disposing the singleton asserts instead of breaking the app', () {
      expect(ActivityHeatmapCalendar().dispose, throwsAssertionError);
    });
  });

  group('change notification', () {
    late int notifications;

    setUp(() {
      notifications = 0;
      calendar.addListener(() => notifications++);
    });

    test('a single insert notifies once', () {
      calendar.insert(act('a', DateTime(2026, 3, 2)));
      expect(notifications, 1);
    });

    test('insertAll notifies once', () {
      calendar.insertAll(<Activity>[
        act('a', DateTime(2026, 3, 2)),
        act('b', DateTime(2026, 3, 3)),
      ]);
      expect(notifications, 1);
    });

    test('a batch of 100 inserts notifies once', () {
      calendar.batch(() {
        for (int i = 0; i < 100; i++) {
          calendar.insert(act('a$i', DateTime(2026, 3, 2)));
        }
      });
      expect(notifications, 1);
      expect(calendar.length, 100);
    });

    test('nested batches notify once, at the outermost exit', () {
      calendar.batch(() {
        calendar.insert(act('a', DateTime(2026, 3, 2)));
        calendar.batch(() {
          calendar.insert(act('b', DateTime(2026, 3, 3)));
        });
        expect(notifications, 0, reason: 'inner batch must not notify');
      });
      expect(notifications, 1);
    });

    test('an empty batch does not notify', () {
      calendar.batch(() {});
      expect(notifications, 0);
    });

    test('a batch that throws still restores the depth', () {
      expect(
        () => calendar.batch(() => throw StateError('boom')),
        throwsStateError,
      );
      calendar.insert(act('a', DateTime(2026, 3, 2)));
      expect(notifications, 1);
    });

    test('a no-op mutation does not notify', () {
      calendar
        ..clear()
        ..removeWhere((Activity a) => false)
        ..filter(null)
        ..setConfig(const ActivityHeatmapConfig());
      expect(notifications, 0);
    });

    test('remove notifies only when something was removed', () {
      final BaseActivity a = act('a', DateTime(2026, 3, 2));
      calendar.insert(a);
      expect(notifications, 1);
      expect(calendar.remove(a), isTrue);
      expect(notifications, 2);
      expect(calendar.remove(a), isFalse);
      expect(notifications, 2);
    });

    test('setConfig and filter notify', () {
      calendar
        ..setConfig(const ActivityHeatmapConfig(splitMonthView: true))
        ..filter(kWorkout);
      expect(notifications, 2);
    });
  });

  group('queries', () {
    setUp(() {
      calendar.insertAll(<Activity>[
        act('w1', DateTime(2026, 3, 2), type: kWorkout),
        act('r1', DateTime(2026, 3, 2), type: kReading),
        act('w2', DateTime(2026, 3, 5), type: kWorkout),
        act('r2', DateTime(2026, 4), type: kReading),
      ]);
    });

    test('showActivities ignores the filter by default', () {
      calendar.filter(kWorkout);
      expect(calendar.showActivities(DateTime(2026, 3, 2)).length, 2);
    });

    test('showActivities can respect the filter', () {
      calendar.filter(kWorkout);
      final List<Activity> filtered = calendar.showActivities(
        DateTime(2026, 3, 2),
        respectFilter: true,
      );
      expect(filtered.map((Activity a) => a.name), <String>['w1']);
    });

    test('showActivitiesBetween ignores the filter by default', () {
      calendar.filter(kWorkout);
      expect(
        calendar
            .showActivitiesBetween(DateTime(2026, 3), DateTime(2026, 4, 30))
            .length,
        4,
      );
    });

    test('showActivitiesBetween can respect the filter', () {
      calendar.filter(kReading);
      expect(
        calendar
            .showActivitiesBetween(
              DateTime(2026, 3),
              DateTime(2026, 4, 30),
              respectFilter: true,
            )
            .map((Activity a) => a.name),
        <String>['r1', 'r2'],
      );
    });

    test('countOn respects the filter by default', () {
      expect(calendar.countOn(DateTime(2026, 3, 2)), 2);
      calendar.filter(kWorkout);
      expect(calendar.countOn(DateTime(2026, 3, 2)), 1);
      expect(calendar.countOn(DateTime(2026, 3, 2), respectFilter: false), 2);
    });

    test('knownTypes reports every inserted type', () {
      expect(calendar.knownTypes, <ActivityType>{kWorkout, kReading});
    });

    test('dataBounds spans the data', () {
      expect(calendar.dataBounds!.start, DateTime(2026, 3, 2));
      expect(calendar.dataBounds!.end, DateTime(2026, 4));
    });
  });

  group('filter', () {
    test('ActivityType.all clears the filter, like null', () {
      calendar
        ..insert(act('a', DateTime(2026, 3, 2), type: kWorkout))
        ..filter(kWorkout);
      expect(calendar.activeFilter, kWorkout);

      calendar.filter(ActivityType.all);
      expect(calendar.activeFilter, isNull);

      calendar
        ..filter(kWorkout)
        ..clearFilter();
      expect(calendar.activeFilter, isNull);
    });

    test('a specific type excludes uncategorised activities', () {
      calendar
        ..insert(act('typed', DateTime(2026, 3, 2), type: kWorkout))
        ..insert(act('untyped', DateTime(2026, 3, 2)))
        ..filter(kWorkout);
      expect(
        calendar
            .showActivities(DateTime(2026, 3, 2), respectFilter: true)
            .map((Activity a) => a.name),
        <String>['typed'],
      );
    });
  });

  group('heatmapData', () {
    test('recomputes the scale from the filtered data', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime(2026, 3),
        end: DateTime(2026, 3, 31),
      );
      // Ten workouts on one day, one reading on another.
      calendar.insertAll(<Activity>[
        for (int i = 0; i < 10; i++)
          act('w$i', DateTime(2026, 3, 2), type: kWorkout),
        act('r', DateTime(2026, 3, 5), type: kReading),
      ]);

      final HeatmapData unfiltered = calendar.heatmapData(range);
      expect(unfiltered.valueOf(20260302), 10);
      expect(unfiltered.valueOf(20260305), 1);

      calendar.filter(kReading);
      final HeatmapData filtered = calendar.heatmapData(range);
      expect(filtered.valueOf(20260302), 0);
      expect(filtered.valueOf(20260305), 1);
      expect(filtered.maxValue, 1);
      expect(filtered.activeDayCount, 1);
    });

    test('is cached until something changes', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime(2026, 3),
        end: DateTime(2026, 3, 31),
      );
      calendar.insert(act('a', DateTime(2026, 3, 2)));
      final HeatmapData first = calendar.heatmapData(range);
      expect(identical(calendar.heatmapData(range), first), isTrue);

      calendar.insert(act('b', DateTime(2026, 3, 2)));
      expect(identical(calendar.heatmapData(range), first), isFalse);
    });

    test('applies the configured activity weight', () {
      calendar
        ..setConfig(
          ActivityHeatmapConfig(
            activityWeight: (Activity a) => a.detail as int? ?? 1,
          ),
        )
        ..insert(
          BaseActivity(name: 'run', date: DateTime(2026, 3, 2), detail: 30),
        );

      final HeatmapData data = calendar.heatmapData(
        DateTimeRange(start: DateTime(2026, 3), end: DateTime(2026, 3, 31)),
      );
      expect(data.valueOf(20260302), 30);
    });

    test('an explicit resolver and weight override the configuration', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime(2026, 3),
        end: DateTime(2026, 3, 31),
      );
      calendar.insertAll(<Activity>[
        for (int i = 0; i < 4; i++)
          BaseActivity(name: 'a$i', date: DateTime(2026, 3, 2), detail: 5),
        BaseActivity(name: 'b', date: DateTime(2026, 3, 5), detail: 5),
      ]);

      // The controller is configured with the fixed GitHub thresholds and no
      // weighting; a view rendering with its own configuration must get its
      // own heat model, not the controller's.
      final HeatmapData local = calendar.heatmapData(
        range,
        levelResolver: const RelativeLevelResolver(),
        activityWeight: (Activity a) => a.detail! as int,
      );
      expect(local.valueOf(20260302), 20);
      expect(local.scale.thresholds, <int>[1, 5, 10, 15]);
      expect(local.scale.levelOf(20), 4);

      // ...and the controller's own view is unaffected.
      final HeatmapData shared = calendar.heatmapData(range);
      expect(shared.valueOf(20260302), 4);
    });
  });

  group('resolveRange', () {
    test('follows the configured range', () {
      calendar.setConfig(
        ActivityHeatmapConfig(
          range: const HeatmapRange.year(2026),
          today: DateTime(2026, 6, 15),
        ),
      );
      expect(calendar.resolveRange().start, DateTime(2026));
      expect(calendar.resolveRange().end, DateTime(2026, 12, 31));
    });

    test('auto follows the data', () {
      calendar
        ..setConfig(
          ActivityHeatmapConfig(
            range: const HeatmapRange.auto(),
            today: DateTime(2026, 6, 15),
          ),
        )
        ..insertAll(<Activity>[
          act('a', DateTime(2026, 3, 10)),
          act('b', DateTime(2026, 4, 10)),
        ]);
      expect(calendar.resolveRange().start, DateTime(2026, 3, 3));
      expect(calendar.resolveRange().end, DateTime(2026, 4, 17));
    });

    test('auto falls back to twelve months with no data', () {
      calendar.setConfig(
        ActivityHeatmapConfig(
          range: const HeatmapRange.auto(),
          today: DateTime(2026, 6, 15),
        ),
      );
      expect(calendar.resolveRange().start, DateTime(2025, 6, 16));
      expect(calendar.resolveRange().end, DateTime(2026, 6, 15));
    });
  });

  group('goto', () {
    test('drives every attached view', () async {
      final FakeAttachment a = FakeAttachment();
      final FakeAttachment b = FakeAttachment();
      calendar
        ..attach(a)
        ..attach(b);

      await calendar.goto(DateTime(2026, 3, 2), alignment: 0.25);

      expect(a.calls.single.date, DateTime(2026, 3, 2));
      expect(a.calls.single.alignment, 0.25);
      expect(b.calls.single.date, DateTime(2026, 3, 2));
    });

    test('queues the target when no view is attached yet', () async {
      await calendar.goto(DateTime(2026, 3, 2), alignment: 0.25);
      expect(calendar.pendingGotoAlignment, 0.25);
      expect(calendar.takePendingGoto(), DateTime(2026, 3, 2));
      // Consumed exactly once.
      expect(calendar.takePendingGoto(), isNull);
    });

    test('the queue falls back to the configured initial alignment', () {
      calendar.setConfig(const ActivityHeatmapConfig(initialAlignment: 0));
      expect(calendar.takePendingGoto(), isNull);
      expect(calendar.pendingGotoAlignment, 0);
    });

    test('attaching twice does not scroll twice', () async {
      final FakeAttachment a = FakeAttachment();
      calendar
        ..attach(a)
        ..attach(a);
      await calendar.goto(DateTime(2026, 3, 2));
      expect(a.calls.length, 1);
    });

    test('a detached view is no longer driven', () async {
      final FakeAttachment a = FakeAttachment();
      calendar
        ..attach(a)
        ..detach(a);
      await calendar.goto(DateTime(2026, 3, 2));
      expect(a.calls, isEmpty);
    });

    test('gotoToday uses the configured today', () async {
      final FakeAttachment a = FakeAttachment();
      calendar
        ..setConfig(ActivityHeatmapConfig(today: DateTime(2026, 6, 15)))
        ..attach(a);
      await calendar.gotoToday();
      expect(a.calls.single.date, DateTime(2026, 6, 15));
    });
  });

  group('config', () {
    test('updateConfig derives from the current config', () {
      calendar
        ..setConfig(const ActivityHeatmapConfig(weekStartsOn: DateTime.sunday))
        ..updateConfig(
          (ActivityHeatmapConfig c) => c.copyWith(splitMonthView: true),
        );
      expect(calendar.config.weekStartsOn, DateTime.sunday);
      expect(calendar.config.splitMonthView, isTrue);
    });
  });

  test('resetForTest clears everything', () {
    final FakeAttachment a = FakeAttachment();
    calendar
      ..insert(act('a', DateTime(2026, 3, 2), type: kWorkout))
      ..filter(kWorkout)
      ..setConfig(const ActivityHeatmapConfig(splitMonthView: true))
      ..attach(a)
      ..resetForTest();

    expect(calendar.isEmpty, isTrue);
    expect(calendar.activeFilter, isNull);
    expect(calendar.config, const ActivityHeatmapConfig());
    expect(calendar.takePendingGoto(), isNull);
  });
}
