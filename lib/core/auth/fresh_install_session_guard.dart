import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:flutter/foundation.dart';

/// Signs a reinstalled iOS app out.
///
/// iOS keeps keychain items when an app is uninstalled, so a reinstall would
/// otherwise start signed in with the previous account. Preferences are
/// removed on uninstall, which is what tells the two cases apart (see
/// [AppPreferencesStore.isFreshInstall]): an upgrade keeps its preferences and
/// is never signed out.
///
/// Run it before anything reads the session. Other platforms do nothing: the
/// Android keystore data goes with the app.
class FreshInstallSessionGuard {
  FreshInstallSessionGuard({
    required AppPreferencesStore preferences,
    required SecureStorageService secureStorage,
    TargetPlatform? platform,
  }) : _preferences = preferences,
       _secureStorage = secureStorage,
       _platform = platform;

  final AppPreferencesStore _preferences;
  final SecureStorageService _secureStorage;
  final TargetPlatform? _platform;

  /// Wipes secure storage on the first launch of a fresh iOS install, then
  /// records the install. Returns whether the wipe happened.
  Future<bool> run() async {
    if ((_platform ?? defaultTargetPlatform) != TargetPlatform.iOS) {
      return false;
    }
    var wiped = false;
    if (await _preferences.isFreshInstall()) {
      // When the wipe fails the error propagates and the marker is not
      // written, so the next launch tries again.
      await _secureStorage.resetAll();
      wiped = true;
    }
    await _preferences.markInstalled();
    return wiped;
  }
}
