import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart' show DateTimeRange, EdgeInsets;
import 'package:flutter_test/flutter_test.dart';

const HeatmapCellStyle kStyle = HeatmapCellStyle(); // 24 + 4 = 28 per column

HeatmapGridModel build({
  required DateTime start,
  required DateTime end,
  int weekStartsOn = DateTime.monday,
  bool split = false,
  HeatmapCellStyle style = kStyle,
  double sectionGap = 16,
  EdgeInsets sectionPadding = EdgeInsets.zero,
}) {
  return HeatmapGridModel.build(
    range: DateTimeRange(start: start, end: end),
    weekStartsOn: weekStartsOn,
    cellStyle: style,
    splitMonthView: split,
    sectionGap: sectionGap,
    sectionPadding: sectionPadding,
  );
}

void main() {
  group('continuous geometry', () {
    test('starts the grid on the week containing the range start', () {
      // 2026-03-04 is a Wednesday.
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 31),
      );
      expect(model.gridStart, DateTime(2026, 3, 2)); // Monday
      expect(model.dateAt(0, 0), DateTime(2026, 3, 2));
      expect(model.isInRange(DateTime(2026, 3, 2)), isFalse);
      expect(model.isInRange(DateTime(2026, 3, 4)), isTrue);
    });

    test('honours weekStartsOn', () {
      final HeatmapGridModel sunday = build(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 31),
        weekStartsOn: DateTime.sunday,
      );
      expect(sunday.gridStart, DateTime(2026, 3));
      expect(sunday.gridStart.weekday, DateTime.sunday);

      final HeatmapGridModel saturday = build(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 31),
        weekStartsOn: DateTime.saturday,
      );
      expect(saturday.gridStart.weekday, DateTime.saturday);
    });

    test('column count covers the last day of the range', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 29), // exactly four weeks
      );
      expect(model.columnCount, 4);
      expect(model.dateAt(3, 6), DateTime(2026, 3, 29));
    });

    test('total extent is columns times the cell extent', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 29),
      );
      expect(model.cellExtent, 28);
      expect(model.totalExtent, 4 * 28);
    });

    test('grid height covers seven rows', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 29),
      );
      expect(model.gridHeight, 7 * 24 + 6 * 4);
    });

    test('handles a single-day range', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 4),
      );
      expect(model.columnCount, 1);
      expect(
        model.cellOf(DateTime(2026, 3, 4)),
        const HeatmapCellPosition(column: 0, row: 2),
      );
    });

    test('handles a ten year range', () {
      final HeatmapGridModel model = build(
        start: DateTime(2016),
        end: DateTime(2026),
      );
      expect(model.columnCount, greaterThan(520));
      expect(model.cellOf(DateTime(2021, 6, 15)), isNotNull);
    });
  });

  group('cellOf / dateAt round trip', () {
    test('is consistent for every day of three years and all week starts', () {
      for (
        int weekStartsOn = DateTime.monday;
        weekStartsOn <= DateTime.sunday;
        weekStartsOn++
      ) {
        final HeatmapGridModel model = build(
          start: DateTime(2024),
          end: DateTime(2026, 12, 31),
          weekStartsOn: weekStartsOn,
        );
        for (final DateTime day in HeatmapDateUtils.eachDay(
          DateTime(2024),
          DateTime(2026, 12, 31),
        )) {
          final HeatmapCellPosition? position = model.cellOf(day);
          expect(
            position,
            isNotNull,
            reason: '$day missing (start $weekStartsOn)',
          );
          expect(
            model.dateAt(position!.column, position.row),
            day,
            reason: 'round trip failed for $day (weekStartsOn $weekStartsOn)',
          );
        }
      }
    });

    test('spans a leap day', () {
      final HeatmapGridModel model = build(
        start: DateTime(2024, 2),
        end: DateTime(2024, 3, 31),
      );
      final HeatmapCellPosition position = model.cellOf(DateTime(2024, 2, 29))!;
      expect(
        model.dateAt(position.column, position.row),
        DateTime(2024, 2, 29),
      );
    });

    test('returns null outside the range', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3, 4),
        end: DateTime(2026, 3, 31),
      );
      expect(model.cellOf(DateTime(2026, 3, 3)), isNull);
      expect(model.cellOf(DateTime(2026, 4)), isNull);
    });
  });

  group('month labels', () {
    test('marks the column where the month changes', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      expect(model.isFirstColumnOfMonth(0), isTrue);

      final List<int> labelled = <int>[
        for (int c = 0; c < model.columnCount; c++)
          if (model.isFirstColumnOfMonth(c)) c,
      ];
      // Twelve months in a full year.
      expect(labelled.length, 12);
      for (int i = 1; i < labelled.length; i++) {
        expect(
          model.monthOfColumn(labelled[i]).month,
          isNot(model.monthOfColumn(labelled[i - 1]).month),
        );
      }
    });

    test('does not label a month that never owns a column', () {
      // 2026-04-02 is a Thursday, so April shares its only week with March.
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 4, 2),
      );
      final int aprilColumn = model.cellOf(DateTime(2026, 4))!.column;
      expect(model.monthOfColumn(aprilColumn), DateTime(2026, 3));
      expect(model.isFirstColumnOfMonth(aprilColumn), isFalse);
    });

    test('skips a month too narrow to label', () {
      // 2026-06-01 is a Monday, so June owns exactly one column here while
      // May owns four.
      final HeatmapGridModel model = build(
        start: DateTime(2026, 5, 4),
        end: DateTime(2026, 6, 7),
      );
      expect(model.columnCount, 5);
      expect(model.isFirstColumnOfMonth(4), isTrue);
      expect(model.shouldLabelColumn(4), isFalse);
      expect(model.shouldLabelColumn(0), isTrue);
    });

    test(
      'labels the first column with the range start month, not its week',
      () {
        // The week containing 2026-01-01 starts on 2025-12-29.
        final HeatmapGridModel model = build(
          start: DateTime(2026),
          end: DateTime(2026, 12, 31),
        );
        expect(model.gridStart, DateTime(2025, 12, 29));
        expect(model.monthOfColumn(0), DateTime(2026));
      },
    );
  });

  group('offsetToCenter (continuous)', () {
    late HeatmapGridModel model;
    setUp(() {
      // 53 columns of 28 = 1484 wide.
      model = build(start: DateTime(2026), end: DateTime(2026, 12, 31));
    });

    test('centres a mid-range day', () {
      const double viewport = 300;
      final DateTime day = DateTime(2026, 7);
      final double offset = model.offsetToCenter(day, viewportWidth: viewport);
      final int column = model.cellOf(day)!.column;
      expect(offset, column * 28 - 0.5 * (viewport - 28));
    });

    test('honours the alignment parameter', () {
      const double viewport = 300;
      final DateTime day = DateTime(2026, 7);
      final int column = model.cellOf(day)!.column;
      expect(
        model.offsetToCenter(day, viewportWidth: viewport, alignment: 0),
        column * 28,
      );
      expect(
        model.offsetToCenter(day, viewportWidth: viewport, alignment: 1),
        column * 28 - (viewport - 28),
      );
    });

    test('clamps at the start of the range', () {
      expect(model.offsetToCenter(DateTime(2026), viewportWidth: 300), 0);
    });

    test('clamps at the end of the range', () {
      final double max = model.totalExtent - 300;
      expect(
        model.offsetToCenter(DateTime(2026, 12, 31), viewportWidth: 300),
        max,
      );
    });

    test('returns zero when the content fits the viewport', () {
      final HeatmapGridModel small = build(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 29),
      );
      expect(
        small.offsetToCenter(DateTime(2026, 3, 20), viewportWidth: 1000),
        0,
      );
    });

    test('clamps dates outside the range to the nearest end', () {
      expect(model.offsetToCenter(DateTime(2020), viewportWidth: 300), 0);
      expect(
        model.offsetToCenter(DateTime(2030), viewportWidth: 300),
        model.totalExtent - 300,
      );
    });
  });

  group('split month geometry', () {
    test('produces one section per month, clipped to the range', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026, 2, 10),
        end: DateTime(2026, 5, 20),
        split: true,
      );
      expect(model.monthSections.length, 4);
      expect(model.monthSections.first.month, DateTime(2026, 2));
      expect(model.monthSections.first.firstDay, DateTime(2026, 2, 10));
      expect(model.monthSections.last.month, DateTime(2026, 5));
      expect(model.monthSections.last.lastDay, DateTime(2026, 5, 20));
    });

    test('each section starts on a week boundary', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        split: true,
        weekStartsOn: DateTime.sunday,
      );
      for (final HeatmapMonthSection section in model.monthSections) {
        expect(section.gridStart.weekday, DateTime.sunday);
        expect(
          HeatmapDateUtils.daysBetween(section.gridStart, section.firstDay),
          inInclusiveRange(0, 6),
        );
      }
    });

    test('offsets accumulate with the section gap', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 3, 31),
        split: true,
      );
      double expected = 0;
      for (final HeatmapMonthSection section in model.monthSections) {
        expect(section.offset, expected);
        expected += section.extent + 16;
      }
      // No trailing gap after the last section.
      expect(model.totalExtent, expected - 16);
    });

    test('section padding widens the block and shifts the content', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 2, 28),
        split: true,
        sectionPadding: const EdgeInsets.symmetric(horizontal: 6),
      );
      final HeatmapMonthSection first = model.monthSections.first;
      expect(first.extent, first.columnCount * 28 + 12);
      expect(first.contentOffset, first.offset + 6);
    });

    test('cellOf reports the section and a section-relative column', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 3, 31),
        split: true,
      );
      final HeatmapCellPosition position = model.cellOf(DateTime(2026, 2, 10))!;
      expect(position.section, 1);
      expect(
        model.monthSections[1].dateAt(position.column, position.row),
        DateTime(2026, 2, 10),
      );
    });

    test('round trips every day of a year', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        split: true,
      );
      for (final DateTime day in HeatmapDateUtils.eachDay(
        DateTime(2026),
        DateTime(2026, 12, 31),
      )) {
        final HeatmapCellPosition position = model.cellOf(day)!;
        expect(
          model.monthSections[position.section!].dateAt(
            position.column,
            position.row,
          ),
          day,
        );
      }
    });

    test('offsetToCenter uses the section offset', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        split: true,
      );
      const double viewport = 300;
      final DateTime day = DateTime(2026, 7, 15);
      final HeatmapCellPosition position = model.cellOf(day)!;
      final HeatmapMonthSection section =
          model.monthSections[position.section!];
      expect(
        model.offsetToCenter(day, viewportWidth: viewport),
        section.contentOffset + position.column * 28 - 0.5 * (viewport - 28),
      );
    });

    test('a single-month range has one section and no gap', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026, 3),
        end: DateTime(2026, 3, 31),
        split: true,
      );
      expect(model.monthSections.length, 1);
      expect(model.totalExtent, model.monthSections.single.extent);
    });
  });

  group('dateAtOffset', () {
    test('round trips with offsetToCenter in continuous mode', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      const double viewport = 300;
      for (final DateTime day in <DateTime>[
        DateTime(2026, 3, 15),
        DateTime(2026, 7),
        DateTime(2026, 10, 20),
      ]) {
        final double offset = model.offsetToCenter(
          day,
          viewportWidth: viewport,
        );
        final DateTime recovered = model.dateAtOffset(
          offset,
          viewportWidth: viewport,
        );
        expect(
          HeatmapDateUtils.daysBetween(recovered, day).abs(),
          lessThanOrEqualTo(7),
          reason: 'recovered $recovered for $day',
        );
      }
    });

    test('round trips in split mode', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        split: true,
      );
      const double viewport = 300;
      final DateTime day = DateTime(2026, 8, 12);
      final double offset = model.offsetToCenter(day, viewportWidth: viewport);
      final DateTime recovered = model.dateAtOffset(
        offset,
        viewportWidth: viewport,
      );
      expect(HeatmapDateUtils.isSameMonth(recovered, day), isTrue);
    });

    test('reports the day at the centre of the viewport', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      // At offset 0 the centre of a 300px viewport sits in column 5.
      expect(model.dateAtOffset(0, viewportWidth: 300), model.dateAt(5, 0));
    });

    test('clamps to the range at both ends', () {
      final HeatmapGridModel model = build(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      expect(model.dateAtOffset(-1000, viewportWidth: 300), DateTime(2026));
      expect(
        model
            .dateAtOffset(model.totalExtent * 2, viewportWidth: 300)
            .isAfter(DateTime(2026, 12)),
        isTrue,
      );
    });
  });
}
