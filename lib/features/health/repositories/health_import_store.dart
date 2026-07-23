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

  /// Returns every stored import for [sourceId] across all connection profiles.
  ///
  /// Health-platform workout ids are device-global, so the same [sourceId] can
  /// appear under more than one profile (e.g. imported to a self-hosted and a
  /// managed connection). Callers reconcile these against the authoritative
  /// local activity record before adopting one (see [reassignImportProfile]).
  Future<List<({String profileId, String localActivityId})>> importsForSource(
    String sourceId,
  );

  /// Re-keys the import for [sourceId] from [fromProfileId] to [toProfileId].
  ///
  /// Used to migrate a provenance row written under a pre-origin-qualified
  /// profile id onto the current globally-unique profile id once the linked
  /// local activity confirms it belongs to that connection.
  Future<void> reassignImportProfile({
    required String sourceId,
    required String fromProfileId,
    required String toProfileId,
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
