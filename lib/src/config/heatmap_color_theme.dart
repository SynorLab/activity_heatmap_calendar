import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

/// The colour ramp used to paint intensity levels.
///
/// A theme holds one colour per non-empty level plus the colour of an empty
/// day. It can also carry a [dark] counterpart which [resolve] selects
/// automatically from the ambient [Brightness], so a single value works in
/// both themes:
///
/// ```dart
/// ActivityHeatmapConfig(colorTheme: HeatmapColorTheme.github)
/// ```
@immutable
class HeatmapColorTheme {
  /// Creates a colour theme from an explicit ramp.
  ///
  /// [levelColors] holds the colours of levels `1..n` in increasing intensity
  /// order and must not be empty. Level `0` uses [emptyColor].
  const HeatmapColorTheme({
    required this.emptyColor,
    required this.levelColors,
    this.borderColor,
    this.todayRingColor,
    this.selectedRingColor,
    this.dark,
  });

  /// Builds a ramp from a single seed colour.
  ///
  /// The ramp keeps the seed's hue and walks its lightness, which produces an
  /// evenly spaced, monotonically intensifying scale. For [Brightness.light]
  /// the ramp goes from pale to deep; for [Brightness.dark] it goes from a
  /// dim shade that reads as "barely anything" to a vivid one, matching how
  /// GitHub inverts its own scale in dark mode.
  ///
  /// The returned theme carries a matching [dark] variant unless
  /// [withDarkVariant] is false.
  factory HeatmapColorTheme.fromSeed(
    Color seed, {
    int levels = 4,
    Brightness brightness = Brightness.light,
    bool withDarkVariant = true,
  }) {
    assert(levels > 0, 'levels must be positive');
    final HSLColor base = HSLColor.fromColor(seed);
    final bool isLight = brightness == Brightness.light;

    // Endpoints of the lightness walk, chosen so the faintest level is still
    // distinguishable from the empty colour and the strongest keeps enough
    // contrast against text drawn on top of the surface.
    final double startL = isLight ? 0.82 : 0.20;
    final double endL = isLight ? 0.30 : 0.68;
    final double startS = (base.saturation * (isLight ? 0.62 : 0.70))
        .clamp(0.0, 1.0)
        .toDouble();
    final double endS = (base.saturation * (isLight ? 1.0 : 0.95))
        .clamp(0.0, 1.0)
        .toDouble();

    final List<Color> ramp = List<Color>.generate(levels, (int i) {
      final double t = levels == 1 ? 1.0 : i / (levels - 1);
      return base
          .withLightness(_lerp(startL, endL, t))
          .withSaturation(_lerp(startS, endS, t))
          .toColor();
    });

    final HeatmapColorTheme theme = HeatmapColorTheme(
      emptyColor: isLight ? const Color(0xFFEBEDF0) : const Color(0xFF161B22),
      levelColors: ramp,
      dark: withDarkVariant && isLight
          ? HeatmapColorTheme.fromSeed(
              seed,
              levels: levels,
              brightness: Brightness.dark,
              withDarkVariant: false,
            )
          : null,
    );
    return theme;
  }

  /// Fill colour of a day with no activity.
  final Color emptyColor;

  /// Colours of levels `1..n`, in increasing intensity order.
  final List<Color> levelColors;

  /// Hairline colour drawn around every cell.
  ///
  /// When null, the cell derives a subtle border from its own fill, which is
  /// what the built-in themes rely on.
  final Color? borderColor;

  /// Colour of the ring marking today. Defaults to the strongest level colour
  /// when null.
  final Color? todayRingColor;

  /// Colour of the ring marking the day whose detail sheet is open.
  ///
  /// When null, the cell uses the ambient `ColorScheme.primary`.
  final Color? selectedRingColor;

  /// Variant used when the ambient brightness is dark. When null, this theme
  /// is used in both brightnesses.
  final HeatmapColorTheme? dark;

  /// The number of non-empty levels.
  int get levelCount => levelColors.length;

  /// The fill colour for [level].
  ///
  /// Levels at or below zero map to [emptyColor]; levels above [levelCount]
  /// are clamped to the strongest colour rather than throwing.
  Color colorForLevel(int level) {
    if (level <= 0) {
      return emptyColor;
    }
    if (level >= levelCount) {
      return levelColors.last;
    }
    return levelColors[level - 1];
  }

  /// The ring colour to use for today.
  Color get resolvedTodayRingColor => todayRingColor ?? levelColors.last;

  /// Picks between this theme and [dark] using the ambient [Brightness].
  HeatmapColorTheme resolve(BuildContext context) =>
      resolveBrightness(Theme.of(context).brightness);

