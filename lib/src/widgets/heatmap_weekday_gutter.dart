import 'package:flutter/widgets.dart';

import '../config/heatmap_labels_config.dart';
import '../models/heatmap_date_utils.dart';
import 'heatmap_render_spec.dart';

/// The fixed column of weekday names beside the grid.
///
/// It sits outside the scroll view so the names stay put while the weeks move.
/// Its top padding matches the grid's month label row so the seven names line
/// up with the seven rows of cells.
class HeatmapWeekdayGutter extends StatelessWidget {
  /// Creates the weekday gutter.
  const HeatmapWeekdayGutter({
    required this.spec,
    required this.topInset,
    super.key,
  });

  /// The resolved inputs of this build pass.
  final HeatmapRenderSpec spec;

  /// Space above the first name, matching the grid's header so the seven names
  /// line up with the seven rows of cells.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final HeatmapLabelsConfig labels = spec.config.labels;
    final double cellSize = spec.cellSize;
    final double spacing = spec.config.cellStyle.spacing;

    // A week whose first day matches weekStartsOn, used purely as a source of
    // weekday names.
    final DateTime reference = HeatmapDateUtils.startOfWeek(
      DateTime(2024),
      spec.config.weekStartsOn,
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: topInset,
        end: labels.gutterSpacing,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: spacing,
        children: <Widget>[
          for (int row = 0; row < 7; row++)
            SizedBox(
              height: cellSize,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _labelFor(context, reference, row),
                  maxLines: 1,
                  softWrap: false,
                  style: spec.labelStyle(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(BuildContext context, DateTime reference, int row) {
    if (!_showsRow(row)) {
      return '';
    }
    final DateTime day = HeatmapDateUtils.addDays(reference, row);
    return spec.config.labels.weekdayLabelBuilder?.call(context, day) ??
        spec.formatter.weekdayShort(day);
  }

  /// GitHub labels every other row, which reads as far less noise next to
  /// small cells while still orienting the reader.
  bool _showsRow(int row) => switch (spec.config.labels.weekdayLabelMode) {
    HeatmapWeekdayLabelMode.all => true,
    HeatmapWeekdayLabelMode.alternate => row.isOdd,
    HeatmapWeekdayLabelMode.none => false,
  };
}
