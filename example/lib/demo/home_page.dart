import 'package:activity_heatmap_calendar/activity_heatmap_calendar.dart';
import 'package:flutter/material.dart';

import 'controls_panel.dart';
import 'demo_data.dart';
import 'demo_settings.dart';

/// The demo screen: the heatmap plus everything you can do with the API.
class HomePage extends StatefulWidget {
  const HomePage({required this.settings, super.key});

  final DemoSettings settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ActivityHeatmapCalendar calendar = ActivityHeatmapCalendar();

  DemoSettings get settings => widget.settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      endDrawer: ControlsPanel(settings: settings),
      appBar: AppBar(
        title: const Text('Activity Heatmap Calendar'),
        actions: <Widget>[
          _LocaleMenu(settings: settings),
          IconButton(
            tooltip: 'Toggle brightness',
            icon: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => settings.edit(
              () => settings.themeMode = settings.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ),
          Builder(
            builder: (BuildContext context) => IconButton(
              tooltip: 'Options',
              icon: const Icon(Icons.tune_rounded),
              onPressed: Scaffold.of(context).openEndDrawer,
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        // The controller is a ChangeNotifier, so the surrounding UI can react
        // to inserts and filters exactly like the heatmap does.
        listenable: calendar,
        builder: (BuildContext context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: <Widget>[
            _Card(child: _buildHeatmap(context)),
            const SizedBox(height: 16),
            _TypeFilterChips(calendar: calendar),
            const SizedBox(height: 16),
            _NavigationBar(calendar: calendar),
            const SizedBox(height: 16),
            _RangeSummary(calendar: calendar),
            const SizedBox(height: 24),
            Text(
              '${calendar.length} activities across '
              '${calendar.knownTypes.length} types.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    // A per-view configuration override: the controller keeps the shared
    // settings, this view adds the builder-based extras.
    ActivityHeatmapConfig config = settings.config;
    if (settings.customCells) {
      config = config.copyWith(
        cellStyle: config.cellStyle.copyWith(builder: _buildCustomCell),
      );
    }

    Widget view = ActivityHeatmapCalendarView(
      config: config,
      detailBuilder: (Activity activity) => activity.detail.toString(),
      bottomSheetBuilder: settings.customSheet ? _buildCustomSheet : null,
    );

    if (settings.overrideStrings) {
      view = ActivityHeatmapStrings(
        overrides: const HeatmapStringOverrides(
          legendLess: 'Quiet',
          legendMore: 'Busy',
        ),
        child: view,
      );
    }
    return view;
  }

  /// A cell builder: circles instead of squares, a ring on today.
  ///
  /// Returning null for a placeholder day falls back to the package's own
  /// rendering, so only the cells you care about need handling.
  Widget? _buildCustomCell(BuildContext context, HeatmapCellData data) {
    if (data.isPlaceholder) {
      return null;
    }
    final double size = settings.cellSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: data.color,
        shape: BoxShape.circle,
        border: data.isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: data.count > 3 && size >= 20
          ? Text(
              '${data.count}',
              style: TextStyle(
                fontSize: size * 0.4,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }

  /// A replacement for the built-in detail sheet.
  Widget _buildCustomSheet(
    BuildContext context,
    DateTime date,
    List<Activity> activities,
  ) {
    final int minutes = activities.fold<int>(
      0,
      (int sum, Activity a) => sum + (a.detail! as Session).minutes,
    );
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            HeatmapLabelFormatter.of(context).fullDate(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text('$minutes minutes across ${activities.length} activities'),
          const SizedBox(height: 16),
          for (final Activity activity in activities)
            Text('• ${activity.name} — ${activity.detail}'),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}

/// Requirement 7: one tap filters both the list and the graph.
class _TypeFilterChips extends StatelessWidget {
  const _TypeFilterChips({required this.calendar});

  final ActivityHeatmapCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final ActivityType? active = calendar.activeFilter;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: <Widget>[
        ChoiceChip(
          label: const Text('All'),
          selected: active == null,
          onSelected: (_) => calendar.clearFilter(),
        ),
        for (final ActivityType type in demoTypes)
          ChoiceChip(
            avatar: Icon(type.icon, size: 18, color: type.color),
            label: Text(type.displayLabel),
            selected: active == type,
            selectedColor: type.color?.withValues(alpha: 0.2),
            onSelected: (bool selected) =>
                calendar.filter(selected ? type : ActivityType.all),
          ),
      ],
    );
  }
}

/// Requirement 4: `goto` moves every attached view to a date.
class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.calendar});

  final ActivityHeatmapCalendar calendar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: <Widget>[
        FilledButton.tonalIcon(
          icon: const Icon(Icons.today_rounded),
          label: const Text('Today'),
          onPressed: () => calendar.gotoToday(alignment: 1),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.event_rounded),
          label: const Text('Go to date…'),
          onPressed: () => _pickDate(context),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.casino_rounded),
          label: const Text('Add today'),
          onPressed: () => calendar.insert(
            DemoActivity(
              name: 'Logged from the demo',
              date: DateTime.now(),
              type: coding,
              session: const Session(minutes: 30, note: 'just now'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTimeRange range = calendar.resolveRange();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: calendar.config.resolvedToday,
      firstDate: range.start,
      lastDate: range.end,
    );
    if (picked != null) {
      await calendar.goto(picked);
    }
  }
}

/// Requirements 5 and 6: querying the store directly.
class _RangeSummary extends StatelessWidget {
  const _RangeSummary({required this.calendar});

  final ActivityHeatmapCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime today = calendar.config.resolvedToday;
    final DateTime weekAgo = HeatmapDateUtils.addDays(today, -6);
    final List<Activity> week = calendar.showActivitiesBetween(
      weekAgo,
      today,
      respectFilter: true,
    );
    final List<Activity> todayOnly = calendar.showActivities(
      today,
      respectFilter: true,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('This week', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'showActivitiesBetween → ${week.length} activities, '
            '${week.fold<int>(0, (int s, Activity a) => s + (a.detail! as Session).minutes)} minutes',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'showActivities(today) → ${todayOnly.length} activities',
            style: theme.textTheme.bodyMedium,
          ),
          if (week.isNotEmpty) ...<Widget>[
            const Divider(height: 24),
            for (final Activity activity in week.take(3))
              Text(
                '• ${activity.name} · ${activity.type.displayLabel}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

class _LocaleMenu extends StatelessWidget {
  const _LocaleMenu({required this.settings});

  final DemoSettings settings;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      tooltip: 'Language',
      icon: const Icon(Icons.translate_rounded),
      initialValue: settings.locale,
      onSelected: (Locale locale) =>
          settings.edit(() => settings.locale = locale),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        for (final MapEntry<String, Locale> entry in demoLocales.entries)
          PopupMenuItem<Locale>(value: entry.value, child: Text(entry.key)),
      ],
    );
  }
}
