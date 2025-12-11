import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:endurain/core/theme/app_theme.dart';
import 'package:endurain/shared/widgets/app_bottom_nav.dart';
import 'package:endurain/features/auth/login_screen.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/utils/platform_utils.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _storage = SecureStorageService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await _storage.isAuthenticated();
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading screen while checking authentication
      return PlatformUtils.isApplePlatform
          ? const CupertinoApp(
              home: Center(child: CupertinoActivityIndicator()),
            )
          : const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
    }

    // Use Cupertino on iOS/macOS, Material on Android
    if (PlatformUtils.isApplePlatform) {
      return CupertinoApp(
        title: 'Endurain',
        theme: AppTheme.cupertinoLightTheme,
        // Cupertino automatically switches to dark theme based on system settings
        // when we provide a dark theme with matching brightness
        builder: (context, child) {
          final brightness = MediaQuery.platformBrightnessOf(context);
          return CupertinoTheme(
            data: brightness == Brightness.dark
                ? AppTheme.cupertinoDarkTheme
                : AppTheme.cupertinoLightTheme,
            child: child!,
          );
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('pt')],
        home: _isAuthenticated
            ? AppBottomNav(onLogout: _onLogout)
            : LoginScreen(onLoginSuccess: _onLoginSuccess),
      );
    } else {
      return MaterialApp(
        title: 'Endurain',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('pt')],
        home: _isAuthenticated
            ? AppBottomNav(onLogout: _onLogout)
            : LoginScreen(onLoginSuccess: _onLoginSuccess),
      );
    }
  }
}
