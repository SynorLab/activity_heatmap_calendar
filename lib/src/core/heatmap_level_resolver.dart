import 'package:flutter/foundation.dart';

/// A prepared mapping from a daily value to an intensity level.
///
/// Produced by [HeatmapLevelResolver.prepare] once per data change, then
/// queried once per painted cell.
@immutable
class HeatmapLevelScale {
  /// Creates a scale from explicit lower bounds.
  ///
  /// [thresholds] holds the minimum value required to reach levels `1..n`, in
  /// strictly increasing order.
  const HeatmapLevelScale(this.thresholds);

  /// A single-level scale: any non-zero value is level 1.
  static const HeatmapLevelScale single = HeatmapLevelScale(<int>[1]);

  /// Minimum value for levels `1..n`.
  final List<int> thresholds;

  /// The number of non-empty levels.
  int get levelCount => thresholds.length;

  /// The intensity level of [value].
  ///
  /// Zero and negative values are level `0`. Any positive value is at least
  /// level `1`, even when it is below the first threshold, so a day with an
  /// activity is never painted as empty.
  int levelOf(int value) {
    if (value <= 0) {
      return 0;
    }
    int level = 1;
    for (int i = 0; i < thresholds.length; i++) {
      if (value >= thresholds[i]) {
        level = i + 1;
      } else {
        break;
      }
    }
    return level;
  }

  /// A representative value for [level], used to render the legend swatches.
  int sampleValueFor(int level) {
    if (level <= 0) {
      return 0;
    }
    return thresholds[(level - 1).clamp(0, thresholds.length - 1)];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapLevelScale && listEquals(other.thresholds, thresholds);

  @override
  int get hashCode => Object.hashAll(thresholds);

  @override
  String toString() => 'HeatmapLevelScale($thresholds)';
}

/// Turns the distribution of daily values into a [HeatmapLevelScale].
///
/// Implement this to control how counts map to colours. The resolver is
/// re-run whenever the data or the active filter changes, so a resolver that
/// adapts to the data — such as [QuantileLevelResolver] — stays meaningful
/// after filtering.
@immutable
abstract class HeatmapLevelResolver {
  /// Const constructor for subclasses.
  const HeatmapLevelResolver();

  /// Builds a scale with [levelCount] non-empty levels.
  ///
  /// [dailyValues] contains one entry per day that has at least one activity;
  /// empty days are not included. It may be empty.
  HeatmapLevelScale prepare(Iterable<int> dailyValues, int levelCount);
}

/// Maps values to levels using fixed thresholds, ignoring the data.
///
/// Predictable and stable: the same count always gets the same colour, which
/// is what GitHub does.
class ThresholdLevelResolver extends HeatmapLevelResolver {
  /// Creates a resolver from explicit thresholds, which must be strictly
  /// increasing and positive.
  const ThresholdLevelResolver(this.thresholds);

  /// The default: 1, 3, 6 and 9 activities per day.
  const ThresholdLevelResolver.github() : thresholds = const <int>[1, 3, 6, 9];

  /// Minimum value for levels `1..n`.
  final List<int> thresholds;

  @override
  HeatmapLevelScale prepare(Iterable<int> dailyValues, int levelCount) {
    assert(
      _isStrictlyIncreasing(thresholds),
      'thresholds must be strictly increasing, got $thresholds',
    );
    if (thresholds.length == levelCount) {
      return HeatmapLevelScale(thresholds);
    }
    if (thresholds.length > levelCount) {
      return HeatmapLevelScale(thresholds.sublist(0, levelCount));
    }
    // Extend by repeating the last step so a longer colour ramp still gets a
    // usable scale instead of throwing.
    final List<int> extended = List<int>.of(thresholds);
    final int step = thresholds.length >= 2
        ? thresholds.last - thresholds[thresholds.length - 2]
        : 1;
    while (extended.length < levelCount) {
      extended.add(extended.last + (step < 1 ? 1 : step));
    }
    return HeatmapLevelScale(extended);
  }

