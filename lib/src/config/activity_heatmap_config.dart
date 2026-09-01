import 'package:flutter/widgets.dart';

import '../core/heatmap_level_resolver.dart';
import '../models/activity.dart';
import 'heatmap_cell_style.dart';
import 'heatmap_color_theme.dart';
import 'heatmap_labels_config.dart';
import 'heatmap_range.dart';

/// Signature for the integer heat contribution of a single activity.
///
/// Return a value greater than one to make an activity weigh more. For
/// example, heat by workout duration:
///
/// ```dart
/// activityWeight: (a) => (a.detail as Workout).minutes,
/// ```
typedef ActivityWeight = int Function(Activity activity);

/// How the activities of a day are ordered in the detail sheet.
@immutable
class ActivitySort {
  const ActivitySort._(this._comparator, this._name);

  /// Builds a sort from a custom comparator.
  factory ActivitySort.custom(Comparator<Activity> comparator) =>
      ActivitySort._(comparator, 'custom');

  /// Keeps the order in which activities were inserted. The default.
  static const ActivitySort insertion = ActivitySort._(null, 'insertion');

  /// Alphabetical by name.
  static final ActivitySort byName = ActivitySort._(
    (Activity a, Activity b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    'byName',
  );

  /// Grouped by type id, then by name.
  static final ActivitySort byType = ActivitySort._((Activity a, Activity b) {
    final int byType = a.type.id.compareTo(b.type.id);
    return byType != 0 ? byType : a.name.compareTo(b.name);
  }, 'byType');

  /// Chronological by the full timestamp, so activities with a time of day
  /// read in the order they happened.
  static final ActivitySort byTime = ActivitySort._(
    (Activity a, Activity b) => a.date.compareTo(b.date),
    'byTime',
  );

  final Comparator<Activity>? _comparator;
  final String _name;

  /// Returns a sorted copy of [activities], or the same list when this is
  /// [insertion].
  List<Activity> apply(List<Activity> activities) {
    if (_comparator == null) {
      return activities;
    }
    return List<Activity>.of(activities)..sort(_comparator);
  }

  @override
  String toString() => 'ActivitySort.$_name';
}

/// Every knob that changes how the heatmap looks and behaves.
///
/// The configuration lives on the controller so that all attached views stay
/// in sync, but a single view can override it locally:
///
/// ```dart
/// ActivityHeatmapCalendar().setConfig(
///   const ActivityHeatmapConfig(splitMonthView: true),
/// );
/// ```
@immutable
class ActivityHeatmapConfig {
  /// Creates a configuration. Every field has a sensible default.
  const ActivityHeatmapConfig({
    this.range = const HeatmapRange.trailingMonths(12),
    this.weekStartsOn = DateTime.monday,
    this.cellStyle = const HeatmapCellStyle(),
    this.colorTheme = HeatmapColorTheme.github,
    this.levelResolver = const ThresholdLevelResolver.github(),
    this.labels = const HeatmapLabelsConfig(),
    this.showMonthLabels = true,
    this.showWeekdayLabels = true,
    this.showLegend = true,
    this.splitMonthView = false,
    this.yearDisplay = HeatmapYearDisplay.onChange,
    this.showFilterBanner = true,
    this.useTypeColorWhenFiltered = true,
    this.tapEmptyCells = true,
    this.alwaysShowSheet = false,
    this.showTooltips = true,
    this.activitySort = ActivitySort.insertion,
    this.activityWeight,
    this.initialDate,
    this.initialAlignment = 1,
    this.padding = const EdgeInsets.all(12),
    this.today,
  }) : assert(
         weekStartsOn >= DateTime.monday && weekStartsOn <= DateTime.sunday,
         'weekStartsOn must be a DateTime weekday constant (1..7)',
       ),
       assert(
         initialAlignment >= 0 && initialAlignment <= 1,
         'initialAlignment must be between 0 and 1',
       );

  /// Which span of days the grid covers.
  final HeatmapRange range;

  /// First day of the week, using the [DateTime.monday]…[DateTime.sunday]
  /// constants. Defaults to Monday.
  final int weekStartsOn;

  /// Size, radius and custom builder of a day cell.
  final HeatmapCellStyle cellStyle;

  /// The intensity colour ramp.
  final HeatmapColorTheme colorTheme;

  /// Strategy converting a daily value into an intensity level.
  final HeatmapLevelResolver levelResolver;

  /// Typography and text overrides for labels.
  final HeatmapLabelsConfig labels;

  /// Whether month names appear above the grid.
  final bool showMonthLabels;

  /// Whether weekday names appear in the left gutter.
  final bool showWeekdayLabels;

  /// Whether the "Less … More" legend appears below the grid.
  final bool showLegend;

  /// Whether each month is drawn as its own block instead of one continuous
  /// run of weeks.
  final bool splitMonthView;

  /// Whether and when month labels include the year.
  final HeatmapYearDisplay yearDisplay;

  /// Whether a dismissible banner appears while a type filter is active.
  final bool showFilterBanner;

  /// Whether filtering by a type that declares a colour re-tints the heatmap
  /// with that colour, making the active filter obvious at a glance.
  final bool useTypeColorWhenFiltered;

  /// Whether days with no activities respond to taps.
  final bool tapEmptyCells;

  /// Whether the default bottom sheet still opens when a custom `onCellTap`
  /// is supplied. Defaults to false: a custom callback replaces the sheet.
  final bool alwaysShowSheet;

