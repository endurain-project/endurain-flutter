import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/app/navigation/app_routes.dart';
import 'package:endurain/core/diagnostics/diagnostics_scope.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.mapTab,
    required this.settingsTab,
  });

  /// Builds the map tab's screen.
  final WidgetBuilder mapTab;

  /// Builds the settings tab's screen.
  final WidgetBuilder settingsTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveBottomNavigation(
      onTabChanged: (tab) => DiagnosticsScope.of(context).recordBreadcrumbSync(
        DiagnosticsEvents.navigationTabChanged,
        details: {'tab': tab},
      ),
      tabs: [
        AdaptiveTab(
          routeName: AppRoutes.map,
          label: l10n.mapTab,
          materialIcon: Icons.map,
          cupertinoIcon: CupertinoIcons.map,
          builder: mapTab,
        ),
        AdaptiveTab(
          routeName: AppRoutes.settings,
          label: l10n.settingsTab,
          materialIcon: Icons.settings,
          cupertinoIcon: CupertinoIcons.settings,
          builder: settingsTab,
        ),
      ],
    );
  }
}
