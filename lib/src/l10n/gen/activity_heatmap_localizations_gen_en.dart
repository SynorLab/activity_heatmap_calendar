// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'activity_heatmap_localizations_gen.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ActivityHeatmapLocalizationsGenEn
    extends ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGenEn([String locale = 'en']) : super(locale);

  @override
  String get legendLess => 'Less';

  @override
  String get legendMore => 'More';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
      zero: 'No activities',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => 'Nothing here yet';

  @override
  String get noActivitiesBody =>
      'There are no activities recorded on this day.';

  @override
  String get close => 'Close';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
      zero: 'no activities',
    );
    return '$date, $_temp0';
  }

  @override
  String filterBanner(String type) {
    return 'Filtered by $type';
  }

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get typeAll => 'All';

  @override
  String get today => 'Today';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
      zero: 'No activities',
    );
    return '$_temp0 on $date';
  }
}
