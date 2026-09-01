import 'package:flutter/widgets.dart';

import '../config/activity_heatmap_config.dart';
import '../config/heatmap_color_theme.dart';
import '../core/heatmap_data.dart';
import '../core/heatmap_grid_model.dart';
import '../l10n/activity_heatmap_localizations.dart';
import '../l10n/heatmap_label_formatter.dart';
import '../models/activity_type.dart';
import '../models/heatmap_cell_data.dart';
import '../models/heatmap_date_utils.dart';

/// Everything the grid widgets need, resolved once per build pass.
///
/// Bundling these keeps the widget tree shallow in parameters and, more
/// importantly, guarantees that every cell in a frame reads the same data,
/// theme and "today" — mixing two of those produces subtle off-by-one-day
/// artefacts that are painful to track down.
@immutable
class HeatmapRenderSpec {
  /// Bundles the resolved inputs of a build pass.
  const HeatmapRenderSpec({
    required this.config,
    required this.model,
    required this.data,
    required this.theme,
    required this.today,
    required this.formatter,
    required this.strings,
    required this.textDirection,
    this.activeFilter,
    this.selectedDate,
  });

  /// The active configuration.
  final ActivityHeatmapConfig config;

  /// The grid geometry.
  final HeatmapGridModel model;

  /// Daily values and the intensity scale.
  final HeatmapData data;

  /// The colour ramp, already resolved for the ambient brightness and, when
  /// filtering by a type that declares a colour, re-tinted with it.
  final HeatmapColorTheme theme;

  /// Local midnight of the day treated as today.
  final DateTime today;

  /// Date formatter for the ambient locale.
  final HeatmapLabelFormatter formatter;

  /// The package's UI strings.
  final ActivityHeatmapLocalizations strings;

  /// Reading direction, which mirrors the grid and the gutter.
  final TextDirection textDirection;

  /// The type filter in effect, or null.
  final ActivityType? activeFilter;

  /// The day whose detail sheet is open, or null.
  final DateTime? selectedDate;

  /// Shorthand for the cell geometry.
  double get cellSize => config.cellStyle.size;

  /// Shorthand for the distance between column origins.
  double get cellExtent => model.cellExtent;

  /// Height reserved above the grid for month labels, or zero when they are
  /// hidden.
  double get monthLabelHeight =>
      config.showMonthLabels ? config.labels.monthLabelHeight : 0;

  /// Builds the render data for a single day.
  ///
  /// [sectionMonth] is the month block being painted in split-month view.
  /// Days that spill into the neighbouring month stay in the grid so the
  /// 1st / 2nd / 3rd sit on the correct weekday row, but they are placeholders
  /// rather than painted cells of that neighbour.
  HeatmapCellData cellDataFor(DateTime date, {DateTime? sectionMonth}) {
    final bool inRange = model.isInRange(date);
    final bool inSection =
        sectionMonth == null ||
        HeatmapDateUtils.isSameMonth(date, sectionMonth);
    final bool visible = inRange && inSection;
    final int value = visible ? data.valueOf(HeatmapDateUtils.dayKey(date)) : 0;
    final int level = visible ? data.scale.levelOf(value) : 0;
    return HeatmapCellData(
      date: date,
      count: value,
      level: level,
      levelCount: theme.levelCount,
      color: visible ? theme.colorForLevel(level) : const Color(0x00000000),
      isToday: HeatmapDateUtils.isSameDay(date, today),
      isOutOfRange: !inRange,
      isPlaceholder: !visible,
      isSelected:
          selectedDate != null &&
          HeatmapDateUtils.isSameDay(date, selectedDate!),
      activeFilter: activeFilter,
    );
  }

  /// The text style used for month and weekday labels.
  TextStyle labelStyle(BuildContext context) {
    final TextStyle base = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 11, height: 1.2, fontWeight: FontWeight.w500);
    return config.labels.textStyle == null
        ? base
        : base.merge(config.labels.textStyle);
  }

  /// The month label for a date, honouring the year display setting.
  ///
  /// [showYear] is decided by the caller because it depends on the previous
  /// label, which only the layout knows.
  String monthLabel(
    BuildContext context,
    DateTime date, {
    bool showYear = false,
  }) {
    final String? custom = config.labels.monthLabelBuilder?.call(context, date);
    if (custom != null) {
      return custom;
    }
    return showYear ? formatter.monthWithYear(date) : formatter.month(date);
  }
}
