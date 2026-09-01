import 'package:flutter/widgets.dart';

import 'activity_type.dart';

/// Everything a cell builder needs to know about one day of the heatmap.
///
/// Passed to `HeatmapCellStyle.builder` and to the label and semantics
/// builders in `HeatmapLabelsConfig`.
@immutable
class HeatmapCellData {
  /// Creates the render data for a single day cell.
  const HeatmapCellData({
    required this.date,
    required this.count,
    required this.level,
    required this.levelCount,
    required this.color,
    required this.isToday,
    required this.isOutOfRange,
    required this.isPlaceholder,
    this.isSelected = false,
    this.activeFilter,
  });

  /// Local midnight of the day this cell represents.
  ///
  /// For a placeholder cell — a leading or trailing slot used to pad a
  /// partial week, or a neighbouring-month day in split-month view — this is
  /// still a real date. The cell takes up space so weekdays stay aligned.
  final DateTime date;

  /// Number of activities on [date] after the active filter is applied.
  final int count;

  /// Intensity bucket, from `0` (empty) to [levelCount].
  final int level;

  /// The number of non-empty intensity buckets in the active colour theme.
  final int levelCount;

  /// The resolved fill colour for [level].
  final Color color;

  /// Whether [date] is today.
  final bool isToday;

  /// Whether [date] falls outside the configured range.
  final bool isOutOfRange;

  /// Whether this cell only exists to pad a partial week and should normally
  /// be rendered as blank space.
  final bool isPlaceholder;

  /// Whether this day is the one whose detail sheet is currently open.
  final bool isSelected;

  /// The type filter in effect, or `null` when nothing is filtered.
  final ActivityType? activeFilter;

  /// Whether the day has at least one activity.
  bool get hasActivity => count > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapCellData &&
          other.date == date &&
          other.count == count &&
          other.level == level &&
          other.levelCount == levelCount &&
          other.color == color &&
          other.isToday == isToday &&
          other.isOutOfRange == isOutOfRange &&
          other.isPlaceholder == isPlaceholder &&
          other.isSelected == isSelected &&
          other.activeFilter == activeFilter;

  @override
  int get hashCode => Object.hash(
    date,
    count,
    level,
    levelCount,
    color,
    isToday,
    isOutOfRange,
    isPlaceholder,
    isSelected,
    activeFilter,
  );

  @override
  String toString() {
    final String day =
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return 'HeatmapCellData($day, count: $count, level: $level/$levelCount'
        '${isToday ? ', today' : ''}'
        '${isPlaceholder ? ', placeholder' : ''}'
        '${isSelected ? ', selected' : ''}'
        '${activeFilter == null ? '' : ', filter: ${activeFilter!.id}'})';
  }
}
