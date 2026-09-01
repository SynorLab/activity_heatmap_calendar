import 'package:flutter/material.dart';

import '../config/heatmap_cell_style.dart';
import '../models/heatmap_cell_data.dart';
import 'heatmap_render_spec.dart';

/// A single day square.
///
/// Renders as a rounded rectangle filled with the colour of its intensity
/// level, with an optional ring marking today and a hover highlight on
/// desktop and web. When [HeatmapCellStyle.builder] returns a widget, that
/// replaces the default appearance while the tap target and semantics stay in
/// place.
class HeatmapCell extends StatefulWidget {
  /// Creates a day cell.
  const HeatmapCell({
    required this.spec,
    required this.date,
    this.sectionMonth,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// The resolved inputs of this build pass.
  final HeatmapRenderSpec spec;

  /// The day this cell represents.
  final DateTime date;

  /// The month block this cell is painted in, if any.
  ///
  /// Split-month view passes the block's month so neighbouring-month days
  /// that pad a partial week stay aligned but blank.
  final DateTime? sectionMonth;

  /// Called when the cell is tapped. A null callback makes the cell inert.
  final void Function(DateTime date)? onTap;

  /// Called on a long press.
  final void Function(DateTime date)? onLongPress;

  @override
  State<HeatmapCell> createState() => _HeatmapCellState();
}

class _HeatmapCellState extends State<HeatmapCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final HeatmapRenderSpec spec = widget.spec;
    final HeatmapCellStyle style = spec.config.cellStyle;
    final HeatmapCellData data = spec.cellDataFor(
      widget.date,
      sectionMonth: widget.sectionMonth,
    );

    // Days outside the range only exist to pad a partial week; they take up
    // space so the grid stays aligned but must not be interactive or visible.
    if (data.isPlaceholder) {
      return SizedBox.square(dimension: style.size);
    }

    final Widget visual =
        style.builder?.call(context, data) ??
        _defaultVisual(context, spec, style, data);

    final bool interactive =
        widget.onTap != null && (data.hasActivity || spec.config.tapEmptyCells);

    Widget cell = MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: interactive ? () => widget.onTap!(widget.date) : null,
        onLongPress: widget.onLongPress == null
            ? null
            : () => widget.onLongPress!(widget.date),
        child: visual,
      ),
    );

    if (spec.config.showTooltips) {
      cell = Tooltip(
        message: spec.strings.tooltipActivities(
          data.count,
          spec.formatter.mediumDate(widget.date),
        ),
        // Hover still opens the tooltip; manual mode keeps long press free for
        // the widget's own callback.
        triggerMode: TooltipTriggerMode.manual,
        excludeFromSemantics: true,
        child: cell,
      );
    }

    return Semantics(
      button: interactive,
      label:
          spec.config.labels.cellSemanticsBuilder?.call(context, data) ??
          spec.strings.cellSemantics(
            spec.formatter.fullDate(widget.date),
            data.count,
          ),
      child: cell,
    );
  }

  void _setHovered(bool value) {
    if (_hovered != value && mounted) {
      setState(() => _hovered = value);
    }
  }

  Widget _defaultVisual(
    BuildContext context,
    HeatmapRenderSpec spec,
    HeatmapCellStyle style,
    HeatmapCellData data,
  ) {
    final BorderRadius radius = BorderRadius.circular(style.radius);
    final Color borderColor =
        spec.theme.borderColor ??
        _implicitBorderColor(Theme.of(context).brightness);

    return Container(
      width: style.size,
      height: style.size,
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: radius,
        border: style.borderWidth > 0
            ? Border.all(color: borderColor, width: style.borderWidth)
            : null,
      ),
      foregroundDecoration: _overlayDecoration(
        context,
        spec,
        style,
        data,
        radius,
      ),
    );
  }

  /// The ring marking the open sheet, today, the hover highlight, or nothing.
  BoxDecoration? _overlayDecoration(
    BuildContext context,
    HeatmapRenderSpec spec,
    HeatmapCellStyle style,
    HeatmapCellData data,
    BorderRadius radius,
  ) {
    if (data.isSelected && style.selectedRingWidth > 0) {
      return BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color:
              spec.theme.selectedRingColor ??
              Theme.of(context).colorScheme.primary,
          width: style.selectedRingWidth,
        ),
      );
    }
    if (data.isToday && style.showTodayRing) {
      return BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: spec.theme.resolvedTodayRingColor,
          width: style.todayRingWidth,
        ),
      );
    }
    if (_hovered) {
      return BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: spec.theme.levelColors.last.withValues(alpha: 0.55),
          width: 1.5,
        ),
      );
    }
    return null;
  }

  /// A hairline that keeps the palest levels legible on a white surface,
  /// mirroring the inset border GitHub draws on its own cells.
  Color _implicitBorderColor(Brightness brightness) =>
      brightness == Brightness.light
      ? const Color(0x0F1B1F23)
      : const Color(0x14FFFFFF);
}
