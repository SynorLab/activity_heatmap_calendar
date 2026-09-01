import 'package:flutter/widgets.dart';

import 'heatmap_render_spec.dart';

/// The "Less ▢▢▢▢▢ More" scale shown under the grid.
class HeatmapLegend extends StatelessWidget {
  /// Creates the intensity legend.
  const HeatmapLegend({required this.spec, super.key});

  /// The resolved inputs of this build pass.
  final HeatmapRenderSpec spec;

  @override
  Widget build(BuildContext context) {
    final double size = (spec.cellSize * 0.5).clamp(10.0, 14.0);
    final BorderRadius radius = BorderRadius.circular(
      spec.config.cellStyle.radius * 0.5,
    );
    final TextStyle style = spec.labelStyle(context);

    return Semantics(
      label: '${spec.strings.legendLess} – ${spec.strings.legendMore}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: <Widget>[
          Text(spec.strings.legendLess, style: style),
          for (int level = 0; level <= spec.theme.levelCount; level++)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: spec.theme.colorForLevel(level),
                borderRadius: radius,
              ),
            ),
          Text(spec.strings.legendMore, style: style),
        ],
      ),
    );
  }
}
