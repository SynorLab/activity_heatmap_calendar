// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'activity_heatmap_localizations_gen.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class ActivityHeatmapLocalizationsGenKo
    extends ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGenKo([String locale = 'ko']) : super(locale);

  @override
  String get legendLess => '적음';

  @override
  String get legendMore => '많음';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '활동 $count개',
      zero: '활동 없음',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => '아직 기록이 없습니다';

  @override
  String get noActivitiesBody => '이 날에 기록된 활동이 없습니다.';

  @override
  String get close => '닫기';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '활동 $count개',
      zero: '활동 없음',
    );
    return '$date, $_temp0';
  }

  @override
  String filterBanner(String type) {
    return '$type(으)로 필터링됨';
  }

  @override
  String get clearFilter => '필터 지우기';

  @override
  String get typeAll => '전체';

  @override
  String get today => '오늘';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '활동 $count개',
      zero: '활동 없음',
    );
    return '$date: $_temp0';
  }
}
