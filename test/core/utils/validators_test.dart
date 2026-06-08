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
        expect(Validators.validateUrl(null, l10n), l10n.requiredField);
        expect(Validators.validateUrl('', l10n), l10n.requiredField);
      });

      test('rejects non-http/https schemes', () {
        expect(
          Validators.validateUrl('endurain.example.test', l10n),
          l10n.invalidUrl,
        );
        expect(
          Validators.validateUrl('ftp://example.test', l10n),
          l10n.invalidUrl,
        );
      });

      test('accepts https', () {
        expect(Validators.validateUrl('https://example.test', l10n), isNull);
      });

      test('accepts http in self-hosted mode', () {
        expect(Validators.validateUrl('http://localhost:8080', l10n), isNull);
      });
    });

    group('validateUrl (managed mode)', () {
      const managed = AppConfig(transportMode: AppTransportMode.managed);

      test('accepts https', () {
        expect(
          Validators.validateUrl('https://example.test', l10n, config: managed),
          isNull,
        );
      });

      test('rejects http', () {
        expect(
          Validators.validateUrl('http://example.test', l10n, config: managed),
          l10n.invalidUrl,
        );
      });
    });
  });
}
