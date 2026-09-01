import 'package:flutter/material.dart';

import '../config/activity_heatmap_config.dart';
import '../l10n/activity_heatmap_localizations.dart';
import '../l10n/heatmap_label_formatter.dart';
import '../models/activity.dart';
import '../models/activity_type.dart';

/// Signature for a custom detail sheet.
typedef ActivitySheetBuilder =
    Widget Function(
      BuildContext context,
      DateTime date,
      List<Activity> activities,
    );

/// Signature for rendering an activity's `detail` payload as a subtitle.
typedef ActivityDetailBuilder = String? Function(Activity activity);

/// Called when a listed activity is tapped in the default bottom sheet.
typedef HeatmapActivityTapCallback =
    void Function(BuildContext context, Activity activity);

/// The sheet shown when a day cell is tapped.
///
/// Groups the day's activities by type, with a section header carrying each
/// type's colour and icon, and falls back to an illustrated empty state for
/// days with nothing recorded. It follows the ambient [ThemeData], so it
/// inherits your app's colours and shape without configuration.
///
/// To replace it entirely, pass `bottomSheetBuilder` to
/// `ActivityHeatmapCalendarView`, or handle `onCellTap` yourself.
class DefaultActivityBottomSheet extends StatelessWidget {
  /// Creates the detail sheet for [date].
  const DefaultActivityBottomSheet({
    required this.date,
    required this.activities,
    this.sort = ActivitySort.insertion,
    this.detailBuilder,
    this.onActivityTap,
    super.key,
  });

  /// The day being described.
  final DateTime date;

  /// The activities of that day, already filtered.
  final List<Activity> activities;

  /// Order the activities are listed in.
  final ActivitySort sort;

  /// Converts an activity's `detail` into a subtitle. Defaults to
  /// `detail.toString()`.
  final ActivityDetailBuilder? detailBuilder;

  /// Called when a listed activity is tapped.
  ///
  /// When non-null, each row becomes a button so the host app can open an
  /// editor without replacing the whole sheet.
  final HeatmapActivityTapCallback? onActivityTap;

  /// Opens this sheet as a modal.
  ///
  /// [wrapper] wraps the sheet before it is inserted into the modal route,
  /// which is where the view re-provides inherited widgets — string overrides
  /// in particular — that do not reach above the navigator on their own.
  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<Activity> activities,
    ActivitySort sort = ActivitySort.insertion,
    ActivityDetailBuilder? detailBuilder,
    HeatmapActivityTapCallback? onActivityTap,
    Widget Function(Widget child)? wrapper,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      // Material 3 caps sheets at 640px on large screens; the heatmap
      // sheet is meant to span the app.
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (BuildContext sheetContext) {
        final Widget sheet = DefaultActivityBottomSheet(
          date: date,
          activities: activities,
          sort: sort,
          detailBuilder: detailBuilder,
          onActivityTap: onActivityTap,
        );
        return wrapper == null ? sheet : wrapper(sheet);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ActivityHeatmapLocalizations strings =
        ActivityHeatmapLocalizations.of(context);
    final HeatmapLabelFormatter formatter = HeatmapLabelFormatter.of(context);
    final List<Activity> sorted = sort.apply(activities);

    final Size mediaSize = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: mediaSize.width,
        maxWidth: mediaSize.width,
        maxHeight: mediaSize.height * 0.8,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _Grabber(),
            _Header(
              title: formatter.fullDate(date),
              subtitle: strings.activityCount(sorted.length),
              closeLabel: strings.close,
            ),
            if (sorted.isEmpty)
              _EmptyState(
                title: strings.noActivitiesTitle,
                body: strings.noActivitiesBody,
              )
            else
              Flexible(
                child: _ActivityList(
                  activities: sorted,
                  detailBuilder: detailBuilder,
                  onActivityTap: onActivityTap,
                  strings: strings,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.closeLabel,
  });

  final String title;
  final String subtitle;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: closeLabel,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.activities,
    required this.strings,
    this.detailBuilder,
    this.onActivityTap,
  });

  final List<Activity> activities;
  final ActivityHeatmapLocalizations strings;
  final ActivityDetailBuilder? detailBuilder;
  final HeatmapActivityTapCallback? onActivityTap;

  @override
  Widget build(BuildContext context) {
    final List<_Section> sections = _groupByType(activities);

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      itemCount: sections.length,
      itemBuilder: (BuildContext context, int index) {
        final _Section section = sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (sections.length > 1 || !section.type.isAll)
              _SectionHeader(
                type: section.type,
                label: strings.typeLabel(section.type),
              ),
            for (final Activity activity in section.activities)
              _ActivityTile(
                activity: activity,
                detailBuilder: detailBuilder,
                onTap: onActivityTap == null
                    ? null
                    : () => onActivityTap!(context, activity),
              ),
          ],
        );
      },
    );
  }

  /// Groups by type while preserving the order types first appear in, so the
  /// sheet never reorders unpredictably between two openings.
  List<_Section> _groupByType(List<Activity> activities) {
    final Map<ActivityType, List<Activity>> grouped =
        <ActivityType, List<Activity>>{};
    for (final Activity activity in activities) {
      (grouped[activity.type] ??= <Activity>[]).add(activity);
    }
    return <_Section>[
      for (final MapEntry<ActivityType, List<Activity>> entry
          in grouped.entries)
        _Section(entry.key, entry.value),
    ];
  }
}

class _Section {
  const _Section(this.type, this.activities);

  final ActivityType type;
  final List<Activity> activities;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.type, required this.label});

  final ActivityType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = type.color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, this.detailBuilder, this.onTap});

  final Activity activity;
  final ActivityDetailBuilder? detailBuilder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = activity.type.color ?? theme.colorScheme.primary;
    final String? subtitle = detailBuilder != null
        ? detailBuilder!(activity)
        : activity.detail?.toString();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          activity.type.icon ?? Icons.bolt_rounded,
          size: 20,
          color: accent,
        ),
      ),
      title: Text(
        activity.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle == null || subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: onTap == null
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        32,
        16,
        32,
        MediaQuery.paddingOf(context).bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
