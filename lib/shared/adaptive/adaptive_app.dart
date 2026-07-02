import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/theme/app_theme.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/l10n/app_localizations.dart';

class AdaptiveApp extends StatelessWidget {
  /// Hosts a single [home] widget (used by tests and simple, non-routed apps).
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

  @override
  Widget build(BuildContext context) {
    final router = routerConfig;
    if (PlatformUtils.isApplePlatform) {
      Widget cupertinoBuilder(BuildContext context, Widget? child) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        return CupertinoTheme(
          data: brightness == Brightness.dark
              ? AppTheme.cupertinoDarkTheme
              : AppTheme.cupertinoLightTheme,
          child: child!,
        );
      }

      if (router != null) {
        return CupertinoApp.router(
          title: title,
          theme: AppTheme.cupertinoLightTheme,
          builder: cupertinoBuilder,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          localeListResolutionCallback: appLocaleListResolution,
          routerConfig: router,
        );
      }

      return CupertinoApp(
        title: title,
        theme: AppTheme.cupertinoLightTheme,
        builder: cupertinoBuilder,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        localeListResolutionCallback: appLocaleListResolution,
        home: home,
      );
    }

    if (router != null) {
      return MaterialApp.router(
        title: title,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        localeListResolutionCallback: appLocaleListResolution,
        routerConfig: router,
      );
    }

    return MaterialApp(
      title: title,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      localeListResolutionCallback: appLocaleListResolution,
      home: home,
    );
  }
}
