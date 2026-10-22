import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/recording_permission_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import '../../../helpers/fake_location_platform_adapter.dart';

RecordingPermissionGate _gate({
  bool serviceEnabled = true,
  LocationPermission permission = LocationPermission.whileInUse,
  LocationPermission requested = LocationPermission.whileInUse,
}) {
  return RecordingPermissionGate(
    LocationService(
      platformAdapter: FakeLocationPlatformAdapter(
        serviceEnabled: serviceEnabled,
        permission: permission,
        requestedPermission: requested,
      ),
    ),
  );
}

void main() {
  group('RecordingPermissionGate.locationError', () {
    test('reports a disabled location service', () async {
      expect(
        await _gate(serviceEnabled: false).locationError(),
        ActivityRecordingError.locationServiceDisabled,
      );
    });

    test('allows while-in-use and always permission', () async {
      expect(await _gate().locationError(), isNull);
      expect(
        await _gate(permission: LocationPermission.always).locationError(),
        isNull,
      );
    });

    test('requests permission when undecided and allows a grant', () async {
      final gate = _gate(permission: LocationPermission.denied);
      expect(await gate.locationError(), isNull);
    });

    test('reports a denied request', () async {
      final gate = _gate(
        permission: LocationPermission.denied,
        requested: LocationPermission.denied,
      );
      expect(
        await gate.locationError(),
        ActivityRecordingError.locationPermissionDenied,
      );
    });

    test('reports permanent denial', () async {
      expect(
        await _gate(permission: LocationPermission.deniedForever)
            .locationError(),
        ActivityRecordingError.locationPermissionDeniedForever,
      );
    });

    test('treats an undeterminable permission as denied', () async {
      expect(
        await _gate(permission: LocationPermission.unableToDetermine)
            .locationError(),
        ActivityRecordingError.locationPermissionDenied,
      );
    });
  });

  group('RecordingPermissionGate background access', () {
    test('backgroundError is null when not required', () async {
      expect(await _gate().backgroundError(required: false), isNull);
    });

    test('backgroundError requires always permission when required', () async {
      expect(
        await _gate().backgroundError(required: true),
        ActivityRecordingError.backgroundPermissionRequired,
      );
      expect(
        await _gate(permission: LocationPermission.always)
            .backgroundError(required: true),
        isNull,
      );
    });

    test('requestBackground succeeds trivially when not required', () async {
      expect(await _gate().requestBackground(required: false), isTrue);
    });

    test('requestBackground asks when undecided', () async {
      expect(
        await _gate(
          permission: LocationPermission.denied,
          requested: LocationPermission.always,
        ).requestBackground(required: true),
        isTrue,
      );
      expect(
        await _gate(
          permission: LocationPermission.denied,
          requested: LocationPermission.whileInUse,
        ).requestBackground(required: true),
        isFalse,
      );
    });

    test('requestBackground does not re-ask after a firm answer', () async {
      expect(
        await _gate(
          permission: LocationPermission.deniedForever,
          requested: LocationPermission.always,
        ).requestBackground(required: true),
        isFalse,
      );
    });
  });

  group('recordingErrorForRecorderFailure', () {
    test('maps each reason', () {
      expect(
        recordingErrorForRecorderFailure(
          ActivityRecorderFailureReason.locationUnavailable,
        ),
        ActivityRecordingError.locationServiceDisabled,
      );
      expect(
        recordingErrorForRecorderFailure(
          ActivityRecorderFailureReason.permissionLost,
        ),
        ActivityRecordingError.locationPermissionDenied,
      );
      expect(
        recordingErrorForRecorderFailure(
          ActivityRecorderFailureReason.persistenceFailed,
        ),
        ActivityRecordingError.localSaveFailed,
      );
      expect(
        recordingErrorForRecorderFailure(null),
        ActivityRecordingError.locationStreamFailed,
      );
    });
  });
}
