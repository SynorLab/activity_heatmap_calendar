import 'activity_type.dart';

/// A single dated activity contributing to the heatmap.
///
/// This is an interface: implement it on your own model so the calendar can
/// read your data without you having to duplicate it.
///
/// ```dart
/// class Workout implements Activity {
///   Workout(this.name, this.date, this.minutes);
///
///   @override
///   String name;
///   @override
///   DateTime date;
///   final int minutes;
///
///   @override
///   ActivityType type = const ActivityType('workout');
///   @override
///   Object? get detail => '$minutes min';
///   @override
///   set detail(Object? value) {}
/// }
/// ```
///
/// If you do not need a custom model, use [BaseActivity].
///
/// ## Mutability and the store index
///
/// All four properties are read/write, but the calendar indexes activities by
/// their [date] (and groups them by [type]) at insertion time. If you mutate
/// [date] or [type] of an activity that is already inserted, you **must** call
/// `ActivityHeatmapCalendar().reindex()` afterwards, otherwise queries will
/// return stale results.
abstract class Activity {
  /// Implementations supply their own constructor; this one exists only so
  /// subclasses can be `const`.
  const Activity();

  /// The category this activity belongs to.
  ///
  /// Defaults to [ActivityType.all] for uncategorised activities.
  ActivityType get type;
  set type(ActivityType value);

  /// Short human readable name, shown as the title in the default bottom
  /// sheet.
  String get name;
  set name(String value);

  /// The day this activity happened.
  ///
  /// Only the local calendar date is used for indexing; the time component is
  /// ignored (but preserved on your object). UTC values are converted to local
  /// time before the date is taken.
  DateTime get date;
  set date(DateTime value);

  /// Optional payload of any type: a description string, a map, or your own
  /// object. Rendered with `toString()` by the default bottom sheet unless you
  /// supply a custom detail builder.
  Object? get detail;
  set detail(Object? value);
}

/// A ready-made mutable [Activity] implementation.
///
/// Use it when you do not need to attach the heatmap to an existing model:
///
/// ```dart
/// ActivityHeatmapCalendar().insert(
///   BaseActivity(name: 'Morning run', date: DateTime.now()),
/// );
/// ```
class BaseActivity implements Activity {
  /// Creates an activity.
  ///
  /// [type] defaults to [ActivityType.all].
  BaseActivity({
    required this.name,
    required this.date,
    this.type = ActivityType.all,
    this.detail,
  });

  @override
  ActivityType type;

  @override
  String name;

  @override
  DateTime date;

  @override
  Object? detail;

  /// Returns a copy of this activity with the given fields replaced.
  BaseActivity copyWith({
    String? name,
    DateTime? date,
    ActivityType? type,
    Object? detail,
    bool clearDetail = false,
  }) {
    return BaseActivity(
      name: name ?? this.name,
      date: date ?? this.date,
      type: type ?? this.type,
      detail: clearDetail ? null : (detail ?? this.detail),
    );
  }

  @override
  String toString() =>
      'BaseActivity(name: $name, date: $date, type: ${type.id}, '
      'detail: $detail)';
}
