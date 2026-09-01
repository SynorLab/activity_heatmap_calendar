import 'package:flutter/widgets.dart';

import '../config/heatmap_labels_config.dart';
import '../core/heatmap_grid_model.dart';
import 'heatmap_body_continuous.dart';
import 'heatmap_render_spec.dart';

/// The split layout: every month is its own block, separated by a gap.
///
/// Each month gets a single header instead of a label floating above the first
/// column, which makes month boundaries obvious at the cost of a wider graph.
class HeatmapBodySplitMonth extends StatelessWidget {
  /// Creates the split month grid.
  const HeatmapBodySplitMonth({
    required this.spec,
    required this.controller,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// Vertical gap between a month header and its grid.
  static const double headerGap = 4;

  /// The resolved inputs of this build pass.
  final HeatmapRenderSpec spec;

  /// Scroll controller shared with the view so `goto` can drive it.
  final ScrollController controller;

  /// Called when a day is tapped.
  final void Function(DateTime date)? onTap;

  /// Called on a long press on a day.
  final void Function(DateTime date)? onLongPress;

  /// Total height of a month header, or zero when month labels are hidden.
  static double headerHeightFor(HeatmapRenderSpec spec) =>
      spec.config.showMonthLabels
      ? spec.config.labels.monthLabelHeight + headerGap
      : 0;

  @override
  Widget build(BuildContext context) {
    final List<HeatmapMonthSection> sections = spec.model.monthSections;
    final HeatmapLabelsConfig labels = spec.config.labels;

    return ListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      reverse: spec.textDirection == TextDirection.rtl,
      itemCount: sections.length,
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context, int index) {
        final HeatmapMonthSection section = sections[index];
        final bool isLast = index == sections.length - 1;

        return RepaintBoundary(
          child: Padding(
            // The gap belongs to the item rather than sitting between items so
            // that the laid-out offsets match HeatmapGridModel's arithmetic.
            padding: EdgeInsetsDirectional.only(
              end: isLast ? 0 : labels.splitMonthSectionGap,
            ),
            child: _MonthBlock(
              spec: spec,
              section: section,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        );
      },
    );
  }
}

class _MonthBlock extends StatelessWidget {
  const _MonthBlock({
    required this.spec,
    required this.section,
    this.onTap,
    this.onLongPress,
  });

  final HeatmapRenderSpec spec;
  final HeatmapMonthSection section;
  final void Function(DateTime date)? onTap;
  final void Function(DateTime date)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final HeatmapLabelsConfig labels = spec.config.labels;

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (spec.config.showMonthLabels) ...<Widget>[
          SizedBox(
            height: labels.monthLabelHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                spec.monthLabel(context, section.month, showYear: _showsYear()),
                maxLines: 1,
                softWrap: false,
                style: spec.labelStyle(context),
              ),
            ),
          ),
          const SizedBox(height: HeatmapBodySplitMonth.headerGap),
        ],
        HeatmapWeekRow(
          spec: spec,
          gridStart: section.gridStart,
          columnCount: section.columnCount,
          sectionMonth: section.month,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ],
    );

    // Only the horizontal insets are applied: the grid model accounts for
    // them, and vertical padding here would break the alignment between the
    // blocks and the weekday gutter beside them.
    final Widget padded = Padding(
      padding: EdgeInsetsDirectional.only(
        start: labels.splitMonthPadding.left,
        end: labels.splitMonthPadding.right,
      ),
      child: content,
    );

    if (labels.splitMonthDecoration == null) {
      return padded;
    }
    return DecoratedBox(
      decoration: labels.splitMonthDecoration!,
      child: padded,
    );
  }

  bool _showsYear() {
    switch (spec.config.yearDisplay) {
      case HeatmapYearDisplay.never:
        return false;
      case HeatmapYearDisplay.always:
        return true;
      case HeatmapYearDisplay.onChange:
        final List<HeatmapMonthSection> sections = spec.model.monthSections;
        final int index = sections.indexOf(section);
        if (index <= 0) {
          return true;
        }
        return sections[index - 1].month.year != section.month.year;
    }
  }
}
