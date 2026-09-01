## 1.0.1

* Fix the GitHub repository URL in `pubspec.yaml`.
* Fix the preview image URL in `README.md`

## 1.0.0

First release.

* Horizontally scrollable, GitHub-style heatmap of daily activity, with lazy
  column building so a ten year range scrolls as cheaply as a one month range.
* `ActivityHeatmapCalendar()` singleton controller: `insert`, `insertAll`,
  `remove`, `removeWhere`, `replaceAll`, `clear` and `batch`.
* `Activity` and `ActivityType` are abstract and user-defined; activities that
  declare no type fall under `ActivityType.all`.
* Queries: `showActivities(date)`, `showActivitiesBetween(start, end)`,
  `countOn`, `knownTypes` and `dataBounds`, all answered from an index rather
  than by scanning.
* `filter(type)` narrows the list *and* the graph: daily values, the intensity
  scale and — for a type that declares a colour — the ramp itself.
* `goto(date)` and `gotoToday()`, usable before the first layout.
* Configurable colour themes, including `HeatmapColorTheme.fromSeed` and seven
  built-in ramps, with automatic light and dark variants.
* Pluggable intensity scales: fixed thresholds, quantiles or relative to the
  busiest day, plus optional per-activity weighting.
* `weekStartsOn`, cell size, radius, spacing, border and today ring are all
  configurable; cells can be replaced entirely with a builder.
* Month labels, weekday gutter, legend, the year and the split month layout can
  each be toggled.
* Taps open a designed bottom sheet by default, or call your own callback with
  that day's activities.
* Localized into English, German, Spanish, French, Japanese, Korean, and
  Simplified and Traditional Chinese, with `intl` supplying month and weekday
  names for every other locale, per-string overrides, and a safe fallback when
  the delegate is not registered.
