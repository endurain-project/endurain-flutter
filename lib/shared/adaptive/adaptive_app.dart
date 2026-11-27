import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/theme/app_theme.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class AdaptiveApp extends StatelessWidget {
  /// Hosts a single [home] widget. Production uses [AdaptiveApp.router]; this
  /// constructor exists for widget tests.
  @visibleForTesting
  const AdaptiveApp({
    super.key,
    required this.title,
    required this.home,
    this.locale,
  }) : routerConfig = null;

  /// Hosts a declarative [routerConfig] (e.g. a `GoRouter`) so the app gets
  /// auth-guarded, deep-link-ready navigation. Used by the production root.
  const AdaptiveApp.router({
    super.key,
    required this.title,
    required this.routerConfig,
    this.locale,
  }) : home = null;

  final String title;
  final Widget? home;
  final RouterConfig<Object>? routerConfig;

  /// The active locale, or `null` to follow the system locale. Resolved
  /// against [appSupportedLocales] via [appLocaleListResolution] by the
  /// underlying app widget, so any Portuguese variant maps to `pt-PT`.
  final Locale? locale;

  /// Applies the app's Material and Cupertino themes for the current platform
  /// brightness, so widgets of either design system resolve their own theme.
  static Widget _cupertinoBuilder(BuildContext context, Widget? child) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Theme(
      data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: CupertinoTheme(
        data: isDark
            ? AppTheme.cupertinoDarkTheme
            : AppTheme.cupertinoLightTheme,
        child: child!,
      ),
    );
  }

  // The app widgets expose `home` and `router` through separate constructors
  // (they cannot be spread from a shared argument list), so the router/home
  // choice is a single conditional per platform.
  @override
  Widget build(BuildContext context) {
    final router = routerConfig;
    if (PlatformUtils.isApplePlatform) {
      return router != null
          ? CupertinoApp.router(
              title: title,
              theme: AppTheme.cupertinoLightTheme,
              builder: _cupertinoBuilder,
              locale: locale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: appSupportedLocales,
              localeListResolutionCallback: appLocaleListResolution,
              routerConfig: router,
            )
          : CupertinoApp(
              title: title,
              theme: AppTheme.cupertinoLightTheme,
              builder: _cupertinoBuilder,
              locale: locale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: appSupportedLocales,
              localeListResolutionCallback: appLocaleListResolution,
              home: home,
            );
    }
    return router != null
        ? MaterialApp.router(
            title: title,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: locale,
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: appSupportedLocales,
            localeListResolutionCallback: appLocaleListResolution,
            routerConfig: router,
          )
        : MaterialApp(
            title: title,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: locale,
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: appSupportedLocales,
            localeListResolutionCallback: appLocaleListResolution,
            home: home,
          );
  }
}
