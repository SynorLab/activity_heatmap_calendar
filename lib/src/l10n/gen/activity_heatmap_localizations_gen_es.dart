// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'activity_heatmap_localizations_gen.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ActivityHeatmapLocalizationsGenEs
    extends ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGenEs([String locale = 'es']) : super(locale);

  @override
  String get legendLess => 'Menos';

  @override
  String get legendMore => 'Más';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actividades',
      one: '1 actividad',
      zero: 'Sin actividades',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => 'Aún no hay nada';

  @override
  String get noActivitiesBody => 'No hay actividades registradas en este día.';

  @override
  String get close => 'Cerrar';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actividades',
      one: '1 actividad',
      zero: 'sin actividades',
    );
    return '$date, $_temp0';
  }

  @override
  String filterBanner(String type) {
    return 'Filtrado por $type';
  }

  @override
  String get clearFilter => 'Quitar filtro';

  @override
  String get typeAll => 'Todas';

  @override
  String get today => 'Hoy';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actividades',
      one: '1 actividad',
      zero: 'Sin actividades',
    );
    return '$_temp0 el $date';
  }
}
