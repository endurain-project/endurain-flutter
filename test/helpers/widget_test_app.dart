import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// A [MaterialApp] test harness with the app's localization delegates.
///
/// Screens take their dependencies through constructors, so a test passes
/// fakes straight to the widget under test; the harness only supplies what a
/// real app would around it.
class TestMaterialApp extends StatelessWidget {
  const TestMaterialApp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class TestScaffoldApp extends StatelessWidget {
  const TestScaffoldApp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TestMaterialApp(child: Scaffold(body: child));
  }
}
