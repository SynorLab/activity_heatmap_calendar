import 'package:flutter/foundation.dart';

import 'heatmap_level_resolver.dart';

/// The per-day values and the intensity scale derived from them.
///
/// Computed once per data, filter or configuration change and shared by every
/// cell in a build pass, so painting a cell never touches the store.
@immutable
class HeatmapData {
  /// Bundles daily values with the scale prepared from them.
  const HeatmapData({required this.dailyValues, required this.scale});

  /// An empty data set with a single-level scale.
  static const HeatmapData empty = HeatmapData(
    dailyValues: <int, int>{},
    scale: HeatmapLevelScale.single,
  );

  /// Day key (`yyyyMMdd`) to heat value. Days with no activity are absent.
  final Map<int, int> dailyValues;

  /// The prepared level scale.
  final HeatmapLevelScale scale;

  /// The heat value on a day, or zero.
  int valueOf(int dayKey) => dailyValues[dayKey] ?? 0;

  /// The intensity level of a day.
  int levelOf(int dayKey) => scale.levelOf(valueOf(dayKey));

  /// The highest heat value in the data set.
  int get maxValue {
    int max = 0;
    for (final int value in dailyValues.values) {
      if (value > max) {
        max = value;
      }
    }
    return max;
  }

  /// The number of days carrying at least one activity.
  int get activeDayCount => dailyValues.length;
}
