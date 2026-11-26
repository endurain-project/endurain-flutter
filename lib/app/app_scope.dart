import 'package:endurain/app/app_services.dart';
import 'package:flutter/widgets.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices servicesOf(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getElementForInheritedWidgetOfExactType<AppScope>()?.widget
              as AppScope?;

    // Only composition code under `lib/app` reads this; feature code gets what
    // it needs through constructors. A missing scope is a wiring bug, so fail
    // loudly rather than silently reaching for a global.
    if (scope == null) {
      throw FlutterError(
        'AppScope.servicesOf() was called with a context that has no AppScope '
        'ancestor. The root App provides an AppScope in production; wrap the '
        'widget under test in one (the widget test harness does this).',
      );
    }
    return scope.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return services != oldWidget.services;
  }
}
