import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('ActivityRetentionSettingsRepository', () {
    test('missing value returns true (retain by default)', () async {
      final repo = ActivityRetentionSettingsRepository(
        storage: SecureStorageService(),
      );
      expect(await repo.isRetainUploadedGpxEnabled(), isTrue);
    });

    test('persisted true returns true', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        ActivityRetentionSettingsRepository.retainUploadedGpxKey: 'true',
      });
      final repo = ActivityRetentionSettingsRepository(
        storage: SecureStorageService(),
      );
      expect(await repo.isRetainUploadedGpxEnabled(), isTrue);
    });

    test('persisted false returns false', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        ActivityRetentionSettingsRepository.retainUploadedGpxKey: 'false',
      });
      final repo = ActivityRetentionSettingsRepository(
        storage: SecureStorageService(),
      );
      expect(await repo.isRetainUploadedGpxEnabled(), isFalse);
    });

    test('setter writes values that can be read back', () async {
      final repo = ActivityRetentionSettingsRepository(
        storage: SecureStorageService(),
      );

      await repo.setRetainUploadedGpxEnabled(false);
      expect(await repo.isRetainUploadedGpxEnabled(), isFalse);

      await repo.setRetainUploadedGpxEnabled(true);
      expect(await repo.isRetainUploadedGpxEnabled(), isTrue);
    });
  });
}
