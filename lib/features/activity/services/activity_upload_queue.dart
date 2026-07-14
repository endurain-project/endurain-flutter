import 'dart:async';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';

/// App-lifetime durable queue that re-attempts activity uploads that did not
/// reach the server during recording.
///
/// A finished activity is always persisted locally first (GPX + metadata) with
/// an `pending`/`failed` upload status. This queue scans for those records and
/// drains them, so an activity recorded with no connectivity is uploaded later
/// without the user having to open the history screen and tap retry.
///
/// Triggers:
/// - app-resume (wired in `app.dart`),
/// - optionally a `connectivitySignal` that emits `true` when connectivity is
///   restored. The signal is intentionally an injected `Stream` so the app
///   stays dependency-free; a build that wants connectivity-driven draining can
///   pass a stream (e.g. from `connectivity_plus`) without changing this class.
///
/// [drain] is single-flight: concurrent calls share the same in-progress run,
/// so app-resume and a connectivity event cannot start two overlapping drains.
class ActivityUploadQueue {
  ActivityUploadQueue({
    required this._repository,
    required ActivityUploadService uploadService,
    this._retentionSettingsRepository,
    Future<bool> Function()? isUploadAuthorized,
    Future<ConnectionProfile?> Function()? activeConnectionProfile,
    DiagnosticsRecorder? diagnostics,
    DateTime Function()? now,
    Stream<bool>? connectivitySignal,
  }) : _uploadService = uploadService,
       _isUploadAuthorized = isUploadAuthorized ?? _alwaysAuthorized,
       _activeConnectionProfile = activeConnectionProfile,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _now = now ?? DateTime.now {
    if (connectivitySignal != null) {
      _connectivitySubscription = connectivitySignal.listen((isOnline) {
        if (isOnline) {
          unawaited(drain());
        }
      });
    }
  }

  static Future<bool> _alwaysAuthorized() async => true;

  static const Set<LocalActivityUploadStatus> _drainableStatuses = {
    LocalActivityUploadStatus.pending,
    LocalActivityUploadStatus.failed,
    LocalActivityUploadStatus.uploaded,
  };

  final LocalActivityRepository _repository;
  final ActivityUploadService _uploadService;
  final ActivityRetentionSettingsRepository? _retentionSettingsRepository;
  final Future<bool> Function() _isUploadAuthorized;
  final Future<ConnectionProfile?> Function()? _activeConnectionProfile;
  final DiagnosticsRecorder _diagnostics;
  final DateTime Function() _now;

  StreamSubscription<bool>? _connectivitySubscription;
  final StreamController<void> _drainCompletedController =
      StreamController<void>.broadcast();
  Future<void>? _inFlightDrain;
  bool _followUpRequested = false;

  Stream<void> get onDrainCompleted => _drainCompletedController.stream;

  /// Re-attempts every locally-stored activity whose upload has not yet
  /// succeeded. Best-effort: a failure on one record does not stop the others,
  /// and each record keeps its persisted `failed` status for the UI.
  ///
  /// Single-flight: a concurrent call returns the in-progress future.
  Future<void> drain() {
    final inFlight = _inFlightDrain;
    if (inFlight != null) {
      _followUpRequested = true;
      return inFlight;
    }
    return _inFlightDrain = _drainUntilSettled().whenComplete(() {
      _inFlightDrain = null;
      if (!_drainCompletedController.isClosed) {
        _drainCompletedController.add(null);
      }
    });
  }

  Future<void> _drainUntilSettled() async {
    do {
      _followUpRequested = false;
      await _drain();
    } while (_followUpRequested);
  }

  Future<void> _drain() async {
    if (!_uploadService.isConfigured) {
      return;
    }
    // Skip while unauthenticated (e.g. offline guest mode): activities stay
    // locally persisted as pending and drain once the user signs in.
    if (!await _isUploadAuthorized()) {
      return;
    }

    final profileProvider = _activeConnectionProfile;
    final activeProfile = profileProvider == null
        ? null
        : await profileProvider();

    // Claim any activities recorded before a server was connected (guest mode
    // leaves them with no origin/profile) for the now-active connection, so a
    // backlog captured offline finally uploads after sign-in.
    if (activeProfile != null) {
      await _repository.bindUnassignedToProfile(
        origin: activeProfile.origin,
        profileId: activeProfile.id,
        updatedAt: _now().toUtc(),
      );
    }

    final records = await _repository.listByUploadStatus(_drainableStatuses);
    final retryableRecords = records.where(
      (record) =>
          record.uploadStatus == LocalActivityUploadStatus.pending ||
          record.autoRetryEligible ||
          record.gpxCleanupPending,
    );
    final pending = profileProvider == null
        ? retryableRecords.toList()
        : _recordsForActiveProfile(retryableRecords.toList(), activeProfile);
    if (pending.isEmpty) {
      return;
    }

    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityUploadQueueDrainStarted,
      details: {'count': pending.length},
    );

    var uploaded = 0;
    var failed = 0;
    for (final record in pending) {
      try {
        await _uploadService.performUploadAttempt(
          record: record,
          repository: _repository,
          retentionRepository: _retentionSettingsRepository,
          now: _now,
        );
        uploaded++;
      } catch (_) {
        // Best effort: the record is persisted as failed with its typed error
        // code; keep draining the rest. A per-record breadcrumb makes a
        // specific failing activity observable, not just the aggregate count.
        failed++;
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.activityUploadQueueRecordFailed,
          details: {'id': record.id},
        );
      }
    }

    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityUploadQueueDrainFinished,
      details: {'uploaded': uploaded, 'failed': failed},
    );
  }

  List<LocalActivityRecord> _recordsForActiveProfile(
    List<LocalActivityRecord> records,
    ConnectionProfile? profile,
  ) {
    if (profile == null) return const [];
    return records
        .where(
          (record) =>
              record.connectionOrigin == profile.origin &&
              record.connectionProfileId == profile.id,
        )
        .toList();
  }

  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = null;
    unawaited(_drainCompletedController.close());
  }
}
