import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Resolves an [ActivityStatsFormatter] for the current locale and unit
/// preference.
///
/// Single place where the three inputs a formatter needs (localized unit
/// symbols, the resolved [MeasurementSystem], and the locale used for number
/// grouping/decimals) are combined, so screens do not each re-derive them.
///
/// The root `App` rebuilds on both locale and unit changes, so a formatter
/// obtained during `build` is always current.
extension ActivityStatsFormatterScope on BuildContext {
  /// The device's locale, including its region subtag.
  ///
  /// Deliberately NOT `Localizations.localeOf`: that returns the app's
  /// *resolved* locale, which is language-only (`en`, `pt`, ...) because the
  /// supported-locale list carries no regions. Resolving `en-US` against it
  /// yields plain `en`, so region-based defaults would never trigger. The
  /// platform locale keeps the region the OS reported.
  Locale get deviceLocale => View.of(this).platformDispatcher.locale;

  /// The unit system to display: the user's explicit choice when set,
  /// otherwise the convention of the device region.
  ///
  /// Falls back to the device-region default when there is no [AppScope]
  /// ancestor, so a widget rendered in isolation (previews, widget tests) still
  /// formats correctly instead of throwing.
  MeasurementSystem get measurementSystem {
    final services = AppScope.maybeServicesOf(this, listen: false);
    return services?.measurementSystemController.resolve(deviceLocale) ??
        MeasurementSystem.forLocale(deviceLocale);
  }

  /// A formatter bound to the active locale and unit preference.
  ActivityStatsFormatter get statsFormatter {
    return ActivityStatsFormatter.of(
      AppLocalizations.of(this)!,
      system: measurementSystem,
    );
  }

  /// The BCP 47 tag used for number formatting (grouping and decimals).
  String get numberFormatLocale => Localizations.localeOf(this).toLanguageTag();
}
