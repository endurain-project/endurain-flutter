import 'dart:async';

import 'package:async/async.dart';
import 'package:endurain/app/app_infrastructure.dart';
import 'package:endurain/app/modules/auth_module.dart';
import 'package:endurain/app/modules/sensors_module.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/services/platform/share_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/controllers/audio_announcement_settings_controller.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/audio_announcement_settings_repository.dart';
import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:endurain/features/activity/services/activity_finalizer.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/audio_announcement_preview_adapter.dart';
import 'package:endurain/features/activity/services/local_activity_gpx_storage.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:endurain/features/activity/services/recording_live_activity_adapter.dart';
import 'package:endurain/features/activity/services/recording_live_activity_publisher.dart';
import 'package:endurain/features/activity/services/start_countdown_platform_adapter.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:flutter/foundation.dart';

/// Wires the activity recording + upload feature: local storage, the durable
/// upload queue, the app-lifetime recording controller, and the platform
/// recorder.
///
/// Also owns the bridge to the sensors feature: it fans the per-kind sensor
/// streams into the recording pipeline, hands sensors off to the native
/// recorder on Android, and reconnects them once a recording releases the
/// handoff. Depends on [AppInfrastructure], [AuthModule], and [SensorsModule].
class ActivityModule {
  ActivityModule({
    required AppInfrastructure infra,
    required AuthModule auth,
    required SensorsModule sensors,
    Future<void> Function(ConnectionProfile profile)? reconcileProfile,
  }) : _infra = infra,
       _auth = auth,
       _sensors = sensors,
       _reconcileProfile = reconcileProfile;

  final AppInfrastructure _infra;
  final AuthModule _auth;
  final SensorsModule _sensors;

  /// Moves records of an earlier profile id onto the active profile before
  /// each upload drain. Supplied by the composition root, which owns the
  /// cross-feature legacy-profile migration.
  final Future<void> Function(ConnectionProfile profile)? _reconcileProfile;

  late final ActivityUploadService upload = ActivityUploadService(
    uploadFile: _auth.apiClient.uploadFile,
    config: ActivityUploadConfig.fromEndpoints(_infra.endpoints),
    retryPolicy: const ActivityUploadRetryPolicy(maxAttempts: 3),
    activeConnectionProfile: _auth.session.getConnectionProfile,
    fetchIngestionJob: (endpoint, {expectedOrigin, expectedProfileId}) async {
      final read = await _auth.apiClient.getJsonObjectWithHeaders(
        endpoint,
        failureCode: AppErrorCode.activityUploadFailed,
        expectedOrigin: expectedOrigin,
        expectedProfileId: expectedProfileId,
      );
      return (
        job: read.body,
        retryAfter: ActivityUploadService.parseRetryAfter(
          read.headers[ApiConstants.retryAfterHeader],
        ),
      );
    },
  );

  late final LocalActivityGpxStorage gpxStorage = LocalActivityGpxStorage();

  late final LocalActivityRepository localActivities = LocalActivityRepository(
    gpxStorage: gpxStorage,
    store: SqfliteActivityStore(),
  );

  /// Builds the GPX, summary and pending record of a completed activity; shared
  /// by the phone recorder and the watch ingestion.
  late final ActivityFinalizer finalizer = ActivityFinalizer(
    repository: localActivities,
    summaryBuilder: LocalActivitySummaryBuilder(),
  );

  late final ActivityRetentionSettingsRepository retentionSettings =
      ActivityRetentionSettingsRepository(preferences: _infra.preferences);

  late final AudioAnnouncementSettingsRepository audioAnnouncementSettings =
      AudioAnnouncementSettingsRepository(preferences: _infra.preferences);

  /// App-lifetime controller for the audio-announcement preferences. Owned
  /// here (not the settings screen) so the value configured for the next
  /// recording start always reflects the latest saved preference, even if the
  /// settings screen was never opened this session.
  late final AudioAnnouncementSettingsController
  audioAnnouncementSettingsController = AudioAnnouncementSettingsController(
    repository: audioAnnouncementSettings,
    previewAdapter: createAudioAnnouncementPreviewAdapter(),
  );

  /// Builds the announcement preview adapter for the current platform. Only
  /// Android and iOS host the native speech engine.
  AudioAnnouncementPreviewAdapter createAudioAnnouncementPreviewAdapter() {
    if (isMobilePlatform) {
      return MethodChannelAudioAnnouncementPreviewAdapter();
    }
    return const UnsupportedAudioAnnouncementPreviewAdapter();
  }

  late final AutoPauseSettingsRepository autoPauseSettings =
      AutoPauseSettingsRepository(preferences: _infra.preferences);

  late final StartCountdownSettingsRepository startCountdownSettings =
      StartCountdownSettingsRepository(preferences: _infra.preferences);

