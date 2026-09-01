import 'dart:math';

import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';

/// The demo's activity categories.
///
/// A type is just an id plus presentation: give it a colour and the heatmap
/// re-tints itself while that type is the active filter.
const ActivityType workout = ActivityType(
  'workout',
  label: 'Workout',
  color: Color(0xFFE2562B),
  icon: Icons.fitness_center_rounded,
);
const ActivityType reading = ActivityType(
  'reading',
  label: 'Reading',
  color: Color(0xFF7A5AF8),
  icon: Icons.menu_book_rounded,
);
const ActivityType coding = ActivityType(
  'coding',
  label: 'Coding',
  color: Color(0xFF1F883D),
  icon: Icons.code_rounded,
);
const ActivityType cooking = ActivityType(
  'cooking',
  label: 'Cooking',
  color: Color(0xFFDB8B00),
  icon: Icons.restaurant_rounded,
);
const ActivityType meditation = ActivityType(
  'meditation',
  label: 'Meditation',
  color: Color(0xFF0EA5E9),
  icon: Icons.self_improvement_rounded,
);

/// Every type the demo can filter by, in display order.
const List<ActivityType> demoTypes = <ActivityType>[
  workout,
  reading,
  coding,
  cooking,
  meditation,
];

/// A payload carried by an activity, shown as the sheet subtitle.
///
/// `Activity.detail` is an `Object?`, so anything goes: a model, a map, a
/// string. This one also feeds the weighted-heat demo through its [minutes].
@immutable
class Session {
  const Session({required this.minutes, this.note});

  final int minutes;
  final String? note;

  @override
  String toString() => note == null ? '$minutes min' : '$minutes min · $note';
}

/// The demo's own [Activity] implementation.
///
/// `Activity` is abstract precisely so your existing model can implement it
/// instead of being copied into a package type.
class DemoActivity implements Activity {
  DemoActivity({
    required this.name,
    required this.date,
    required this.type,
    required this.session,
  });

  @override
  String name;

  @override
  DateTime date;

  @override
  ActivityType type;

  @override
  Object? get detail => session;

  @override
  set detail(Object? value) => session = value! as Session;

  Session session;
}

const Map<String, List<String>> _namesByType = <String, List<String>>{
  'workout': <String>[
    'Morning run',
    'Push day',
    'Swim',
    'Cycling',
    'Yoga flow',
  ],
  'reading': <String>[
    'The Pragmatic Programmer',
    'Dune',
    'A paper on B-trees',
    'Poetry, out loud',
  ],
  'coding': <String>[
    'Refactored the store',
    'Fixed a timezone bug',
    'Reviewed a pull request',
    'Shipped the heatmap',
  ],
  'cooking': <String>[
    'Ramen from scratch',
    'Sunday roast',
    'Sourdough, attempt 4',
  ],
  'meditation': <String>['Ten quiet minutes', 'Body scan', 'Breathing'],
};

/// Two years of plausible activity, weighted so weekends are busier and the
/// recent months denser than the old ones.
///
/// Seeded, so the graph looks the same on every run and screenshots stay
/// comparable.
List<Activity> buildDemoActivities({DateTime? today, int seed = 20260615}) {
  final DateTime end = HeatmapDateUtils.normalize(today ?? DateTime.now());
  final DateTime start = HeatmapDateUtils.addDays(end, -730);
  final Random random = Random(seed);
  final List<Activity> activities = <Activity>[];

  for (
    DateTime day = start;
    !day.isAfter(end);
    day = HeatmapDateUtils.addDays(day, 1)
  ) {
    final double recency =
        HeatmapDateUtils.daysBetween(start, day) / 730; // 0 → 1
    final bool weekend = day.weekday >= DateTime.saturday;
    final double chance = 0.25 + recency * 0.45 + (weekend ? 0.15 : 0);

    if (random.nextDouble() > chance) {
      continue; // A rest day.
    }

    final int count = 1 + random.nextInt(weekend ? 4 : 3);
    for (int i = 0; i < count; i++) {
      final ActivityType type = demoTypes[random.nextInt(demoTypes.length)];
      final List<String> names = _namesByType[type.id]!;
      activities.add(
        DemoActivity(
          name: names[random.nextInt(names.length)],
          // A time of day, so ActivitySort.byTime has something to sort.
          date: DateTime(
            day.year,
            day.month,
            day.day,
            6 + random.nextInt(15),
            random.nextInt(60),
          ),
          type: type,
          session: Session(
            minutes: 15 + random.nextInt(8) * 15,
            note: random.nextBool() ? null : 'felt good',
          ),
        ),
      );
    }
  }
  return activities;
}
