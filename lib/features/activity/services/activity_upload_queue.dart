import 'dart:async';

import 'package:endurain/core/services/diagnostics_service.dart';
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
    required LocalActivityRepository repository,
    required ActivityUploadService uploadService,
    ActivityRetentionSettingsRepository? retentionSettingsRepository,
    DiagnosticsRecorder? diagnostics,
    DateTime Function()? now,
    Stream<bool>? connectivitySignal,
  }) : _repository = repository,
       _uploadService = uploadService,
       _retentionSettingsRepository = retentionSettingsRepository,
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

  static const Set<LocalActivityUploadStatus> _drainableStatuses = {
    LocalActivityUploadStatus.pending,
    LocalActivityUploadStatus.failed,
  };

  final LocalActivityRepository _repository;
  final ActivityUploadService _uploadService;
  final ActivityRetentionSettingsRepository? _retentionSettingsRepository;
  final DiagnosticsRecorder _diagnostics;
  final DateTime Function() _now;

  StreamSubscription<bool>? _connectivitySubscription;
  Future<void>? _inFlightDrain;

  /// Re-attempts every locally-stored activity whose upload has not yet
  /// succeeded. Best-effort: a failure on one record does not stop the others,
  /// and each record keeps its persisted `failed` status for the UI.
  ///
  /// Single-flight: a concurrent call returns the in-progress future.
  Future<void> drain() {
    return _inFlightDrain ??= _drain().whenComplete(() {
      _inFlightDrain = null;
    });
  }

  Future<void> _drain() async {
    if (!_uploadService.isConfigured) {
      return;
    }

    final pending = await _repository.listByUploadStatus(_drainableStatuses);
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

  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = null;
  }
}
