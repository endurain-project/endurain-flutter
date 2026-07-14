import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';

/// Persistent store tracking which health workouts have already been imported.
///
/// ## Contract
/// - [isImported] returns `true` only for workouts that have been fully
///   persisted and enqueued for upload via `markImported`.
/// - `markImported` is idempotent: calling it twice for the same `sourceId`
///   must not throw or corrupt state.
/// - [lastSyncAt] / [setLastSyncAt] track display and auto-sync state only;
///   deduplication relies exclusively on the imported `sourceId` set.
/// - Failures are surfaced as [AppException] with an appropriate
///   `AppErrorCode`; implementations must never log `sourceId` values or
///   any other PII in diagnostic output.
abstract class HealthImportStore {
  /// Returns `true` when the workout identified by [sourceId] has already been
  /// imported (persisted and enqueued for upload) for [profileId].
  Future<bool> isImported({
    required String profileId,
    required String sourceId,
  });

  Future<String?> localActivityIdFor({
    required String profileId,
    required String sourceId,
  });

  Future<String?> legacyLocalActivityIdFor(String sourceId);

  Future<void> adoptLegacyImport({
    required String profileId,
    required String sourceId,
  });

  /// Marks [sourceId] as imported, recording the [localActivityId] of the
  /// newly-created local activity record.
  ///
  /// Idempotent — safe to call more than once for the same [sourceId].
  Future<void> markImported({
    required String profileId,
    required String sourceId,
    required String localActivityId,
  });

  Future<void> removeByLocalActivityId(String localActivityId);

  /// Removes all imported-workout dedup rows and sync state for [profileId].
  Future<void> clearForProfile(String profileId);

  Future<List<HealthImportedWorkout>> listImported({
    required String profileId,
    required int offset,
    required int limit,
  });

  /// Returns the UTC timestamp of the last successful import, or `null` if
  /// no import has completed yet.
  Future<DateTime?> lastSyncAt(String profileId);

  /// Persists [at] as the last successful sync timestamp.
  Future<void> setLastSyncAt(String profileId, DateTime at);
}
