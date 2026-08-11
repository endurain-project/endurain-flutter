import 'package:flutter/widgets.dart';
import 'package:endurain/core/services/app_services.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices servicesOf(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getElementForInheritedWidgetOfExactType<AppScope>()?.widget
              as AppScope?;

    // Production widgets are always built under the root [AppScope] (provided by
    // `App`), and the widget test harness provides one too. A missing scope is a
    // wiring bug, so fail loudly rather than silently reaching for a global.
    if (scope == null) {
      throw FlutterError(
        'AppScope.servicesOf() was called with a context that has no AppScope '
        'ancestor. The root App provides an AppScope in production; wrap the '
        'widget under test in one (the widget test harness does this).',
      );
    }
    return scope.services;
  }

  /// Returns the ambient [AppServices], or `null` when there is no [AppScope].
  ///
  /// Unlike [servicesOf] this never throws. Use it **only** for optional,
  /// non-load-bearing lookups that have a correct fallback without services —
  /// e.g. resolving the display unit preference, where falling back to the
  /// locale default is right and crashing the widget is not. Anything that
  /// genuinely needs a service must use [servicesOf] so a wiring bug still
  /// fails loudly.
  static AppServices? maybeServicesOf(
    BuildContext context, {
    bool listen = true,
  }) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getElementForInheritedWidgetOfExactType<AppScope>()?.widget
              as AppScope?;
    return scope?.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return services != oldWidget.services;
  }
}
