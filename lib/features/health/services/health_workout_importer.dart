import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/scoped_storage_key.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';

/// Turns discovered health workouts into local activities and keeps the
/// import provenance consistent: dedupes against earlier imports and
/// workouts another Endurain path recorded, adopts pre-migration imports, and
/// writes the GPX, activity record and provenance row for a new import.
///
/// Holds no state and does no profile checks or serialization; the caller
/// (`HealthSyncService`) pins the profile and serializes access.
class HealthWorkoutImporter {
  HealthWorkoutImporter({
    required HealthImportRepository importRepository,
    required LocalActivityRepository localActivities,
    required HealthWorkoutGpxBuilder gpxBuilder,
    required Future<bool> Function(String sourceId) isRecordedElsewhere,
    required DateTime Function() now,
  }) : _importRepo = importRepository,
       _localActivities = localActivities,
       _gpxBuilder = gpxBuilder,
       _isRecordedElsewhere = isRecordedElsewhere,
       _now = now;

  final HealthImportRepository _importRepo;
  final LocalActivityRepository _localActivities;
  final HealthWorkoutGpxBuilder _gpxBuilder;
  final Future<bool> Function(String sourceId) _isRecordedElsewhere;
  final DateTime Function() _now;

  /// Whether the workout with [sourceId] is already imported for [profile]
  /// (adopting a stray pre-migration import) or was recorded by another
  /// Endurain path, so it is neither offered nor imported.
  Future<bool> isAlreadyHandled(
    ConnectionProfile profile,
    String sourceId,
  ) async {
    var importedLocalId = await _importRepo.localActivityIdFor(
      profileId: profile.id,
      sourceId: sourceId,
    );
    importedLocalId ??= await _adoptStrayImport(profile, sourceId);
    return importedLocalId != null || await _isRecordedElsewhere(sourceId);
  }

  Future<void> persist(ConnectionProfile profile, HealthWorkout workout) async {
    final existingMappedLocalId = await _importRepo.localActivityIdFor(
      profileId: profile.id,
      sourceId: workout.sourceId,
    );
    final localId =
        existingMappedLocalId ?? _localIdFor(profile.id, workout.sourceId);
    final existing = await _localActivities.get(localId);
    if (existing != null) {
      if (existing.connectionOrigin != profile.origin ||
          existing.connectionProfileId != profile.id) {
        throw const AppException(AppErrorCode.healthImportFailed);
      }
      await _importRepo.markImported(
        profileId: profile.id,
        sourceId: workout.sourceId,
        localActivityId: localId,
      );
      return;
    }
    final gpx = _gpxBuilder.build(workout);

    final start = workout.startedAt;
    final end = workout.endedAt;
    final elapsedSeconds = end.difference(start).inSeconds;

    final gpxFileName = await _localActivities.writeGpx(id: localId, gpx: gpx);
    final record = LocalActivityRecord(
      id: localId,
      activityType: workout.type.toActivityType(),
      startedAt: start,
      endedAt: end,
      elapsedDurationSeconds: elapsedSeconds,
      distanceMeters: workout.distanceMeters ?? 0,
      pointCount: workout.route.length,
      gpxFileName: gpxFileName,
      uploadStatus: LocalActivityUploadStatus.pending,
      createdAt: _now(),
      updatedAt: _now(),
      // Derive the upload idempotency key from the stable source workout UUID
      // so a re-import (e.g. after the local dedup table is lost) collapses to
      // the same server activity instead of creating a duplicate.
      idempotencyKey: existingMappedLocalId == null
          ? localId
          : 'health_${workout.sourceId}',
      connectionOrigin: profile.origin,
      connectionProfileId: profile.id,
    );

    await _localActivities.upsert(record);
    await _importRepo.markImported(
      profileId: profile.id,
      sourceId: workout.sourceId,
      localActivityId: localId,
    );
  }

  /// Reconciles a workout imported under a pre-origin-qualified profile id.
  ///
  /// Older app versions keyed health provenance on the raw server account id,
  /// which is not unique across origins. Returns the adopted local activity id
  /// when a stray provenance row for [sourceId] is confirmed — by its linked
  /// local activity's origin and (migrated) profile id — to belong to the
  /// active [profile], re-keying that row onto the current profile id. Returns
  /// `null` when there is nothing to adopt, so discovery treats the workout as
  /// importable. The linked activity is the source of truth, so a workout
  /// imported for a *different* connection on the same device is never adopted.
  Future<String?> _adoptStrayImport(
    ConnectionProfile profile,
    String sourceId,
  ) async {
    final strays = await _importRepo.importsForSource(sourceId);
    for (final stray in strays) {
      if (stray.profileId == profile.id) {
        // Already keyed to the active profile; the direct lookup handled it.
        continue;
      }
      final record = await _localActivities.get(stray.localActivityId);
      if (record != null &&
          record.connectionOrigin == profile.origin &&
          record.connectionProfileId == profile.id) {
        await _importRepo.reassignImportProfile(
          sourceId: sourceId,
          fromProfileId: stray.profileId,
          toProfileId: profile.id,
        );
        return stray.localActivityId;
      }
    }
    return null;
  }

  String _localIdFor(String profileId, String sourceId) {
    return scopedStorageKey('health', '$profileId\n$sourceId');
  }
}
