// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'activity_heatmap_localizations_gen.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class ActivityHeatmapLocalizationsGenDe
    extends ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGenDe([String locale = 'de']) : super(locale);

  @override
  String get legendLess => 'Weniger';

  @override
  String get legendMore => 'Mehr';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aktivitäten',
      one: '1 Aktivität',
      zero: 'Keine Aktivitäten',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => 'Noch nichts vorhanden';

  @override
  String get noActivitiesBody =>
      'An diesem Tag wurden keine Aktivitäten erfasst.';

  @override
  String get close => 'Schließen';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aktivitäten',
      one: '1 Aktivität',
      zero: 'keine Aktivitäten',
    );
    return '$date, $_temp0';
  }

  @override
  String filterBanner(String type) {
    return 'Gefiltert nach $type';
  }

  @override
  String get clearFilter => 'Filter entfernen';

  @override
  String get typeAll => 'Alle';

  @override
  String get today => 'Heute';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aktivitäten',
      one: '1 Aktivität',
      zero: 'Keine Aktivitäten',
    );
    return '$_temp0 am $date';
  }
}
