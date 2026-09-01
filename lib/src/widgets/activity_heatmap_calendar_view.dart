import 'package:flutter/material.dart';

import '../config/activity_heatmap_config.dart';
import '../config/heatmap_color_theme.dart';
import '../core/activity_heatmap_calendar.dart';
import '../core/heatmap_data.dart';
import '../core/heatmap_grid_model.dart';
import '../core/heatmap_view_attachment.dart';
import '../l10n/activity_heatmap_localizations.dart';
import '../l10n/heatmap_label_formatter.dart';
import '../l10n/heatmap_string_overrides.dart';
import '../models/activity.dart';
import '../models/activity_type.dart';
import '../models/heatmap_date_utils.dart';
import 'default_activity_bottom_sheet.dart';
import 'heatmap_body_continuous.dart';
import 'heatmap_body_split_month.dart';
import 'heatmap_legend.dart';
import 'heatmap_render_spec.dart';
import 'heatmap_weekday_gutter.dart';

/// Signature for the tap callback of a day cell.
typedef HeatmapCellTapCallback =
    void Function(DateTime date, List<Activity> activities);

/// The heatmap widget.
///
/// By default it renders the singleton `ActivityHeatmapCalendar()`, so the
/// whole setup is:
///
/// ```dart
/// ActivityHeatmapCalendar().insert(
///   BaseActivity(name: 'Morning run', date: DateTime.now()),
/// );
/// // ...
/// const ActivityHeatmapCalendarView()
/// ```
///
/// The widget listens to its controller, so inserting activities or calling
/// `filter` from anywhere in your app updates it with no further wiring.
class ActivityHeatmapCalendarView extends StatefulWidget {
  /// Creates a heatmap view.
  const ActivityHeatmapCalendarView({
    this.calendar,
    this.config,
    this.onCellTap,
    this.onCellLongPress,
    this.onActivityTap,
    this.bottomSheetBuilder,
    this.detailBuilder,
    this.emptyStateBuilder,
    super.key,
  });

  /// The controller to render. Defaults to the singleton.
  final ActivityHeatmapCalendar? calendar;

  /// Overrides the controller's configuration for this view only.
  ///
  /// Useful when two views share one data set but need different layouts.
  final ActivityHeatmapConfig? config;

  /// Called when a day is tapped, with that day's activities after the active
  /// filter.
  ///
  /// Supplying a callback replaces the default bottom sheet. Set
  /// `alwaysShowSheet: true` in the configuration to get both.
  final HeatmapCellTapCallback? onCellTap;

  /// Called when a day is long pressed.
  final HeatmapCellTapCallback? onCellLongPress;

  /// Called when an activity in the default bottom sheet is tapped.
  ///
  /// Ignored when [bottomSheetBuilder] replaces the sheet. Does not suppress
  /// the default sheet — use this to open an editor from a listed activity.
  final HeatmapActivityTapCallback? onActivityTap;

  /// Replaces the contents of the default bottom sheet.
  final ActivitySheetBuilder? bottomSheetBuilder;

  /// Renders an activity's `detail` payload as a subtitle in the default
  /// sheet. Defaults to `detail.toString()`.
  final ActivityDetailBuilder? detailBuilder;

  /// Shown instead of the grid while the controller holds no activities.
  ///
  /// When null an empty grid is drawn, which is usually what you want: it
  /// still communicates the date range.
  final WidgetBuilder? emptyStateBuilder;

  @override
  State<ActivityHeatmapCalendarView> createState() =>
      _ActivityHeatmapCalendarViewState();
}

