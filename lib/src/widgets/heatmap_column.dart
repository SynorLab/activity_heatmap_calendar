import 'package:flutter/widgets.dart';

import 'heatmap_cell.dart';
import 'heatmap_render_spec.dart';

/// One week of the grid: an optional month label above seven day cells.
///
/// The label lives inside the column rather than in a separate header row, so
/// it scrolls with its week for free. A second scroll view synchronised to the
/// first would be the obvious alternative and is a reliable source of drift
/// and jitter.
class HeatmapColumn extends StatelessWidget {
  /// Creates a week column starting at [weekStart].
  const HeatmapColumn({
    required this.spec,
    required this.weekStart,
    required this.labelSlotHeight,
    this.sectionMonth,
    this.label,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// The resolved inputs of this build pass.
  final HeatmapRenderSpec spec;

  /// Local midnight of the first day in this column.
  final DateTime weekStart;

  /// The month this column belongs to in split-month view.
  ///
  /// Days that fall in a neighbouring month stay in the column so weekdays
  /// line up, but they are painted as placeholders.
  final DateTime? sectionMonth;

  /// Height reserved above the cells for a month label.
  ///
  /// Pass zero in split month view, where the month name is drawn once as a
  /// block header instead of once per column.
  final double labelSlotHeight;

  /// Month label to draw above the column, or null for no label.
  final String? label;

  /// Called when a day in this column is tapped.
  final void Function(DateTime date)? onTap;

  /// Called on a long press on a day in this column.
  final void Function(DateTime date)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final double spacing = spec.config.cellStyle.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (labelSlotHeight > 0)
          SizedBox(
            height: labelSlotHeight,
            width: spec.cellSize,
            child: label == null ? null : _MonthLabel(spec: spec, text: label!),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: spacing,
          children: <Widget>[
            for (int row = 0; row < 7; row++)
              HeatmapCell(
                spec: spec,
                date: DateTime(
                  weekStart.year,
                  weekStart.month,
                  weekStart.day + row,
                ),
                sectionMonth: sectionMonth,
                onTap: onTap,
                onLongPress: onLongPress,
              ),
          ],
        ),
      ],
    );
  }
}

/// A month name that is allowed to spill past its one-column-wide slot.
class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.spec, required this.text});

  final HeatmapRenderSpec spec;
  final String text;

  @override
  Widget build(BuildContext context) {
    // A month name is far wider than a 24px column, so the slot must not
    // constrain it. The label is drawn before the next column's cells and sits
    // on its own row, so the overflow cannot collide with anything.
    return OverflowBox(
      alignment: AlignmentDirectional.centerStart,
      maxWidth: 140,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: spec.labelStyle(context),
        ),
      ),
    );
  }
}
