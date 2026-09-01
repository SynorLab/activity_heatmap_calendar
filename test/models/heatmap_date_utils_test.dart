import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayKey', () {
    test('packs a local date as yyyyMMdd', () {
      expect(HeatmapDateUtils.dayKey(DateTime(2026, 3, 2)), 20260302);
      expect(HeatmapDateUtils.dayKey(DateTime(2026, 12, 31)), 20261231);
      expect(HeatmapDateUtils.dayKey(DateTime(1999)), 19990101);
    });

    test('ignores the time component', () {
      expect(
        HeatmapDateUtils.dayKey(DateTime(2026, 3, 2, 23, 59, 59, 999)),
        HeatmapDateUtils.dayKey(DateTime(2026, 3, 2)),
      );
    });

    test('converts UTC input to local time before taking the date', () {
      final DateTime utc = DateTime.utc(2026, 3, 2, 12);
      expect(
        HeatmapDateUtils.dayKey(utc),
        HeatmapDateUtils.dayKey(utc.toLocal()),
      );
    });

    test('round-trips through dateFromKey', () {
      for (final DateTime day in HeatmapDateUtils.eachDay(
        DateTime(2024),
        DateTime(2024, 12, 31),
      )) {
        expect(HeatmapDateUtils.dateFromKey(HeatmapDateUtils.dayKey(day)), day);
      }
    });

    test('is monotonically increasing with time', () {
      expect(
        HeatmapDateUtils.dayKey(DateTime(2026, 1, 31)) <
            HeatmapDateUtils.dayKey(DateTime(2026, 2)),
        isTrue,
      );
      expect(
        HeatmapDateUtils.dayKey(DateTime(2025, 12, 31)) <
            HeatmapDateUtils.dayKey(DateTime(2026)),
        isTrue,
      );
    });
  });

  group('normalize / isSameDay', () {
    test('normalize strips the time', () {
      expect(
        HeatmapDateUtils.normalize(DateTime(2026, 5, 4, 18, 30)),
        DateTime(2026, 5, 4),
      );
    });

    test('isSameDay compares calendar dates only', () {
      expect(
        HeatmapDateUtils.isSameDay(
          DateTime(2026, 5, 4),
          DateTime(2026, 5, 4, 23, 59),
        ),
        isTrue,
      );
      expect(
        HeatmapDateUtils.isSameDay(DateTime(2026, 5, 4), DateTime(2026, 5, 5)),
        isFalse,
      );
    });
  });

  group('addDays / daysBetween', () {
    test('addDays crosses month and year boundaries', () {
      expect(
        HeatmapDateUtils.addDays(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2),
      );
      expect(
        HeatmapDateUtils.addDays(DateTime(2026, 12, 31), 1),
        DateTime(2027),
      );
      expect(
        HeatmapDateUtils.addDays(DateTime(2026), -1),
        DateTime(2025, 12, 31),
      );
    });

    test('addDays handles leap years', () {
      expect(
        HeatmapDateUtils.addDays(DateTime(2024, 2, 28), 1),
        DateTime(2024, 2, 29),
      );
      expect(
        HeatmapDateUtils.addDays(DateTime(2025, 2, 28), 1),
        DateTime(2025, 3),
      );
    });

    test('addDays always lands on local midnight', () {
      // Spans the northern-hemisphere DST transition in most zones.
      for (int i = 0; i < 400; i++) {
        final DateTime d = HeatmapDateUtils.addDays(DateTime(2026), i);
        expect(d.hour, 0, reason: 'day $i drifted to ${d.hour}h');
        expect(d.minute, 0);
      }
    });

    test('daysBetween is a signed whole-day count', () {
      expect(
        HeatmapDateUtils.daysBetween(DateTime(2026), DateTime(2026, 1, 11)),
        10,
      );
      expect(
        HeatmapDateUtils.daysBetween(DateTime(2026, 1, 11), DateTime(2026)),
        -10,
      );
      expect(HeatmapDateUtils.daysBetween(DateTime(2026), DateTime(2026)), 0);
    });

    test('daysBetween ignores the time component', () {
      expect(
        HeatmapDateUtils.daysBetween(
          DateTime(2026, 1, 1, 23, 59),
          DateTime(2026, 1, 2, 0, 1),
        ),
        1,
      );
    });

    test('daysBetween survives DST transitions in the local zone', () {
      // Any zone: walking one day at a time must agree with daysBetween over
      // a full year, which necessarily contains both DST transitions.
      DateTime cursor = DateTime(2026);
      for (int i = 0; i <= 365; i++) {
        expect(
          HeatmapDateUtils.daysBetween(DateTime(2026), cursor),
          i,
          reason: 'mismatch at $cursor',
        );
        cursor = HeatmapDateUtils.addDays(cursor, 1);
      }
    });

    test('daysBetween is consistent across a leap year', () {
      expect(HeatmapDateUtils.daysBetween(DateTime(2024), DateTime(2025)), 366);
      expect(HeatmapDateUtils.daysBetween(DateTime(2025), DateTime(2026)), 365);
    });
  });

  group('startOfWeek', () {
    test('covers all 49 combinations of weekday and weekStartsOn', () {
      // 2026-03-02 is a Monday; the following seven days cover every weekday.
      for (int offset = 0; offset < 7; offset++) {
        final DateTime day = DateTime(2026, 3, 2 + offset);
        for (int start = DateTime.monday; start <= DateTime.sunday; start++) {
          final DateTime weekStart = HeatmapDateUtils.startOfWeek(day, start);
          expect(
            weekStart.weekday,
            start,
            reason: 'startOfWeek($day, $start) landed on a wrong weekday',
          );
          final int delta = HeatmapDateUtils.daysBetween(weekStart, day);
          expect(
            delta,
            inInclusiveRange(0, 6),
            reason: 'startOfWeek($day, $start) is not within the same week',
          );
        }
      }
    });

    test('is idempotent', () {
      for (int start = DateTime.monday; start <= DateTime.sunday; start++) {
        final DateTime once = HeatmapDateUtils.startOfWeek(
          DateTime(2026, 7, 15),
          start,
        );
        expect(HeatmapDateUtils.startOfWeek(once, start), once);
      }
    });
  });

  group('weekdayIndex', () {
    test('is 0 on the first day of the week', () {
      for (int start = DateTime.monday; start <= DateTime.sunday; start++) {
        final DateTime weekStart = HeatmapDateUtils.startOfWeek(
          DateTime(2026, 7, 15),
          start,
        );
        expect(HeatmapDateUtils.weekdayIndex(weekStart, start), 0);
      }
    });

    test('increases by one per day and wraps after 7', () {
      const int start = DateTime.sunday;
      DateTime cursor = HeatmapDateUtils.startOfWeek(
        DateTime(2026, 7, 15),
        start,
      );
      for (int i = 0; i < 14; i++) {
        expect(HeatmapDateUtils.weekdayIndex(cursor, start), i % 7);
        cursor = HeatmapDateUtils.addDays(cursor, 1);
      }
    });
  });

  group('weeksBetween', () {
    test('counts whole weeks between the containing weeks', () {
      expect(
        HeatmapDateUtils.weeksBetween(
          DateTime(2026, 3, 2), // Monday
          DateTime(2026, 3, 8), // Sunday of the same ISO week
          DateTime.monday,
        ),
        0,
      );
      expect(
        HeatmapDateUtils.weeksBetween(
          DateTime(2026, 3, 2),
          DateTime(2026, 3, 9),
          DateTime.monday,
        ),
        1,
      );
    });

    test('depends on weekStartsOn', () {
      // Sunday 2026-03-08 and Monday 2026-03-09 are in the same week when the
      // week starts on Sunday, but in different weeks when it starts on Monday.
      expect(
        HeatmapDateUtils.weeksBetween(
          DateTime(2026, 3, 8),
          DateTime(2026, 3, 9),
          DateTime.sunday,
        ),
        0,
      );
      expect(
        HeatmapDateUtils.weeksBetween(
          DateTime(2026, 3, 8),
          DateTime(2026, 3, 9),
          DateTime.monday,
        ),
        1,
      );
    });

    test('is negative when going backwards', () {
      expect(
        HeatmapDateUtils.weeksBetween(
          DateTime(2026, 3, 30),
          DateTime(2026, 3, 2),
          DateTime.monday,
        ),
        -4,
      );
    });
  });

  group('month helpers', () {
    test('startOfMonth and endOfMonth', () {
      expect(
        HeatmapDateUtils.startOfMonth(DateTime(2026, 2, 17)),
        DateTime(2026, 2),
      );
      expect(
        HeatmapDateUtils.endOfMonth(DateTime(2026, 2, 17)),
        DateTime(2026, 2, 28),
      );
      expect(
        HeatmapDateUtils.endOfMonth(DateTime(2024, 2, 17)),
        DateTime(2024, 2, 29),
      );
      expect(
        HeatmapDateUtils.endOfMonth(DateTime(2026, 12, 5)),
        DateTime(2026, 12, 31),
      );
    });

    test('monthsBetween counts calendar months', () {
      expect(
        HeatmapDateUtils.monthsBetween(DateTime(2025, 11), DateTime(2026, 2)),
        3,
      );
      expect(
        HeatmapDateUtils.monthsBetween(DateTime(2026, 2), DateTime(2025, 11)),
        -3,
      );
    });

    test('addMonths clamps the day of month', () {
      expect(
        HeatmapDateUtils.addMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
      expect(
        HeatmapDateUtils.addMonths(DateTime(2024, 1, 31), 1),
        DateTime(2024, 2, 29),
      );
      expect(
        HeatmapDateUtils.addMonths(DateTime(2026, 3, 15), -3),
        DateTime(2025, 12, 15),
      );
    });
  });

  group('eachDay', () {
    test('is inclusive on both ends', () {
      final List<DateTime> days = HeatmapDateUtils.eachDay(
        DateTime(2026),
        DateTime(2026, 1, 3),
      ).toList();
      expect(days, <DateTime>[
        DateTime(2026),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      ]);
    });

    test('yields a single day when start == end', () {
      expect(
        HeatmapDateUtils.eachDay(DateTime(2026), DateTime(2026)).length,
        1,
      );
    });

    test('yields nothing when end is before start', () {
      expect(
        HeatmapDateUtils.eachDay(DateTime(2026, 1, 5), DateTime(2026)),
        isEmpty,
      );
    });

    test('yields 366 days for a leap year', () {
      expect(
        HeatmapDateUtils.eachDay(DateTime(2024), DateTime(2024, 12, 31)).length,
        366,
      );
    });
  });
}
