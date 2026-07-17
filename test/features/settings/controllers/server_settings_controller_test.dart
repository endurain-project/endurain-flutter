import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/features/settings/controllers/server_settings_controller.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerSettingsController', () {
    StoredServerSettings settingsFor({
      String? serverUrl = 'https://endurain.example.test',
      String? username = 'joao',
      String tileServerUrl = 'https://tiles.example.test/{z}/{x}/{y}.png',
    }) {
      return StoredServerSettings(
        serverUrl: serverUrl,
        username: username,
        tileServerUrl: tileServerUrl,
      );
    }

    ServerSettingsController controllerFor(
      _FakeServerSettingsRepository repository, {
      AppConfig config = AppConfig.defaults,
    }) {
      return ServerSettingsController(repository: repository, config: config);
    }

    test('starts in the loading state before load runs', () {
      final controller = controllerFor(
        _FakeServerSettingsRepository(settings: settingsFor()),
      );
      addTearDown(controller.dispose);

      expect(controller.isLoading, isTrue);
      expect(controller.serverUrl, isNull);
      expect(controller.username, isNull);
      expect(controller.tileServerUrl, isEmpty);
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
      expect(
        controller.tileServerUrl,
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
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

    group('evaluateTileHost', () {
      test('allows an empty or hostless tile URL', () async {
        final controller = controllerFor(
          _FakeServerSettingsRepository(settings: settingsFor()),
        );
        addTearDown(controller.dispose);
        await controller.load();

        expect(controller.evaluateTileHost(''), TileServerHostDecision.allowed);
        expect(
          controller.evaluateTileHost('/relative/{z}/{x}/{y}.png'),
          TileServerHostDecision.allowed,
        );
      });

      test('allows a tile host equal to the server host', () async {
        final controller = controllerFor(
          _FakeServerSettingsRepository(settings: settingsFor()),
        );
        addTearDown(controller.dispose);
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://endurain.example.test/tiles/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.allowed,
        );
      });

      test('needs confirmation for a different tile host', () async {
        final controller = controllerFor(
          _FakeServerSettingsRepository(settings: settingsFor()),
        );
        addTearDown(controller.dispose);
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://tiles.other.test/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.needsConfirmation,
        );
      });

      test('allows any host when no server host is configured', () async {
        final controller = controllerFor(
          _FakeServerSettingsRepository(settings: settingsFor(serverUrl: null)),
        );
        addTearDown(controller.dispose);
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://tiles.other.test/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.allowed,
        );
      });

      test('blocks a host outside the managed allowlist', () async {
        final controller = controllerFor(
          _FakeServerSettingsRepository(settings: settingsFor()),
          config: const AppConfig(
            allowedTileServerHosts: {'endurain.example.test'},
          ),
        );
        addTearDown(controller.dispose);
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://not-allowed.test/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.blocked,
        );
      });

      test('allows an allowlisted host that also matches the server', () async {
        final controller = controllerFor(
          _FakeServerSettingsRepository(settings: settingsFor()),
          config: const AppConfig(
            allowedTileServerHosts: {'endurain.example.test'},
          ),
        );
        addTearDown(controller.dispose);
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://endurain.example.test/tiles/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.allowed,
        );
      });
    });

    test('saveTileServerUrl delegates to the repository', () async {
      final repository = _FakeServerSettingsRepository(settings: settingsFor());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);

      await controller.saveTileServerUrl(
        'https://tiles.new.test/{z}/{x}/{y}.png',
      );

      expect(repository.savedUrls, ['https://tiles.new.test/{z}/{x}/{y}.png']);
    });

    test('saveTileServerUrl propagates a repository error', () async {
      final repository = _FakeServerSettingsRepository(
        settings: settingsFor(),
        saveError: StateError('boom'),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);

      await expectLater(
        controller.saveTileServerUrl('https://tiles.new.test/{z}/{x}/{y}.png'),
        throwsA(isA<StateError>()),
      );
      expect(repository.savedUrls, isEmpty);
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
    this.saveError,
  });

  final StoredServerSettings settings;
  final bool logoutResult;
  final Object? saveError;
  final List<String> savedUrls = <String>[];
  int logoutCallCount = 0;

  @override
  Future<StoredServerSettings> loadSettings() async => settings;

  @override
  Future<void> saveTileServerUrl(String url) async {
    final error = saveError;
    if (error != null) {
      throw error;
    }
    savedUrls.add(url);
  }

  @override
  Future<bool> logout() async {
    logoutCallCount++;
    return logoutResult;
  }
}
