import 'package:endurain/l10n/app_localizations.dart';

enum ActivityRecordingError {
  invalidTransition,
  locationStreamFailed,
  emptyRecording,
  gpxGenerationFailed,
  localSaveFailed,
  locationServiceDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  backgroundPermissionRequired,
}

/// Localized, user-facing message for a recording error. Co-located with the
/// enum so the mapping lives with the type it describes (mirrors
/// `ActivityTypeLabel.localizedLabel`) instead of being inlined in a widget.
extension ActivityRecordingErrorL10n on ActivityRecordingError {
  String localizedMessage(AppLocalizations l10n) {
    return switch (this) {
      ActivityRecordingError.emptyRecording => l10n.activityRecordingEmpty,
      ActivityRecordingError.gpxGenerationFailed =>
        l10n.activityGpxGenerationFailed,
      ActivityRecordingError.localSaveFailed => l10n.activityLocalSaveFailed,
      ActivityRecordingError.locationPermissionDenied =>
        l10n.activityLocationPermissionDenied,
      ActivityRecordingError.locationPermissionDeniedForever =>
        l10n.activityLocationPermissionDeniedForever,
      ActivityRecordingError.backgroundPermissionRequired =>
        l10n.activityBackgroundPermissionRequired,
      ActivityRecordingError.locationServiceDisabled =>
        l10n.activityLocationServiceDisabled,
      ActivityRecordingError.locationStreamFailed =>
        l10n.activityLocationStreamFailed,
      ActivityRecordingError.invalidTransition => l10n.activityRecordingFailed,
    };
  }
}
