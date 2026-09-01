import 'package:flutter/widgets.dart';

import 'heatmap_grid_model.dart';

/// The hook a view exposes so the controller can drive its scroll position.
///
/// `ActivityHeatmapCalendarView` implements this and registers itself with
/// `ActivityHeatmapCalendar.attach` while it is mounted. Application code does
/// not normally implement it, but doing so lets a custom view participate in
/// `goto`.
abstract class HeatmapViewAttachment {
  /// Allows implementations to declare a `const` constructor.
  const HeatmapViewAttachment();

  /// The geometry the view is currently rendering, or null before the first
  /// layout pass.
  HeatmapGridModel? get gridModel;

  /// Width available for the scrollable grid, or null before the first layout
  /// pass.
  double? get viewportWidth;

  /// Brings [date] to [alignment] within the viewport.
  ///
  /// Returns once the animation has finished, or immediately when [animate] is
  /// false or the view is not laid out yet.
  Future<void> scrollToDate(
    DateTime date, {
    double alignment,
    bool animate,
    Duration duration,
    Curve curve,
  });
}
