# activity_heatmap_calendar

A GitHub-style activity heatmap for Flutter: horizontally scrollable,
localized, and driven by *your* activity model.

![Activity heatmap calendar](https://raw.githubusercontent.com/SynorLab/activity_heatmap_calendar/refs/heads/main/assets/cover.png)

**[Live demo](https://synorlab.com/open-source/activity-heatmap-calendar)**

```dart
ActivityHeatmapCalendar().insert(
  BaseActivity(name: 'Morning run', date: DateTime.now()),
);

const ActivityHeatmapCalendarView();
```

The widget listens to the controller, so inserting an activity anywhere in
your app repaints the graph.

## Features

- Lazy horizontal heatmap (one column per week)
- Use `BaseActivity` or implement `Activity` on your own model
- Filter by type: values, scale, and colour ramp all update
- Seven built-in themes, `fromSeed`, light/dark, custom cells
- Nine locales, `intl` month/weekday names, RTL, string overrides



## Install

```yaml
dependencies:
  activity_heatmap_calendar: ^1.0.0
```



## Quick start

```dart
BaseActivity(
  name: 'Morning run',
  date: DateTime(2026, 6, 15),
  type: const ActivityType('workout', label: 'Workout', color: Colors.orange),
  detail: '5 km, easy',
);
```

Or implement `Activity` on a class you already have. Then fill the
controller and show the view:

```dart
ActivityHeatmapCalendar().insertAll(await loadActivities());

const ActivityHeatmapCalendarView();
```

`ActivityHeatmapCalendar()` is a singleton: fill it from a repository, a
bloc, or `main`. Wrap bulk inserts in `batch` so the view repaints once.

## Configuration

```dart
ActivityHeatmapCalendar().setConfig(
  const ActivityHeatmapConfig(
    range: HeatmapRange.trailingMonths(12),
    weekStartsOn: DateTime.monday,
    colorTheme: HeatmapColorTheme.github,
    splitMonthView: false,
  ),
);
```

Override per view with `ActivityHeatmapCalendarView(config: …)`. Common
knobs: `range`, `cellStyle`, `colorTheme`, `levelResolver`,
`activityWeight`, `showLegend`, `splitMonthView`.

```dart
calendar.filter(const ActivityType('workout'));
await calendar.goto(DateTime(2026, 3, 17));
await calendar.gotoToday(alignment: 1);

final work = ActivityHeatmapCalendar.named('work');
```

Built-in themes: `github`, `ocean`, `sunset`, `violet`, `forest`, `rose`,
`mono`. Intensity scales: `ThresholdLevelResolver.github()`,
`QuantileLevelResolver()`, `RelativeLevelResolver()`.

## Localization

```dart
MaterialApp(
  localizationsDelegates: const [
    ActivityHeatmapLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: ActivityHeatmapLocalizations.supportedLocales,
)
```

Shipped: `en`, `de`, `es`, `fr`, `ja`, `ko`, `zh`, `zh_Hans`, `zh_Hant`.
The delegate is optional: strings fall back to English.

Override a few words with `ActivityHeatmapStrings`.

## Example

[Live demo](https://synorlab.com/open-source/activity-heatmap-calendar) —
or run it locally:

```bash
cd example && flutter run
```



## About

`activity_heatmap_calendar` is maintained by the
[SynorLab](https://synorlab.com/) team. SynorLab is dedicated to
*Make life simple and joyful* — apps that connect people and enrich
daily life.

## License

MIT: see [LICENSE](LICENSE).