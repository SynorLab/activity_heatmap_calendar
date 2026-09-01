import 'package:flutter/widgets.dart';

import '../config/heatmap_labels_config.dart';
import '../models/heatmap_date_utils.dart';
import 'heatmap_column.dart';
import 'heatmap_render_spec.dart';

/// The default layout: one uninterrupted run of week columns.
///
/// Columns are built lazily by a [ListView] with a fixed item extent, so a ten
/// year range costs the same to scroll as a one month range.
class HeatmapBodyContinuous extends StatelessWidget {
  /// Creates the continuous grid.
  const HeatmapBodyContinuous({
    required this.spec,
    required this.controller,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// The resolved inputs of this build pass.
  final HeatmapRenderSpec spec;

  /// Scroll controller shared with the view so `goto` can drive it.
  final ScrollController controller;

  /// Called when a day is tapped.
  final void Function(DateTime date)? onTap;

  /// Called on a long press on a day.
  final void Function(DateTime date)? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      reverse: spec.textDirection == TextDirection.rtl,
      itemExtent: spec.cellExtent,
      itemCount: spec.model.columnCount,
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context, int column) {
        return RepaintBoundary(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: spec.config.cellStyle.spacing,
            ),
            child: HeatmapColumn(
              spec: spec,
              weekStart: spec.model.dateAt(column, 0),
              labelSlotHeight: spec.monthLabelHeight,
              label: _labelFor(context, column),
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        );
      },
    );
  }

  /// The month label for [column], or null when the column carries none.
  String? _labelFor(BuildContext context, int column) {
    if (!spec.config.showMonthLabels || !spec.model.shouldLabelColumn(column)) {
      return null;
    }
    final DateTime month = spec.model.monthOfColumn(column);
    return spec.monthLabel(context, month, showYear: _showsYear(column, month));
  }

  bool _showsYear(int column, DateTime month) {
    switch (spec.config.yearDisplay) {
      case HeatmapYearDisplay.never:
        return false;
      case HeatmapYearDisplay.always:
        return true;
      case HeatmapYearDisplay.onChange:
        // The first label always carries the year; later ones only when the
        // year has changed since the previous labelled column, so a range
        // spanning a new year reads "Nov, Dec, Jan 2027, Feb".
        for (int c = column - 1; c >= 0; c--) {
          if (spec.model.shouldLabelColumn(c)) {
            return spec.model.monthOfColumn(c).year != month.year;
          }
        }
        return true;
    }
  }
}

/// A grid of week columns without its own scroll view, used inside a month
/// block in split month view.
class HeatmapWeekRow extends StatelessWidget {
  /// Creates a run of [columnCount] week columns starting at [gridStart].
  const HeatmapWeekRow({
    required this.spec,
    required this.gridStart,
    required this.columnCount,
    required this.sectionMonth,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// The resolved inputs of this build pass.
  final HeatmapRenderSpec spec;

  /// Local midnight of the first day of the first column.
  final DateTime gridStart;

  /// How many week columns to draw.
  final int columnCount;

  /// The month this block represents. Days outside it stay in the grid so
  /// weekdays line up, but they are painted as placeholders.
  final DateTime sectionMonth;

  /// Called when a day is tapped.
  final void Function(DateTime date)? onTap;

  /// Called on a long press on a day.
  final void Function(DateTime date)? onLongPress;

  @override
  Widget build(BuildContext context) {
    // Each column occupies a full cell extent, trailing gap included, so the
    // rendered width equals HeatmapGridModel's computed section extent and
    // `goto` lands where the arithmetic says it should.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int column = 0; column < columnCount; column++)
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: spec.config.cellStyle.spacing,
            ),
            child: HeatmapColumn(
              spec: spec,
              weekStart: HeatmapDateUtils.addDays(gridStart, column * 7),
              labelSlotHeight: 0,
              sectionMonth: sectionMonth,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
      ],
    );
  }
}