  /// Picks between this theme and [dark] for an explicit [brightness].
  ///
  /// When no [dark] variant was supplied but the brightness is dark, the ramp
  /// is re-derived from the strongest level colour so a single-ramp theme
  /// still looks deliberate on a dark surface instead of glowing.
  HeatmapColorTheme resolveBrightness(Brightness brightness) {
    if (brightness == Brightness.light) {
      return this;
    }
    if (dark != null) {
      return dark!;
    }
    return HeatmapColorTheme.fromSeed(
      levelColors.last,
      levels: levelCount,
      brightness: Brightness.dark,
      withDarkVariant: false,
    );
  }

  /// Returns a copy of this theme with the given fields replaced.
  HeatmapColorTheme copyWith({
    Color? emptyColor,
    List<Color>? levelColors,
    Color? borderColor,
    Color? todayRingColor,
    Color? selectedRingColor,
    HeatmapColorTheme? dark,
    bool clearDark = false,
  }) {
    return HeatmapColorTheme(
      emptyColor: emptyColor ?? this.emptyColor,
      levelColors: levelColors ?? this.levelColors,
      borderColor: borderColor ?? this.borderColor,
      todayRingColor: todayRingColor ?? this.todayRingColor,
      selectedRingColor: selectedRingColor ?? this.selectedRingColor,
      dark: clearDark ? null : (dark ?? this.dark),
    );
  }

  static double _lerp(double a, double b, double t) =>
      (a + (b - a) * t).clamp(0.0, 1.0).toDouble();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapColorTheme &&
          other.emptyColor == emptyColor &&
          listEquals(other.levelColors, levelColors) &&
          other.borderColor == borderColor &&
          other.todayRingColor == todayRingColor &&
          other.selectedRingColor == selectedRingColor &&
          other.dark == dark;

  @override
  int get hashCode => Object.hash(
    emptyColor,
    Object.hashAll(levelColors),
    borderColor,
    todayRingColor,
    selectedRingColor,
    dark,
  );

  // ------------------------------------------------------------- built-ins

  /// The exact GitHub contribution graph palette, light and dark.
  static const HeatmapColorTheme github = HeatmapColorTheme(
    emptyColor: Color(0xFFEBEDF0),
    levelColors: <Color>[
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ],
    dark: githubDark,
  );

  /// The dark half of the GitHub palette. Usually reached through
  /// [github]'s [resolve] rather than used directly.
  static const HeatmapColorTheme githubDark = HeatmapColorTheme(
    emptyColor: Color(0xFF161B22),
    levelColors: <Color>[
      Color(0xFF0E4429),
      Color(0xFF006D32),
      Color(0xFF26A641),
      Color(0xFF39D353),
    ],
  );

  /// A cool blue ramp.
  static final HeatmapColorTheme ocean = HeatmapColorTheme.fromSeed(
    const Color(0xFF1B6FC4),
  );

  /// A warm orange-to-red ramp.
  static final HeatmapColorTheme sunset = HeatmapColorTheme.fromSeed(
    const Color(0xFFE2562B),
  );

  /// A purple ramp.
  static final HeatmapColorTheme violet = HeatmapColorTheme.fromSeed(
    const Color(0xFF7C3AED),
  );

  /// A deep green ramp, softer than [github].
  static final HeatmapColorTheme forest = HeatmapColorTheme.fromSeed(
    const Color(0xFF2F855A),
  );

  /// A pink ramp.
  static final HeatmapColorTheme rose = HeatmapColorTheme.fromSeed(
    const Color(0xFFDB2777),
  );

  /// A neutral greyscale ramp, useful for print or for letting per-type
  /// colours stand out.
  static const HeatmapColorTheme mono = HeatmapColorTheme(
    emptyColor: Color(0xFFEDEEF0),
    levelColors: <Color>[
      Color(0xFFC8CCD2),
      Color(0xFF98A0AA),
      Color(0xFF636C77),
      Color(0xFF2F3742),
    ],
    dark: HeatmapColorTheme(
      emptyColor: Color(0xFF17191C),
      levelColors: <Color>[
        Color(0xFF31363D),
        Color(0xFF4E5661),
        Color(0xFF7C8794),
        Color(0xFFB8C1CC),
      ],
    ),
  );

  /// Every built-in theme by name, handy for building a theme picker.
  static Map<String, HeatmapColorTheme> get builtIn =>
      <String, HeatmapColorTheme>{
        'GitHub': github,
        'Ocean': ocean,
        'Sunset': sunset,
        'Violet': violet,
        'Forest': forest,
        'Rose': rose,
        'Mono': mono,
      };
}
