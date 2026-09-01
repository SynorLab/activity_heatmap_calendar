/// Date helpers shared by the whole package.
///
/// Every function here treats a "day" as a **local calendar date**: UTC inputs
/// are converted with [DateTime.toLocal] first, and the time component is
/// discarded. Day arithmetic is performed in UTC space so that daylight saving
/// transitions never add or drop a day.
abstract final class HeatmapDateUtils {
  /// Packs the local calendar date of [date] into a sortable integer of the
  /// form `yyyyMMdd`.
  ///
  /// This is the key type used by the activity index. Integers are used rather
  /// than [DateTime] because `DateTime` equality includes the time component
  /// and the time zone, which makes it a hazardous map key.
  static int dayKey(DateTime date) {
    final DateTime d = date.isUtc ? date.toLocal() : date;
    return d.year * 10000 + d.month * 100 + d.day;
  }

  /// Inverse of [dayKey]: returns local midnight of the encoded day.
  static DateTime dateFromKey(int key) {
    final int year = key ~/ 10000;
    final int month = (key ~/ 100) % 100;
    final int day = key % 100;
    return DateTime(year, month, day);
  }

  /// Local midnight of the day containing [date].
  static DateTime normalize(DateTime date) {
    final DateTime d = date.isUtc ? date.toLocal() : date;
    return DateTime(d.year, d.month, d.day);
  }

  /// Whether [a] and [b] fall on the same local calendar date.
  static bool isSameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

  /// Whether [date] is today in local time.
  static bool isToday(DateTime date, {DateTime? now}) =>
      isSameDay(date, now ?? DateTime.now());

  /// The first day of the week containing [date].
  ///
  /// [weekStartsOn] uses the [DateTime.monday]…[DateTime.sunday] constants
  /// (1…7). The result is local midnight.
  static DateTime startOfWeek(DateTime date, int weekStartsOn) {
    assert(
      weekStartsOn >= DateTime.monday && weekStartsOn <= DateTime.sunday,
      'weekStartsOn must be a DateTime weekday constant (1..7)',
    );
    final DateTime d = normalize(date);
    final int delta = (d.weekday - weekStartsOn + 7) % 7;
    return addDays(d, -delta);
  }

  /// The row index (0…6) of [date] in a grid whose weeks start on
  /// [weekStartsOn].
  static int weekdayIndex(DateTime date, int weekStartsOn) {
    final DateTime d = date.isUtc ? date.toLocal() : date;
    return (d.weekday - weekStartsOn + 7) % 7;
  }

  /// Local midnight of the first day of the month containing [date].
  static DateTime startOfMonth(DateTime date) {
    final DateTime d = date.isUtc ? date.toLocal() : date;
    return DateTime(d.year, d.month);
  }

  /// Local midnight of the last day of the month containing [date].
  static DateTime endOfMonth(DateTime date) {
    final DateTime d = date.isUtc ? date.toLocal() : date;
    return DateTime(d.year, d.month + 1, 0);
  }

  /// Whether [a] and [b] fall in the same calendar month of the same year.
  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Returns [date] shifted by [days] calendar days.
  ///
  /// Uses `DateTime(y, m, d + days)` rather than adding a [Duration] so that
  /// the result stays at local midnight across daylight saving transitions.
  static DateTime addDays(DateTime date, int days) {
    final DateTime d = date.isUtc ? date.toLocal() : date;
    return DateTime(d.year, d.month, d.day + days);
  }

  /// The number of whole calendar days from [from] to [to].
  ///
  /// Positive when [to] is later. The computation happens in UTC space, so a
  /// daylight saving transition between the two dates cannot shift the result.
  static int daysBetween(DateTime from, DateTime to) {
    final DateTime a = normalize(from);
    final DateTime b = normalize(to);
    final int ms = DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inMilliseconds;
    return ms ~/ Duration.millisecondsPerDay;
  }

  /// The number of whole weeks between the week containing [from] and the week
  /// containing [to], given a week starting on [weekStartsOn].
  static int weeksBetween(DateTime from, DateTime to, int weekStartsOn) {
    final DateTime a = startOfWeek(from, weekStartsOn);
    final DateTime b = startOfWeek(to, weekStartsOn);
    return daysBetween(a, b) ~/ 7;
  }

  /// The number of whole months from [from] to [to], ignoring the day of
  /// month.
  static int monthsBetween(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + (to.month - from.month);

  /// Returns [date] shifted by [months] calendar months, clamping the day of
  /// month to the length of the target month.
  static DateTime addMonths(DateTime date, int months) {
    final DateTime d = date.isUtc ? date.toLocal() : date;
    final int targetMonthLength = DateTime(d.year, d.month + months + 1, 0).day;
    return DateTime(
      d.year,
      d.month + months,
      d.day < targetMonthLength ? d.day : targetMonthLength,
    );
  }

  /// Lazily yields local midnight for every day from [start] to [end]
  /// inclusive. Yields nothing when [end] is before [start].
  static Iterable<DateTime> eachDay(DateTime start, DateTime end) sync* {
    DateTime cursor = normalize(start);
    final DateTime last = normalize(end);
    while (!cursor.isAfter(last)) {
      yield cursor;
      cursor = addDays(cursor, 1);
    }
  }
}
