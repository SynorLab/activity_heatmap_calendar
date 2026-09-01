import 'package:flutter/widgets.dart';

import '../models/heatmap_cell_data.dart';

/// Signature for a fully custom day cell.
///
/// Return `null` to fall back to the package's default rendering for that
/// particular cell, which makes it easy to special-case only some days.
typedef HeatmapCellBuilder =
    Widget? Function(BuildContext context, HeatmapCellData data);

/// Geometry and decoration of a single day cell.
///
/// The defaults reproduce a slightly larger, rounder version of the GitHub
/// contribution graph: a 24 logical pixel square with a 6 pixel corner radius.
@immutable
class HeatmapCellStyle {
  /// Creates a cell style.
  const HeatmapCellStyle({
    this.size = 24,
    this.radius = 6,
    this.spacing = 4,
    this.borderWidth = 1,
    this.showTodayRing = true,
    this.todayRingWidth = 2,
    this.selectedRingWidth = 2,
    this.builder,
  }) : assert(size > 0, 'size must be positive'),
       assert(radius >= 0, 'radius cannot be negative'),
       assert(spacing >= 0, 'spacing cannot be negative'),
       assert(borderWidth >= 0, 'borderWidth cannot be negative'),
       assert(selectedRingWidth >= 0, 'selectedRingWidth cannot be negative');

  /// Side length of the square cell in logical pixels.
  final double size;

  /// Corner radius of the cell.
  final double radius;

  /// Gap between adjacent cells, horizontally and vertically.
  final double spacing;

  /// Width of the hairline drawn around every cell. Set to `0` to remove it.
  ///
  /// The colour comes from `HeatmapColorTheme.borderColor`; when that is null
  /// a subtle tint of the fill colour is used, which keeps light cells legible
  /// against a white background exactly like GitHub does.
  final double borderWidth;

  /// Whether today's cell is outlined with an accent ring.
  final bool showTodayRing;

  /// Width of the ring drawn around today's cell.
  final double todayRingWidth;

  /// Width of the ring drawn around the day whose detail sheet is open.
  ///
  /// Set to `0` to keep the sheet from changing the cell's border.
  final double selectedRingWidth;

  /// Optional builder that replaces the default cell rendering.
  final HeatmapCellBuilder? builder;

  /// Horizontal and vertical distance from one cell origin to the next.
  double get extent => size + spacing;

  /// Returns a copy of this style with the given fields replaced.
  HeatmapCellStyle copyWith({
    double? size,
    double? radius,
    double? spacing,
    double? borderWidth,
    bool? showTodayRing,
    double? todayRingWidth,
    double? selectedRingWidth,
    HeatmapCellBuilder? builder,
    bool clearBuilder = false,
  }) {
    return HeatmapCellStyle(
      size: size ?? this.size,
      radius: radius ?? this.radius,
      spacing: spacing ?? this.spacing,
      borderWidth: borderWidth ?? this.borderWidth,
      showTodayRing: showTodayRing ?? this.showTodayRing,
      todayRingWidth: todayRingWidth ?? this.todayRingWidth,
      selectedRingWidth: selectedRingWidth ?? this.selectedRingWidth,
      builder: clearBuilder ? null : (builder ?? this.builder),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapCellStyle &&
          other.size == size &&
          other.radius == radius &&
          other.spacing == spacing &&
          other.borderWidth == borderWidth &&
          other.showTodayRing == showTodayRing &&
          other.todayRingWidth == todayRingWidth &&
          other.selectedRingWidth == selectedRingWidth &&
          other.builder == builder;

  @override
  int get hashCode => Object.hash(
    size,
    radius,
    spacing,
    borderWidth,
    showTodayRing,
    todayRingWidth,
    selectedRingWidth,
    builder,
  );
}
