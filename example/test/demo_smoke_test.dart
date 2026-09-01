import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:activity_heatmap_calendar_example/demo/demo_data.dart';
import 'package:activity_heatmap_calendar_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A smoke test for the demo, so the example cannot rot silently.
void main() {
  late ActivityHeatmapCalendar calendar;

  setUp(() {
    calendar = ActivityHeatmapCalendar()
      ..resetForTest()
      ..insertAll(buildDemoActivities(today: DateTime(2026, 6, 15)));
  });

  testWidgets('the demo renders the heatmap and its controls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    expect(find.byType(ActivityHeatmapCalendarView), findsOneWidget);
    expect(find.byType(HeatmapCell), findsWidgets);
    expect(find.text('Less'), findsOneWidget);
  });

  testWidgets('a type chip filters the graph', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Reading'));
    await tester.pumpAndSettle();

    expect(calendar.activeFilter, reading);
    expect(find.text('Filtered by Reading'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(calendar.activeFilter, isNull);
  });

  testWidgets('the control panel drives the configuration', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Options'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Split month view'));
    await tester.pumpAndSettle();
    expect(calendar.config.splitMonthView, isTrue);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Legend'));
    await tester.pumpAndSettle();
    expect(calendar.config.showLegend, isFalse);
  });

  testWidgets('tapping a day opens the detail sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HeatmapCell).first);
    await tester.pumpAndSettle();

    expect(find.byType(DefaultActivityBottomSheet), findsOneWidget);
  });
}
