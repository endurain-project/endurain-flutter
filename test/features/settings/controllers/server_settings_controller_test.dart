import 'package:endurain/features/settings/controllers/server_settings_controller.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerSettingsController', () {
    StoredServerSettings settingsFor({
      String? serverUrl = 'https://endurain.example.test',
      String? username = 'joao',
    }) {
      return StoredServerSettings(serverUrl: serverUrl, username: username);
    }

    ServerSettingsController controllerFor(
      _FakeServerSettingsRepository repository,
    ) {
      return ServerSettingsController(repository: repository);
    }

    test('starts in the loading state before load runs', () {
      final controller = controllerFor(
        _FakeServerSettingsRepository(settings: settingsFor()),
      );
      addTearDown(controller.dispose);

      expect(controller.isLoading, isTrue);
      expect(controller.serverUrl, isNull);
      expect(controller.username, isNull);
    });

    test('load populates state and toggles loading, notifying twice', () async {
      final controller = controllerFor(
        _FakeServerSettingsRepository(settings: settingsFor()),
      );
      addTearDown(controller.dispose);
      final loadingStates = <bool>[];
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.load();

      expect(loadingStates, [true, false]);
      expect(controller.isLoading, isFalse);
      expect(controller.serverUrl, 'https://endurain.example.test');
      expect(controller.username, 'joao');
    });

    test('load preserves null account fields', () async {
      final controller = controllerFor(
        _FakeServerSettingsRepository(
          settings: settingsFor(serverUrl: null, username: null),
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.serverUrl, isNull);
      expect(controller.username, isNull);
    });

    test('logout delegates and returns the repository result', () async {
      final repository = _FakeServerSettingsRepository(
        settings: settingsFor(),
        logoutResult: false,
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);

      final result = await controller.logout();

      expect(result, isFalse);
      expect(repository.logoutCallCount, 1);
    });
  });
}

class _FakeServerSettingsRepository implements ServerSettingsRepository {
  _FakeServerSettingsRepository({
    required this.settings,
    this.logoutResult = true,
  });

  final StoredServerSettings settings;
  final bool logoutResult;
  int logoutCallCount = 0;

  @override
  Future<StoredServerSettings> loadSettings() async => settings;

  @override
  Future<bool> logout() async {
    logoutCallCount++;
    return logoutResult;
  }
}
