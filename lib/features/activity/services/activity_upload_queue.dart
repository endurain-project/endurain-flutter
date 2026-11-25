import 'dart:async';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
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
    Future<void> Function(ConnectionProfile profile)? reconcileProfile,
    DiagnosticsRecorder? diagnostics,
    DateTime Function()? now,
    Stream<bool>? connectivitySignal,
  }) : _uploadService = uploadService,
       _isUploadAuthorized = isUploadAuthorized ?? _alwaysAuthorized,
       _activeConnectionProfile = activeConnectionProfile,
       _reconcileProfile = reconcileProfile,
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

  /// Whether the drain must act on [record]. The repository query already
  /// selects these records ([LocalActivityRepository.listUploadQueueCandidates]);
  /// this re-check keeps the rule in one readable place. The pass carries two
  /// distinct responsibilities, both resolved by
  /// [ActivityUploadService.performUploadAttempt] (which uploads a not-yet-
  /// uploaded record and, for an already-uploaded one, only finishes its GPX
  /// cleanup):
  /// - **upload**: a fresh `pending` record, or a `failed` one whose failure
  ///   was transient and so stays auto-retryable (`autoRetryEligible`); or
  /// - **cleanup**: an already-`uploaded` record whose post-upload GPX cleanup
  ///   was deferred (`gpxCleanupPending`) and must be retried, with no network
  ///   upload.
  static bool _requiresDrainPass(LocalActivityRecord record) {
    return switch (record.uploadStatus) {
      LocalActivityUploadStatus.pending => true,
      LocalActivityUploadStatus.failed =>
        record.autoRetryEligible || record.gpxCleanupPending,
      LocalActivityUploadStatus.uploaded => record.gpxCleanupPending,
    };
  }

  final LocalActivityRepository _repository;
  final ActivityUploadService _uploadService;
  final ActivityRetentionSettingsRepository? _retentionSettingsRepository;
  final Future<bool> Function() _isUploadAuthorized;
  final Future<ConnectionProfile?> Function()? _activeConnectionProfile;

  /// Moves records the active profile owns under an earlier profile id onto
  /// it before the drain selects them (see `LegacyProfileAdoptionService`).
  final Future<void> Function(ConnectionProfile profile)? _reconcileProfile;
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
      await _reconcileProfile?.call(activeProfile);
    }

    final records = await _repository.listUploadQueueCandidates();
    final retryableRecords = records.where(_requiresDrainPass);
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
      } catch (error) {
        // Best effort: the record is persisted as failed with its typed error
        // code; keep draining the rest. A per-record breadcrumb makes a
        // specific failing activity observable, not just the aggregate count.
        failed++;
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.activityUploadQueueRecordFailed,
          details: {'id': record.id, ...diagnosticErrorDetails(error)},
        );
        // A lost session fails every remaining record the same way; they stay
        // retryable and drain after the next sign-in.
        if (ActivityUploadService.isAuthFailure(error)) {
          break;
        }
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
