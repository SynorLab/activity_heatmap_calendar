// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'activity_heatmap_localizations_gen.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ActivityHeatmapLocalizationsGenZh
    extends ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGenZh([String locale = 'zh']) : super(locale);

  @override
  String get legendLess => '少';

  @override
  String get legendMore => '多';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动',
      zero: '没有活动',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => '这天还没有记录';

  @override
  String get noActivitiesBody => '这一天没有任何活动记录。';

  @override
  String get close => '关闭';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动',
      zero: '没有活动',
    );
    return '$date，$_temp0';
  }

  @override
  String filterBanner(String type) {
    return '已筛选：$type';
  }

  @override
  String get clearFilter => '清除筛选';

  @override
  String get typeAll => '全部';

  @override
  String get today => '今天';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动',
      zero: '没有活动',
    );
    return '$date：$_temp0';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class ActivityHeatmapLocalizationsGenZhHans
    extends ActivityHeatmapLocalizationsGenZh {
  ActivityHeatmapLocalizationsGenZhHans() : super('zh_Hans');

  @override
  String get legendLess => '少';

  @override
  String get legendMore => '多';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动',
      zero: '没有活动',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => '这天还没有记录';

  @override
  String get noActivitiesBody => '这一天没有任何活动记录。';

  @override
  String get close => '关闭';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动',
      zero: '没有活动',
    );
    return '$date，$_temp0';
  }

  @override
  String filterBanner(String type) {
    return '已筛选：$type';
  }

  @override
  String get clearFilter => '清除筛选';

  @override
  String get typeAll => '全部';

  @override
  String get today => '今天';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动',
      zero: '没有活动',
    );
    return '$date：$_temp0';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class ActivityHeatmapLocalizationsGenZhHant
    extends ActivityHeatmapLocalizationsGenZh {
  ActivityHeatmapLocalizationsGenZhHant() : super('zh_Hant');

  @override
  String get legendLess => '少';

  @override
  String get legendMore => '多';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個活動',
      zero: '沒有活動',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => '這天還沒有紀錄';

  @override
  String get noActivitiesBody => '這一天沒有任何活動紀錄。';

  @override
  String get close => '關閉';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個活動',
      zero: '沒有活動',
    );
    return '$date，$_temp0';
  }

  @override
  String filterBanner(String type) {
    return '已篩選：$type';
  }

  @override
  String get clearFilter => '清除篩選';

  @override
  String get typeAll => '全部';

  @override
  String get today => '今天';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個活動',
      zero: '沒有活動',
    );
    return '$date：$_temp0';
  }
}
