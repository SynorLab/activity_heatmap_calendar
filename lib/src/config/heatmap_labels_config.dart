import 'package:flutter/widgets.dart';

import '../models/heatmap_cell_data.dart';

/// Signature for overriding a date-derived label such as a month or weekday
/// name.
typedef HeatmapDateLabelBuilder =
    String Function(BuildContext context, DateTime date);

/// Signature for overriding the accessibility label of a day cell.
typedef HeatmapSemanticsBuilder =
    String Function(BuildContext context, HeatmapCellData data);

/// How often weekday names appear in the left gutter.
enum HeatmapWeekdayLabelMode {
  /// A name on every row.
  all,

  /// A name on every other row, like GitHub. Reads as less noise at small
  /// cell sizes.
  alternate,

  /// No names, but the gutter keeps its width so the grid stays aligned.
  none,
}

/// Whether month labels include the year.
enum HeatmapYearDisplay {
  /// Never show the year.
  never,

  /// Show the year only on the first month of the range and whenever the year
  /// changes, so "Dec, Jan 2027, Feb" reads naturally.
  onChange,

  /// Show the year on every month label.
  always,
}

/// Typography, spacing and text overrides for the heatmap's labels.
@immutable
class HeatmapLabelsConfig {
  /// Creates a labels configuration.
  const HeatmapLabelsConfig({
    this.weekdayLabelMode = HeatmapWeekdayLabelMode.alternate,
    this.monthLabelBuilder,
    this.weekdayLabelBuilder,
    this.cellSemanticsBuilder,
    this.textStyle,
    this.monthLabelHeight = 20,
    this.gutterSpacing = 8,
    this.splitMonthSectionGap = 16,
    this.splitMonthDecoration,
    this.splitMonthPadding = const EdgeInsets.symmetric(horizontal: 6),
  });

  /// How often weekday names are drawn.
  final HeatmapWeekdayLabelMode weekdayLabelMode;

  /// Overrides the month label text. Receives the first day of the month.
  ///
  /// When null the name comes from `intl`'s `DateFormat` in the ambient
  /// locale, so it follows the app's language with no configuration.
  final HeatmapDateLabelBuilder? monthLabelBuilder;

  /// Overrides the weekday label text. Receives a date whose weekday is the
  /// one being labelled.
  final HeatmapDateLabelBuilder? weekdayLabelBuilder;

  /// Overrides the screen-reader description of a day cell.
  final HeatmapSemanticsBuilder? cellSemanticsBuilder;

  /// Text style for month and weekday labels.
  ///
  /// Merged over `textTheme.labelSmall` with a muted colour, so passing only
  /// a `fontSize` or `color` works as expected.
  final TextStyle? textStyle;

  /// Height reserved above the grid for month labels.
  ///
  /// Reserved even when month labels are hidden is *not* the behaviour: the
  /// space collapses in that case. This value only applies when labels show.
  final double monthLabelHeight;

  /// Gap between the weekday gutter and the first column of cells.
  final double gutterSpacing;

  /// Gap between month blocks when `splitMonthView` is enabled.
  final double splitMonthSectionGap;

  /// Optional decoration painted behind each month block in split month view.
  final BoxDecoration? splitMonthDecoration;

  /// Padding inside each month block in split month view.
  final EdgeInsets splitMonthPadding;

  /// Returns a copy of this configuration with the given fields replaced.
  HeatmapLabelsConfig copyWith({
    HeatmapWeekdayLabelMode? weekdayLabelMode,
    HeatmapDateLabelBuilder? monthLabelBuilder,
    HeatmapDateLabelBuilder? weekdayLabelBuilder,
    HeatmapSemanticsBuilder? cellSemanticsBuilder,
    TextStyle? textStyle,
    double? monthLabelHeight,
    double? gutterSpacing,
    double? splitMonthSectionGap,
    BoxDecoration? splitMonthDecoration,
    EdgeInsets? splitMonthPadding,
  }) {
    return HeatmapLabelsConfig(
      weekdayLabelMode: weekdayLabelMode ?? this.weekdayLabelMode,
      monthLabelBuilder: monthLabelBuilder ?? this.monthLabelBuilder,
      weekdayLabelBuilder: weekdayLabelBuilder ?? this.weekdayLabelBuilder,
      cellSemanticsBuilder: cellSemanticsBuilder ?? this.cellSemanticsBuilder,
      textStyle: textStyle ?? this.textStyle,
      monthLabelHeight: monthLabelHeight ?? this.monthLabelHeight,
      gutterSpacing: gutterSpacing ?? this.gutterSpacing,
      splitMonthSectionGap: splitMonthSectionGap ?? this.splitMonthSectionGap,
      splitMonthDecoration: splitMonthDecoration ?? this.splitMonthDecoration,
      splitMonthPadding: splitMonthPadding ?? this.splitMonthPadding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapLabelsConfig &&
          other.weekdayLabelMode == weekdayLabelMode &&
          other.monthLabelBuilder == monthLabelBuilder &&
          other.weekdayLabelBuilder == weekdayLabelBuilder &&
          other.cellSemanticsBuilder == cellSemanticsBuilder &&
          other.textStyle == textStyle &&
          other.monthLabelHeight == monthLabelHeight &&
          other.gutterSpacing == gutterSpacing &&
          other.splitMonthSectionGap == splitMonthSectionGap &&
          other.splitMonthDecoration == splitMonthDecoration &&
          other.splitMonthPadding == splitMonthPadding;

  @override
  int get hashCode => Object.hash(
    weekdayLabelMode,
    monthLabelBuilder,
    weekdayLabelBuilder,
    cellSemanticsBuilder,
    textStyle,
    monthLabelHeight,
    gutterSpacing,
    splitMonthSectionGap,
    splitMonthDecoration,
    splitMonthPadding,
  );
}
