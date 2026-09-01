import 'package:flutter/widgets.dart';

/// Per-string overrides for the package's own UI text.
///
/// Use this when you want to change a word or two without adopting the
/// package's localization delegate, or when your app keeps its strings
/// somewhere other than an ARB file:
///
/// ```dart
/// ActivityHeatmapStrings(
///   overrides: HeatmapStringOverrides(
///     legendLess: 'Quiet',
///     legendMore: 'Busy',
///     activityCount: (count) => '$count sessions',
///   ),
///   child: const ActivityHeatmapCalendarView(),
/// )
/// ```
///
/// Any field left null falls back to the localized string.
@immutable
class HeatmapStringOverrides {
  /// Creates a set of overrides. Every field is optional.
  const HeatmapStringOverrides({
    this.legendLess,
    this.legendMore,
    this.activityCount,
    this.noActivitiesTitle,
    this.noActivitiesBody,
    this.close,
    this.cellSemantics,
    this.filterBanner,
    this.clearFilter,
    this.typeAll,
    this.today,
    this.tooltipActivities,
  });

  /// Leading label of the intensity legend.
  final String? legendLess;

  /// Trailing label of the intensity legend.
  final String? legendMore;

  /// Subtitle describing how many activities a day holds.
  final String Function(int count)? activityCount;

  /// Title of the empty state.
  final String? noActivitiesTitle;

  /// Body of the empty state.
  final String? noActivitiesBody;

  /// Label of the sheet's close button.
  final String? close;

  /// Screen-reader description of a day cell.
  final String Function(String date, int count)? cellSemantics;

  /// Text of the active-filter banner.
  final String Function(String type)? filterBanner;

  /// Tooltip of the button that clears the filter.
  final String? clearFilter;

  /// Display name of [ActivityType.all].
  final String? typeAll;

  /// Label marking the current day.
  final String? today;

  /// Hover tooltip over a day cell.
  final String Function(int count, String date)? tooltipActivities;

  /// Whether every field is null.
  bool get isEmpty =>
      legendLess == null &&
      legendMore == null &&
      activityCount == null &&
      noActivitiesTitle == null &&
      noActivitiesBody == null &&
      close == null &&
      cellSemantics == null &&
      filterBanner == null &&
      clearFilter == null &&
      typeAll == null &&
      today == null &&
      tooltipActivities == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapStringOverrides &&
          other.legendLess == legendLess &&
          other.legendMore == legendMore &&
          other.activityCount == activityCount &&
          other.noActivitiesTitle == noActivitiesTitle &&
          other.noActivitiesBody == noActivitiesBody &&
          other.close == close &&
          other.cellSemantics == cellSemantics &&
          other.filterBanner == filterBanner &&
          other.clearFilter == clearFilter &&
          other.typeAll == typeAll &&
          other.today == today &&
          other.tooltipActivities == tooltipActivities;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    legendLess,
    legendMore,
    activityCount,
    noActivitiesTitle,
    noActivitiesBody,
    close,
    cellSemantics,
    filterBanner,
    clearFilter,
    typeAll,
    today,
    tooltipActivities,
  ]);
}

/// Supplies [HeatmapStringOverrides] to the heatmaps below it in the tree.
class ActivityHeatmapStrings extends InheritedWidget {
  /// Wraps [child] so its heatmaps use [overrides].
  const ActivityHeatmapStrings({
    required this.overrides,
    required super.child,
    super.key,
  });

  /// The overrides in effect.
  final HeatmapStringOverrides overrides;

  /// The nearest overrides above [context], or null.
  static HeatmapStringOverrides? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ActivityHeatmapStrings>()
      ?.overrides;

  @override
  bool updateShouldNotify(ActivityHeatmapStrings oldWidget) =>
      oldWidget.overrides != overrides;
}
