import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_finalizer.dart';
import 'package:endurain/features/activity/services/activity_gpx_builder.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';

/// Builds an [ActivityRecordingController] with default collaborators, which
/// the production constructor deliberately requires from the composition root.
///
/// The defaults match what the controller used to create for itself, so tests
/// that never reach storage or the network behave as before.
ActivityRecordingController createTestRecordingController({
  required ActivityRecordingService recordingService,
  ActivityUploadService? uploadService,
  LocalActivityRepository? localActivityRepository,
  ActivityGpxBuilder gpxBuilder = const ActivityGpxBuilder(),
  ActivityRetentionSettingsRepository? retentionSettingsRepository,
  AutoPauseSettingsRepository? autoPauseSettingsRepository,
  Future<bool> Function()? isUploadAuthorized,
  Future<ConnectionProfile?> Function()? activeConnectionProfile,
  DiagnosticsRecorder? diagnostics,
  String Function()? localActivityIdProvider,
  DateTime Function()? now,
  bool ownsService = true,
}) {
  final repository = localActivityRepository ?? LocalActivityRepository();
  return ActivityRecordingController(
    recordingService: recordingService,
    uploadService: uploadService ?? ActivityUploadService(),
    localActivityRepository: repository,
    finalizer: ActivityFinalizer(
      repository: repository,
      summaryBuilder: LocalActivitySummaryBuilder(),
      gpxBuilder: gpxBuilder,
      now: now,
    ),
    retentionSettingsRepository: retentionSettingsRepository,
    autoPauseSettingsRepository: autoPauseSettingsRepository,
    isUploadAuthorized: isUploadAuthorized,
    activeConnectionProfile: activeConnectionProfile,
    diagnostics: diagnostics,
    localActivityIdProvider: localActivityIdProvider,
    now: now,
    ownsService: ownsService,
  );
}

/// Builds a [ActivityFinalizer] over [repository] for tests.
ActivityFinalizer createTestFinalizer(
  LocalActivityRepository repository, {
  DateTime Function()? now,
  ActivityGpxBuilder gpxBuilder = const ActivityGpxBuilder(),
}) => ActivityFinalizer(
  repository: repository,
  summaryBuilder: LocalActivitySummaryBuilder(),
  gpxBuilder: gpxBuilder,
  now: now,
);
