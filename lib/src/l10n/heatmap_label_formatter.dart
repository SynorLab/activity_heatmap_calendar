import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats the dates that appear as labels, in the ambient locale.
///
/// Month and weekday names come from `intl` rather than from the package's own
/// ARB files, so they follow the app's language with no configuration and
/// cover every locale `intl` knows — far more than the package ships strings
/// for.
///
/// Each formatter is cached per locale, because constructing a [DateFormat] is
/// noticeably more expensive than using one and the heatmap formats a label
/// for every visible column.
@immutable
class HeatmapLabelFormatter {
  const HeatmapLabelFormatter._(this.localeName);

  /// The formatter for the locale of [context].
  factory HeatmapLabelFormatter.of(BuildContext context) =>
      HeatmapLabelFormatter.forLocale(Localizations.localeOf(context));

  /// The formatter for an explicit [locale].
  factory HeatmapLabelFormatter.forLocale(Locale locale) {
    final String name = locale.toString();
    return _cache[name] ??= HeatmapLabelFormatter._(name);
  }

  static final Map<String, HeatmapLabelFormatter> _cache =
      <String, HeatmapLabelFormatter>{};

  /// The locale these formats use.
  final String localeName;

  /// Abbreviated month name, for example `Mar`.
  String month(DateTime date) => _format(DateFormat.MMM, date);

  /// Abbreviated month name with the year, for example `Mar 2026`.
  String monthWithYear(DateTime date) => _format(DateFormat.yMMM, date);

  /// The year alone, for example `2026`.
  String year(DateTime date) => _format(DateFormat.y, date);

  /// Abbreviated weekday name, for example `Mon`.
  String weekdayShort(DateTime date) => _format(DateFormat.E, date);

  /// Full date with the weekday, for example `Monday, 2 March 2026`.
  ///
  /// Used as the title of the detail sheet.
  String fullDate(DateTime date) => _format(DateFormat.yMMMMEEEEd, date);

  /// Medium date, for example `2 Mar 2026`. Used in tooltips.
  String mediumDate(DateTime date) => _format(DateFormat.yMMMd, date);

  /// Formats [date] with [build], falling back to the default locale.
  ///
  /// `intl` throws when a locale's date symbols were never initialized, which
  /// happens whenever an app registers this package's delegate but not
  /// `GlobalMaterialLocalizations.delegate`. Rendering the label in the
  /// default locale is a far better outcome than crashing the heatmap, and it
  /// keeps the same skeleton so a month label stays a month label.
  String _format(DateFormat Function([String? locale]) build, DateTime date) {
    try {
      return build(localeName).format(date);
    } on Exception {
      return build().format(date);
    }
  }
}
