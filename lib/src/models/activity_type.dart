import 'package:flutter/widgets.dart';

/// A user-definable category for an [Activity].
///
/// An [ActivityType] is a lightweight value object identified solely by its
/// [id]. Two types with the same [id] are considered equal even if their
/// [label], [color] or [icon] differ, which means you can construct throwaway
/// instances for lookups:
///
/// ```dart
/// calendar.filter(const ActivityType('workout'));
/// ```
///
/// ## The `all` type has two meanings
///
/// [ActivityType.all] is used in two places and it is important to understand
/// both:
///
/// 1. It is the **default type** of any activity that does not declare one.
/// 2. It is the **"no filter"** sentinel accepted by
///    `ActivityHeatmapCalendar.filter`, where it behaves exactly like passing
///    `null`.
///
/// A consequence of (1) and (2) combined: filtering by a *specific* type such
/// as `ActivityType('workout')` will **exclude** activities whose type is
/// [ActivityType.all], because those activities are not workouts — they are
/// uncategorised. If you want an activity to appear under a category, give it
/// that category explicitly.
@immutable
class ActivityType {
  /// Creates an activity type identified by [id].
  ///
  /// [label] is an optional static display name. When omitted, the UI falls
  /// back to a localized name (for [all]) or to [id] itself.
  ///
  /// [color] optionally overrides the heatmap's accent colour while this type
  /// is the active filter, and is used for the type dot in the default bottom
  /// sheet.
  const ActivityType(this.id, {this.label, this.color, this.icon});

  /// The default type, used by activities that do not declare one and as the
  /// "clear the filter" sentinel.
  ///
  /// See the class documentation for the full semantics.
  static const ActivityType all = ActivityType('all');

  /// Stable identifier. Equality and hashing are based on this alone.
  final String id;

  /// Optional human readable name shown in the UI.
  final String? label;

  /// Optional accent colour for this type.
  final Color? color;

  /// Optional icon shown next to activities of this type.
  final IconData? icon;

  /// Whether this type is the default [all] type.
  bool get isAll => id == all.id;

  /// The name to display when no localization is available.
  ///
  /// Prefer `ActivityHeatmapLocalizations.typeLabel` in widgets, which can
  /// localize the [all] type.
  String get displayLabel => label ?? id;

  /// Returns a copy of this type with the given fields replaced.
  ActivityType copyWith({
    String? id,
    String? label,
    Color? color,
    IconData? icon,
  }) {
    return ActivityType(
      id ?? this.id,
      label: label ?? this.label,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ActivityType && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ActivityType($id)';
}
