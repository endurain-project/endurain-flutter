import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A [MaterialApp] test harness that provides an [AppScope] so screens which
/// read services from the scope work without a global fallback.
///
/// A fresh [AppServices] is created when none is supplied. Services are lazy, so
/// only what the widget under test touches is ever built.
class TestMaterialApp extends StatefulWidget {
  const TestMaterialApp({super.key, required this.child, this.services});

  final Widget child;

  /// Optional services for the provided [AppScope]. Supply a purpose-built
  /// instance when a test needs to observe or stub composition-root services.
  final AppServices? services;

  @override
  State<TestMaterialApp> createState() => _TestMaterialAppState();
}

class _TestMaterialAppState extends State<TestMaterialApp> {
  late final AppServices _services = widget.services ?? AppServices();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget.child,
      ),
    );
  }
}

class TestScaffoldApp extends StatelessWidget {
  const TestScaffoldApp({super.key, required this.child, this.services});

  final Widget child;
  final AppServices? services;

  @override
  Widget build(BuildContext context) {
    return TestMaterialApp(services: services, child: Scaffold(body: child));
  }
}

/// Provides an [AppScope] around [child] without imposing a `MaterialApp`.
///
/// Use inside a bare `AdaptiveApp`/`MaterialApp` `home:` when a screen reads
/// services from the scope but the test drives the app wrapper itself (e.g.
/// adaptive-platform screen tests). A fresh [AppServices] is created when none
/// is supplied; services are lazy, so only what the screen touches is built.
class TestAppScope extends StatefulWidget {
  const TestAppScope({super.key, required this.child, this.services});

  final Widget child;
  final AppServices? services;

  @override
  State<TestAppScope> createState() => _TestAppScopeState();
}

class _TestAppScopeState extends State<TestAppScope> {
  late final AppServices _services = widget.services ?? AppServices();

  @override
  Widget build(BuildContext context) {
    return AppScope(services: _services, child: widget.child);
  }
}
