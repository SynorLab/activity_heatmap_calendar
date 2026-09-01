import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// The cell is the only widget a reader actually points at, so its hover,
/// tooltip and accessibility behaviour get their own tests.
void main() {
  late ActivityHeatmapCalendar calendar;

  setUp(() {
    calendar = ActivityHeatmapCalendar()..resetForTest();
  });

  group('semantics', () {
    testWidgets('a day announces its date and count', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      calendar.insertAll(<Activity>[
        act('a', DateTime(2026, 6, 10)),
        act('b', DateTime(2026, 6, 10)),
      ]);
      await pumpView(tester);

      expect(
        find.bySemanticsLabel(RegExp('June 10, 2026, 2 activities')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('an empty day says so', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpView(tester);
      expect(
        find.bySemanticsLabel(RegExp('June 10, 2026, no activities')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a custom builder replaces the label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      calendar.insert(act('a', DateTime(2026, 6, 10)));
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          labels: HeatmapLabelsConfig(
            cellSemanticsBuilder:
                (BuildContext context, HeatmapCellData data) =>
                    'day ${data.date.day} level ${data.level}',
          ),
        ),
      );

      expect(find.bySemanticsLabel('day 10 level 1'), findsOneWidget);
      handle.dispose();
    });
  });

  group('tooltips', () {
    testWidgets('hovering a day shows one', (WidgetTester tester) async {
      calendar.insert(act('a', DateTime(2026, 6, 10)));
      await pumpView(tester, config: baseConfig().copyWith(showTooltips: true));

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(cellFinder(DateTime(2026, 6, 10))));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 activity on'), findsOneWidget);
    });

    testWidgets('they can be switched off', (WidgetTester tester) async {
      calendar.insert(act('a', DateTime(2026, 6, 10)));
      await pumpView(tester);

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(cellFinder(DateTime(2026, 6, 10))));
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsNothing);
    });
  });

  group('hover', () {
    testWidgets('a highlight appears and disappears', (
      WidgetTester tester,
    ) async {
      await pumpView(tester);
      final Finder cell = cellFinder(DateTime(2026, 6, 10));

      Decoration? overlay() => tester
          .widget<Container>(
            find.descendant(of: cell, matching: find.byType(Container)).first,
          )
          .foregroundDecoration;

      expect(overlay(), isNull);

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(cell));
      await tester.pumpAndSettle();
      expect(overlay(), isNotNull);

      await gesture.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(overlay(), isNull);
    });
  });

  group('decoration', () {
    testWidgets('the hairline border can be removed', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        config: baseConfig(cellStyle: const HeatmapCellStyle(borderWidth: 0)),
      );
      final Container box = tester.widget<Container>(
        find
            .descendant(
              of: cellFinder(DateTime(2026, 6, 10)),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((box.decoration! as BoxDecoration).border, isNull);
    });

    testWidgets('the today ring can be removed', (WidgetTester tester) async {
      await pumpView(
        tester,
        config: baseConfig(
          cellStyle: const HeatmapCellStyle(showTodayRing: false),
        ),
      );
      final Container box = tester.widget<Container>(
        find
            .descendant(
              of: cellFinder(kToday),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(box.foregroundDecoration, isNull);
    });

    testWidgets('an explicit border colour wins', (WidgetTester tester) async {
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          colorTheme: HeatmapColorTheme.github.copyWith(
            borderColor: const Color(0xFFFF0000),
          ),
        ),
      );
      final Container box = tester.widget<Container>(
        find
            .descendant(
              of: cellFinder(DateTime(2026, 6, 10)),
              matching: find.byType(Container),
            )
            .first,
      );
      final BoxBorder border = (box.decoration! as BoxDecoration).border!;
      expect(border.top.color, const Color(0xFFFF0000));
    });
  });

  group('selection ring', () {
    BoxDecoration? overlayOf(WidgetTester tester, DateTime date) {
      return tester
              .widget<Container>(
                find
                    .descendant(
                      of: cellFinder(date),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .foregroundDecoration
          as BoxDecoration?;
    }

    testWidgets('opening the sheet outlines the tapped cell', (
      WidgetTester tester,
    ) async {
      final DateTime day = DateTime(2026, 6, 10);
      await pumpView(tester);
      expect(overlayOf(tester, day), isNull);

      await tapCell(tester, day);

      final BoxDecoration overlay = overlayOf(tester, day)!;
      expect(
        overlay.border!.top.color,
        Theme.of(tester.element(cellFinder(day).first)).colorScheme.primary,
      );
      expect(cellData(tester, day)!.isSelected, isTrue);
      expect(cellData(tester, kToday)!.isSelected, isFalse);
    });

    testWidgets('dismissing the sheet restores the ordinary border', (
      WidgetTester tester,
    ) async {
      final DateTime day = DateTime(2026, 6, 10);
      await pumpView(tester);
      await tapCell(tester, day);
      expect(cellData(tester, day)!.isSelected, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(DefaultActivityBottomSheet), findsNothing);
      expect(cellData(tester, day)!.isSelected, isFalse);
      expect(overlayOf(tester, day), isNull);
    });

    testWidgets('uses an explicit selected ring colour', (
      WidgetTester tester,
    ) async {
      final DateTime day = DateTime(2026, 6, 10);
      await pumpView(
        tester,
        config: baseConfig().copyWith(
          colorTheme: HeatmapColorTheme.github.copyWith(
            selectedRingColor: const Color(0xFF00AAFF),
          ),
        ),
      );
      await tapCell(tester, day);
      expect(
        overlayOf(tester, day)!.border!.top.color,
        const Color(0xFF00AAFF),
      );
    });
  });

  group('interaction guards', () {
    testWidgets('placeholder days are inert', (WidgetTester tester) async {
      DateTime? tapped;
      await pumpView(tester, onCellTap: (DateTime d, _) => tapped = d);

      // 2026-04-27 pads the first column and falls outside the range.
      await tester.tap(cellFinder(DateTime(2026, 4, 27)), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tapped, isNull);
    });

    testWidgets('empty days are inert when configured that way', (
      WidgetTester tester,
    ) async {
      DateTime? tapped;
      await pumpView(
        tester,
        config: baseConfig().copyWith(tapEmptyCells: false),
        onCellTap: (DateTime d, _) => tapped = d,
      );

      await tester.tap(cellFinder(DateTime(2026, 6, 10)));
      await tester.pumpAndSettle();
      expect(tapped, isNull);

      calendar.insert(act('a', DateTime(2026, 6, 10)));
      await tester.pumpAndSettle();
      await tester.tap(cellFinder(DateTime(2026, 6, 10)));
      await tester.pumpAndSettle();
      expect(tapped, DateTime(2026, 6, 10));
    });
  });
}
