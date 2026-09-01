// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'activity_heatmap_localizations_gen.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ActivityHeatmapLocalizationsGenFr
    extends ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGenFr([String locale = 'fr']) : super(locale);

  @override
  String get legendLess => 'Moins';

  @override
  String get legendMore => 'Plus';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités',
      one: '1 activité',
      zero: 'Aucune activité',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => 'Rien pour le moment';

  @override
  String get noActivitiesBody => 'Aucune activité enregistrée ce jour-là.';

  @override
  String get close => 'Fermer';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités',
      one: '1 activité',
      zero: 'aucune activité',
    );
    return '$date, $_temp0';
  }

  @override
  String filterBanner(String type) {
    return 'Filtré par $type';
  }

  @override
  String get clearFilter => 'Effacer le filtre';

  @override
  String get typeAll => 'Toutes';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités',
      one: '1 activité',
      zero: 'Aucune activité',
    );
    return '$_temp0 le $date';
  }
}
