import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// Golden tests for the layouts that are hard to assert on with finders:
/// spacing, alignment of the labels against the grid, and the colour ramps.
///
/// Regenerate with `flutter test --update-goldens`.
void main() {
  late ActivityHeatmapCalendar calendar;

  setUp(() {
    calendar = ActivityHeatmapCalendar()..resetForTest();
    // A deterministic, visually varied month and a half.
    final DateTime start = DateTime(2026, 5, 4);
    for (int i = 0; i < 45; i++) {
      final DateTime day = HeatmapDateUtils.addDays(start, i);
      final int count = <int>[0, 1, 2, 4, 7, 11, 3][i % 7];
      for (int n = 0; n < count; n++) {
        calendar.insert(
          act('a$i-$n', day, type: n.isEven ? kWorkout : kReading),
        );
      }
    }
  });

  Future<void> pumpGolden(
    WidgetTester tester, {
    required ActivityHeatmapConfig config,
    ThemeData? theme,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(760, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        debugShowCheckedModeBanner: false,
        theme: theme ?? ThemeData.light(useMaterial3: true),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          ActivityHeatmapLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: ActivityHeatmapLocalizations.supportedLocales,
        home: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey<String>('golden'),
                child: SizedBox(
                  width: 720,
                  child: ActivityHeatmapCalendarView(config: config),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectGolden(WidgetTester tester, String name) => expectLater(
    find.byKey(const ValueKey<String>('golden')),
    matchesGoldenFile('goldens/$name.png'),
  );

  testWidgets('continuous, light', (WidgetTester tester) async {
    await pumpGolden(tester, config: baseConfig());
    await expectGolden(tester, 'continuous_light');
  });

  testWidgets('continuous, dark', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      config: baseConfig(),
      theme: ThemeData.dark(useMaterial3: true),
    );
    await expectGolden(tester, 'continuous_dark');
  });

  testWidgets('split month, light', (WidgetTester tester) async {
    await pumpGolden(tester, config: baseConfig(splitMonthView: true));
    await expectGolden(tester, 'split_month_light');
  });

  testWidgets('split month, dark', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      config: baseConfig(splitMonthView: true),
      theme: ThemeData.dark(useMaterial3: true),
    );
    await expectGolden(tester, 'split_month_dark');
  });

  testWidgets('no labels, no legend', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      config: baseConfig(
        showMonthLabels: false,
        showWeekdayLabels: false,
        showLegend: false,
      ),
    );
    await expectGolden(tester, 'bare');
  });

  testWidgets('small cells', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      config: baseConfig(
        cellStyle: const HeatmapCellStyle(size: 11, radius: 2, spacing: 2),
      ),
    );
    await expectGolden(tester, 'small_cells');
  });

  testWidgets('right to left', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      config: baseConfig(),
      textDirection: TextDirection.rtl,
    );
    await expectGolden(tester, 'rtl');
  });

  testWidgets('filtered and re-tinted', (WidgetTester tester) async {
    calendar.filter(kWorkout);
    await pumpGolden(tester, config: baseConfig());
    await expectGolden(tester, 'filtered');
  });

  testWidgets('a custom theme', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      config: baseConfig().copyWith(colorTheme: HeatmapColorTheme.violet),
    );
    await expectGolden(tester, 'violet');
  });

  testWidgets('the detail sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(useMaterial3: true),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          ActivityHeatmapLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey<String>('golden'),
            child: DefaultActivityBottomSheet(
              date: DateTime(2026, 5, 20),
              activities: <Activity>[
                act(
                  'Morning run',
                  DateTime(2026, 5, 20),
                  type: kWorkout,
                  detail: '5 km, easy',
                ),
                act('Evening swim', DateTime(2026, 5, 20), type: kWorkout),
                act(
                  'Dune',
                  DateTime(2026, 5, 20),
                  type: kReading,
                  detail: 'chapter 12',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectGolden(tester, 'detail_sheet');
  });
}
