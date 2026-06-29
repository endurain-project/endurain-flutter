import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaults match self-hosted behavior', () {
      const config = AppConfig.defaults;
      expect(config.apiBasePath, AppConfig.defaultApiBasePath);
      expect(config.transportMode, AppTransportMode.selfHosted);
      expect(config.allowInsecureTransport, isTrue);
    });

    test('managed mode has allowInsecureTransport false', () {
      const config = AppConfig(transportMode: AppTransportMode.managed);
      expect(config.transportMode, AppTransportMode.managed);
      expect(config.allowInsecureTransport, isFalse);
    });

    test('custom apiBasePath is preserved', () {
      const config = AppConfig(
        apiBasePath: '/api/v2',
        transportMode: AppTransportMode.managed,
      );
      expect(config.apiBasePath, '/api/v2');
      expect(config.allowInsecureTransport, isFalse);
    });

    test('defaultApiBasePath is /api/v1', () {
      expect(AppConfig.defaultApiBasePath, '/api/v1');
    });

    group('isTileServerHostAllowed', () {
      test('returns true for any host when allowedTileServerHosts is null', () {
        const config = AppConfig.defaults;
        expect(config.isTileServerHostAllowed('tiles.example.com'), isTrue);
        expect(config.isTileServerHostAllowed('any.host.test'), isTrue);
      });

      test('returns true for hosts in the allowlist', () {
        const config = AppConfig(
          allowedTileServerHosts: {'tiles.example.com', 'maps.example.com'},
        );
        expect(config.isTileServerHostAllowed('tiles.example.com'), isTrue);
        expect(config.isTileServerHostAllowed('maps.example.com'), isTrue);
      });

      test('returns false for hosts not in the allowlist', () {
        const config = AppConfig(allowedTileServerHosts: {'tiles.example.com'});
        expect(config.isTileServerHostAllowed('other.host.test'), isFalse);
      });
    });

    group('allowInsecureTransportFor', () {
      test('follows the self-hosted policy when no cloud origin is set', () {
        const config = AppConfig.defaults;
        expect(config.allowInsecureTransportFor('http://local.test'), isTrue);
        expect(config.allowInsecureTransportFor('https://local.test'), isTrue);
      });

      test('follows the managed policy when no cloud origin is set', () {
        const config = AppConfig(transportMode: AppTransportMode.managed);
        expect(config.allowInsecureTransportFor('http://local.test'), isFalse);
      });

      test('always rejects http to the managed cloud origin', () {
        const config = AppConfig(cloudBaseUrl: 'https://app.endurain.test');
        // Self-hosted build, but the managed origin must stay strict.
        expect(config.transportMode, AppTransportMode.selfHosted);
        expect(
          config.allowInsecureTransportFor('http://app.endurain.test'),
          isFalse,
        );
      });

      test('still allows http to self-hosted origins when cloud is set', () {
        const config = AppConfig(cloudBaseUrl: 'https://app.endurain.test');
        expect(
          config.allowInsecureTransportFor('http://my-nas.local:8080'),
          isTrue,
        );
      });

      test('matches the cloud origin host case-insensitively', () {
        const config = AppConfig(cloudBaseUrl: 'https://App.Endurain.Test');
        expect(
          config.allowInsecureTransportFor('http://app.endurain.test/login'),
          isFalse,
        );
      });

      test('falls back to the build policy for unparseable targets', () {
        const config = AppConfig(cloudBaseUrl: 'https://app.endurain.test');
        // No authority => cannot match the cloud origin; self-hosted allows it.
        expect(config.allowInsecureTransportFor('not a url'), isTrue);
      });
    });
  });
}
