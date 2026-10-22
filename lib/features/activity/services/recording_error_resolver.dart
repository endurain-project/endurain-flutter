import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:geolocator/geolocator.dart';

/// Checks whether location (and, on Apple platforms, always-on background)
/// access allows a recording to start or resume.
class RecordingPermissionGate {
  RecordingPermissionGate(this._location);

  final LocationService _location;

  /// The blocking location error, requesting permission when still undecided;
  /// null when recording may proceed.
  Future<ActivityRecordingError?> locationError() async {
    if (!await _location.isLocationServiceEnabled()) {
      return ActivityRecordingError.locationServiceDisabled;
    }

    var permission = await _location.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _location.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => null,
      LocationPermission.denied =>
        ActivityRecordingError.locationPermissionDenied,
      LocationPermission.deniedForever =>
        ActivityRecordingError.locationPermissionDeniedForever,
      LocationPermission.unableToDetermine =>
        ActivityRecordingError.locationPermissionDenied,
    };
  }

  /// The blocking background-permission error; null when not required or
  /// already granted.
  Future<ActivityRecordingError?> backgroundError({
    required bool required,
  }) async {
    if (!required) {
      return null;
    }
    final permission = await _location.checkPermission();
    return permission == LocationPermission.always
        ? null
        : ActivityRecordingError.backgroundPermissionRequired;
  }

  /// Asks for always-on location; true when granted or not required.
  Future<bool> requestBackground({required bool required}) async {
    if (!required) {
      return true;
    }
    var permission = await _location.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await _location.requestPermission();
    }
    return permission == LocationPermission.always;
  }
}

/// Maps a native recorder failure reason to the user-facing recording error.
ActivityRecordingError recordingErrorForRecorderFailure(
  ActivityRecorderFailureReason? reason,
) {
  return switch (reason) {
    ActivityRecorderFailureReason.locationUnavailable =>
      ActivityRecordingError.locationServiceDisabled,
    ActivityRecorderFailureReason.permissionLost =>
      ActivityRecordingError.locationPermissionDenied,
    ActivityRecorderFailureReason.persistenceFailed =>
      ActivityRecordingError.localSaveFailed,
    ActivityRecorderFailureReason.unsupportedPlatform ||
    ActivityRecorderFailureReason.locationStreamFailed ||
    null => ActivityRecordingError.locationStreamFailed,
  };
}
