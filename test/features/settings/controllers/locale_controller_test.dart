import 'dart:ui';

import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  group('LocaleController', () {
    late FakePreferencesStore preferences;
    late LocaleController controller;

    setUp(() {
      preferences = FakePreferencesStore();
      controller = LocaleController(
        repository: LocaleSettingsRepository(preferences: preferences),
      );
    });

    tearDown(() => controller.dispose());

    test('starts unloaded and follows the system locale', () {
      expect(controller.locale, isNull);
      expect(controller.isLoaded, isFalse);
    });

    test('load reads the persisted locale', () async {
      await preferences.write(key: 'app_locale', value: 'pt');

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.locale?.languageCode, 'pt');
    });

    test('setLocale updates, notifies, and persists', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLocale(const Locale('pt'));

      expect(controller.locale, const Locale('pt'));
      expect(notifications, 1);
      expect(await preferences.read(key: 'app_locale'), 'pt');
    });

    test('setLocale to the current value is a no-op', () async {
      await controller.setLocale(const Locale('en'));
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLocale(const Locale('en'));

      expect(notifications, 0);
    });

    test('setLocale(null) clears the persisted preference', () async {
      await controller.setLocale(const Locale('pt'));

      await controller.setLocale(null);

      expect(controller.locale, isNull);
      expect(await preferences.read(key: 'app_locale'), isNull);
    });

    test('load falls back to the system locale on a read error', () async {
      final failing = LocaleController(repository: _ThrowingRepository());
      addTearDown(failing.dispose);

      await failing.load();

      expect(failing.isLoaded, isTrue);
      expect(failing.locale, isNull);
    });
  });
}

class _ThrowingRepository implements LocaleSettingsRepository {
  @override
  Future<Locale?> getLocale() async => throw StateError('boom');

  @override
  Future<void> setLocale(Locale? locale) async {}
}
