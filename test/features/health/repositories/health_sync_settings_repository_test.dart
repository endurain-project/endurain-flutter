import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const profileA = 'profile-a';
  const profileB = 'profile-b';

  HealthSyncSettingsRepository makeRepo() =>
      HealthSyncSettingsRepository(preferences: FakePreferencesStore());

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
        expect(await repo.isAutoSyncOnResumeEnabled(profileA), isFalse);
      });

      test('setAutoSyncOnResumeEnabled round-trips', () async {
        final repo = makeRepo();
        await repo.setAutoSyncOnResumeEnabled(profileA, true);
        expect(await repo.isAutoSyncOnResumeEnabled(profileA), isTrue);
        expect(await repo.isAutoSyncOnResumeEnabled(profileB), isFalse);
        await repo.setAutoSyncOnResumeEnabled(profileA, false);
        expect(await repo.isAutoSyncOnResumeEnabled(profileA), isFalse);
      });
    });

    test('clearForProfile removes both settings for that profile', () async {
      final repo = makeRepo();
      await repo.setConnected(profileA, true);
      await repo.setAutoSyncOnResumeEnabled(profileA, true);
      await repo.setConnected(profileB, true);

      await repo.clearForProfile(profileA);

      expect(await repo.isConnected(profileA), isFalse);
      expect(await repo.isAutoSyncOnResumeEnabled(profileA), isFalse);
      expect(await repo.isConnected(profileB), isTrue);
    });
  });
}
