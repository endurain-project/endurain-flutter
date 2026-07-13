import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';

void main() {
  const originA = 'https://a.example';
  const originB = 'https://b.example';
  TestWidgetsFlutterBinding.ensureInitialized();
  const profileA = 'profile-a';
  const profileB = 'profile-b';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  HealthSyncSettingsRepository makeRepo() =>
      HealthSyncSettingsRepository(storage: SecureStorageService());

  group('HealthSyncSettingsRepository', () {
    group('isConnected', () {
      test('defaults to false when no value is stored', () async {
        final repo = makeRepo();
        expect(await repo.isConnected(profileA), isFalse);
      });

      test('setConnected round-trips', () async {
        final repo = makeRepo();
        await repo.setConnected(profileA, true);
        expect(await repo.isConnected(profileA), isTrue);
        expect(await repo.isConnected(profileB), isFalse);
        await repo.setConnected(profileA, false);
        expect(await repo.isConnected(profileA), isFalse);
      });
    });

    group('isAutoSyncOnResumeEnabled', () {
      test('defaults to false when no value is stored', () async {
        final repo = makeRepo();
        expect(await repo.isAutoSyncOnResumeEnabled(originA), isFalse);
      });

      test('setAutoSyncOnResumeEnabled round-trips', () async {
        final repo = makeRepo();
        await repo.setAutoSyncOnResumeEnabled(originA, true);
        expect(await repo.isAutoSyncOnResumeEnabled(originA), isTrue);
        expect(await repo.isAutoSyncOnResumeEnabled(originB), isFalse);
        await repo.setAutoSyncOnResumeEnabled(originA, false);
        expect(await repo.isAutoSyncOnResumeEnabled(originA), isFalse);
      });
    });
  });
}