  /// Whether hovering a cell on desktop and web shows a tooltip.
  final bool showTooltips;

  /// Order of activities inside the detail sheet.
  final ActivitySort activitySort;

  /// Optional per-activity heat weight. When null every activity counts as 1.
  final ActivityWeight? activityWeight;

  /// Date the view scrolls to on first layout. Defaults to today.
  final DateTime? initialDate;

  /// Where [initialDate] sits in the viewport: `0` left, `0.5` centred,
  /// `1` right. Defaults to `1`, so the graph opens on the most recent days.
  final double initialAlignment;

  /// Padding around the whole widget.
  final EdgeInsets padding;

  /// Overrides "today" for range resolution and the today ring.
  ///
  /// Injectable so tests and screenshots are deterministic.
  final DateTime? today;

  /// The value of "today" this configuration should use.
  DateTime get resolvedToday => today ?? DateTime.now();

  /// Returns a copy of this configuration with the given fields replaced.
  ActivityHeatmapConfig copyWith({
    HeatmapRange? range,
    int? weekStartsOn,
    HeatmapCellStyle? cellStyle,
    HeatmapColorTheme? colorTheme,
    HeatmapLevelResolver? levelResolver,
    HeatmapLabelsConfig? labels,
    bool? showMonthLabels,
    bool? showWeekdayLabels,
    bool? showLegend,
    bool? splitMonthView,
    HeatmapYearDisplay? yearDisplay,
    bool? showFilterBanner,
    bool? useTypeColorWhenFiltered,
    bool? tapEmptyCells,
    bool? alwaysShowSheet,
    bool? showTooltips,
    ActivitySort? activitySort,
    ActivityWeight? activityWeight,
    bool clearActivityWeight = false,
    DateTime? initialDate,
    bool clearInitialDate = false,
    double? initialAlignment,
    EdgeInsets? padding,
    DateTime? today,
    bool clearToday = false,
  }) {
    return ActivityHeatmapConfig(
      range: range ?? this.range,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      cellStyle: cellStyle ?? this.cellStyle,
      colorTheme: colorTheme ?? this.colorTheme,
      levelResolver: levelResolver ?? this.levelResolver,
      labels: labels ?? this.labels,
      showMonthLabels: showMonthLabels ?? this.showMonthLabels,
      showWeekdayLabels: showWeekdayLabels ?? this.showWeekdayLabels,
      showLegend: showLegend ?? this.showLegend,
      splitMonthView: splitMonthView ?? this.splitMonthView,
      yearDisplay: yearDisplay ?? this.yearDisplay,
      showFilterBanner: showFilterBanner ?? this.showFilterBanner,
      useTypeColorWhenFiltered:
          useTypeColorWhenFiltered ?? this.useTypeColorWhenFiltered,
      tapEmptyCells: tapEmptyCells ?? this.tapEmptyCells,
      alwaysShowSheet: alwaysShowSheet ?? this.alwaysShowSheet,
      showTooltips: showTooltips ?? this.showTooltips,
      activitySort: activitySort ?? this.activitySort,
      activityWeight: clearActivityWeight
          ? null
          : (activityWeight ?? this.activityWeight),
      initialDate: clearInitialDate ? null : (initialDate ?? this.initialDate),
      initialAlignment: initialAlignment ?? this.initialAlignment,
      padding: padding ?? this.padding,
      today: clearToday ? null : (today ?? this.today),
    );
  }

  /// Whether a change from [other] to this configuration invalidates the
  /// cached grid geometry.
  bool affectsLayout(ActivityHeatmapConfig other) =>
      other.range != range ||
      other.weekStartsOn != weekStartsOn ||
      other.cellStyle.extent != cellStyle.extent ||
      other.splitMonthView != splitMonthView ||
      other.labels.splitMonthSectionGap != labels.splitMonthSectionGap ||
      other.labels.splitMonthPadding != labels.splitMonthPadding ||
      other.today != today;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityHeatmapConfig &&
          other.range == range &&
          other.weekStartsOn == weekStartsOn &&
          other.cellStyle == cellStyle &&
          other.colorTheme == colorTheme &&
          other.levelResolver == levelResolver &&
          other.labels == labels &&
          other.showMonthLabels == showMonthLabels &&
          other.showWeekdayLabels == showWeekdayLabels &&
          other.showLegend == showLegend &&
          other.splitMonthView == splitMonthView &&
          other.yearDisplay == yearDisplay &&
          other.showFilterBanner == showFilterBanner &&
          other.useTypeColorWhenFiltered == useTypeColorWhenFiltered &&
          other.tapEmptyCells == tapEmptyCells &&
          other.alwaysShowSheet == alwaysShowSheet &&
          other.showTooltips == showTooltips &&
          other.activitySort == activitySort &&
          other.activityWeight == activityWeight &&
          other.initialDate == initialDate &&
          other.initialAlignment == initialAlignment &&
          other.padding == padding &&
          other.today == today;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    range,
    weekStartsOn,
    cellStyle,
    colorTheme,
    levelResolver,
    labels,
    showMonthLabels,
    showWeekdayLabels,
    showLegend,
    splitMonthView,
    yearDisplay,
    showFilterBanner,
    useTypeColorWhenFiltered,
    tapEmptyCells,
    alwaysShowSheet,
    showTooltips,
    activitySort,
    activityWeight,
    initialDate,
    initialAlignment,
    padding,
    today,
  ]);
}
