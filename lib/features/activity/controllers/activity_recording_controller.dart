import 'dart:async';

// Recording type relationships (controller -> service -> recorder):
// the durable session model survives app restarts; the ephemeral state model
// drives the live UI.

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/core/utils/id_generation.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_upload_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_gpx_builder.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

class ActivityRecordingController extends SafeNotifier {
  ActivityRecordingController({
    required this._recordingService,
    ActivityGpxBuilder gpxBuilder = const ActivityGpxBuilder(),
    ActivityUploadService? uploadService,
    LocalActivityRepository? localActivityRepository,
    LocalActivitySummaryBuilder? localActivitySummaryBuilder,
    this._retentionSettingsRepository,
    this._autoPauseSettingsRepository,
    Future<bool> Function()? isUploadAuthorized,
    Future<ConnectionProfile?> Function()? activeConnectionProfile,
    DiagnosticsRecorder? diagnostics,
    String Function()? localActivityIdProvider,
    DateTime Function()? now,
    this._ownsService = true,
  }) : _gpxBuilder = gpxBuilder,
       _uploadService = uploadService ?? ActivityUploadService(),
       _localActivityRepository =
           localActivityRepository ?? LocalActivityRepository(),
       _localActivitySummaryBuilder =
           localActivitySummaryBuilder ?? LocalActivitySummaryBuilder(),
       _isUploadAuthorized = isUploadAuthorized ?? _alwaysAuthorized,
       _activeConnectionProfile = activeConnectionProfile ?? _noActiveProfile,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _localActivityIdProvider = localActivityIdProvider ?? localActivityId,
       _now = now ?? DateTime.now {
    _stateSubscription = _recordingService.stateStream.listen((state) {
      _setState(state);
    });
  }

  static Future<bool> _alwaysAuthorized() async => true;
  static Future<ConnectionProfile?> _noActiveProfile() async => null;

  final ActivityRecordingService _recordingService;
  final ActivityGpxBuilder _gpxBuilder;
  final ActivityUploadService _uploadService;
  final LocalActivityRepository _localActivityRepository;
  final LocalActivitySummaryBuilder _localActivitySummaryBuilder;
  final ActivityRetentionSettingsRepository? _retentionSettingsRepository;
  final AutoPauseSettingsRepository? _autoPauseSettingsRepository;
  final Future<bool> Function() _isUploadAuthorized;
  final Future<ConnectionProfile?> Function() _activeConnectionProfile;
  final DiagnosticsRecorder _diagnostics;
  final String Function() _localActivityIdProvider;
  final DateTime Function() _now;
  final bool _ownsService;
  late final StreamSubscription<ActivityRecordingState> _stateSubscription;

  ActivityRecordingState _state = ActivityRecordingState();
  ActivityType _selectedActivityType = ActivityType.run;
  String? _completedGpx;
  String? _completedLocalActivityId;
  LocalActivityRecord? _completedLocalActivityRecord;
  ActivityUploadStatus _uploadStatus = ActivityUploadStatus.idle;
  AppException? _uploadError;
  Future<void>? _activeUpload;
  Future<bool>? _activeRecovery;
  BackgroundLocationConfig? _backgroundConfig;

  ActivityRecordingState get state => _state;

  ActivityType get selectedActivityType => _selectedActivityType;

  String? get completedGpx => _completedGpx;

  String? get completedLocalActivityId => _completedLocalActivityId;

  ActivityUploadStatus get uploadStatus => _uploadStatus;

  AppException? get uploadError => _uploadError;

  /// Supplies the localized notification text used to keep location tracking
  /// alive while the app is backgrounded during a recording.
  void configureBackgroundTracking(BackgroundLocationConfig config) {
    _backgroundConfig = config;
    _recordingService.configureBackgroundTracking(config);
  }

  void selectActivityType(ActivityType type) {
    if (_state.isActive || _state.status == ActivityRecordingStatus.stopping) {
      return;
    }
    if (_selectedActivityType == type) {
      return;
    }
    _selectedActivityType = type;
    notify();
  }

  Future<void> start(ActivityType type) async {
    await _activeRecovery;
    if (_state.isActive ||
        _state.status == ActivityRecordingStatus.stopping ||
        _state.status == ActivityRecordingStatus.completed) {
      return;
    }
    _completedGpx = null;
    _completedLocalActivityId = null;
    _completedLocalActivityRecord = null;
    _setUploadState(ActivityUploadStatus.idle);
    selectActivityType(type);
    final localActivityId = _localActivityIdProvider();
    final profile = await _activeConnectionProfile();
    final autoPauseRepository = _autoPauseSettingsRepository;
    if (autoPauseRepository != null) {
      _recordingService.configureAutoPause(
        await autoPauseRepository.getConfig(),
      );
    }
    await _recordingService.start(
      activityType: _selectedActivityType,
      backgroundConfig: _backgroundConfig,
      localSessionId: localActivityId,
      connectionOrigin: profile?.origin,
      connectionProfileId: profile?.id,
    );
    _setState(_recordingService.state);
  }

