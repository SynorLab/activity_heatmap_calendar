import 'dart:math' as math;

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/widgets.dart';

import '../config/heatmap_cell_style.dart';
import '../models/heatmap_date_utils.dart';

/// Where a date sits in the grid.
@immutable
class HeatmapCellPosition {
  /// Creates a grid position.
  const HeatmapCellPosition({
    required this.column,
    required this.row,
    this.section,
  });

  /// Column index. In split month view this is relative to [section].
  final int column;

  /// Row index, `0` for the first day of the week.
  final int row;

  /// Index into [HeatmapGridModel.monthSections], or null in continuous mode.
  final int? section;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapCellPosition &&
          other.column == column &&
          other.row == row &&
          other.section == section;

  @override
  int get hashCode => Object.hash(column, row, section);

  @override
  String toString() =>
      'HeatmapCellPosition(section: $section, column: $column, row: $row)';
}

/// One month block in split month view.
@immutable
class HeatmapMonthSection {
  /// Creates a month block.
  const HeatmapMonthSection({
    required this.month,
    required this.gridStart,
    required this.firstDay,
    required this.lastDay,
    required this.columnCount,
    required this.offset,
    required this.extent,
    required this.contentInset,
  });

  /// Local midnight of the first day of the month.
  final DateTime month;

  /// Start of the week containing [firstDay]; the origin of this block's grid.
  final DateTime gridStart;

  /// First day of the month that is inside the configured range.
  final DateTime firstDay;

  /// Last day of the month that is inside the configured range.
  final DateTime lastDay;

  /// Number of week columns in this block.
  final int columnCount;

  /// Scroll offset of the block's leading edge.
  final double offset;

  /// Full width of the block, including its padding.
  final double extent;

  /// Distance from [offset] to the first cell, that is the block's leading
  /// padding.
  final double contentInset;

  /// Scroll offset of the first cell in this block.
  double get contentOffset => offset + contentInset;

  /// The date at [column] and [row] of this block. May fall outside the month
  /// when the week spills over into a neighbouring month.
  DateTime dateAt(int column, int row) =>
      HeatmapDateUtils.addDays(gridStart, column * 7 + row);

  /// Whether [date] belongs to this block's month.
  bool contains(DateTime date) => HeatmapDateUtils.isSameMonth(date, month);
}

/// The pure geometry of the heatmap: which date sits at which grid slot, how
/// wide the content is, and what scroll offset brings a given day into view.
///
/// This class deliberately contains no widgets. Everything it exposes is
/// computed arithmetically rather than measured, which is what lets
/// `ActivityHeatmapCalendar.goto` work before the first layout pass and lets
/// the geometry be unit tested.
@immutable
class HeatmapGridModel {
  const HeatmapGridModel._({
    required this.range,
    required this.weekStartsOn,
    required this.cellExtent,
    required this.cellSize,
    required this.spacing,
    required this.splitMonthView,
    required this.gridStart,
    required this.columnCount,
    required this.totalExtent,
    required this.monthSections,
  });

