import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/l10n/app_localizations_pt.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('localizedErrorMessage', () {
    test('localizes app exceptions without details', () {
      expect(
        localizedErrorMessage(
          const AppException(AppErrorCode.sessionExpired),
          l10n,
        ),
        l10n.errorSessionExpired,
      );
    });

    test('localizes app exceptions with server details', () {
      expect(
        localizedErrorMessage(
          const AppException(
            AppErrorCode.loginFailed,
            details: 'Bad credentials',
          ),
          l10n,
        ),
        l10n.errorLoginFailedWithDetails('Bad credentials'),
      );
    });

    test('localizes ingestion job error codes of a failed upload', () {
      final expected = <String, String>{
        'unsupported_format': l10n.errorActivityIngestionUnsupportedFormat,
        'invalid_file': l10n.errorActivityIngestionInvalidFile,
        'no_activities_found': l10n.errorActivityIngestionNoActivitiesFound,
        'processing_failed': l10n.errorActivityIngestionProcessingFailed,
        'provider_unavailable': l10n.errorActivityIngestionProviderUnavailable,
      };

      for (final entry in expected.entries) {
        expect(
          localizedErrorMessage(
            AppException(AppErrorCode.activityUploadFailed, details: entry.key),
            l10n,
          ),
          entry.value,
        );
      }
      expect(expected.values.toSet(), hasLength(expected.length));
    });

    test('shows an unknown upload failure detail as before', () {
      expect(
        localizedErrorMessage(
          const AppException(
            AppErrorCode.activityUploadFailed,
            details: 'HTTP 422',
          ),
          l10n,
        ),
        l10n.errorActivityUploadFailedWithDetails('HTTP 422'),
      );
    });

    test('localizes ingestion job error codes in other languages', () {
      final pt = AppLocalizationsPt();

      expect(
        localizedErrorMessage(
          const AppException(
            AppErrorCode.activityUploadFailed,
            details: 'unsupported_format',
          ),
          pt,
        ),
        'O formato do ficheiro não é suportado',
      );
    });

    test('strips plain Exception prefix from fallback errors', () {
      expect(
        localizedErrorMessage(Exception('Network failed'), l10n),
        'Network failed',
      );
    });

    test('returns the raw string for non-Exception errors', () {
      expect(localizedErrorMessage('plain error', l10n), 'plain error');
    });

    for (final AppLocalizations locale in <AppLocalizations>[
      AppLocalizationsEn(),
      AppLocalizationsPt(),
    ]) {
      test(
        'maps every error code to a non-empty message (${locale.localeName})',
        () {
          for (final code in AppErrorCode.values) {
            final withoutDetails = localizedErrorMessage(
              AppException(code),
              locale,
            );
            expect(
              withoutDetails,
              isNotEmpty,
              reason: '$code without details (${locale.localeName})',
            );

            final withDetails = localizedErrorMessage(
              AppException(code, details: 'boundary-detail'),
              locale,
            );
            expect(
              withDetails,
              isNotEmpty,
              reason: '$code with details (${locale.localeName})',
            );
          }
        },
      );
    }
  });
}
