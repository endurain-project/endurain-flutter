import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/utils/scoped_storage_key.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const profileA = 'profile-a';
  const profileB = 'profile-b';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  HealthSyncSettingsRepository makeRepo() => HealthSyncSettingsRepository(
    preferences: FakePreferencesStore(),
    storage: SecureStorageService(),
  );

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

      test('ignores a connected marker restored through preferences', () async {
        final preferences = FakePreferencesStore();
        await preferences.write(
          key: scopedStorageKey('health_connected', profileA),
          value: 'true',
        );
        final repo = HealthSyncSettingsRepository(
          preferences: preferences,
          storage: SecureStorageService(),
        );

        expect(await repo.isConnected(profileA), isFalse);
      });
    });

    group('isAutoSyncEnabled', () {
      test('defaults to false when no value is stored', () async {
        final repo = makeRepo();
        expect(await repo.isAutoSyncEnabled(profileA), isFalse);
      });

      test('setAutoSyncEnabled round-trips', () async {
        final repo = makeRepo();
        await repo.setAutoSyncEnabled(profileA, true);
        expect(await repo.isAutoSyncEnabled(profileA), isTrue);
        expect(await repo.isAutoSyncEnabled(profileB), isFalse);
        await repo.setAutoSyncEnabled(profileA, false);
        expect(await repo.isAutoSyncEnabled(profileA), isFalse);
      });
    });

    test('clearForProfile removes both settings for that profile', () async {
      final repo = makeRepo();
      await repo.setConnected(profileA, true);
      await repo.setAutoSyncEnabled(profileA, true);
      await repo.setConnected(profileB, true);

      await repo.clearForProfile(profileA);

      expect(await repo.isConnected(profileA), isFalse);
      expect(await repo.isAutoSyncEnabled(profileA), isFalse);
      expect(await repo.isConnected(profileB), isTrue);
    });

    test('the workout changes token is kept per profile', () async {
      final repo = makeRepo();
      expect(await repo.workoutChangesToken(profileA), isNull);

      await repo.setWorkoutChangesToken(profileA, 'token-a');

      expect(await repo.workoutChangesToken(profileA), 'token-a');
      expect(await repo.workoutChangesToken(profileB), isNull);
    });

    test('clearForProfile removes the workout changes token', () async {
      final repo = makeRepo();
      await repo.setWorkoutChangesToken(profileA, 'token-a');
      await repo.setWorkoutChangesToken(profileB, 'token-b');

      await repo.clearForProfile(profileA);

      expect(await repo.workoutChangesToken(profileA), isNull);
      expect(await repo.workoutChangesToken(profileB), 'token-b');
    });
  });

  group('moveProfile', () {
    test('moves both settings and removes the old ones', () async {
      final repo = makeRepo();
      await repo.setConnected(profileA, true);
      await repo.setAutoSyncEnabled(profileA, true);

      await repo.moveProfile(fromProfileId: profileA, toProfileId: profileB);

      expect(await repo.isConnected(profileB), isTrue);
      expect(await repo.isAutoSyncEnabled(profileB), isTrue);
      expect(await repo.isConnected(profileA), isFalse);
      expect(await repo.isAutoSyncEnabled(profileA), isFalse);
    });

    test('keeps a value the target already has', () async {
      final repo = makeRepo();
      await repo.setAutoSyncEnabled(profileA, true);
      await repo.setAutoSyncEnabled(profileB, false);

      await repo.moveProfile(fromProfileId: profileA, toProfileId: profileB);

      expect(await repo.isAutoSyncEnabled(profileB), isFalse);
    });

    test('is a no-op when there is nothing to move', () async {
      final repo = makeRepo();
      await repo.moveProfile(fromProfileId: profileA, toProfileId: profileB);
      expect(await repo.isConnected(profileB), isFalse);
      expect(await repo.isAutoSyncEnabled(profileB), isFalse);
    });
  });
}