  /// Native support for the start countdown (spoken cues, iOS warm-up). Only
  /// Android and iOS host the native recorder channel.
  late final StartCountdownPlatformAdapter startCountdownPlatform =
      isMobilePlatform
      ? MethodChannelStartCountdownPlatformAdapter()
      : const UnsupportedStartCountdownPlatformAdapter();

  /// App-lifetime durable upload queue. Drains locally-stored activities whose
  /// upload has not yet succeeded; triggered on app-resume (see `app.dart`) and
  /// whenever connectivity is restored.
  late final ActivityUploadQueue uploadQueue = ActivityUploadQueue(
    repository: localActivities,
    uploadService: upload,
    retentionSettingsRepository: retentionSettings,
    isUploadAuthorized: _auth.service.isAuthenticated,
    activeConnectionProfile: _auth.session.getConnectionProfile,
    reconcileProfile: _reconcileProfile,
    diagnostics: _infra.diagnostics,
    connectivitySignal: _infra.connectivity.onOnlineChanged,
  );

  /// App-lifetime controller for the active recording session. Owned here so it
  /// survives tab navigation and can be used by non-map screens. Consumers
  /// obtain it from the app scope and must NOT dispose it.
  late final ActivityRecordingController recordingController =
      _buildRecordingController();

  ActivityRecordingController _buildRecordingController() {
    final controller = ActivityRecordingController(
      recordingService: createRecordingService(),
      uploadService: upload,
      localActivityRepository: localActivities,
      finalizer: finalizer,
      retentionSettingsRepository: retentionSettings,
      autoPauseSettingsRepository: autoPauseSettings,
      isUploadAuthorized: _auth.service.isAuthenticated,
      activeConnectionProfile: _auth.session.getConnectionProfile,
      diagnostics: _infra.diagnostics,
      liveActivity: RecordingLiveActivityPublisher(
        // Only iOS has a Live Activity.
        adapter: defaultTargetPlatform == TargetPlatform.iOS
            ? MethodChannelRecordingLiveActivityAdapter()
            : const UnsupportedRecordingLiveActivityAdapter(),
        diagnostics: _infra.diagnostics,
      ),
    );
    // When a recording ends, the native recorder releases the sensor handoff;
    // bring the Dart-side sensor links back so they are ready again without the
    // user reconnecting on the Sensors screen.
    controller.addListener(
      () => _handleRecordingStatusForSensors(controller.state.status),
    );
    return controller;
  }

  /// Builds a route-owned [LocalActivityHistoryController].
  ///
  /// [removeImportProvenance] clears any health-import provenance when a local
  /// activity is deleted; the composition root supplies the health default.
  /// Other overrides (typically injected in tests) take precedence over the
  /// app-lifetime services wired here.
  LocalActivityHistoryController createHistoryController({
    required Future<void> Function(String localActivityId)
    removeImportProvenance,
    LocalActivityRepository? repository,
    ActivityUploadService? uploadService,
    ShareService? shareService,
    ActivityRetentionSettingsRepository? retentionSettingsRepository,
  }) {
    return LocalActivityHistoryController(
      repository: repository ?? localActivities,
      uploadService: uploadService ?? upload,
      shareService: shareService ?? _infra.share,
      retentionSettingsRepository:
          retentionSettingsRepository ?? retentionSettings,
      diagnostics: _infra.diagnostics,
      removeImportProvenance: removeImportProvenance,
    );
  }

  /// Builds the active-recording recorder: the native background-capable
  /// recorder on Android and iOS, the only platforms the app ships on.
  ///
  /// The Dart geolocator recorder and file store that used to back other
  /// platforms live in `test/helpers`; tests inject them through
  /// [ActivityRecordingService] directly.
  ActivityLocationRecorder createLocationRecorder({
    LocationService? locationService,
  }) {
    if (isMobilePlatform) {
      return NativeActivityRecorderChannel();
    }
    throw UnsupportedError(
      'Activity recording is only supported on Android and iOS.',
    );
  }

  /// Assembles a ready-to-use [ActivityRecordingService] for the current
  /// platform, wiring the correct recorder and the sensor sources.
  ActivityRecordingService createRecordingService({
    LocationService? locationService,
  }) {
    final loc = locationService ?? _infra.location;
    final usesNativeHeartRate = usesNativeHeartRateHandoff(
      defaultTargetPlatform,
    );
    final recorder = createLocationRecorder(locationService: loc);
    return ActivityRecordingService(
      diagnostics: _infra.diagnostics,
      locationService: loc,
      recorder: recorder,
      sensorRecorder: switch (recorder) {
        final ActivitySensorRecorder sensorRecorder when !usesNativeHeartRate =>
          sensorRecorder,
        _ => null,
      },
      // Only Android hands the sensors off to the native foreground service,
      // whose FOREGROUND_SERVICE_CONNECTED_DEVICE model must own the single GATT
      // links. iOS keeps the Dart (universal_ble) connections — alive in the
      // background during an active recording via the bluetooth-central mode —
      // and feeds their live streams into the recording pipeline, so the
      // sensors stay connected and their values are shown live and stamped onto
      // points.
      sensorReadings: usesNativeHeartRate ? null : _mergedSensorReadings(),
      prepareSensorSources: usesNativeHeartRate
          ? _nativeSensorSourcePreparers()
          : const {},
    );
  }

