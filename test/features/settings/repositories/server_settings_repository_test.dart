import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('ServerSettingsRepository', () {
    test('loads the stored server and user', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');
      await storage.setUsername('joao');

      final repository = ServerSettingsRepository(
        storage: storage,
        authService: AuthService(storage: storage),
      );

      final settings = await repository.loadSettings();

      expect(settings.serverUrl, 'https://endurain.example.test');
      expect(settings.username, 'joao');
    });
  });
}