class _ActivityHeatmapCalendarViewState
    extends State<ActivityHeatmapCalendarView>
    implements HeatmapViewAttachment {
  ScrollController? _controller;
  HeatmapGridModel? _model;
  double? _measuredViewportWidth;

  /// A scroll target that arrived before the first layout.
  ({DateTime date, double alignment})? _pendingTarget;

  /// The day whose detail sheet is currently open, if any.
  DateTime? _selectedDate;

  ActivityHeatmapCalendar get _calendar =>
      widget.calendar ?? ActivityHeatmapCalendar.instance;

  @override
  HeatmapGridModel? get gridModel => _model;

  @override
  double? get viewportWidth => _measuredViewportWidth;

  @override
  void initState() {
    super.initState();
    _calendar.attach(this);
    final DateTime? pending = _calendar.takePendingGoto();
    if (pending != null) {
      _pendingTarget = (
        date: pending,
        alignment: _calendar.pendingGotoAlignment,
      );
    }
  }

  @override
  void didUpdateWidget(ActivityHeatmapCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendar != widget.calendar) {
      (oldWidget.calendar ?? ActivityHeatmapCalendar.instance).detach(this);
      _calendar.attach(this);
    }
  }

  @override
  void dispose() {
    _calendar.detach(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Future<void> scrollToDate(
    DateTime date, {
    double alignment = 0.5,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
  }) async {
    final HeatmapGridModel? model = _model;
    final double? width = _measuredViewportWidth;
    final ScrollController? controller = _controller;

    // Before the first layout there is nothing to scroll; remember the target
    // and let the scroll view open on it directly instead of jumping after a
    // frame, which would be visible.
    if (model == null ||
        width == null ||
        controller == null ||
        !controller.hasClients) {
      _pendingTarget = (date: date, alignment: alignment);
      return;
    }

    final double offset = model.offsetToCenter(
      date,
      viewportWidth: width,
      alignment: alignment,
    );
    if (!animate) {
      controller.jumpTo(offset);
      return;
    }
    await controller.animateTo(offset, duration: duration, curve: curve);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _calendar,
      builder: (BuildContext context, Widget? child) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ActivityHeatmapConfig config = widget.config ?? _calendar.config;
    final Brightness brightness = Theme.of(context).brightness;
    final ActivityType? filter = _calendar.activeFilter;

    final HeatmapGridModel model = HeatmapGridModel.build(
      range: config.range.resolve(
        today: config.resolvedToday,
        dataBounds: _calendar.dataBounds,
      ),
      weekStartsOn: config.weekStartsOn,
      cellStyle: config.cellStyle,
      splitMonthView: config.splitMonthView,
      sectionGap: config.labels.splitMonthSectionGap,
      sectionPadding: config.labels.splitMonthPadding,
    );

    final HeatmapColorTheme theme = _resolveTheme(config, brightness, filter);
    final HeatmapData data = _calendar.heatmapData(
      model.range,
      levelCount: theme.levelCount,
      levelResolver: config.levelResolver,
      activityWeight: config.activityWeight,
    );

    final HeatmapRenderSpec spec = HeatmapRenderSpec(
      config: config,
      model: model,
      data: data,
      theme: theme,
      today: HeatmapDateUtils.normalize(config.resolvedToday),
      formatter: HeatmapLabelFormatter.of(context),
      strings: ActivityHeatmapLocalizations.of(context),
      textDirection: Directionality.of(context),
      activeFilter: filter,
      selectedDate: _selectedDate,
    );

    _adoptModel(model);

    return Padding(
      padding: config.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (config.showFilterBanner && filter != null)
            _FilterBanner(spec: spec, onClear: _calendar.clearFilter),
          if (widget.emptyStateBuilder != null && _calendar.isEmpty)
            widget.emptyStateBuilder!(context)
          else
            _buildGrid(context, spec),
          if (config.showLegend) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: HeatmapLegend(spec: spec),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, HeatmapRenderSpec spec) {
    final double headerHeight = spec.config.splitMonthView
        ? HeatmapBodySplitMonth.headerHeightFor(spec)
        : spec.monthLabelHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (spec.config.showWeekdayLabels)
          HeatmapWeekdayGutter(spec: spec, topInset: headerHeight),
        Expanded(
          child: SizedBox(
            height: headerHeight + spec.model.gridHeight,
            // The grid is the only widget that knows its own viewport width,
            // and it must be measured here rather than from the whole widget:
            // the weekday gutter's width depends on the locale's weekday names
            // and cannot be predicted.
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                _measuredViewportWidth = constraints.maxWidth;
                final ScrollController controller = _ensureController(
                  spec,
                  constraints.maxWidth,
                );

                return spec.config.splitMonthView
                    ? HeatmapBodySplitMonth(
                        spec: spec,
                        controller: controller,
                        onTap: _handleTap,
                        onLongPress: widget.onCellLongPress == null
                            ? null
                            : _handleLongPress,
                      )
                    : HeatmapBodyContinuous(
                        spec: spec,
                        controller: controller,
                        onTap: _handleTap,
                        onLongPress: widget.onCellLongPress == null
                            ? null
                            : _handleLongPress,
                      );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Filtering by a type that declares a colour re-tints the whole ramp with
  /// it, which makes the active filter obvious without any extra chrome.
  HeatmapColorTheme _resolveTheme(
    ActivityHeatmapConfig config,
    Brightness brightness,
    ActivityType? filter,
  ) {
    final HeatmapColorTheme base = config.colorTheme.resolveBrightness(
      brightness,
    );
    if (!config.useTypeColorWhenFiltered || filter?.color == null) {
      return base;
    }
    return HeatmapColorTheme.fromSeed(
      filter!.color!,
      levels: base.levelCount,
      brightness: brightness,
      withDarkVariant: false,
    );
  }

  /// Installs a new geometry, keeping the day at the centre of the viewport
  /// visible when the layout changes underneath the reader.
  void _adoptModel(HeatmapGridModel model) {
    final HeatmapGridModel? previous = _model;
    _model = model;

    final ScrollController? controller = _controller;
    final double? width = _measuredViewportWidth;
    if (previous == null ||
        controller == null ||
        width == null ||
        !controller.hasClients) {
      return;
    }
    if (previous.totalExtent == model.totalExtent &&
        previous.splitMonthView == model.splitMonthView &&
        previous.cellExtent == model.cellExtent) {
      return;
    }

    final DateTime centre = previous.dateAtOffset(
      controller.offset,
      viewportWidth: width,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) {
        return;
      }
      controller.jumpTo(model.offsetToCenter(centre, viewportWidth: width));
    });
  }

  ScrollController _ensureController(
    HeatmapRenderSpec spec,
    double viewportWidth,
  ) {
    final ScrollController? existing = _controller;
    if (existing != null) {
      return existing;
    }

    final ({DateTime date, double alignment}) target =
        _pendingTarget ??
        (
          date: spec.config.initialDate ?? spec.today,
          alignment: spec.config.initialAlignment,
        );
    _pendingTarget = null;

    return _controller = ScrollController(
      initialScrollOffset: spec.model.offsetToCenter(
        target.date,
        viewportWidth: viewportWidth,
        alignment: target.alignment,
      ),
    );
  }

  void _handleTap(DateTime date) {
    final List<Activity> activities = _calendar.showActivities(
      date,
      respectFilter: true,
    );
    final ActivityHeatmapConfig config = widget.config ?? _calendar.config;

    if (widget.onCellTap != null) {
      widget.onCellTap!(date, activities);
      if (!config.alwaysShowSheet) {
        return;
      }
    }
    _presentSheet(date, activities, config);
  }

  void _handleLongPress(DateTime date) {
    widget.onCellLongPress?.call(
      date,
      _calendar.showActivities(date, respectFilter: true),
    );
  }

  Future<void> _presentSheet(
    DateTime date,
    List<Activity> activities,
    ActivityHeatmapConfig config,
  ) async {
    setState(() => _selectedDate = date);
    try {
      await _showSheet(date, activities, config);
    } finally {
      if (mounted) {
        setState(() => _selectedDate = null);
      }
    }
  }

  Future<void> _showSheet(
    DateTime date,
    List<Activity> activities,
    ActivityHeatmapConfig config,
  ) async {
    assert(
      Navigator.maybeOf(context) != null,
      'ActivityHeatmapCalendarView needs a Navigator above it to open the '
      'default detail sheet. Wrap the app in a MaterialApp, or handle taps '
      'yourself with onCellTap.',
    );
    if (Navigator.maybeOf(context) == null) {
      return;
    }

    // The sheet is built under the navigator, above this widget, so any
    // string overrides installed around the heatmap are out of scope there.
    // Re-provide them so the sheet speaks the same language as the graph.
    final HeatmapStringOverrides? overrides = ActivityHeatmapStrings.maybeOf(
      context,
    );
    Widget withOverrides(Widget child) => overrides == null
        ? child
        : ActivityHeatmapStrings(overrides: overrides, child: child);

    final ActivitySheetBuilder? custom = widget.bottomSheetBuilder;
    if (custom == null) {
      return DefaultActivityBottomSheet.show(
        context,
        date: date,
        activities: activities,
        sort: config.activitySort,
        detailBuilder: widget.detailBuilder,
        onActivityTap: widget.onActivityTap,
        wrapper: withOverrides,
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          withOverrides(custom(context, date, activities)),
    );
  }
}

/// The dismissible banner shown while a type filter is active.
class _FilterBanner extends StatelessWidget {
  const _FilterBanner({required this.spec, required this.onClear});

  final HeatmapRenderSpec spec;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ActivityType filter = spec.activeFilter!;
    final Color accent = filter.color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: 12,
            end: 4,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                spec.strings.filterBanner(spec.strings.typeLabel(filter)),
                style: theme.textTheme.labelLarge?.copyWith(color: accent),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: accent,
                tooltip: spec.strings.clearFilter,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onClear,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
