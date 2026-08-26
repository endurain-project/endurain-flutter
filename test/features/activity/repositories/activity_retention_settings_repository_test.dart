import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = ActivityRetentionSettingsRepository.retainUploadedGpxKey;

  group('ActivityRetentionSettingsRepository', () {
    test('missing value returns true (retain by default)', () async {
      final repo = ActivityRetentionSettingsRepository(
        preferences: FakePreferencesStore(),
      );
      expect(await repo.isRetainUploadedGpxEnabled(), isTrue);
    });

    test('persisted true returns true', () async {
      final prefs = FakePreferencesStore();
      await prefs.write(key: key, value: 'true');
      final repo = ActivityRetentionSettingsRepository(preferences: prefs);
      expect(await repo.isRetainUploadedGpxEnabled(), isTrue);
    });

    test('persisted false returns false', () async {
      final prefs = FakePreferencesStore();
      await prefs.write(key: key, value: 'false');
      final repo = ActivityRetentionSettingsRepository(preferences: prefs);
      expect(await repo.isRetainUploadedGpxEnabled(), isFalse);
    });

    test('setter writes values that can be read back', () async {
      final repo = ActivityRetentionSettingsRepository(
        preferences: FakePreferencesStore(),
      );

      await repo.setRetainUploadedGpxEnabled(false);
      expect(await repo.isRetainUploadedGpxEnabled(), isFalse);

      await repo.setRetainUploadedGpxEnabled(true);
      expect(await repo.isRetainUploadedGpxEnabled(), isTrue);
    });
  });
}
