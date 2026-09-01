import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('colorForLevel', () {
    const HeatmapColorTheme theme = HeatmapColorTheme.github;

    test('level 0 and below is the empty colour', () {
      expect(theme.colorForLevel(0), theme.emptyColor);
      expect(theme.colorForLevel(-3), theme.emptyColor);
    });

    test('levels map to the ramp in order', () {
      expect(theme.colorForLevel(1), theme.levelColors.first);
      expect(theme.colorForLevel(3), theme.levelColors[2]);
    });

    test('levels beyond the ramp clamp instead of throwing', () {
      expect(theme.colorForLevel(99), theme.levelColors.last);
    });

    test('the today ring defaults to the strongest colour', () {
      expect(theme.resolvedTodayRingColor, theme.levelColors.last);
      expect(
        theme
            .copyWith(todayRingColor: const Color(0xFF123456))
            .resolvedTodayRingColor,
        const Color(0xFF123456),
      );
    });
  });

  group('fromSeed', () {
    test('produces a ramp of the requested length', () {
      expect(
        HeatmapColorTheme.fromSeed(
          const Color(0xFF1B6FC4),
          levels: 6,
        ).levelCount,
        6,
      );
    });

    test('darkens monotonically in light mode', () {
      final HeatmapColorTheme theme = HeatmapColorTheme.fromSeed(
        const Color(0xFF1B6FC4),
      );
      final List<double> lightness = theme.levelColors
          .map((Color c) => HSLColor.fromColor(c).lightness)
          .toList();
      for (int i = 1; i < lightness.length; i++) {
        expect(lightness[i], lessThan(lightness[i - 1]));
      }
    });

    test('brightens monotonically in dark mode', () {
      final HeatmapColorTheme theme = HeatmapColorTheme.fromSeed(
        const Color(0xFF1B6FC4),
        brightness: Brightness.dark,
        withDarkVariant: false,
      );
      final List<double> lightness = theme.levelColors
          .map((Color c) => HSLColor.fromColor(c).lightness)
          .toList();
      for (int i = 1; i < lightness.length; i++) {
        expect(lightness[i], greaterThan(lightness[i - 1]));
      }
    });

    test('keeps the seed hue', () {
      const Color seed = Color(0xFF1B6FC4);
      final HeatmapColorTheme theme = HeatmapColorTheme.fromSeed(seed);
      final double hue = HSLColor.fromColor(seed).hue;
      for (final Color color in theme.levelColors) {
        expect(HSLColor.fromColor(color).hue, closeTo(hue, 1.5));
      }
    });

    test('carries a dark variant by default', () {
      final HeatmapColorTheme theme = HeatmapColorTheme.fromSeed(
        const Color(0xFF1B6FC4),
      );
      expect(theme.dark, isNotNull);
      expect(theme.dark!.dark, isNull);
    });

    test('a single level still works', () {
      final HeatmapColorTheme theme = HeatmapColorTheme.fromSeed(
        const Color(0xFF1B6FC4),
        levels: 1,
      );
      expect(theme.levelCount, 1);
      expect(theme.colorForLevel(1), theme.levelColors.single);
    });
  });

  group('resolveBrightness', () {
    test('light returns the theme itself', () {
      expect(
        HeatmapColorTheme.github.resolveBrightness(Brightness.light),
        HeatmapColorTheme.github,
      );
    });

    test('dark returns the declared variant', () {
      expect(
        HeatmapColorTheme.github.resolveBrightness(Brightness.dark),
        HeatmapColorTheme.githubDark,
      );
    });

    test('a theme without a variant derives one', () {
      const HeatmapColorTheme flat = HeatmapColorTheme(
        emptyColor: Color(0xFFEEEEEE),
        levelColors: <Color>[Color(0xFF88CCFF), Color(0xFF1B6FC4)],
      );
      final HeatmapColorTheme dark = flat.resolveBrightness(Brightness.dark);
      expect(dark, isNot(flat));
      expect(dark.levelCount, flat.levelCount);
      expect(dark.emptyColor, isNot(flat.emptyColor));
    });
  });

  testWidgets('resolve uses the ambient brightness', (
    WidgetTester tester,
  ) async {
    late HeatmapColorTheme resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (BuildContext context) {
            resolved = HeatmapColorTheme.github.resolve(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, HeatmapColorTheme.githubDark);
  });

  group('value semantics', () {
    test('copyWith replaces only what it is given', () {
      final HeatmapColorTheme theme = HeatmapColorTheme.github.copyWith(
        borderColor: const Color(0xFF000000),
      );
      expect(theme.borderColor, const Color(0xFF000000));
      expect(theme.levelColors, HeatmapColorTheme.github.levelColors);
      expect(theme.dark, HeatmapColorTheme.githubDark);
    });

    test('copyWith can drop the dark variant', () {
      expect(HeatmapColorTheme.github.copyWith(clearDark: true).dark, isNull);
    });

    test('equal themes are equal', () {
      expect(HeatmapColorTheme.github.copyWith(), HeatmapColorTheme.github);
      expect(
        HeatmapColorTheme.github.copyWith().hashCode,
        HeatmapColorTheme.github.hashCode,
      );
      expect(
        HeatmapColorTheme.github.copyWith(emptyColor: const Color(0xFF00FF00)),
        isNot(HeatmapColorTheme.github),
      );
    });

    test('the built-in map is complete', () {
      expect(
        HeatmapColorTheme.builtIn.keys,
        containsAll(<String>[
          'GitHub',
          'Ocean',
          'Sunset',
          'Violet',
          'Forest',
          'Rose',
          'Mono',
        ]),
      );
      for (final HeatmapColorTheme theme in HeatmapColorTheme.builtIn.values) {
        expect(theme.levelCount, greaterThanOrEqualTo(3));
      }
    });
  });
}
