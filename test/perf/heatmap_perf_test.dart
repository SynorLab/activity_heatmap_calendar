import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// Guards the two properties that keep a ten year graph usable: the grid is
/// built lazily, and the store answers queries without scanning everything.
///
/// The time budgets are deliberately loose — they are there to catch a change
/// in complexity, not to measure the machine.
void main() {
  late ActivityHeatmapCalendar calendar;

  setUp(() {
    calendar = ActivityHeatmapCalendar()..resetForTest();
  });

  /// 100 000 activities spread over ten years.
  void seedLarge() {
    final DateTime start = DateTime(2016, 6, 15);
    calendar.batch(() {
      for (int i = 0; i < 100000; i++) {
        calendar.insert(
          act(
            'a$i',
            HeatmapDateUtils.addDays(start, i % 3650),
            type: i.isEven ? kWorkout : kReading,
          ),
        );
      }
    });
  }

  test('inserting a hundred thousand activities stays fast', () {
    final Stopwatch watch = Stopwatch()..start();
    seedLarge();
    watch.stop();

    expect(calendar.length, 100000);
    expect(watch.elapsedMilliseconds, lessThan(3000));
  });

  test('day and range queries do not scan the store', () {
    seedLarge();

    final Stopwatch watch = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      calendar.showActivities(DateTime(2020, 6, 15));
      calendar.showActivitiesBetween(DateTime(2020, 6), DateTime(2020, 6, 30));
    }
    watch.stop();

    expect(watch.elapsedMilliseconds, lessThan(1000));
  });

  test('the heat model for a ten year range is computed once', () {
    seedLarge();
    final DateTimeRange range = DateTimeRange(
      start: DateTime(2016, 6, 15),
      end: DateTime(2026, 6, 15),
    );

    final Stopwatch cold = Stopwatch()..start();
    final HeatmapData first = calendar.heatmapData(range);
    cold.stop();

    final Stopwatch warm = Stopwatch()..start();
    final HeatmapData second = calendar.heatmapData(range);
    warm.stop();

    expect(first.dailyValues.length, greaterThan(3000));
    expect(identical(first, second), isTrue);
    expect(cold.elapsedMilliseconds, lessThan(1000));
    expect(warm.elapsedMicroseconds, lessThan(cold.elapsedMicroseconds + 1000));
  });

  testWidgets('a ten year graph only builds the visible columns', (
    WidgetTester tester,
  ) async {
    seedLarge();
    await pumpView(
      tester,
      config: baseConfig().copyWith(
        range: HeatmapRange.explicit(
          DateTime(2016, 6, 15),
          DateTime(2026, 6, 15),
        ),
      ),
    );

    // 522 columns exist; a 600 pixel viewport shows roughly 22 of them.
    final int built = find.byType(HeatmapCell).evaluate().length;
    expect(built, lessThan(60 * 7));
    expect(built, greaterThan(0));
  });

  testWidgets('scrolling a ten year graph does not throw', (
    WidgetTester tester,
  ) async {
    seedLarge();
    await pumpView(
      tester,
      config: baseConfig().copyWith(
        range: HeatmapRange.explicit(
          DateTime(2016, 6, 15),
          DateTime(2026, 6, 15),
        ),
      ),
    );

    final Offset grid = tester.getCenter(find.byType(Scrollable).first);
    for (int i = 0; i < 5; i++) {
      await tester.dragFrom(grid, const Offset(-800, 0));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('goto lands on a date far from the start', (
    WidgetTester tester,
  ) async {
    seedLarge();
    await pumpView(
      tester,
      config: baseConfig().copyWith(
        range: HeatmapRange.explicit(
          DateTime(2016, 6, 15),
          DateTime(2026, 6, 15),
        ),
      ),
    );

    await calendar.goto(DateTime(2021, 3, 17), animate: false);
    await tester.pumpAndSettle();

    expect(cellFinder(DateTime(2021, 3, 17)), findsOneWidget);
  });
}
