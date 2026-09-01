import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapCellStyle', () {
    test('extent includes the spacing', () {
      expect(const HeatmapCellStyle(size: 20, spacing: 6).extent, 26);
    });

    test('copyWith replaces only what it is given', () {
      const HeatmapCellStyle style = HeatmapCellStyle();
      final HeatmapCellStyle wider = style.copyWith(size: 30);
      expect(wider.size, 30);
      expect(wider.radius, style.radius);
      expect(wider.spacing, style.spacing);
    });

    test('copyWith can drop a builder', () {
      final HeatmapCellStyle withBuilder = const HeatmapCellStyle().copyWith(
        builder: (BuildContext context, HeatmapCellData data) => null,
      );
      expect(withBuilder.builder, isNotNull);
      expect(withBuilder.copyWith(clearBuilder: true).builder, isNull);
    });

    test('has value equality', () {
      expect(const HeatmapCellStyle(), const HeatmapCellStyle());
      expect(
        const HeatmapCellStyle().hashCode,
        const HeatmapCellStyle().hashCode,
      );
      expect(const HeatmapCellStyle(size: 12), isNot(const HeatmapCellStyle()));
    });

    test('rejects impossible geometry', () {
      expect(() => HeatmapCellStyle(size: 0), throwsAssertionError);
      expect(() => HeatmapCellStyle(radius: -1), throwsAssertionError);
      expect(() => HeatmapCellStyle(spacing: -1), throwsAssertionError);
      expect(() => HeatmapCellStyle(borderWidth: -1), throwsAssertionError);
      expect(
        () => HeatmapCellStyle(selectedRingWidth: -1),
        throwsAssertionError,
      );
    });
  });

  group('HeatmapLabelsConfig', () {
    test('copyWith replaces only what it is given', () {
      const HeatmapLabelsConfig labels = HeatmapLabelsConfig();
      final HeatmapLabelsConfig updated = labels.copyWith(
        weekdayLabelMode: HeatmapWeekdayLabelMode.all,
        gutterSpacing: 20,
      );
      expect(updated.weekdayLabelMode, HeatmapWeekdayLabelMode.all);
      expect(updated.gutterSpacing, 20);
      expect(updated.monthLabelHeight, labels.monthLabelHeight);
      expect(updated.splitMonthPadding, labels.splitMonthPadding);
    });

    test('has value equality', () {
      expect(const HeatmapLabelsConfig(), const HeatmapLabelsConfig());
      expect(
        const HeatmapLabelsConfig().hashCode,
        const HeatmapLabelsConfig().hashCode,
      );
      expect(
        const HeatmapLabelsConfig(monthLabelHeight: 30),
        isNot(const HeatmapLabelsConfig()),
      );
    });

    test('carries the builders it is given', () {
      final HeatmapLabelsConfig labels = const HeatmapLabelsConfig().copyWith(
        monthLabelBuilder: (BuildContext context, DateTime date) => 'M',
        weekdayLabelBuilder: (BuildContext context, DateTime date) => 'W',
        cellSemanticsBuilder: (BuildContext context, HeatmapCellData d) => 'S',
        textStyle: const TextStyle(fontSize: 9),
        splitMonthDecoration: const BoxDecoration(),
        splitMonthSectionGap: 24,
      );
      expect(labels.monthLabelBuilder, isNotNull);
      expect(labels.weekdayLabelBuilder, isNotNull);
      expect(labels.cellSemanticsBuilder, isNotNull);
      expect(labels.textStyle!.fontSize, 9);
      expect(labels.splitMonthDecoration, isNotNull);
      expect(labels.splitMonthSectionGap, 24);
    });
  });

  group('HeatmapRange', () {
    final DateTime today = DateTime(2026, 6, 15);

    test('explicit keeps its bounds', () {
      final DateTimeRange range = HeatmapRange.explicit(
        DateTime(2026),
        DateTime(2026, 3, 31),
      ).resolve(today: today);
      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2026, 3, 31));
    });

    test('explicit swaps inverted bounds', () {
      final DateTimeRange range = HeatmapRange.explicit(
        DateTime(2026, 3, 31),
        DateTime(2026),
      ).resolve(today: today);
      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2026, 3, 31));
    });

    test('trailingDays ends today and is inclusive', () {
      final DateTimeRange range = const HeatmapRange.trailingDays(
        7,
      ).resolve(today: today);
      expect(range.end, DateTime(2026, 6, 15));
      expect(range.start, DateTime(2026, 6, 9));
    });

    test('trailingMonths mirrors GitHub', () {
      final DateTimeRange range = const HeatmapRange.trailingMonths(
        12,
      ).resolve(today: today);
      expect(range.end, DateTime(2026, 6, 15));
      expect(range.start, DateTime(2025, 6, 16));
    });

    test('a non-positive amount is clamped to one', () {
      expect(
        const HeatmapRange.trailingDays(0).resolve(today: today).start,
        DateTime(2026, 6, 15),
      );
      expect(
        const HeatmapRange.trailingMonths(0).resolve(today: today).start,
        DateTime(2026, 5, 16),
      );
    });

    test('year spans the whole calendar year', () {
      final DateTimeRange range = const HeatmapRange.year(
        2025,
      ).resolve(today: today);
      expect(range.start, DateTime(2025));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('auto follows the data with padding', () {
      final DateTimeRange range = const HeatmapRange.auto(paddingDays: 3)
          .resolve(
            today: today,
            dataBounds: DateTimeRange(
              start: DateTime(2026, 4, 10),
              end: DateTime(2026, 5, 2),
            ),
          );
      expect(range.start, DateTime(2026, 4, 7));
      expect(range.end, DateTime(2026, 5, 5));
      expect(const HeatmapRange.auto().isAuto, isTrue);
      expect(const HeatmapRange.trailingDays(7).isAuto, isFalse);
    });

    test('auto falls back to a year while the store is empty', () {
      final DateTimeRange range = const HeatmapRange.auto().resolve(
        today: today,
      );
      expect(range.start, DateTime(2025, 6, 16));
      expect(range.end, DateTime(2026, 6, 15));
    });

    test('resolution ignores the time of day', () {
      final DateTimeRange range = const HeatmapRange.trailingDays(
        1,
      ).resolve(today: DateTime(2026, 6, 15, 23, 59));
      expect(range.start, DateTime(2026, 6, 15));
      expect(range.end, DateTime(2026, 6, 15));
    });

    test('has value equality and a readable description', () {
      expect(
        const HeatmapRange.trailingMonths(6),
        const HeatmapRange.trailingMonths(6),
      );
      expect(
        const HeatmapRange.trailingMonths(6).hashCode,
        const HeatmapRange.trailingMonths(6).hashCode,
      );
      expect(
        const HeatmapRange.trailingMonths(6),
        isNot(const HeatmapRange.trailingDays(6)),
      );
      expect(
        const HeatmapRange.trailingMonths(6).toString(),
        'HeatmapRange.trailingMonths(6)',
      );
      expect(const HeatmapRange.year(2026).toString(), contains('2026'));
    });
  });

  group('ActivitySort', () {
    final List<Activity> activities = <Activity>[
      BaseActivity(
        name: 'Zebra',
        date: DateTime(2026, 6, 10, 18),
        type: const ActivityType('reading'),
      ),
      BaseActivity(
        name: 'apple',
        date: DateTime(2026, 6, 10, 7),
        type: const ActivityType('workout'),
      ),
      BaseActivity(name: 'Mango', date: DateTime(2026, 6, 10, 12)),
    ];

    test('insertion keeps the list untouched', () {
      expect(
        identical(ActivitySort.insertion.apply(activities), activities),
        isTrue,
      );
    });

    test('byName is case insensitive', () {
      expect(
        ActivitySort.byName.apply(activities).map((Activity a) => a.name),
        <String>['apple', 'Mango', 'Zebra'],
      );
    });

    test('byTime follows the timestamp', () {
      expect(
        ActivitySort.byTime.apply(activities).map((Activity a) => a.name),
        <String>['apple', 'Mango', 'Zebra'],
      );
    });

    test('byType groups by type id', () {
      expect(
        ActivitySort.byType.apply(activities).map((Activity a) => a.type.id),
        <String>['all', 'reading', 'workout'],
      );
    });

    test('custom uses the given comparator', () {
      final ActivitySort sort = ActivitySort.custom(
        (Activity a, Activity b) => b.name.compareTo(a.name),
      );
      expect(sort.apply(activities).map((Activity a) => a.name), <String>[
        'apple',
        'Zebra',
        'Mango',
      ]);
      expect(sort.toString(), 'ActivitySort.custom');
    });

    test('sorting does not mutate the input', () {
      ActivitySort.byName.apply(activities);
      expect(activities.first.name, 'Zebra');
    });
  });

  group('ActivityHeatmapConfig', () {
    test('rejects an impossible week start', () {
      expect(
        () => ActivityHeatmapConfig(weekStartsOn: 0),
        throwsAssertionError,
      );
      expect(
        () => ActivityHeatmapConfig(weekStartsOn: 8),
        throwsAssertionError,
      );
    });

    test('rejects an alignment outside the viewport', () {
      expect(
        () => ActivityHeatmapConfig(initialAlignment: 1.5),
        throwsAssertionError,
      );
    });

    test('resolvedToday defaults to now', () {
      final DateTime resolved = const ActivityHeatmapConfig().resolvedToday;
      expect(
        resolved.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 5)),
      );
      expect(
        ActivityHeatmapConfig(today: DateTime(2026, 6, 15)).resolvedToday,
        DateTime(2026, 6, 15),
      );
    });

    test('copyWith replaces only what it is given', () {
      const ActivityHeatmapConfig config = ActivityHeatmapConfig();
      final ActivityHeatmapConfig updated = config.copyWith(
        splitMonthView: true,
        weekStartsOn: DateTime.sunday,
      );
      expect(updated.splitMonthView, isTrue);
      expect(updated.weekStartsOn, DateTime.sunday);
      expect(updated.colorTheme, config.colorTheme);
      expect(updated.showLegend, config.showLegend);
    });

    test('copyWith can clear the nullable fields', () {
      final ActivityHeatmapConfig config = ActivityHeatmapConfig(
        activityWeight: (Activity a) => 2,
        initialDate: DateTime(2026, 6),
        today: DateTime(2026, 6, 15),
      );
      final ActivityHeatmapConfig cleared = config.copyWith(
        clearActivityWeight: true,
        clearInitialDate: true,
        clearToday: true,
      );
      expect(cleared.activityWeight, isNull);
      expect(cleared.initialDate, isNull);
      expect(cleared.today, isNull);
    });

    test('affectsLayout only reacts to geometry', () {
      const ActivityHeatmapConfig config = ActivityHeatmapConfig();
      expect(config.affectsLayout(config.copyWith(showLegend: false)), isFalse);
      expect(
        config.affectsLayout(
          config.copyWith(colorTheme: HeatmapColorTheme.mono),
        ),
        isFalse,
      );
      expect(
        config.affectsLayout(config.copyWith(splitMonthView: true)),
        isTrue,
      );
      expect(
        config.affectsLayout(
          config.copyWith(cellStyle: const HeatmapCellStyle(size: 10)),
        ),
        isTrue,
      );
      expect(
        config.affectsLayout(config.copyWith(weekStartsOn: DateTime.sunday)),
        isTrue,
      );
      expect(
        config.affectsLayout(
          config.copyWith(range: const HeatmapRange.trailingDays(30)),
        ),
        isTrue,
      );
      expect(
        config.affectsLayout(config.copyWith(today: DateTime(2026, 6, 15))),
        isTrue,
      );
    });

    test('has value equality', () {
      expect(const ActivityHeatmapConfig(), const ActivityHeatmapConfig());
      expect(
        const ActivityHeatmapConfig().hashCode,
        const ActivityHeatmapConfig().hashCode,
      );
      expect(
        const ActivityHeatmapConfig(showLegend: false),
        isNot(const ActivityHeatmapConfig()),
      );
    });
  });

  group('HeatmapCellData', () {
    HeatmapCellData data({int count = 2, bool placeholder = false}) =>
        HeatmapCellData(
          date: DateTime(2026, 6, 10),
          count: count,
          level: count == 0 ? 0 : 2,
          levelCount: 4,
          color: const Color(0xFF40C463),
          isToday: false,
          isOutOfRange: placeholder,
          isPlaceholder: placeholder,
          activeFilter: const ActivityType('workout'),
        );

    test('hasActivity follows the count', () {
      expect(data().hasActivity, isTrue);
      expect(data(count: 0).hasActivity, isFalse);
    });

    test('has value equality', () {
      expect(data(), data());
      expect(data().hashCode, data().hashCode);
      expect(data(), isNot(data(count: 3)));
      expect(data(), isNot(data(placeholder: true)));
    });

    test('describes itself', () {
      expect(data().toString(), contains('2026'));
    });
  });

  group('HeatmapStringOverrides', () {
    test('isEmpty is true only when nothing is set', () {
      expect(const HeatmapStringOverrides().isEmpty, isTrue);
      expect(
        const HeatmapStringOverrides(legendLess: 'Quiet').isEmpty,
        isFalse,
      );
    });

    test('has value equality', () {
      expect(
        const HeatmapStringOverrides(legendLess: 'Quiet'),
        const HeatmapStringOverrides(legendLess: 'Quiet'),
      );
      expect(
        const HeatmapStringOverrides(legendLess: 'Quiet').hashCode,
        const HeatmapStringOverrides(legendLess: 'Quiet').hashCode,
      );
      expect(
        const HeatmapStringOverrides(legendLess: 'Quiet'),
        isNot(const HeatmapStringOverrides(legendMore: 'Busy')),
      );
    });

    testWidgets('the inherited widget updates its dependents', (
      WidgetTester tester,
    ) async {
      final List<String?> seen = <String?>[];

      Widget build(HeatmapStringOverrides overrides) => ActivityHeatmapStrings(
        overrides: overrides,
        child: Builder(
          builder: (BuildContext context) {
            seen.add(ActivityHeatmapStrings.maybeOf(context)?.legendLess);
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(build(const HeatmapStringOverrides()));
      await tester.pumpWidget(
        build(const HeatmapStringOverrides(legendLess: 'Quiet')),
      );
      expect(seen, <String?>[null, 'Quiet']);
    });

    testWidgets('maybeOf returns null with no ancestor', (
      WidgetTester tester,
    ) async {
      HeatmapStringOverrides? found = const HeatmapStringOverrides();
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            found = ActivityHeatmapStrings.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(found, isNull);
    });
  });
}
