import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('ActivityRecordingErrorL10n.localizedMessage', () {
    test('maps every error to a non-empty localized message', () {
      for (final error in ActivityRecordingError.values) {
        expect(
          error.localizedMessage(l10n),
          isNotEmpty,
          reason: 'missing message for $error',
        );
      }
    });

    test('maps known errors to their specific strings', () {
      expect(
        ActivityRecordingError.emptyRecording.localizedMessage(l10n),
        l10n.activityRecordingEmpty,
      );
      expect(
        ActivityRecordingError.gpxGenerationFailed.localizedMessage(l10n),
        l10n.activityGpxGenerationFailed,
      );
      expect(
        ActivityRecordingError.localSaveFailed.localizedMessage(l10n),
        l10n.activityLocalSaveFailed,
      );
      expect(
        ActivityRecordingError.invalidTransition.localizedMessage(l10n),
        l10n.activityRecordingFailed,
      );
    });
  });
}
