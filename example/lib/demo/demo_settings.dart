import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';

import 'demo_data.dart';

/// Named colour ramps offered by the control panel.
final Map<String, HeatmapColorTheme> demoThemes = <String, HeatmapColorTheme>{
  'GitHub': HeatmapColorTheme.github,
  'Ocean': HeatmapColorTheme.ocean,
  'Sunset': HeatmapColorTheme.sunset,
  'Violet': HeatmapColorTheme.violet,
  'Forest': HeatmapColorTheme.forest,
  'Rose': HeatmapColorTheme.rose,
  'Mono': HeatmapColorTheme.mono,
};

/// Named intensity strategies offered by the control panel.
const Map<String, HeatmapLevelResolver> demoResolvers =
    <String, HeatmapLevelResolver>{
      'Fixed (GitHub)': ThresholdLevelResolver.github(),
      'Quantile': QuantileLevelResolver(),
      'Quantile (tail)': QuantileLevelResolver.tail(),
      'Relative': RelativeLevelResolver(),
    };

/// The locales the demo can switch between, with their own names.
const Map<String, Locale> demoLocales = <String, Locale>{
  'English': Locale('en'),
  '繁體中文': Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  '简体中文': Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  '日本語': Locale('ja'),
  '한국어': Locale('ko'),
  'Español': Locale('es'),
  'Français': Locale('fr'),
  'Deutsch': Locale('de'),
};

/// Every knob the demo exposes, kept in one place.
///
/// Whenever something changes, the derived [ActivityHeatmapConfig] is pushed
/// to the singleton with `setConfig`, so every attached view updates at once.
class DemoSettings extends ChangeNotifier {
  DemoSettings(this.calendar) {
    apply();
  }

  final ActivityHeatmapCalendar calendar;

  Locale locale = const Locale('en');
  ThemeMode themeMode = ThemeMode.light;

  String themeName = 'GitHub';
  String resolverName = 'Fixed (GitHub)';
  int weekStartsOn = DateTime.monday;
  double cellSize = 24;
  double cellRadius = 6;
  double cellSpacing = 4;
  int trailingMonths = 12;

  bool showMonthLabels = true;
  bool showWeekdayLabels = true;
  bool showLegend = true;
  bool splitMonthView = false;
  bool showTooltips = true;
  bool showFilterBanner = true;
  bool useTypeColorWhenFiltered = true;
  HeatmapYearDisplay yearDisplay = HeatmapYearDisplay.onChange;
  HeatmapWeekdayLabelMode weekdayLabelMode = HeatmapWeekdayLabelMode.alternate;
  ActivitySort activitySort = ActivitySort.insertion;

  /// Weigh a day by minutes practised instead of by number of activities.
  bool weightByMinutes = false;

  /// Replace the square cells with a custom builder.
  bool customCells = false;

  /// Replace the default detail sheet with the demo's own.
  bool customSheet = false;

  /// Replace two of the package's strings.
  bool overrideStrings = false;

  /// The configuration described by the current knobs.
  ActivityHeatmapConfig get config => ActivityHeatmapConfig(
    range: HeatmapRange.trailingMonths(trailingMonths),
    weekStartsOn: weekStartsOn,
    colorTheme: demoThemes[themeName]!,
    levelResolver: demoResolvers[resolverName]!,
    cellStyle: HeatmapCellStyle(
      size: cellSize,
      radius: cellRadius,
      spacing: cellSpacing,
    ),
    labels: HeatmapLabelsConfig(weekdayLabelMode: weekdayLabelMode),
    showMonthLabels: showMonthLabels,
    showWeekdayLabels: showWeekdayLabels,
    showLegend: showLegend,
    splitMonthView: splitMonthView,
    showTooltips: showTooltips,
    showFilterBanner: showFilterBanner,
    useTypeColorWhenFiltered: useTypeColorWhenFiltered,
    yearDisplay: yearDisplay,
    activitySort: activitySort,
    activityWeight: weightByMinutes
        ? (Activity a) => (a.detail! as Session).minutes
        : null,
  );

  /// Pushes the current configuration to the controller and rebuilds the demo.
  void apply() {
    calendar.setConfig(config);
    notifyListeners();
  }

  /// Runs [update] and then applies the result.
  void edit(VoidCallback update) {
    update();
    apply();
  }
}