  /// Merges every Dart-side sensor stream into one [RecordedSensorSample]
  /// stream for the recording pipeline, tagging each reading with its kind.
  Stream<RecordedSensorSample> _mergedSensorReadings() {
    return StreamGroup.merge<RecordedSensorSample>([
      for (final entry in _sensors.services.entries)
        entry.value.measurements.map(
          (measurement) => RecordedSensorSample(
            kind: _recordedKindFor(entry.key),
            timestamp: measurement.timestamp,
            value: measurement.value,
          ),
        ),
    ]);
  }

  /// Native (Android) device-id resolvers per sensor kind, used to hand each
  /// paired sensor off to the foreground-service recorder at recording start.
  Map<RecordedSensorKind, Future<String?> Function()>
  _nativeSensorSourcePreparers() {
    return <RecordedSensorKind, Future<String?> Function()>{
      for (final kind in SensorMeasurementKind.values)
        _recordedKindFor(kind): () => _sensors.prepareNativeSource(kind),
    };
  }

  /// Maps a sensor-layer [SensorMeasurementKind] to the activity-layer
  /// [RecordedSensorKind] the recording pipeline consumes.
  RecordedSensorKind _recordedKindFor(SensorMeasurementKind kind) {
    return switch (kind) {
      SensorMeasurementKind.heartRate => RecordedSensorKind.heartRate,
      SensorMeasurementKind.power => RecordedSensorKind.power,
      SensorMeasurementKind.cadence => RecordedSensorKind.cadence,
    };
  }

  /// Whether the external sensor services may auto-reconnect right now.
  ///
  /// Only Android hands sensors off: while a recording is active (or stopping)
  /// the native recorder owns the BLE links, so reconnecting the Dart side then
  /// would fight those connections and is suppressed until the recording
  /// finishes. On iOS and elsewhere the Dart links stay connected throughout, so
  /// reconnection is always allowed. Passed to [SensorsModule] as its gate.
  bool canAutoReconnectSensors() {
    if (!usesNativeHeartRateHandoff(defaultTargetPlatform)) {
      return true;
    }
    final status = recordingController.state.status;
    return status != ActivityRecordingStatus.recording &&
        status != ActivityRecordingStatus.paused &&
        status != ActivityRecordingStatus.stopping;
  }

  ActivityRecordingStatus? _previousRecordingStatus;

  /// Reconnects the remembered external sensors when a recording leaves the
  /// phase that owns them (recording/paused/stopping) for a terminal one
  /// (completed/failed/idle). By this point the native recorder has released the
  /// BLE links, so the Dart side can reclaim them. No-ops on the non-native
  /// path, where the links were never handed off.
  void _handleRecordingStatusForSensors(ActivityRecordingStatus status) {
    final previous = _previousRecordingStatus;
    _previousRecordingStatus = status;
    if (heartRateHandoffReleased(previous, status)) {
      unawaited(_sensors.reconnectRemembered());
    }
  }

  /// Whether [platform] hands the paired sensors off to the native recorder for
  /// the duration of a recording.
  ///
  /// Only Android needs this: its foreground-service model
  /// (`FOREGROUND_SERVICE_CONNECTED_DEVICE`) owns the single GATT connection, so
  /// the Dart-side links are released and the native service captures readings.
  /// iOS and every other platform keep the Dart (universal_ble) connections and
  /// feed their live streams into the recording pipeline instead.
  @visibleForTesting
  static bool usesNativeHeartRateHandoff(TargetPlatform platform) =>
      platform == TargetPlatform.android;

  /// Whether a recording status transition from [previous] to [current] means
  /// the native sensor handoff has just been released (the recording left the
  /// recording/paused/stopping phase for a terminal one).
  @visibleForTesting
  static bool heartRateHandoffReleased(
    ActivityRecordingStatus? previous,
    ActivityRecordingStatus current,
  ) {
    if (previous == null) {
      return false;
    }
    const owningSensor = {
      ActivityRecordingStatus.recording,
      ActivityRecordingStatus.paused,
      ActivityRecordingStatus.stopping,
    };
    return owningSensor.contains(previous) && !owningSensor.contains(current);
  }
}
