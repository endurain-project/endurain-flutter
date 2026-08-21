import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';

class AdaptiveTab {
  const AdaptiveTab({
    required this.routeName,
    required this.label,
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.builder,
  });

  final String routeName;
  final String label;
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final WidgetBuilder builder;
}

class AdaptiveBottomNavigation extends StatefulWidget {
  const AdaptiveBottomNavigation({super.key, required this.tabs});

  final List<AdaptiveTab> tabs;

  @override
  State<AdaptiveBottomNavigation> createState() =>
      _AdaptiveBottomNavigationState();
}

class _AdaptiveBottomNavigationState extends State<AdaptiveBottomNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          height: UIConstants.tabBarHeight,
          items: [
            for (final tab in widget.tabs)
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: UIConstants.paddingSmall),
                  child: Icon(tab.cupertinoIcon),
                ),
                label: tab.label,
              ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) => widget.tabs[index].builder(context),
          );
        },
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (final tab in widget.tabs)
            KeyedSubtree(
              key: PageStorageKey(tab.routeName),
              child: tab.builder(context),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          for (final tab in widget.tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.materialIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
