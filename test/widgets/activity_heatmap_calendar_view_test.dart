import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:activity_heatmap_calendar/src/widgets/heatmap_body_split_month.dart';
import 'package:activity_heatmap_calendar/src/widgets/heatmap_column.dart';
import 'package:activity_heatmap_calendar/src/widgets/heatmap_weekday_gutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  late ActivityHeatmapCalendar calendar;

  setUp(() {
    calendar = ActivityHeatmapCalendar()..resetForTest();
  });

  group('rendering', () {
    testWidgets('paints days by intensity level', (WidgetTester tester) async {
      calendar.insertAll(<Activity>[
        act('a', DateTime(2026, 6, 10)),
        for (int i = 0; i < 9; i++) act('b$i', DateTime(2026, 6, 11)),
      ]);
      await pumpView(tester);

      const HeatmapColorTheme theme = HeatmapColorTheme.github;
      expect(cellColor(tester, DateTime(2026, 6, 9)), theme.emptyColor);
      expect(cellColor(tester, DateTime(2026, 6, 10)), theme.colorForLevel(1));
      expect(cellColor(tester, DateTime(2026, 6, 11)), theme.colorForLevel(4));
    });

    testWidgets('renders nothing for days outside the range', (
      WidgetTester tester,
    ) async {
      await pumpView(tester);
      // 2026-05-01 is a Friday, so the first column pads back to 2026-04-27.
      final Finder padded = find.byWidgetPredicate(
        (Widget w) =>
            w is HeatmapCell &&
            HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 4, 27)),
      );
      expect(padded, findsOneWidget);
      expect(cellColor(tester, DateTime(2026, 4, 27)), isNull);
    });

    testWidgets('honours a custom cell size and radius', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        config: baseConfig(
          cellStyle: const HeatmapCellStyle(size: 12, radius: 2, spacing: 2),
        ),
      );
      final Finder finder = find.byWidgetPredicate(
        (Widget w) =>
            w is HeatmapCell &&
            HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
      );
      expect(tester.getSize(finder.first), const Size(12, 12));
    });

    testWidgets('uses a custom cell builder', (WidgetTester tester) async {
      int calls = 0;
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          cellStyle: HeatmapCellStyle(
            builder: (BuildContext context, HeatmapCellData data) {
              calls++;
              return const SizedBox.square(dimension: 24, child: Placeholder());
            },
          ),
        ),
      );
      expect(calls, greaterThan(0));
      expect(find.byType(Placeholder), findsWidgets);
    });

    testWidgets('marks today with a ring', (WidgetTester tester) async {
      await pumpView(tester);
      final Finder finder = find.byWidgetPredicate(
        (Widget w) =>
            w is HeatmapCell && HeatmapDateUtils.isSameDay(w.date, kToday),
      );
      final Container box = tester.widget<Container>(
        find
            .descendant(of: finder.first, matching: find.byType(Container))
            .first,
      );
      expect(box.foregroundDecoration, isNotNull);
    });
  });

  group('labels and chrome', () {
    testWidgets('shows month labels, weekday gutter and legend by default', (
      WidgetTester tester,
    ) async {
      await pumpView(tester);
      expect(find.text('Jun'), findsOneWidget);
      expect(find.byType(HeatmapWeekdayGutter), findsOneWidget);
      expect(find.byType(HeatmapLegend), findsOneWidget);
    });

    testWidgets('hides month labels when asked', (WidgetTester tester) async {
      await pumpView(tester, config: baseConfig(showMonthLabels: false));
      expect(find.text('Jun'), findsNothing);
    });

    testWidgets('hides the weekday gutter when asked', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, config: baseConfig(showWeekdayLabels: false));
      expect(find.byType(HeatmapWeekdayGutter), findsNothing);
    });

    testWidgets('hides the legend when asked', (WidgetTester tester) async {
      await pumpView(tester, config: baseConfig(showLegend: false));
      expect(find.byType(HeatmapLegend), findsNothing);
    });

    testWidgets('adds the year on a year change', (WidgetTester tester) async {
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          range: HeatmapRange.explicit(
            DateTime(2025, 11),
            DateTime(2026, 2, 28),
          ),
        ),
      );
      expect(find.text('Jan 2026'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
    });

    testWidgets('never shows the year when told not to', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          range: HeatmapRange.explicit(
            DateTime(2025, 11),
            DateTime(2026, 2, 28),
          ),
          yearDisplay: HeatmapYearDisplay.never,
        ),
      );
      expect(find.text('Jan 2026'), findsNothing);
      expect(find.text('Jan'), findsOneWidget);
    });

    testWidgets('shows the year on every label when told to', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        config: baseConfig().copyWith(yearDisplay: HeatmapYearDisplay.always),
      );
      expect(find.text('Jun 2026'), findsOneWidget);
      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('weekday label mode controls how many names appear', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          labels: const HeatmapLabelsConfig(
            weekdayLabelMode: HeatmapWeekdayLabelMode.all,
          ),
        ),
      );
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('weekStartsOn changes the first gutter row', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          weekStartsOn: DateTime.sunday,
          labels: const HeatmapLabelsConfig(
            weekdayLabelMode: HeatmapWeekdayLabelMode.all,
          ),
        ),
      );
      final HeatmapWeekdayGutter gutter = tester.widget(
        find.byType(HeatmapWeekdayGutter),
      );
      expect(gutter.spec.config.weekStartsOn, DateTime.sunday);

      final List<String> names = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(HeatmapWeekdayGutter),
              matching: find.byType(Text),
            ),
          )
          .map((Text t) => t.data!)
          .toList();
      expect(names.first, 'Sun');
    });
  });

  group('split month view', () {
    testWidgets('renders one block per month', (WidgetTester tester) async {
      await pumpView(tester, config: baseConfig(splitMonthView: true));
      expect(find.byType(HeatmapBodySplitMonth), findsOneWidget);
      // The first label carries the year under HeatmapYearDisplay.onChange.
      expect(find.text('May 2026'), findsOneWidget);
      expect(find.text('Jun'), findsOneWidget);
      expect(find.text('Jul'), findsOneWidget);
    });

    testWidgets('still paints activity levels', (WidgetTester tester) async {
      calendar.insert(act('a', DateTime(2026, 6, 10)));
      await pumpView(tester, config: baseConfig(splitMonthView: true));
      expect(
        cellColor(tester, DateTime(2026, 6, 10)),
        HeatmapColorTheme.github.colorForLevel(1),
      );
    });

    testWidgets('columns carry no per-column label slot', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, config: baseConfig(splitMonthView: true));
      final HeatmapColumn column = tester
          .widgetList<HeatmapColumn>(find.byType(HeatmapColumn))
          .first;
      expect(column.labelSlotHeight, 0);
    });

    testWidgets('the 1st sits on its weekday; neighbour days stay blank', (
      WidgetTester tester,
    ) async {
      // 2026-07-01 is a Wednesday. With weeks starting Monday, July's first
      // column is 2026-06-29..2026-07-05: Mon/Tue belong to June and must
      // remain placeholders so the 1st stays on row 2.
      calendar.insert(act('june', DateTime(2026, 6, 29)));
      calendar.insert(act('july', DateTime(2026, 7)));
      await pumpView(tester, config: baseConfig(splitMonthView: true));

      final HeatmapColumn julyFirst = tester.widget<HeatmapColumn>(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapColumn &&
              HeatmapDateUtils.isSameDay(w.weekStart, DateTime(2026, 6, 29)) &&
              w.sectionMonth != null &&
              HeatmapDateUtils.isSameMonth(w.sectionMonth!, DateTime(2026, 7)),
        ),
      );
      expect(julyFirst.weekStart.weekday, DateTime.monday);

      HeatmapCellData dataOf(DateTime date) {
        final HeatmapCell cell = tester.widget<HeatmapCell>(
          find.descendant(
            of: find.byWidget(julyFirst),
            matching: find.byWidgetPredicate(
              (Widget w) =>
                  w is HeatmapCell && HeatmapDateUtils.isSameDay(w.date, date),
            ),
          ),
        );
        return cell.spec.cellDataFor(date, sectionMonth: cell.sectionMonth);
      }

      expect(dataOf(DateTime(2026, 6, 29)).isPlaceholder, isTrue);
      expect(dataOf(DateTime(2026, 6, 30)).isPlaceholder, isTrue);
      expect(dataOf(DateTime(2026, 7)).isPlaceholder, isFalse);
      expect(dataOf(DateTime(2026, 7)).hasActivity, isTrue);
      expect(
        HeatmapDateUtils.weekdayIndex(DateTime(2026, 7), DateTime.monday),
        2,
      );
    });
  });

  group('interaction', () {
    testWidgets('tapping a cell reports that day and its activities', (
      WidgetTester tester,
    ) async {
      calendar.insertAll(<Activity>[
        act('run', DateTime(2026, 6, 10), type: kWorkout),
        act('book', DateTime(2026, 6, 10), type: kReading),
        act('other', DateTime(2026, 6, 11)),
      ]);

      DateTime? tappedDate;
      List<Activity>? tappedActivities;
      await pumpView(
        tester,
        onCellTap: (DateTime date, List<Activity> activities) {
          tappedDate = date;
          tappedActivities = activities;
        },
      );

      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapCell &&
              HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tappedDate, DateTime(2026, 6, 10));
      expect(tappedActivities!.map((Activity a) => a.name), <String>[
        'run',
        'book',
      ]);
    });

    testWidgets('a custom callback suppresses the default sheet', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('run', DateTime(2026, 6, 10)));
      await pumpView(tester, onCellTap: (_, _) {});

      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapCell &&
              HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DefaultActivityBottomSheet), findsNothing);
    });

    testWidgets('opens the default sheet with the day content', (
      WidgetTester tester,
    ) async {
      calendar.insertAll(<Activity>[
        act(
          'Morning run',
          DateTime(2026, 6, 10),
          type: kWorkout,
          detail: '5 km',
        ),
      ]);
      await pumpView(tester);

      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapCell &&
              HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DefaultActivityBottomSheet), findsOneWidget);
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('1 activity'), findsOneWidget);
      expect(find.text('WORKOUT'), findsOneWidget);

      final Size sheetSize = tester.getSize(
        find.byType(DefaultActivityBottomSheet),
      );
      final Size screen = tester.getSize(find.byType(MaterialApp));
      expect(sheetSize.height, lessThan(screen.height * 0.8));
    });

    testWidgets('an empty day opens the empty state', (
      WidgetTester tester,
    ) async {
      await pumpView(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapCell &&
              HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('empty days can be made inert', (WidgetTester tester) async {
      await pumpView(
        tester,
        config: baseConfig().copyWith(tapEmptyCells: false),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapCell &&
              HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DefaultActivityBottomSheet), findsNothing);
    });

    testWidgets('a custom sheet builder replaces the default sheet', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('run', DateTime(2026, 6, 10)));
      await pumpView(
        tester,
        bottomSheetBuilder:
            (BuildContext context, DateTime date, List<Activity> activities) =>
                Material(child: Text('custom ${activities.length}')),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapCell &&
              HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('custom 1'), findsOneWidget);
      expect(find.byType(DefaultActivityBottomSheet), findsNothing);
    });

    testWidgets('tapping a listed activity reports it', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('run', DateTime(2026, 6, 10)));
      Activity? tapped;
      await pumpView(
        tester,
        onActivityTap: (_, Activity activity) => tapped = activity,
      );
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('run'), findsOneWidget);

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();
      expect(tapped?.name, 'run');
    });

    testWidgets('long press reports the day', (WidgetTester tester) async {
      calendar.insert(act('run', DateTime(2026, 6, 10)));
      DateTime? pressed;
      await pumpView(
        tester,
        onCellLongPress: (DateTime date, List<Activity> a) => pressed = date,
      );

      await tester.longPress(
        find.byWidgetPredicate(
          (Widget w) =>
              w is HeatmapCell &&
              HeatmapDateUtils.isSameDay(w.date, DateTime(2026, 6, 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(pressed, DateTime(2026, 6, 10));
    });
  });

  group('reactivity', () {
    testWidgets('inserting repaints the affected day', (
      WidgetTester tester,
    ) async {
      await pumpView(tester);
      expect(
        cellColor(tester, DateTime(2026, 6, 10)),
        HeatmapColorTheme.github.emptyColor,
      );

      calendar.insert(act('a', DateTime(2026, 6, 10)));
      await tester.pumpAndSettle();
      expect(
        cellColor(tester, DateTime(2026, 6, 10)),
        HeatmapColorTheme.github.colorForLevel(1),
      );
    });

    testWidgets('clearing empties the graph', (WidgetTester tester) async {
      calendar.insert(act('a', DateTime(2026, 6, 10)));
      await pumpView(tester);

      calendar.clear();
      await tester.pumpAndSettle();
      expect(
        cellColor(tester, DateTime(2026, 6, 10)),
        HeatmapColorTheme.github.emptyColor,
      );
    });
  });
}
