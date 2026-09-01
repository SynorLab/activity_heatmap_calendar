import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'activity_heatmap_localizations_gen_de.dart';
import 'activity_heatmap_localizations_gen_en.dart';
import 'activity_heatmap_localizations_gen_es.dart';
import 'activity_heatmap_localizations_gen_fr.dart';
import 'activity_heatmap_localizations_gen_ja.dart';
import 'activity_heatmap_localizations_gen_ko.dart';
import 'activity_heatmap_localizations_gen_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ActivityHeatmapLocalizationsGen
/// returned by `ActivityHeatmapLocalizationsGen.of(context)`.
///
/// Applications need to include `ActivityHeatmapLocalizationsGen.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/activity_heatmap_localizations_gen.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ActivityHeatmapLocalizationsGen.localizationsDelegates,
///   supportedLocales: ActivityHeatmapLocalizationsGen.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ActivityHeatmapLocalizationsGen.supportedLocales
/// property.
abstract class ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGen(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ActivityHeatmapLocalizationsGen of(BuildContext context) {
    return Localizations.of<ActivityHeatmapLocalizationsGen>(
      context,
      ActivityHeatmapLocalizationsGen,
    )!;
  }

  static const LocalizationsDelegate<ActivityHeatmapLocalizationsGen> delegate =
      _ActivityHeatmapLocalizationsGenDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Left-hand label of the heatmap intensity legend.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get legendLess;

  /// Right-hand label of the heatmap intensity legend.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get legendMore;

  /// Number of activities on a day, used as the bottom sheet subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No activities} =1{1 activity} other{{count} activities}}'**
  String activityCount(int count);

  /// Title of the empty state shown when a day has no activities.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noActivitiesTitle;

  /// Body of the empty state shown when a day has no activities.
  ///
  /// In en, this message translates to:
  /// **'There are no activities recorded on this day.'**
  String get noActivitiesBody;

  /// Tooltip and semantics label of the bottom sheet close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Accessibility label announced for a single heatmap day cell.
  ///
  /// In en, this message translates to:
  /// **'{date}, {count, plural, =0{no activities} =1{1 activity} other{{count} activities}}'**
  String cellSemantics(String date, int count);

  /// Banner shown above the heatmap while a type filter is active.
  ///
  /// In en, this message translates to:
  /// **'Filtered by {type}'**
  String filterBanner(String type);

  /// Tooltip of the button that removes the active type filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// Display name of the default ActivityType.all category.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get typeAll;

  /// Label marking the current day.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Hover tooltip shown over a day cell on desktop and web.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No activities} =1{1 activity} other{{count} activities}} on {date}'**
  String tooltipActivities(int count, String date);
}

class _ActivityHeatmapLocalizationsGenDelegate
    extends LocalizationsDelegate<ActivityHeatmapLocalizationsGen> {
  const _ActivityHeatmapLocalizationsGenDelegate();

  @override
  Future<ActivityHeatmapLocalizationsGen> load(Locale locale) {
    return SynchronousFuture<ActivityHeatmapLocalizationsGen>(
      lookupActivityHeatmapLocalizationsGen(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_ActivityHeatmapLocalizationsGenDelegate old) => false;
}

ActivityHeatmapLocalizationsGen lookupActivityHeatmapLocalizationsGen(
  Locale locale,
) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return ActivityHeatmapLocalizationsGenZhHans();
          case 'Hant':
            return ActivityHeatmapLocalizationsGenZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return ActivityHeatmapLocalizationsGenDe();
    case 'en':
      return ActivityHeatmapLocalizationsGenEn();
    case 'es':
      return ActivityHeatmapLocalizationsGenEs();
    case 'fr':
      return ActivityHeatmapLocalizationsGenFr();
    case 'ja':
      return ActivityHeatmapLocalizationsGenJa();
    case 'ko':
      return ActivityHeatmapLocalizationsGenKo();
    case 'zh':
      return ActivityHeatmapLocalizationsGenZh();
  }

  throw FlutterError(
    'ActivityHeatmapLocalizationsGen.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
