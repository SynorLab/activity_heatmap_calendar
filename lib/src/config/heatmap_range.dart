import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/widgets.dart';

import '../models/heatmap_date_utils.dart';

enum _RangeKind { explicit, trailingDays, trailingMonths, year, auto }

/// Declares which span of days the heatmap covers.
///
/// A range is a *description*, not a fixed pair of dates: `trailingMonths(12)`
/// keeps meaning "the last twelve months" as the clock advances, and `auto`
/// follows whatever data is in the store. Call [resolve] to turn it into
/// concrete bounds.
@immutable
class HeatmapRange {
  const HeatmapRange._(
    this._kind, {
    this.start,
    this.end,
    this.amount = 0,
    this.paddingDays = 0,
  });

  /// A fixed span from [start] to [end], both inclusive.
  ///
  /// Bounds are swapped when given in the wrong order.
  HeatmapRange.explicit(DateTime start, DateTime end)
    : _kind = _RangeKind.explicit,
      start = start.isAfter(end)
          ? HeatmapDateUtils.normalize(end)
          : HeatmapDateUtils.normalize(start),
      end = start.isAfter(end)
          ? HeatmapDateUtils.normalize(start)
          : HeatmapDateUtils.normalize(end),
      amount = 0,
      paddingDays = 0;

  /// The last [days] days, ending today.
  const HeatmapRange.trailingDays(int days)
    : this._(_RangeKind.trailingDays, amount: days);

  /// The last [months] months, ending today.
  ///
  /// This is the default and mirrors GitHub's one-year graph.
  const HeatmapRange.trailingMonths(int months)
    : this._(_RangeKind.trailingMonths, amount: months);

  /// The whole calendar year [year], from 1 January to 31 December.
  const HeatmapRange.year(int year) : this._(_RangeKind.year, amount: year);

  /// Spans exactly the data in the store, widened by [paddingDays] on each
  /// side.
  ///
  /// Falls back to the last twelve months while the store is empty.
  const HeatmapRange.auto({int paddingDays = 7})
    : this._(_RangeKind.auto, paddingDays: paddingDays);

  final _RangeKind _kind;

  /// Lower bound of an [HeatmapRange.explicit] range, otherwise null.
  final DateTime? start;

  /// Upper bound of an [HeatmapRange.explicit] range, otherwise null.
  final DateTime? end;

  /// Days, months or the year number, depending on the kind of range.
  final int amount;

  /// Extra days added on each side of an [HeatmapRange.auto] range.
  final int paddingDays;

  /// Whether these bounds follow the contents of the store.
  bool get isAuto => _kind == _RangeKind.auto;

  /// Turns this description into concrete, inclusive bounds at local midnight.
  ///
  /// [today] is injectable so tests and `goto` do not depend on the wall
  /// clock. [dataBounds] is only consulted by [HeatmapRange.auto].
  DateTimeRange resolve({required DateTime today, DateTimeRange? dataBounds}) {
    final DateTime now = HeatmapDateUtils.normalize(today);
    switch (_kind) {
      case _RangeKind.explicit:
        return DateTimeRange(start: start!, end: end!);

      case _RangeKind.trailingDays:
        final int days = amount < 1 ? 1 : amount;
        return DateTimeRange(
          start: HeatmapDateUtils.addDays(now, -(days - 1)),
          end: now,
        );

      case _RangeKind.trailingMonths:
        final int months = amount < 1 ? 1 : amount;
        return DateTimeRange(
          start: HeatmapDateUtils.addDays(
            HeatmapDateUtils.addMonths(now, -months),
            1,
          ),
          end: now,
        );

      case _RangeKind.year:
        return DateTimeRange(
          start: DateTime(amount),
          end: DateTime(amount, 12, 31),
        );

      case _RangeKind.auto:
        if (dataBounds == null) {
          return const HeatmapRange.trailingMonths(12).resolve(today: now);
        }
        return DateTimeRange(
          start: HeatmapDateUtils.addDays(dataBounds.start, -paddingDays),
          end: HeatmapDateUtils.addDays(dataBounds.end, paddingDays),
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapRange &&
          other._kind == _kind &&
          other.start == start &&
          other.end == end &&
          other.amount == amount &&
          other.paddingDays == paddingDays;

  @override
  int get hashCode => Object.hash(_kind, start, end, amount, paddingDays);

  @override
  String toString() => switch (_kind) {
    _RangeKind.explicit => 'HeatmapRange.explicit($start, $end)',
    _RangeKind.trailingDays => 'HeatmapRange.trailingDays($amount)',
    _RangeKind.trailingMonths => 'HeatmapRange.trailingMonths($amount)',
    _RangeKind.year => 'HeatmapRange.year($amount)',
    _RangeKind.auto => 'HeatmapRange.auto(paddingDays: $paddingDays)',
  };
}