  /// Builds the geometry for a configuration.
  ///
  /// [sectionGap] and [sectionPadding] only apply when [splitMonthView] is
  /// true.
  factory HeatmapGridModel.build({
    required DateTimeRange range,
    required int weekStartsOn,
    required HeatmapCellStyle cellStyle,
    bool splitMonthView = false,
    double sectionGap = 16,
    EdgeInsets sectionPadding = EdgeInsets.zero,
  }) {
    final DateTime start = HeatmapDateUtils.normalize(range.start);
    final DateTime end = HeatmapDateUtils.normalize(range.end);
    final DateTime gridStart = HeatmapDateUtils.startOfWeek(
      start,
      weekStartsOn,
    );
    final double cellExtent = cellStyle.extent;

    if (!splitMonthView) {
      final int columnCount =
          HeatmapDateUtils.weeksBetween(gridStart, end, weekStartsOn) + 1;
      return HeatmapGridModel._(
        range: DateTimeRange(start: start, end: end),
        weekStartsOn: weekStartsOn,
        cellExtent: cellExtent,
        cellSize: cellStyle.size,
        spacing: cellStyle.spacing,
        splitMonthView: false,
        gridStart: gridStart,
        columnCount: columnCount,
        totalExtent: columnCount * cellExtent,
        monthSections: const <HeatmapMonthSection>[],
      );
    }

    final List<HeatmapMonthSection> sections = <HeatmapMonthSection>[];
    final double inset = sectionPadding.horizontal;
    double cursor = 0;
    DateTime month = HeatmapDateUtils.startOfMonth(start);
    final DateTime lastMonth = HeatmapDateUtils.startOfMonth(end);

    while (!month.isAfter(lastMonth)) {
      final DateTime monthEnd = HeatmapDateUtils.endOfMonth(month);
      final DateTime firstDay = month.isBefore(start) ? start : month;
      final DateTime lastDay = monthEnd.isAfter(end) ? end : monthEnd;
      final DateTime sectionStart = HeatmapDateUtils.startOfWeek(
        firstDay,
        weekStartsOn,
      );
      final int columns =
          HeatmapDateUtils.weeksBetween(sectionStart, lastDay, weekStartsOn) +
          1;
      final double extent = columns * cellExtent + inset;

      sections.add(
        HeatmapMonthSection(
          month: month,
          gridStart: sectionStart,
          firstDay: firstDay,
          lastDay: lastDay,
          columnCount: columns,
          offset: cursor,
          extent: extent,
          contentInset: sectionPadding.left,
        ),
      );

      cursor += extent + sectionGap;
      month = HeatmapDateUtils.addMonths(month, 1);
    }

    return HeatmapGridModel._(
      range: DateTimeRange(start: start, end: end),
      weekStartsOn: weekStartsOn,
      cellExtent: cellExtent,
      cellSize: cellStyle.size,
      spacing: cellStyle.spacing,
      splitMonthView: true,
      gridStart: gridStart,
      columnCount: sections.fold<int>(
        0,
        (int sum, HeatmapMonthSection s) => sum + s.columnCount,
      ),
      // The gap after the final section is not part of the content.
      totalExtent: sections.isEmpty ? 0 : cursor - sectionGap,
      monthSections: List<HeatmapMonthSection>.unmodifiable(sections),
    );
  }

  /// The inclusive span of days the grid covers, at local midnight.
  final DateTimeRange range;

  /// First day of the week, `1`…`7`.
  final int weekStartsOn;

  /// Distance from one column (or row) origin to the next.
  final double cellExtent;

  /// Side length of a cell.
  final double cellSize;

  /// Gap between cells.
  final double spacing;

  /// Whether the grid is laid out as separate month blocks.
  final bool splitMonthView;

  /// Start of the week containing [range].start; the origin of the continuous
  /// grid.
  final DateTime gridStart;

  /// Total number of week columns across the whole grid.
  final int columnCount;

  /// Width of the scrollable content.
  final double totalExtent;

  /// The month blocks, empty in continuous mode.
  final List<HeatmapMonthSection> monthSections;

  /// Rows in a column; always seven.
  static const int rowCount = 7;

  /// Height of the grid itself, excluding labels.
  double get gridHeight => rowCount * cellSize + (rowCount - 1) * spacing;

  /// The date at [column] and [row] of the continuous grid.
  ///
  /// Dates outside [range] are still returned; use [isInRange] to decide
  /// whether to paint them as placeholders.
  DateTime dateAt(int column, int row) =>
      HeatmapDateUtils.addDays(gridStart, column * 7 + row);

  /// Whether [date] falls inside the configured range.
  bool isInRange(DateTime date) {
    final int key = HeatmapDateUtils.dayKey(date);
    return key >= HeatmapDateUtils.dayKey(range.start) &&
        key <= HeatmapDateUtils.dayKey(range.end);
  }

  /// The grid position of [date], or null when it lies outside [range].
  HeatmapCellPosition? cellOf(DateTime date) {
    if (!isInRange(date)) {
      return null;
    }
    final int row = HeatmapDateUtils.weekdayIndex(date, weekStartsOn);
    if (!splitMonthView) {
      return HeatmapCellPosition(
        column: HeatmapDateUtils.weeksBetween(gridStart, date, weekStartsOn),
        row: row,
      );
    }
    final int index = sectionIndexOf(date);
    if (index < 0) {
      return null;
    }
    final HeatmapMonthSection section = monthSections[index];
    return HeatmapCellPosition(
      column: HeatmapDateUtils.weeksBetween(
        section.gridStart,
        date,
        weekStartsOn,
      ),
      row: row,
      section: index,
    );
  }

  /// Index of the month block containing [date], or `-1`.
  int sectionIndexOf(DateTime date) {
    for (int i = 0; i < monthSections.length; i++) {
      if (monthSections[i].contains(date)) {
        return i;
      }
    }
    return -1;
  }

