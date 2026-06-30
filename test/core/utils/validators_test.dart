import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('Validators', () {
    test('validates required fields', () {
      expect(
        Validators.validateRequired(null, l10n, 'Username'),
        l10n.requiredField,
      );
      expect(
        Validators.validateRequired('   ', l10n, 'Username'),
        l10n.requiredField,
      );
      expect(Validators.validateRequired('joao', l10n, 'Username'), isNull);
    });

    group('validateUrl (self-hosted, default)', () {
      test('rejects null or empty', () {
        expect(
          Validators.validateUrl(null, l10n, config: AppConfig.defaults),
          l10n.requiredField,
        );
        expect(
          Validators.validateUrl('', l10n, config: AppConfig.defaults),
          l10n.requiredField,
        );
      });

      test('rejects non-http/https schemes', () {
        expect(
          Validators.validateUrl(
            'endurain.example.test',
            l10n,
            config: AppConfig.defaults,
          ),
          l10n.invalidUrl,
        );
        expect(
          Validators.validateUrl(
            'ftp://example.test',
            l10n,
            config: AppConfig.defaults,
          ),
          l10n.invalidUrl,
        );
      });

      test('accepts https', () {
        expect(
          Validators.validateUrl(
            'https://example.test',
            l10n,
            config: AppConfig.defaults,
          ),
          isNull,
        );
      });

      test('accepts http in self-hosted mode', () {
        expect(
          Validators.validateUrl(
            'http://localhost:8080',
            l10n,
            config: AppConfig.defaults,
          ),
          isNull,
        );
      });
    });

    group('validateUrl (cloud origin)', () {
      const config = AppConfig(cloudBaseUrl: 'https://example.test');

      test('accepts https to the cloud origin', () {
        expect(
          Validators.validateUrl('https://example.test', l10n, config: config),
          isNull,
        );
      });

      test('rejects http to the cloud origin', () {
        expect(
          Validators.validateUrl('http://example.test', l10n, config: config),
          l10n.invalidUrl,
        );
      });

      test('still accepts http to a self-hosted origin', () {
        expect(
          Validators.validateUrl('http://my-nas.local', l10n, config: config),
          isNull,
        );
      });
    });
  });
}
