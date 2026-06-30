import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('ServerSettingsRepository', () {
    test('loads stored server, user, and map settings', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'server_settings_repo_test_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');
      await storage.setUsername('joao');

      final prefs = AppPreferencesStore(
        supportDirectoryProvider: () async => tempDir,
      );
      final mapSettings = MapSettingsRepository(preferences: prefs);
      await mapSettings.saveTileServerUrl(
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );

      final repository = ServerSettingsRepository(
        storage: storage,
        authService: AuthService(storage: storage),
        mapSettingsRepository: mapSettings,
      );

      final settings = await repository.loadSettings();

      expect(settings.serverUrl, 'https://endurain.example.test');
      expect(settings.username, 'joao');
      expect(
        settings.tileServerUrl,
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
    });
  });
}