  /// The month a continuous-mode column belongs to.
  ///
  /// Taken from the first day of the column that is inside the range, not from
  /// the start of its week. The two only differ on the first column, whose
  /// week usually begins in the previous month — using the week start there
  /// would label a January-to-December range with a phantom "December".
  DateTime monthOfColumn(int column) {
    for (int row = 0; row < rowCount; row++) {
      final DateTime date = dateAt(column, row);
      if (isInRange(date)) {
        return HeatmapDateUtils.startOfMonth(date);
      }
    }
    return HeatmapDateUtils.startOfMonth(dateAt(column, 0));
  }

  /// Whether [column] is the first column of a new month, and so the one that
  /// carries the month label.
  bool isFirstColumnOfMonth(int column) {
    if (column <= 0) {
      return true;
    }
    return monthOfColumn(column) != monthOfColumn(column - 1);
  }

  /// Whether [column] should actually render a month label.
  ///
  /// A month that only occupies a single column at the very end of the range
  /// has no room for its name without colliding with the previous label, so
  /// it is skipped — the same compromise GitHub makes.
  bool shouldLabelColumn(int column, {int minColumns = 2}) {
    if (!isFirstColumnOfMonth(column)) {
      return false;
    }
    final DateTime month = monthOfColumn(column);
    int width = 0;
    for (int c = column; c < columnCount; c++) {
      if (monthOfColumn(c) != month) {
        break;
      }
      width++;
    }
    return width >= minColumns;
  }

  /// The scroll offset of the leading edge of a continuous-mode column.
  double offsetOfColumn(int column) => column * cellExtent;

  /// The scroll offset that brings [date] to [alignment] within a viewport of
  /// [viewportWidth].
  ///
  /// `0` puts the day at the leading edge, `0.5` centres it and `1` puts it at
  /// the trailing edge. The result is clamped to the scrollable extent, so
  /// days near either end come as close as the content allows. Dates outside
  /// the range are clamped to the nearest end.
  double offsetToCenter(
    DateTime date, {
    required double viewportWidth,
    double alignment = 0.5,
  }) {
    final double maxOffset = math.max(0, totalExtent - viewportWidth);
    if (maxOffset <= 0) {
      return 0;
    }

    final DateTime clamped = _clampToRange(date);
    final double columnLeft;
    if (!splitMonthView) {
      columnLeft = offsetOfColumn(
        HeatmapDateUtils.weeksBetween(gridStart, clamped, weekStartsOn),
      );
    } else {
      final int index = sectionIndexOf(clamped);
      if (index < 0) {
        return 0;
      }
      final HeatmapMonthSection section = monthSections[index];
      columnLeft =
          section.contentOffset +
          HeatmapDateUtils.weeksBetween(
                section.gridStart,
                clamped,
                weekStartsOn,
              ) *
              cellExtent;
    }

    final double raw =
        columnLeft - alignment.clamp(0.0, 1.0) * (viewportWidth - cellExtent);
    return raw.clamp(0.0, maxOffset).toDouble();
  }

  /// The date closest to the centre of the viewport at [offset].
  ///
  /// Used to preserve the visible day when the geometry is rebuilt after a
  /// configuration change.
  DateTime dateAtOffset(double offset, {required double viewportWidth}) {
    final double centre = offset + viewportWidth / 2;
    if (!splitMonthView) {
      final int column = (centre / cellExtent).floor().clamp(
        0,
        math.max(0, columnCount - 1),
      );
      return _clampToRange(dateAt(column, 0));
    }
    for (final HeatmapMonthSection section in monthSections) {
      if (centre < section.offset + section.extent) {
        final int column = ((centre - section.contentOffset) / cellExtent)
            .floor()
            .clamp(0, math.max(0, section.columnCount - 1));
        return _clampToRange(section.dateAt(column, 0));
      }
    }
    return range.end;
  }

  DateTime _clampToRange(DateTime date) {
    final DateTime d = HeatmapDateUtils.normalize(date);
    if (d.isBefore(range.start)) {
      return range.start;
    }
    if (d.isAfter(range.end)) {
      return range.end;
    }
    return d;
  }

  @override
  String toString() =>
      'HeatmapGridModel(${range.start} – ${range.end}, '
      'columns: $columnCount, split: $splitMonthView, '
      'extent: ${totalExtent.toStringAsFixed(1)})';
}
