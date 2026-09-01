import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'demo/demo_data.dart';
import 'demo/demo_settings.dart';
import 'demo/home_page.dart';

void main() {
  // The controller is a singleton: fill it once, anywhere, and every view in
  // the app renders the same data.
  ActivityHeatmapCalendar().insertAll(buildDemoActivities());
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final DemoSettings settings = DemoSettings(ActivityHeatmapCalendar());

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (BuildContext context, _) => MaterialApp(
        title: 'Activity Heatmap Calendar',
        debugShowCheckedModeBanner: false,
        locale: settings.locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          ActivityHeatmapLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: ActivityHeatmapLocalizations.supportedLocales,
        themeMode: settings.themeMode,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1F883D),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF1F883D),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: HomePage(settings: settings),
      ),
    );
  }
}
