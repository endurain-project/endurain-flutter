import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/navigation/app_routes.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/features/map/screens/map_screen.dart';
import 'package:endurain/features/settings/screens/settings_screen.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    this.onLogout,
    this.isGuest = false,
    this.onSignIn,
  });

  final VoidCallback? onLogout;

  /// Whether the app is running in local-only guest mode (no server session).
  final bool isGuest;

  /// Invoked from Settings when a guest wants to connect a server / sign in.
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveBottomNavigation(
      tabs: [
        AdaptiveTab(
          routeName: AppRoutes.map,
          label: l10n.mapTab,
          materialIcon: Icons.map,
          cupertinoIcon: CupertinoIcons.map,
          builder: (context) => const MapScreen(),
        ),
        AdaptiveTab(
          routeName: AppRoutes.settings,
          label: l10n.settingsTab,
          materialIcon: Icons.settings,
          cupertinoIcon: CupertinoIcons.settings,
          builder: (context) => SettingsScreen(
            onLogout: onLogout,
            isGuest: isGuest,
            onSignIn: onSignIn,
          ),
        ),
      ],
    );
  }
}
