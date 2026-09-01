import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:activity_heatmap_calendar/src/widgets/heatmap_weekday_gutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../support/widget_harness.dart';

/// Requirement 16: the package must read correctly in every language it ships
/// strings for, must not crash when an app forgets the delegate, and must let
/// an app override any single string.
void main() {
  late ActivityHeatmapCalendar calendar;

  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() {
    calendar = ActivityHeatmapCalendar()..resetForTest();
  });

  group('delegate', () {
    testWidgets('falls back to English when no delegate is registered', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, withDelegates: false);
      expect(tester.takeException(), isNull);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('falls back to English even in a non-English locale', (
      WidgetTester tester,
    ) async {
      // An app that sets a locale but never registers the delegate: the
      // heatmap must render rather than throw.
      await pumpView(tester, withDelegates: false, locale: const Locale('ja'));
      // Flutter itself warns about the missing Material delegates; the point
      // here is that the heatmap keeps rendering.
      expect(
        tester.takeException().toString(),
        contains('localization delegates'),
      );
      expect(find.text('Less'), findsOneWidget);
    });

    testWidgets('ships the documented locales', (WidgetTester tester) async {
      expect(
        ActivityHeatmapLocalizations.supportedLocales.map(
          (Locale l) => l.toString(),
        ),
        containsAll(<String>[
          'en',
          'de',
          'es',
          'fr',
          'ja',
          'ko',
          'zh',
          'zh_Hans',
          'zh_Hant',
          'zh_TW',
        ]),
      );
    });
  });

  group('translated chrome', () {
    testWidgets('legend and banner follow the locale', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('跑步', DateTime(2026, 6, 10), type: kWorkout));
      await pumpView(
        tester,
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ),
      );

      expect(find.text('少'), findsOneWidget);
      expect(find.text('多'), findsOneWidget);

      calendar.filter(kWorkout);
      await tester.pumpAndSettle();
      expect(find.text('已篩選：Workout'), findsOneWidget);
    });

    testWidgets('Simplified and Traditional Chinese differ', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ),
      );
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('这天还没有记录'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      await pumpView(
        tester,
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ),
      );
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('這天還沒有紀錄'), findsOneWidget);
    });

    testWidgets('zh_TW uses Traditional Chinese, not Simplified', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, locale: const Locale('zh', 'TW'));
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('這天還沒有紀錄'), findsOneWidget);
      expect(find.text('这天还没有记录'), findsNothing);
    });

    testWidgets('the empty state is translated', (WidgetTester tester) async {
      await pumpView(tester, locale: const Locale('ja'));
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('まだ記録がありません'), findsOneWidget);
    });
  });

  group('dates', () {
    testWidgets('month labels come from intl', (WidgetTester tester) async {
      await pumpView(tester, locale: const Locale('fr'));
      expect(
        find.text(DateFormat.MMM('fr').format(DateTime(2026, 6))),
        findsOneWidget,
      );
    });

    testWidgets('weekday labels come from intl', (WidgetTester tester) async {
      await pumpView(
        tester,
        locale: const Locale('ja'),
        config: baseConfig().copyWith(
          labels: const HeatmapLabelsConfig(
            weekdayLabelMode: HeatmapWeekdayLabelMode.all,
          ),
        ),
      );
      // 2026-06-15 is a Monday, the first row under the default weekStartsOn.
      expect(
        find.text(DateFormat.E('ja').format(DateTime(2026, 6, 15))),
        findsWidgets,
      );
    });

    testWidgets('the sheet title is a localized full date', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('read', DateTime(2026, 6, 10)));
      await pumpView(tester, locale: const Locale('de'));
      await tapCell(tester, DateTime(2026, 6, 10));

      expect(
        find.text(DateFormat.yMMMMEEEEd('de').format(DateTime(2026, 6, 10))),
        findsOneWidget,
      );
    });
  });

  group('plurals', () {
    testWidgets('English uses the singular for one activity', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('read', DateTime(2026, 6, 10)));
      await pumpView(tester);
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('1 activity'), findsOneWidget);
    });

    testWidgets('English uses the plural for several', (
      WidgetTester tester,
    ) async {
      calendar.insertAll(<Activity>[
        act('a', DateTime(2026, 6, 10)),
        act('b', DateTime(2026, 6, 10)),
        act('c', DateTime(2026, 6, 10)),
      ]);
      await pumpView(tester);
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('3 activities'), findsOneWidget);
    });

    testWidgets('English uses the zero form for an empty day', (
      WidgetTester tester,
    ) async {
      await pumpView(tester);
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('No activities'), findsOneWidget);
    });

    testWidgets('a language without a singular form still reads correctly', (
      WidgetTester tester,
    ) async {
      calendar.insert(act('読書', DateTime(2026, 6, 10)));
      await pumpView(tester, locale: const Locale('ja'));
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('1 件のアクティビティ'), findsOneWidget);
    });
  });

  group('overrides', () {
    testWidgets('replace individual strings', (WidgetTester tester) async {
      await pumpView(
        tester,
        overrides: const HeatmapStringOverrides(
          legendLess: 'Quiet',
          legendMore: 'Busy',
        ),
      );
      expect(find.text('Quiet'), findsOneWidget);
      expect(find.text('Busy'), findsOneWidget);
      expect(find.text('Less'), findsNothing);
    });

    testWidgets('override a plural with a callback', (
      WidgetTester tester,
    ) async {
      calendar.insertAll(<Activity>[
        act('a', DateTime(2026, 6, 10)),
        act('b', DateTime(2026, 6, 10)),
      ]);
      await pumpView(
        tester,
        overrides: HeatmapStringOverrides(
          activityCount: (int count) => '$count sessions logged',
        ),
      );
      await tapCell(tester, DateTime(2026, 6, 10));
      expect(find.text('2 sessions logged'), findsOneWidget);
    });

    testWidgets('an unset field still uses the locale', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ),
        overrides: const HeatmapStringOverrides(legendLess: 'Zzz'),
      );
      expect(find.text('Zzz'), findsOneWidget);
      expect(find.text('多'), findsOneWidget);
    });

    testWidgets('typeLabel prefers a type label, then the localized default', (
      WidgetTester tester,
    ) async {
      late ActivityHeatmapLocalizations strings;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
          ),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            ActivityHeatmapLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: ActivityHeatmapLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              strings = ActivityHeatmapLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(strings.typeLabel(kWorkout), 'Workout');
      expect(strings.typeLabel(ActivityType.all), '全部');
      expect(strings.typeLabel(const ActivityType('cycling')), 'cycling');
    });
  });

  group('direction', () {
    testWidgets('right to left reverses the scroll axis', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, textDirection: TextDirection.rtl);
      final ListView body = tester
          .widgetList<ListView>(find.byType(ListView))
          .first;
      expect(body.reverse, isTrue);
    });

    testWidgets('left to right does not', (WidgetTester tester) async {
      await pumpView(tester, textDirection: TextDirection.ltr);
      final ListView body = tester
          .widgetList<ListView>(find.byType(ListView))
          .first;
      expect(body.reverse, isFalse);
    });

    testWidgets('the weekday gutter stays on the leading edge', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, textDirection: TextDirection.rtl);
      final RenderBox gutter = tester.renderObject(
        find.byType(HeatmapWeekdayGutter),
      );
      final RenderBox row = tester.renderObject(
        find
            .ancestor(
              of: find.byType(HeatmapWeekdayGutter),
              matching: find.byType(Row),
            )
            .first,
      );
      final double gutterStart = gutter.localToGlobal(Offset.zero).dx;
      final double rowEnd = row.localToGlobal(Offset.zero).dx + row.size.width;
      expect(gutterStart + gutter.size.width, lessThanOrEqualTo(rowEnd));
      expect(gutterStart, greaterThan(row.localToGlobal(Offset.zero).dx));
    });
  });
}
