import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapLevelScale', () {
    const HeatmapLevelScale scale = HeatmapLevelScale(<int>[1, 3, 6, 9]);

    test('zero and negatives are level 0', () {
      expect(scale.levelOf(0), 0);
      expect(scale.levelOf(-5), 0);
    });

    test('any positive value reaches at least level 1', () {
      expect(const HeatmapLevelScale(<int>[10, 20]).levelOf(1), 1);
    });

    test('buckets values by their thresholds', () {
      expect(scale.levelOf(1), 1);
      expect(scale.levelOf(2), 1);
      expect(scale.levelOf(3), 2);
      expect(scale.levelOf(8), 3);
      expect(scale.levelOf(9), 4);
      expect(scale.levelOf(900), 4);
    });

    test('exposes a representative value per level', () {
      expect(scale.sampleValueFor(0), 0);
      expect(scale.sampleValueFor(1), 1);
      expect(scale.sampleValueFor(4), 9);
      expect(scale.sampleValueFor(99), 9);
    });

    test('has value equality', () {
      expect(scale, const HeatmapLevelScale(<int>[1, 3, 6, 9]));
      expect(
        scale.hashCode,
        const HeatmapLevelScale(<int>[1, 3, 6, 9]).hashCode,
      );
      expect(scale, isNot(const HeatmapLevelScale(<int>[1, 2])));
      expect(scale.toString(), contains('[1, 3, 6, 9]'));
    });

    test('single accepts any positive value', () {
      expect(HeatmapLevelScale.single.levelCount, 1);
      expect(HeatmapLevelScale.single.levelOf(42), 1);
    });
  });

  group('ThresholdLevelResolver', () {
    test('uses its thresholds verbatim when the counts match', () {
      expect(
        const ThresholdLevelResolver.github().prepare(<int>[], 4).thresholds,
        <int>[1, 3, 6, 9],
      );
    });

    test('truncates when the theme has fewer levels', () {
      expect(
        const ThresholdLevelResolver.github().prepare(<int>[], 2).thresholds,
        <int>[1, 3],
      );
    });

    test('extends by the last step when the theme has more levels', () {
      final HeatmapLevelScale scale = const ThresholdLevelResolver.github()
          .prepare(<int>[], 6);
      expect(scale.thresholds, <int>[1, 3, 6, 9, 12, 15]);
    });

    test('extends a single threshold by one', () {
      expect(
        const ThresholdLevelResolver(<int>[5]).prepare(<int>[], 3).thresholds,
        <int>[5, 6, 7],
      );
    });

    test('ignores the data entirely', () {
      const ThresholdLevelResolver resolver = ThresholdLevelResolver.github();
      expect(
        resolver.prepare(<int>[1000, 2000], 4),
        resolver.prepare(<int>[1], 4),
      );
    });

    test('has value equality', () {
      expect(
        const ThresholdLevelResolver(<int>[1, 3, 6, 9]),
        const ThresholdLevelResolver.github(),
      );
      expect(
        const ThresholdLevelResolver(<int>[1, 3, 6, 9]).hashCode,
        const ThresholdLevelResolver.github().hashCode,
      );
      expect(
        const ThresholdLevelResolver(<int>[1, 2]),
        isNot(const ThresholdLevelResolver.github()),
      );
    });
  });

  group('QuantileLevelResolver', () {
    test('spreads cut points evenly by default', () {
      final HeatmapLevelScale scale = const QuantileLevelResolver().prepare(
        <int>[1, 2, 3, 4, 5, 6, 7, 8],
        4,
      );
      expect(scale.thresholds.first, 1);
      expect(scale.thresholds.length, 4);
      expect(_isStrictlyIncreasing(scale.thresholds), isTrue);
    });

    test('tail emphasises the busiest days', () {
      final List<int> values = List<int>.generate(100, (int i) => i + 1);
      final HeatmapLevelScale even = const QuantileLevelResolver().prepare(
        values,
        4,
      );
      final HeatmapLevelScale tail = const QuantileLevelResolver.tail().prepare(
        values,
        4,
      );
      expect(tail.thresholds.last, greaterThan(even.thresholds.last));
    });

    test('stays strictly increasing on a degenerate distribution', () {
      final HeatmapLevelScale scale = const QuantileLevelResolver().prepare(
        <int>[2, 2, 2, 2],
        4,
      );
      expect(scale.thresholds, <int>[1, 2, 3, 4]);
    });

    test('falls back to 1..n with no data', () {
      expect(
        const QuantileLevelResolver().prepare(<int>[], 4).thresholds,
        <int>[1, 2, 3, 4],
      );
    });

    test('ignores empty days', () {
      final HeatmapLevelScale scale = const QuantileLevelResolver().prepare(
        <int>[0, 0, 0, 10],
        2,
      );
      expect(scale.thresholds.first, 1);
      expect(scale.levelOf(10), 2);
    });

    test('collapses to a single level when asked', () {
      expect(
        const QuantileLevelResolver().prepare(<int>[1, 2], 1),
        HeatmapLevelScale.single,
      );
    });

    test('has value equality', () {
      expect(
        const QuantileLevelResolver(quantiles: <double>[0.5]),
        const QuantileLevelResolver(quantiles: <double>[0.5]),
      );
      expect(
        const QuantileLevelResolver().hashCode,
        const QuantileLevelResolver().hashCode,
      );
      expect(
        const QuantileLevelResolver(),
        isNot(const QuantileLevelResolver.tail()),
      );
    });
  });

  group('RelativeLevelResolver', () {
    test('spreads levels between one and the busiest day', () {
      expect(
        const RelativeLevelResolver().prepare(<int>[1, 20], 4).thresholds,
        <int>[1, 5, 10, 15],
      );
    });

    test('falls back to 1..n when nothing exceeds one', () {
      expect(
        const RelativeLevelResolver().prepare(<int>[1, 1], 3).thresholds,
        <int>[1, 2, 3],
      );
      expect(
        const RelativeLevelResolver().prepare(<int>[], 3).thresholds,
        <int>[1, 2, 3],
      );
    });

    test('stays strictly increasing for a small maximum', () {
      final HeatmapLevelScale scale = const RelativeLevelResolver().prepare(
        <int>[2],
        4,
      );
      expect(_isStrictlyIncreasing(scale.thresholds), isTrue);
    });

    test('collapses to a single level when asked', () {
      expect(
        const RelativeLevelResolver().prepare(<int>[5], 1),
        HeatmapLevelScale.single,
      );
    });

    test('has value equality', () {
      expect(const RelativeLevelResolver(), const RelativeLevelResolver());
      expect(
        const RelativeLevelResolver().hashCode,
        const RelativeLevelResolver().hashCode,
      );
      expect(
        const RelativeLevelResolver(),
        isNot(const QuantileLevelResolver()),
      );
    });
  });
}

bool _isStrictlyIncreasing(List<int> values) {
  for (int i = 1; i < values.length; i++) {
    if (values[i] <= values[i - 1]) {
      return false;
    }
  }
  return true;
}
