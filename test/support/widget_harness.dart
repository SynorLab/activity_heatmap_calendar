import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// A type that declares its own colour, so filter re-tinting can be observed.
const ActivityType kWorkout = ActivityType(
  'workout',
  label: 'Workout',
  color: Color(0xFFE2562B),
);

/// A type without a colour, to prove re-tinting is opt-in per type.
const ActivityType kReading = ActivityType('reading', label: 'Reading');

/// A third type, useful when a test needs two coloured types.
const ActivityType kStudy = ActivityType(
  'study',
  label: 'Study',
  color: Color(0xFF3B6FE0),
);

/// The fixed "today" every widget test runs against.
final DateTime kToday = DateTime(2026, 6, 15);

/// Shorthand for a [BaseActivity].
BaseActivity act(
  String name,
  DateTime date, {
  ActivityType type = ActivityType.all,
  Object? detail,
}) => BaseActivity(name: name, date: date, type: type, detail: detail);

/// A deterministic configuration covering May–July 2026.
ActivityHeatmapConfig baseConfig({
  bool splitMonthView = false,
  bool showMonthLabels = true,
  bool showWeekdayLabels = true,
  bool showLegend = true,
  HeatmapCellStyle cellStyle = const HeatmapCellStyle(),
  HeatmapLevelResolver levelResolver = const ThresholdLevelResolver.github(),
}) {
  return ActivityHeatmapConfig(
    range: HeatmapRange.explicit(DateTime(2026, 5), DateTime(2026, 7, 31)),
    today: kToday,
    splitMonthView: splitMonthView,
    showMonthLabels: showMonthLabels,
    showWeekdayLabels: showWeekdayLabels,
    showLegend: showLegend,
    cellStyle: cellStyle,
    levelResolver: levelResolver,
    showTooltips: false,
  );
}

/// Pumps a view inside a localized [MaterialApp] of a fixed width.
Future<void> pumpView(
  WidgetTester tester, {
  ActivityHeatmapConfig? config,
  HeatmapCellTapCallback? onCellTap,
  HeatmapCellTapCallback? onCellLongPress,
  ActivitySheetBuilder? bottomSheetBuilder,
  HeatmapActivityTapCallback? onActivityTap,
  Locale locale = const Locale('en'),
  bool withDelegates = true,
  TextDirection? textDirection,
  double width = 600,
  HeatmapStringOverrides? overrides,
  ThemeData? theme,
}) async {
  Widget view = ActivityHeatmapCalendarView(
    config: config ?? baseConfig(),
    onCellTap: onCellTap,
    onCellLongPress: onCellLongPress,
    bottomSheetBuilder: bottomSheetBuilder,
    onActivityTap: onActivityTap,
  );
  if (overrides != null) {
    view = ActivityHeatmapStrings(overrides: overrides, child: view);
  }
  if (textDirection != null) {
    view = Directionality(textDirection: textDirection, child: view);
  }

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: theme,
      localizationsDelegates: withDelegates
          ? const <LocalizationsDelegate<Object>>[
              ActivityHeatmapLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ]
          : null,
      supportedLocales: ActivityHeatmapLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: view),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Finds the cell for [date].
Finder cellFinder(DateTime date) => find.byWidgetPredicate(
  (Widget w) => w is HeatmapCell && HeatmapDateUtils.isSameDay(w.date, date),
);

/// Taps the cell for [date] and settles.
Future<void> tapCell(WidgetTester tester, DateTime date) async {
  await tester.tap(cellFinder(date).first);
  await tester.pumpAndSettle();
}

/// The rendered fill colour of the cell for [date], or null when not built.
Color? cellColor(WidgetTester tester, DateTime date) {
  final Finder finder = cellFinder(date);
  if (finder.evaluate().isEmpty) {
    return null;
  }
  final Finder container = find.descendant(
    of: finder.first,
    matching: find.byType(Container),
  );
  if (container.evaluate().isEmpty) {
    // Placeholder cells render as bare space, with nothing to paint.
    return null;
  }
  final Container box = tester.widget<Container>(container.first);
  return (box.decoration! as BoxDecoration).color;
}

/// The data the view resolved for [date], or null when the cell is not built.
HeatmapCellData? cellData(WidgetTester tester, DateTime date) {
  final Finder finder = cellFinder(date);
  if (finder.evaluate().isEmpty) {
    return null;
  }
  final HeatmapCell cell = tester.widget<HeatmapCell>(finder.first);
  return cell.spec.cellDataFor(cell.date, sectionMonth: cell.sectionMonth);
}

/// The intensity level the view assigned to [date].
int? cellLevel(WidgetTester tester, DateTime date) =>
    cellData(tester, date)?.level;