  /// Attempts to restore a recoverable active recording left behind by a
  /// previous app run (e.g. after the process was killed mid-recording).
  ///
  /// Returns `true` when an active or completed recording was restored.
  Future<bool> recoverActiveRecording() {
    final existing = _activeRecovery;
    if (existing != null) {
      return existing;
    }
    final recovery = _recoverActiveRecording().whenComplete(() {
      _activeRecovery = null;
    });
    _activeRecovery = recovery;
    return recovery;
  }

  Future<bool> _recoverActiveRecording() async {
    final recovered = await _recordingService.recoverActiveSession();
    if (recovered) {
      _selectedActivityType =
          _recordingService.state.activityType ?? _selectedActivityType;
      _setState(_recordingService.state);
      if (_recordingService.state.status == ActivityRecordingStatus.completed) {
        await _finalizeCompletedState(_recordingService.state);
      }
    }
    return recovered;
  }

  Future<void> pause() async {
    await _recordingService.pause();
    _setState(_recordingService.state);
  }

  Future<void> resume() async {
    await _recordingService.resume();
    _setState(_recordingService.state);
  }

  Future<void> stop() async {
    await _recordingService.stop();
    final completedState = _recordingService.state;
    if (completedState.status == ActivityRecordingStatus.completed) {
      await _finalizeCompletedState(completedState);
      return;
    }
    _completedGpx = null;
    _completedLocalActivityId = null;
    _completedLocalActivityRecord = null;
    _setState(completedState);
  }

  Future<void> _finalizeCompletedState(
    ActivityRecordingState completedState,
  ) async {
    final gpx = _buildCompletedGpx(completedState);
    if (gpx == null) {
      return;
    }
    final localRecord = await _saveCompletedActivity(completedState, gpx);
    if (localRecord == null) {
      return;
    }
    await _recordingService.acknowledgeFinalized();
    _setState(completedState.copyWith(localActivityId: localRecord.id));
    if (await _isUploadAuthorized()) {
      unawaited(uploadCompletedGpx());
    }
  }

  Future<void> discard() async {
    try {
      final localActivityId =
          _completedLocalActivityId ?? _state.localActivityId;
      if (localActivityId != null) {
        await _localActivityRepository.delete(localActivityId);
      }
    } on AppException catch (error) {
      _setUploadState(ActivityUploadStatus.cleanupFailed, error: error);
      return;
    }
    _completedGpx = null;
    _completedLocalActivityId = null;
    _completedLocalActivityRecord = null;
    _setUploadState(ActivityUploadStatus.idle);
    await _recordingService.discard();
    _setState(_recordingService.state);
  }

  Future<void> clearCompleted() async {
    _completedGpx = null;
    _completedLocalActivityId = null;
    _completedLocalActivityRecord = null;
    _setUploadState(ActivityUploadStatus.idle);
    await _recordingService.discard();
    _setState(_recordingService.state);
  }

  Future<void> uploadCompletedGpx() {
    if (_uploadStatus == ActivityUploadStatus.uploading) {
      return _activeUpload ?? Future<void>.value();
    }
    if ((_completedLocalActivityId ?? _state.localActivityId) == null ||
        _state.status != ActivityRecordingStatus.completed) {
      return Future<void>.value();
    }

    final upload = _uploadCompletedGpx();
    _activeUpload = upload.whenComplete(() => _activeUpload = null);
    return _activeUpload!;
  }

  Future<bool> openLocationSettings() {
    return _recordingService.openAppSettings();
  }

  Future<bool> isBackgroundTrackingReady() {
    return _recordingService.isBackgroundTrackingReady();
  }

  Future<bool> requestBackgroundTrackingPermission() {
    return _recordingService.requestBackgroundTrackingPermission();
  }

