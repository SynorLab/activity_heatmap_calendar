import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// Requirement 7 end to end: `filter` must not merely hide list entries, it
/// must change what the graph is drawn from — the daily values, the intensity
/// scale derived from them, and the colour ramp.
void main() {
  late ActivityHeatmapCalendar calendar;

  setUp(() {
    calendar = ActivityHeatmapCalendar()..resetForTest();
  });

  /// Ten readings and one workout on the 10th, two workouts on the 11th.
  ///
  /// Unfiltered the 10th dominates; filtered to workouts the 11th does, which
  /// is only visible if the scale is rebuilt from the filtered values.
  void seed() {
    calendar.insertAll(<Activity>[
      for (int i = 0; i < 10; i++)
        act('read $i', DateTime(2026, 6, 10), type: kReading),
      act('lift', DateTime(2026, 6, 10), type: kWorkout),
      act('run', DateTime(2026, 6, 11), type: kWorkout),
      act('swim', DateTime(2026, 6, 11), type: kWorkout),
    ]);
  }

  group('heat source', () {
    testWidgets('only the filtered type contributes heat', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      expect(cellLevel(tester, DateTime(2026, 6, 10)), 4);

      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      // Eleven activities on the 10th, but only one of them is a workout.
      expect(cellData(tester, DateTime(2026, 6, 10))!.count, 1);
      expect(cellData(tester, DateTime(2026, 6, 11))!.count, 2);
    });

    testWidgets('a day left with nothing is painted empty', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('read', DateTime(2026, 6, 10), type: kReading));
      await pumpView(tester);
      expect(cellLevel(tester, DateTime(2026, 6, 10)), 1);

      calendar.filter(kWorkout);
      await tester.pumpAndSettle();
      expect(cellLevel(tester, DateTime(2026, 6, 10)), 0);
    });
  });

  group('scale recomputation', () {
    testWidgets('the level scale is rebuilt from the filtered values', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(
        tester,
        config: baseConfig(levelResolver: const RelativeLevelResolver()),
      );

      // Unfiltered the busiest day has 11 activities, so two workouts barely
      // register.
      expect(cellLevel(tester, DateTime(2026, 6, 10)), 4);
      expect(cellLevel(tester, DateTime(2026, 6, 11)), 1);

      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      // Filtered the busiest day has two, so the same two workouts now sit a
      // level above the single one. A scale that was not recomputed would
      // leave both days at level 1.
      expect(cellLevel(tester, DateTime(2026, 6, 10)), 1);
      expect(cellLevel(tester, DateTime(2026, 6, 11)), 2);
    });

    testWidgets('clearing the filter restores the original scale', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(
        tester,
        config: baseConfig(levelResolver: const RelativeLevelResolver()),
      );
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();
      calendar.clearFilter();
      await tester.pumpAndSettle();

      expect(cellLevel(tester, DateTime(2026, 6, 10)), 4);
      expect(cellLevel(tester, DateTime(2026, 6, 11)), 1);
    });

    testWidgets('the legend follows the filtered scale', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      final HeatmapLegend legend = tester.widget<HeatmapLegend>(
        find.byType(HeatmapLegend),
      );
      expect(legend.spec.activeFilter, kWorkout);
      expect(
        legend.spec.theme.levelColors.first,
        isNot(HeatmapColorTheme.github.levelColors.first),
      );
    });
  });

  group('filter identity', () {
    testWidgets('filter(ActivityType.all) is the same as clearFilter', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      final int? before = cellLevel(tester, DateTime(2026, 6, 10));

      calendar.filter(kWorkout);
      await tester.pumpAndSettle();
      calendar.filter(ActivityType.all);
      await tester.pumpAndSettle();

      expect(calendar.activeFilter, isNull);
      expect(cellLevel(tester, DateTime(2026, 6, 10)), before);
      expect(find.textContaining('Filtered by'), findsNothing);
    });

    testWidgets('filter(null) clears too', (WidgetTester tester) async {
      seed();
      await pumpView(tester);
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();
      calendar.filter(null);
      await tester.pumpAndSettle();

      expect(calendar.activeFilter, isNull);
      expect(cellLevel(tester, DateTime(2026, 6, 10)), 4);
    });

    testWidgets('an unknown type yields an empty graph without crashing', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      calendar.filter(const ActivityType('ghost', label: 'Ghost'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(cellLevel(tester, DateTime(2026, 6, 10)), 0);
      expect(cellLevel(tester, DateTime(2026, 6, 11)), 0);
      expect(
        calendar.showActivities(DateTime(2026, 6, 10), respectFilter: true),
        isEmpty,
      );
    });
  });

  group('colour', () {
    testWidgets('a type with a colour re-tints the ramp', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      final HeatmapColorTheme expected = HeatmapColorTheme.fromSeed(
        kWorkout.color!,
        withDarkVariant: false,
      );
      expect(
        cellColor(tester, DateTime(2026, 6, 11)),
        expected.colorForLevel(cellLevel(tester, DateTime(2026, 6, 11))!),
      );
    });

    testWidgets('a type without a colour keeps the configured ramp', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      calendar.filter(kReading);
      await tester.pumpAndSettle();

      expect(
        cellColor(tester, DateTime(2026, 6, 10)),
        HeatmapColorTheme.github.colorForLevel(4),
      );
    });

    testWidgets('re-tinting can be switched off', (WidgetTester tester) async {
      seed();
      await pumpView(
        tester,
        config: baseConfig().copyWith(useTypeColorWhenFiltered: false),
      );
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      expect(
        cellColor(tester, DateTime(2026, 6, 11)),
        HeatmapColorTheme.github.colorForLevel(1),
      );
    });
  });

  group('banner', () {
    testWidgets('names the active type and clears the filter when dismissed', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      expect(find.text('Filtered by Workout'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(calendar.activeFilter, isNull);
      expect(find.text('Filtered by Workout'), findsNothing);
    });

    testWidgets('can be hidden', (WidgetTester tester) async {
      seed();
      await pumpView(
        tester,
        config: baseConfig().copyWith(showFilterBanner: false),
      );
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      expect(find.text('Filtered by Workout'), findsNothing);
      // The filter is still applied to the graph.
      expect(cellData(tester, DateTime(2026, 6, 10))!.count, 1);
    });
  });

  group('details', () {
    testWidgets('the sheet lists only the filtered type', (
      WidgetTester tester,
    ) async {
      seed();
      await pumpView(tester);
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      await tapCell(tester, DateTime(2026, 6, 10));

      expect(find.text('lift'), findsOneWidget);
      expect(find.text('read 0'), findsNothing);
      expect(find.text('1 activity'), findsOneWidget);
    });

    testWidgets('the tap callback receives the filtered activities', (
      WidgetTester tester,
    ) async {
      seed();
      List<Activity>? received;
      await pumpView(
        tester,
        onCellTap: (DateTime date, List<Activity> activities) =>
            received = activities,
      );
      calendar.filter(kWorkout);
      await tester.pumpAndSettle();

      await tapCell(tester, DateTime(2026, 6, 11));
      expect(received!.map((Activity a) => a.name), <String>['run', 'swim']);
    });
  });
}
