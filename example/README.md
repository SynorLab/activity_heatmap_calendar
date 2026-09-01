# activity_heatmap_calendar example

A tour of the package: every configuration option is wired to a live control.

```bash
flutter run
```

- **Options (top right)** — colour theme, intensity scale, cell size, radius
  and spacing, week start, range, year display, weekday label mode, split
  month view, and every visibility toggle.
- **Language menu** — switches between the nine shipped locales; month and
  weekday names follow.
- **Type chips** — `filter(type)`, including the ramp re-tinting.
- **Today / Go to date** — `gotoToday()` and `goto(date)`.
- **This week** — `showActivities` and `showActivitiesBetween`.
- **Data & extensibility** — weighted heat, a custom cell builder, a custom
  detail sheet, and per-string overrides.

The data is two years of seeded random activity, so the graph looks the same
on every run.
