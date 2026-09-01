import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';

import 'demo_settings.dart';

/// The end drawer: every configuration option, live.
class ControlsPanel extends StatelessWidget {
  const ControlsPanel({required this.settings, super.key});

  final DemoSettings settings;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 360,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            const _SectionTitle('Appearance'),
            _Dropdown<String>(
              label: 'Colour theme',
              value: settings.themeName,
              items: demoThemes.keys,
              itemLabel: (String name) => name,
              onChanged: (String name) =>
                  settings.edit(() => settings.themeName = name),
            ),
            _Dropdown<String>(
              label: 'Intensity scale',
              value: settings.resolverName,
              items: demoResolvers.keys,
              itemLabel: (String name) => name,
              onChanged: (String name) =>
                  settings.edit(() => settings.resolverName = name),
            ),
            _Slider(
              label: 'Cell size',
              value: settings.cellSize,
              min: 8,
              max: 36,
              onChanged: (double v) =>
                  settings.edit(() => settings.cellSize = v),
            ),
            _Slider(
              label: 'Corner radius',
              value: settings.cellRadius,
              min: 0,
              max: 18,
              onChanged: (double v) =>
                  settings.edit(() => settings.cellRadius = v),
            ),
            _Slider(
              label: 'Cell spacing',
              value: settings.cellSpacing,
              min: 0,
              max: 12,
              onChanged: (double v) =>
                  settings.edit(() => settings.cellSpacing = v),
            ),

            const _SectionTitle('Layout'),
            _Dropdown<int>(
              label: 'Week starts on',
              value: settings.weekStartsOn,
              items: const <int>[
                DateTime.monday,
                DateTime.sunday,
                DateTime.saturday,
              ],
              itemLabel: _weekdayName,
              onChanged: (int day) =>
                  settings.edit(() => settings.weekStartsOn = day),
            ),
            _Dropdown<int>(
              label: 'Range',
              value: settings.trailingMonths,
              items: const <int>[3, 6, 12, 24],
              itemLabel: (int m) => 'Last $m months',
              onChanged: (int m) =>
                  settings.edit(() => settings.trailingMonths = m),
            ),
            _Dropdown<HeatmapYearDisplay>(
              label: 'Show the year',
              value: settings.yearDisplay,
              items: HeatmapYearDisplay.values,
              itemLabel: (HeatmapYearDisplay v) => switch (v) {
                HeatmapYearDisplay.never => 'Never',
                HeatmapYearDisplay.onChange => 'When it changes',
                HeatmapYearDisplay.always => 'Always',
              },
              onChanged: (HeatmapYearDisplay v) =>
                  settings.edit(() => settings.yearDisplay = v),
            ),
            _Dropdown<HeatmapWeekdayLabelMode>(
              label: 'Weekday labels',
              value: settings.weekdayLabelMode,
              items: HeatmapWeekdayLabelMode.values,
              itemLabel: (HeatmapWeekdayLabelMode v) => switch (v) {
                HeatmapWeekdayLabelMode.all => 'Every day',
                HeatmapWeekdayLabelMode.alternate => 'Every other day',
                HeatmapWeekdayLabelMode.none => 'None',
              },
              onChanged: (HeatmapWeekdayLabelMode v) =>
                  settings.edit(() => settings.weekdayLabelMode = v),
            ),
            _Switch(
              label: 'Split month view',
              subtitle: 'One block per month instead of a continuous run',
              value: settings.splitMonthView,
              onChanged: (bool v) =>
                  settings.edit(() => settings.splitMonthView = v),
            ),
            _Switch(
              label: 'Month labels',
              value: settings.showMonthLabels,
              onChanged: (bool v) =>
                  settings.edit(() => settings.showMonthLabels = v),
            ),
            _Switch(
              label: 'Weekday gutter',
              value: settings.showWeekdayLabels,
              onChanged: (bool v) =>
                  settings.edit(() => settings.showWeekdayLabels = v),
            ),
            _Switch(
              label: 'Legend',
              value: settings.showLegend,
              onChanged: (bool v) =>
                  settings.edit(() => settings.showLegend = v),
            ),
            _Switch(
              label: 'Hover tooltips',
              value: settings.showTooltips,
              onChanged: (bool v) =>
                  settings.edit(() => settings.showTooltips = v),
            ),

            const _SectionTitle('Filtering'),
            _Switch(
              label: 'Filter banner',
              value: settings.showFilterBanner,
              onChanged: (bool v) =>
                  settings.edit(() => settings.showFilterBanner = v),
            ),
            _Switch(
              label: 'Re-tint with the type colour',
              subtitle: 'The ramp adopts the filtered type’s colour',
              value: settings.useTypeColorWhenFiltered,
              onChanged: (bool v) =>
                  settings.edit(() => settings.useTypeColorWhenFiltered = v),
            ),

            const _SectionTitle('Data & extensibility'),
            _Switch(
              label: 'Weigh by minutes',
              subtitle: 'Heat follows time practised, not activity count',
              value: settings.weightByMinutes,
              onChanged: (bool v) =>
                  settings.edit(() => settings.weightByMinutes = v),
            ),
            _Switch(
              label: 'Custom cells',
              subtitle: 'A cell builder drawing circles and a dot for today',
              value: settings.customCells,
              onChanged: (bool v) =>
                  settings.edit(() => settings.customCells = v),
            ),
            _Switch(
              label: 'Custom detail sheet',
              subtitle: 'Replaces the built-in bottom sheet',
              value: settings.customSheet,
              onChanged: (bool v) =>
                  settings.edit(() => settings.customSheet = v),
            ),
            _Switch(
              label: 'Override strings',
              subtitle: '“Less/More” becomes “Quiet/Busy”',
              value: settings.overrideStrings,
              onChanged: (bool v) =>
                  settings.edit(() => settings.overrideStrings = v),
            ),
            _Dropdown<ActivitySort>(
              label: 'Sheet order',
              value: settings.activitySort,
              items: <ActivitySort>[
                ActivitySort.insertion,
                ActivitySort.byTime,
                ActivitySort.byName,
                ActivitySort.byType,
              ],
              itemLabel: (ActivitySort s) => switch (s.toString()) {
                'ActivitySort.byTime' => 'By time',
                'ActivitySort.byName' => 'By name',
                'ActivitySort.byType' => 'By type',
                _ => 'As inserted',
              },
              onChanged: (ActivitySort s) =>
                  settings.edit(() => settings.activitySort = s),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayName(int weekday) => const <int, String>{
    DateTime.monday: 'Monday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  }[weekday]!;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('$label  ·  ${value.round()}'),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Iterable<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: <DropdownMenuItem<T>>[
          for (final T item in items)
            DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
        ],
        onChanged: (T? next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}
