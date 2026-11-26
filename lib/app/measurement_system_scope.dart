import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:flutter/widgets.dart';

/// Provides the unit preference to the widget tree.
///
/// An [InheritedNotifier] so that a units change rebuilds only the widgets that
/// read [of], instead of the whole app and its router.
class MeasurementSystemScope
    extends InheritedNotifier<MeasurementSystemController> {
  const MeasurementSystemScope({
    super.key,
    required MeasurementSystemController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The unit system to display for [context], registering [context] as a
  /// dependant so it rebuilds when the preference changes.
  ///
  /// Falls back to the device region's default when there is no scope, so a
  /// widget rendered in isolation (previews, widget tests) still formats
  /// correctly instead of throwing.
  ///
  /// The device locale is passed rather than read from [Localizations], which
  /// resolves to a language-only locale (see the `ActivityStatsFormatterScope` extension).
  ///
  /// Pass `listen: false` from event handlers, which need the current value
  /// but must not register a rebuild dependency.
  static MeasurementSystem of(
    BuildContext context,
    Locale deviceLocale, {
    bool listen = true,
  }) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<MeasurementSystemScope>()
        : context.getInheritedWidgetOfExactType<MeasurementSystemScope>();
    return scope?.notifier?.resolve(deviceLocale) ??
        MeasurementSystem.forLocale(deviceLocale);
  }
}
