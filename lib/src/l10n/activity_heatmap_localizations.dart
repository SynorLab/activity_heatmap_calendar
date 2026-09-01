import 'package:flutter/widgets.dart';

import '../models/activity_type.dart';
import 'gen/activity_heatmap_localizations_gen.dart';
import 'gen/activity_heatmap_localizations_gen_en.dart';
import 'heatmap_string_overrides.dart';

/// The package's own UI strings, resolved for the ambient locale.
///
/// ## Registering the delegate
///
/// Add [delegate] to your app so the strings follow your app's language:
///
/// ```dart
/// MaterialApp(
///   localizationsDelegates: const [
///     ActivityHeatmapLocalizations.delegate,
///     GlobalMaterialLocalizations.delegate,
///     GlobalWidgetsLocalizations.delegate,
///   ],
///   supportedLocales: ActivityHeatmapLocalizations.supportedLocales,
/// )
/// ```
///
/// Forgetting the delegate is not an error: [of] falls back to English rather
/// than throwing, so a heatmap dropped into an app with no localization set up
/// still renders.
///
/// ## Overriding individual strings
///
/// Wrap the heatmap in an [ActivityHeatmapStrings] widget; see
/// [HeatmapStringOverrides].
@immutable
class ActivityHeatmapLocalizations {
  const ActivityHeatmapLocalizations._(this._strings, this._overrides);

  /// The delegate to register in `localizationsDelegates`.
  ///
  /// `zh_TW` / `zh_HK` / `zh_MO` resolve to Traditional Chinese; `zh_CN` /
  /// `zh_SG` resolve to Simplified. Flutter's generated lookup would otherwise
  /// fall `zh_TW` back to generic `zh`, which this package ships as Simplified.
  static const LocalizationsDelegate<ActivityHeatmapLocalizationsGen> delegate =
      _ChineseScriptAwareDelegate();

  /// Every locale shipped with the package.
  ///
  /// Contributions are welcome: add an ARB file next to the existing ones and
  /// this list grows automatically. Country variants of Chinese are listed
  /// explicitly so a `zh_TW` app locale is not collapsed to generic `zh`.
  static const List<Locale> supportedLocales = <Locale>[
    ...ActivityHeatmapLocalizationsGen.supportedLocales,
    Locale('zh', 'TW'),
    Locale('zh', 'HK'),
    Locale('zh', 'MO'),
    Locale('zh', 'CN'),
    Locale('zh', 'SG'),
  ];

  /// English strings, used when no delegate is registered.
  static final ActivityHeatmapLocalizationsGen fallback =
      ActivityHeatmapLocalizationsGenEn();

  final ActivityHeatmapLocalizationsGen _strings;
  final HeatmapStringOverrides? _overrides;

  /// Resolves the strings for [context].
  ///
  /// Uses, in order: any [ActivityHeatmapStrings] override above [context],
  /// the registered delegate for the ambient locale, then English.
  static ActivityHeatmapLocalizations of(BuildContext context) {
    final ActivityHeatmapLocalizationsGen strings =
        Localizations.of<ActivityHeatmapLocalizationsGen>(
          context,
          ActivityHeatmapLocalizationsGen,
        ) ??
        fallback;
    return ActivityHeatmapLocalizations._(
      strings,
      ActivityHeatmapStrings.maybeOf(context),
    );
  }

  /// Leading label of the intensity legend.
  String get legendLess => _overrides?.legendLess ?? _strings.legendLess;

  /// Trailing label of the intensity legend.
  String get legendMore => _overrides?.legendMore ?? _strings.legendMore;

  /// How many activities a day holds, pluralised for the locale.
  String activityCount(int count) =>
      _overrides?.activityCount?.call(count) ?? _strings.activityCount(count);

  /// Title of the empty state.
  String get noActivitiesTitle =>
      _overrides?.noActivitiesTitle ?? _strings.noActivitiesTitle;

  /// Body of the empty state.
  String get noActivitiesBody =>
      _overrides?.noActivitiesBody ?? _strings.noActivitiesBody;

  /// Label of the sheet's close button.
  String get close => _overrides?.close ?? _strings.close;

  /// Screen-reader description of a day cell.
  String cellSemantics(String date, int count) =>
      _overrides?.cellSemantics?.call(date, count) ??
      _strings.cellSemantics(date, count);

  /// Text of the active-filter banner.
  String filterBanner(String type) =>
      _overrides?.filterBanner?.call(type) ?? _strings.filterBanner(type);

  /// Tooltip of the button that clears the filter.
  String get clearFilter => _overrides?.clearFilter ?? _strings.clearFilter;

  /// Display name of [ActivityType.all].
  String get typeAll => _overrides?.typeAll ?? _strings.typeAll;

  /// Label marking the current day.
  String get today => _overrides?.today ?? _strings.today;

  /// Hover tooltip over a day cell.
  String tooltipActivities(int count, String date) =>
      _overrides?.tooltipActivities?.call(count, date) ??
      _strings.tooltipActivities(count, date);

  /// The display name of [type].
  ///
  /// Uses the type's own `label` when it has one, localizes
  /// [ActivityType.all], and otherwise falls back to the type id.
  String typeLabel(ActivityType type) {
    if (type.label != null) {
      return type.label!;
    }
    return type.isAll ? typeAll : type.id;
  }
}

/// Maps Chinese country codes onto the script variants the ARB files use.
///
/// Generated lookup only branches on `scriptCode`, so `Locale('zh', 'TW')`
/// would otherwise load generic `zh` (Simplified).
class _ChineseScriptAwareDelegate
    extends LocalizationsDelegate<ActivityHeatmapLocalizationsGen> {
  const _ChineseScriptAwareDelegate();

  static const Set<String> _traditionalCountries = <String>{'TW', 'HK', 'MO'};
  static const Set<String> _simplifiedCountries = <String>{'CN', 'SG'};

  static Locale resolve(Locale locale) {
    if (locale.languageCode != 'zh') {
      return locale;
    }
    if (locale.scriptCode == 'Hant' ||
        _traditionalCountries.contains(locale.countryCode)) {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    }
    if (locale.scriptCode == 'Hans' ||
        _simplifiedCountries.contains(locale.countryCode)) {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    }
    return locale;
  }

  @override
  bool isSupported(Locale locale) =>
      ActivityHeatmapLocalizationsGen.delegate.isSupported(locale);

  @override
  Future<ActivityHeatmapLocalizationsGen> load(Locale locale) =>
      ActivityHeatmapLocalizationsGen.delegate.load(resolve(locale));

  @override
  bool shouldReload(_ChineseScriptAwareDelegate old) => false;
}
