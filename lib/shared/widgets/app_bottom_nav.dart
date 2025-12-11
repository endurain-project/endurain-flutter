import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/features/map/map_screen.dart';
import 'package:endurain/features/settings/settings_screen.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/constants/ui_constants.dart';

class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const MapScreen(),
    SettingsScreen(onLogout: widget.onLogout),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Use Cupertino tab bar on iOS/macOS
    if (PlatformUtils.isApplePlatform) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          height: UIConstants.tabBarHeight,
          items: [
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(top: UIConstants.paddingSmall),
                child: Icon(CupertinoIcons.map),
              ),
              label: l10n.mapTab,
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(top: UIConstants.paddingSmall),
                child: Icon(CupertinoIcons.settings),
              ),
              label: l10n.settingsTab,
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(builder: (context) => _screens[index]);
        },
      );
    }

    // Use Material bottom navigation on Android
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: l10n.mapTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
