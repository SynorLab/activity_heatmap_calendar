// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'activity_heatmap_localizations_gen.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class ActivityHeatmapLocalizationsGenJa
    extends ActivityHeatmapLocalizationsGen {
  ActivityHeatmapLocalizationsGenJa([String locale = 'ja']) : super(locale);

  @override
  String get legendLess => '少ない';

  @override
  String get legendMore => '多い';

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のアクティビティ',
      zero: 'アクティビティなし',
    );
    return '$_temp0';
  }

  @override
  String get noActivitiesTitle => 'まだ記録がありません';

  @override
  String get noActivitiesBody => 'この日のアクティビティは記録されていません。';

  @override
  String get close => '閉じる';

  @override
  String cellSemantics(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件',
      zero: 'アクティビティなし',
    );
    return '$date、$_temp0';
  }

  @override
  String filterBanner(String type) {
    return '$type で絞り込み中';
  }

  @override
  String get clearFilter => '絞り込みを解除';

  @override
  String get typeAll => 'すべて';

  @override
  String get today => '今日';

  @override
  String tooltipActivities(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件',
      zero: 'アクティビティなし',
    );
    return '$date：$_temp0';
  }
}