  static bool _isStrictlyIncreasing(List<int> values) {
    for (int i = 1; i < values.length; i++) {
      if (values[i] <= values[i - 1]) {
        return false;
      }
    }
    return values.isEmpty || values.first >= 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThresholdLevelResolver &&
          listEquals(other.thresholds, thresholds);

  @override
  int get hashCode => Object.hashAll(thresholds);
}

/// Maps values to levels using quantiles of the actual data.
///
/// Good when daily counts vary by orders of magnitude, or when a fixed scale
/// would leave the whole graph in one colour. Because the scale is recomputed
/// after filtering, the colours always use the full ramp.
class QuantileLevelResolver extends HeatmapLevelResolver {
  /// Creates a quantile resolver.
  ///
  /// [quantiles] holds the cut points for levels `2..n` in the range `0..1`;
  /// level 1 always starts at 1. When null, the cut points are spaced evenly.
  const QuantileLevelResolver({this.quantiles});

  /// Emphasises the tail: half the active days land in level 1, and only the
  /// top decile reaches the strongest colour.
  const QuantileLevelResolver.tail()
    : quantiles = const <double>[0.5, 0.75, 0.9];

  /// Cut points for levels `2..n`, or null for evenly spaced ones.
  final List<double>? quantiles;

  @override
  HeatmapLevelScale prepare(Iterable<int> dailyValues, int levelCount) {
    if (levelCount <= 1) {
      return HeatmapLevelScale.single;
    }
    final List<int> sorted = dailyValues.where((int v) => v > 0).toList()
      ..sort();
    if (sorted.isEmpty) {
      return HeatmapLevelScale(
        List<int>.generate(levelCount, (int i) => i + 1),
      );
    }

    final List<double> cuts =
        quantiles ??
        List<double>.generate(levelCount - 1, (int i) => (i + 1) / levelCount);

    final List<int> thresholds = <int>[1];
    for (int i = 0; i < levelCount - 1; i++) {
      final double q = i < cuts.length ? cuts[i] : (i + 1) / levelCount;
      final int candidate = _quantile(sorted, q);
      // Keep the scale strictly increasing even when the distribution is
      // degenerate (for example every day has exactly two activities).
      thresholds.add(
        candidate > thresholds.last ? candidate : thresholds.last + 1,
      );
    }
    return HeatmapLevelScale(thresholds);
  }

  static int _quantile(List<int> sorted, double q) {
    final double position = (sorted.length - 1) * q.clamp(0.0, 1.0);
    return sorted[position.round()];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantileLevelResolver && listEquals(other.quantiles, quantiles);

  @override
  int get hashCode => quantiles == null ? 0 : Object.hashAll(quantiles!);
}

/// Spreads the levels evenly between 1 and the busiest day in the data.
///
/// The simplest adaptive scale: with a maximum of 20 activities and four
/// levels the cut points are 1, 6, 11 and 16.
class RelativeLevelResolver extends HeatmapLevelResolver {
  /// Creates a resolver relative to the maximum daily value.
  const RelativeLevelResolver();

  @override
  HeatmapLevelScale prepare(Iterable<int> dailyValues, int levelCount) {
    if (levelCount <= 1) {
      return HeatmapLevelScale.single;
    }
    int max = 0;
    for (final int value in dailyValues) {
      if (value > max) {
        max = value;
      }
    }
    if (max <= 1) {
      return HeatmapLevelScale(
        List<int>.generate(levelCount, (int i) => i + 1),
      );
    }

    final List<int> thresholds = <int>[1];
    for (int i = 1; i < levelCount; i++) {
      final int candidate = 1 + (max - 1) * i ~/ levelCount;
      thresholds.add(
        candidate > thresholds.last ? candidate : thresholds.last + 1,
      );
    }
    return HeatmapLevelScale(thresholds);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RelativeLevelResolver;

  @override
  int get hashCode => (RelativeLevelResolver).hashCode;
}