  String? _buildCompletedGpx(ActivityRecordingState completedState) {
    try {
      final gpx = _gpxBuilder.build(completedState);
      _completedGpx = gpx;
      return gpx;
    } catch (error) {
      // Sanitized breadcrumb only — record the error type, never coordinates,
      // so a field report can pinpoint a GPX-generation failure (the one path
      // that can lose a just-finished workout) without leaking GPS data.
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.activityGpxGenerationFailed,
        details: {'type': error.runtimeType.toString()},
      );
      _completedGpx = null;
      _setState(
        completedState.copyWith(
          status: ActivityRecordingStatus.failed,
          lastError: ActivityRecordingError.gpxGenerationFailed,
        ),
      );
      return null;
    }
  }

  Future<LocalActivityRecord?> _saveCompletedActivity(
    ActivityRecordingState completedState,
    String gpx,
  ) async {
    try {
      final createdAt = _now().toUtc();
      final localActivityId =
          _recordingService.localSessionId ?? _localActivityIdProvider();
      final gpxFileName = await _localActivityRepository.writeGpx(
        id: localActivityId,
        gpx: gpx,
      );
      final localRecord = _localActivitySummaryBuilder
          .build(
            state: completedState,
            id: localActivityId,
            gpxFileName: gpxFileName,
            createdAt: createdAt,
          )
          .copyWith(
            connectionOrigin: _recordingService.connectionOrigin,
            connectionProfileId: _recordingService.connectionProfileId,
          );
      await _localActivityRepository.upsert(localRecord);
      _completedLocalActivityId = localRecord.id;
      _completedLocalActivityRecord = localRecord;
      return localRecord;
    } on AppException catch (error) {
      _failLocalSave(completedState, error);
      return null;
    } catch (error) {
      _failLocalSave(
        completedState,
        AppException(AppErrorCode.activityLocalSaveFailed, cause: error),
      );
      return null;
    }
  }

  void _failLocalSave(
    ActivityRecordingState completedState,
    AppException error,
  ) {
    _completedGpx = null;
    _completedLocalActivityId = null;
    _completedLocalActivityRecord = null;
    _setUploadState(ActivityUploadStatus.failed, error: error);
    _setState(
      completedState.copyWith(
        status: ActivityRecordingStatus.failed,
        lastError: ActivityRecordingError.localSaveFailed,
      ),
    );
  }

  Future<void> _uploadCompletedGpx() async {
    _setUploadState(ActivityUploadStatus.uploading);
    try {
      final record = await _completedRecordForUpload();
      final uploaded = await _uploadService.performUploadAttempt(
        record: record,
        repository: _localActivityRepository,
        retentionRepository: _retentionSettingsRepository,
        now: _now,
      );
      _completedLocalActivityRecord = uploaded;
      if (uploaded.lastUploadErrorCode ==
          AppErrorCode.activityGpxCleanupFailed) {
        _setUploadState(
          ActivityUploadStatus.cleanupFailed,
          error: const AppException(AppErrorCode.activityGpxCleanupFailed),
        );
        return;
      }
      _setUploadState(ActivityUploadStatus.uploaded);
    } catch (error) {
      final appError = error is AppException
          ? error
          : AppException(AppErrorCode.activityUploadFailed, cause: error);
      _uploadError = appError;
      _setUploadState(ActivityUploadStatus.failed, error: appError);
    }
  }

  Future<LocalActivityRecord> _completedRecordForUpload() async {
    final localActivityId = _completedLocalActivityId ?? _state.localActivityId;
    if (localActivityId == null) {
      throw const AppException(AppErrorCode.activityLocalActivityNotFound);
    }
    final cachedRecord = _completedLocalActivityRecord;
    if (cachedRecord != null && cachedRecord.id == localActivityId) {
      return cachedRecord;
    }
    final record = await _localActivityRepository.get(localActivityId);
    if (record == null) {
      throw const AppException(AppErrorCode.activityLocalActivityNotFound);
    }
    _completedLocalActivityRecord = record;
    return record;
  }

  /// Updates the recorded state and notifies listeners.
  ///
  /// **Invariant — localSaveFailed is terminal:**
  /// Once the state has transitioned to `failed` with error key
  /// `localSaveFailed`, no caller may silently move it back to `stopping` or
  /// `completed`. The GPX data is lost and recovery from that state is
  /// undefined; forcing those transitions would show misleading UI (e.g. a
  /// "completed" banner with no persisted activity). The guard below enforces
  /// this boundary. Any new caller that needs to override this must explicitly
  /// handle the save-failed path rather than relying on status transitions.
  void _setState(ActivityRecordingState state) {
    if (_state.status == ActivityRecordingStatus.failed &&
        (_state.lastError == ActivityRecordingError.localSaveFailed ||
            _state.lastError == ActivityRecordingError.gpxGenerationFailed) &&
        (state.status == ActivityRecordingStatus.stopping ||
            state.status == ActivityRecordingStatus.completed)) {
      return;
    }
    if (state.status == ActivityRecordingStatus.completed &&
        state.localActivityId == null &&
        _state.localActivityId != null) {
      state = state.copyWith(localActivityId: _state.localActivityId);
    }
    _state = state;
    notify();
  }

  void _setUploadState(ActivityUploadStatus status, {AppException? error}) {
    _uploadStatus = status;
    _uploadError = error;
    notify();
  }

  @override
  void dispose() {
    unawaited(_stateSubscription.cancel());
    if (_ownsService) {
      _recordingService.dispose();
    }
    super.dispose();
  }
}
