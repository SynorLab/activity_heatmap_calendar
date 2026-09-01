import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A user-supplied implementation, mirroring what package consumers write.
class _Workout implements Activity {
  _Workout(this.name, this.date, this.minutes);

  @override
  String name;

  @override
  DateTime date;

  int minutes;

  @override
  ActivityType type = const ActivityType('workout');

  @override
  Object? get detail => '$minutes min';

  @override
  set detail(Object? value) => minutes = value is int ? value : minutes;
}

void main() {
  group('ActivityType', () {
    test('equality and hashing are based on id alone', () {
      const ActivityType a = ActivityType('workout', label: 'Workout');
      const ActivityType b = ActivityType('workout', color: Colors.red);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ActivityType('reading')));
    });

    test('works as a map and set key', () {
      final Set<ActivityType> set = <ActivityType>{
        const ActivityType('a', label: 'First'),
        const ActivityType('a', label: 'Second'),
        const ActivityType('b'),
      };
      expect(set.length, 2);
    });

    test('all is the default sentinel', () {
      expect(ActivityType.all.id, 'all');
      expect(ActivityType.all.isAll, isTrue);
      expect(const ActivityType('workout').isAll, isFalse);
    });

    test('displayLabel falls back to the id', () {
      expect(const ActivityType('workout').displayLabel, 'workout');
      expect(
        const ActivityType('workout', label: 'Workout').displayLabel,
        'Workout',
      );
    });

    test('copyWith replaces individual fields', () {
      const ActivityType base = ActivityType('a', label: 'A');
      expect(base.copyWith(label: 'B').label, 'B');
      expect(base.copyWith(label: 'B').id, 'a');
      expect(base.copyWith(id: 'c').id, 'c');
      expect(base.copyWith(color: Colors.blue).color, Colors.blue);
      expect(base.copyWith(icon: Icons.abc).icon, Icons.abc);
    });
  });

  group('BaseActivity', () {
    test('defaults to ActivityType.all', () {
      final BaseActivity a = BaseActivity(
        name: 'Something',
        date: DateTime(2026, 3, 2),
      );
      expect(a.type, ActivityType.all);
      expect(a.detail, isNull);
    });

    test('all four properties are mutable', () {
      final BaseActivity a = BaseActivity(name: 'A', date: DateTime(2026, 3, 2))
        ..name = 'B'
        ..date = DateTime(2026, 3, 3)
        ..type = const ActivityType('workout')
        ..detail = <String, int>{'reps': 10};

      expect(a.name, 'B');
      expect(a.date, DateTime(2026, 3, 3));
      expect(a.type, const ActivityType('workout'));
      expect(a.detail, <String, int>{'reps': 10});
    });

    test('copyWith preserves untouched fields and can clear the detail', () {
      final BaseActivity a = BaseActivity(
        name: 'A',
        date: DateTime(2026, 3, 2),
        type: const ActivityType('workout'),
        detail: 'note',
      );
      expect(a.copyWith(name: 'B').detail, 'note');
      expect(a.copyWith(name: 'B').type, const ActivityType('workout'));
      expect(a.copyWith(clearDetail: true).detail, isNull);
    });
  });

  test('a custom implementation satisfies the Activity interface', () {
    final Activity a = _Workout('Run', DateTime(2026, 3, 2), 30);
    expect(a.name, 'Run');
    expect(a.detail, '30 min');
    expect(a.type, const ActivityType('workout'));

    a
      ..type = const ActivityType('cardio')
      ..detail = 45;
    expect(a.type, const ActivityType('cardio'));
    expect(a.detail, '45 min');
  });
}
