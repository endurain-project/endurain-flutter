import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaults match self-hosted behavior', () {
      const config = AppConfig.defaults;
      expect(config.apiBasePath, AppConfig.defaultApiBasePath);
      expect(config.allowInsecureTransport, isTrue);
    });

    test('custom values are preserved', () {
      const config = AppConfig(
        apiBasePath: '/api/v2',
        allowInsecureTransport: false,
      );
      expect(config.apiBasePath, '/api/v2');
      expect(config.allowInsecureTransport, isFalse);
    });

    test('defaultApiBasePath is /api/v1', () {
      expect(AppConfig.defaultApiBasePath, '/api/v1');
    });
  });
}
