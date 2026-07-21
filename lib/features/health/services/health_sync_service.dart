import 'dart:async';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/utils/scoped_storage_key.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_page.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';

const Duration _discoveryPageWindow = Duration(days: 30);
const int _defaultImportedPageSize = 20;

/// Orchestrates the health import pipeline.
///
/// A health workout becomes a GPX file and enters the existing
/// [LocalActivityRepository] → [ActivityUploadQueue] pipeline, identical to
/// the GPS recording path, giving durable storage, retry, idempotency, and
/// connectivity handling for free.
class HealthSyncService {
  HealthSyncService({
    required this._adapter,
    required HealthImportRepository importRepository,
    required this._localActivities,
    required this._uploadQueue,
    required this._gpxBuilder,
    required this._syncSettings,
    required this._diagnostics,
    required this._healthSyncEnabled,
    required Future<ConnectionProfile?> Function() activeConnectionProfile,
    DateTime Function()? now,
  }) : _importRepo = importRepository,
       _activeConnectionProfile = activeConnectionProfile,
       _now = now ?? DateTime.now;

  final HealthPlatformAdapter _adapter;
  final HealthImportRepository _importRepo;
  final LocalActivityRepository _localActivities;
  final ActivityUploadQueue _uploadQueue;
  final HealthWorkoutGpxBuilder _gpxBuilder;
  final HealthSyncSettingsRepository _syncSettings;
  final DiagnosticsRecorder _diagnostics;
  final bool _healthSyncEnabled;
  final Future<ConnectionProfile?> Function() _activeConnectionProfile;
  final DateTime Function() _now;

  final _DiscoveryCursor _cursor = _DiscoveryCursor();
  final SerialTaskQueue _queue = SerialTaskQueue();

  /// Number of workouts in the latest read whose route data could not be read.
  int get routeConsentDeniedCount => _cursor.routeConsentDeniedCount;

  /// Returns `true` when auto-sync on app resume has been enabled by the user.
  ///
  /// Used by the optional Phase N auto-sync path in `app.dart`.
  Future<bool> isAutoSyncOnResumeEnabled() async {
    final profile = await _activeConnectionProfile();
    if (profile == null) return false;
    return _syncSettings.isAutoSyncOnResumeEnabled(profile.id);
  }

  /// Enables or disables auto-sync on app resume.
  Future<void> setAutoSyncOnResumeEnabled(bool enabled) async {
    final profile = await _requireActiveProfile();
    await _syncSettings.setAutoSyncOnResumeEnabled(profile.id, enabled);
  }

  // ── Status ──────────────────────────────────────────────────────────────

  /// Returns the current SDK availability, or [HealthSdkStatus.unsupported]
  /// when the feature is disabled via the compile-time flag.
  Future<HealthSdkStatus> status() async {
    if (!_healthSyncEnabled) return HealthSdkStatus.unsupported;
    return _adapter.getSdkStatus();
  }

  // ── Authorization ───────────────────────────────────────────────────────

  /// Returns the current authorization status without prompting the user.
  ///
  /// Resolves the platform status against the persisted "connected" flag:
  /// iOS HealthKit never reports read-permission grants (`hasPermissions`
  /// returns `notDetermined` even after a grant), so once the user has
  /// connected we treat `notDetermined` as `granted`. A platform `denied`
  /// (e.g. Health Connect permission revoked on Android) always wins.
  Future<HealthAuthorizationStatus> currentAuthorizationStatus() async {
    if (!_healthSyncEnabled) return HealthAuthorizationStatus.denied;
    final profile = await _activeConnectionProfile();
    if (profile == null) return HealthAuthorizationStatus.notDetermined;
    return _currentAuthorizationStatusFor(profile);
  }

  Future<HealthAuthorizationStatus> _currentAuthorizationStatusFor(
    ConnectionProfile profile,
  ) async {
    final raw = await _adapter.currentAuthorizationStatus();
    await _ensureProfileUnchanged(profile);
    if (raw == HealthAuthorizationStatus.granted) {
      return HealthAuthorizationStatus.granted;
    }
    if (raw == HealthAuthorizationStatus.notDetermined &&
        await _syncSettings.isConnected(profile.id)) {
      await _ensureProfileUnchanged(profile);
      return HealthAuthorizationStatus.granted;
    }
    return raw;
  }

  /// Returns a platform-aware detail of the health data Endurain requests.
  ///
  /// HealthKit does not disclose individual read grants; callers use
  /// [HealthDataAccessDetails.canInspectIndividualPermissions] to render the
  /// appropriate system-managed state.
  Future<HealthDataAccessDetails> accessDetails() async {
    if (!_healthSyncEnabled) {
      return const HealthDataAccessDetails.systemManaged();
    }
    return _adapter.getAccessDetails();
  }

  /// Requests health data authorization from the user.
  ///
  /// Short-circuits and returns [HealthAuthorizationStatus.denied] when the
  /// feature is disabled.
  ///
  /// Throws [AppException] with [AppErrorCode.healthPermissionDenied] on a
  /// hard denial.
  Future<HealthAuthorizationStatus> requestAccess() async {
    if (!_healthSyncEnabled) return HealthAuthorizationStatus.denied;
    final profile = await _requireActiveProfile();
    try {
      final result = await _adapter.requestAuthorization();
      if (result == HealthAuthorizationStatus.granted) {
        await _syncSettings.setConnected(profile.id, true);
      }
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthAuthRequested,
        details: {'result': result.name},
      );
      return result;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(AppErrorCode.healthPermissionDenied, cause: e);
    }
  }

  /// Directs the user to the app store to install the health provider
  /// (Google Health Connect on Android).
  ///
  /// No-op when the feature is disabled.
  Future<void> installHealthConnect() async {
    if (!_healthSyncEnabled) return;
    await _adapter.installHealthConnect();
  }

  Future<void> disconnect() {
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      await _adapter.revokePermissions();
      await _syncSettings.clearForProfile(profile.id);
      await _importRepo.clearForProfile(profile.id);
      _cursor.reset();
    });
  }

  /// Clears the route-scoped discovery cursor and candidate cache.
  ///
  /// The owning `HealthSyncController` calls this on dispose so the importable
  /// list's view state does not linger on this app-lifetime service after the
  /// user leaves the health-sync route. Serialized against in-flight discovery
  /// so any concurrent page read completes first.
  Future<void> clearDiscoveryCache() {
    return _serialize(() async => _cursor.reset());
  }

  Future<DateTime?> lastSyncAt() async {
    final profile = await _requireActiveProfile();
    return _importRepo.lastSyncAt(profile.id);
  }

  // ── Preview ─────────────────────────────────────────────────────────────

  /// Loads the first page of importable workouts from the default 30-day
  /// range, discarding pagination metadata.
  ///
  /// A convenience wrapper over [loadAvailable] for callers and tests that only
  /// need the items; the controller uses [loadAvailable] directly so it can
  /// page with `hasMore`.
  Future<List<HealthWorkout>> listImportable() {
    return loadAvailable().then((page) => page.items);
  }

  Future<HealthWorkoutPage> loadAvailable({
    HealthImportRange range = HealthImportRange.defaultRange,
  }) {
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      return _loadAvailableForProfile(profile, range: range, reset: true);
    });
  }

  Future<HealthWorkoutPage> loadMoreAvailable() {
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      return _loadAvailableForProfile(
        profile,
        range: _cursor.range ?? HealthImportRange.defaultRange,
        reset: false,
      );
    });
  }

  Future<HealthWorkoutPage> _loadAvailableForProfile(
    ConnectionProfile profile, {
    required HealthImportRange range,
    required bool reset,
  }) async {
    if (!_healthSyncEnabled) {
      _cursor.reset();
      return const HealthWorkoutPage(items: [], hasMore: false);
    }

    if (reset || _cursor.profileId != profile.id || _cursor.range != range) {
      _cursor.begin(
        profileId: profile.id,
        range: range,
        bounds: range.resolve(_now()),
      );
    }

    final bounds = _cursor.bounds!;
    final pageEndExclusive = _cursor.nextPageEndExclusive!;
    if (!_cursor.hasMore || !pageEndExclusive.isAfter(bounds.startInclusive)) {
      _cursor.hasMore = false;
      return HealthWorkoutPage(
        items: List.unmodifiable(_cursor.candidates),
        hasMore: false,
      );
    }

    final proposedStart = pageEndExclusive.subtract(_discoveryPageWindow);
    final pageStart = proposedStart.isBefore(bounds.startInclusive)
        ? bounds.startInclusive
        : proposedStart;
    final pageEndInclusive = pageEndExclusive.subtract(
      const Duration(microseconds: 1),
    );

    final all = await _readWorkouts(
      profile: profile,
      start: pageStart,
      end: pageEndInclusive,
    );

    final candidates = <HealthWorkout>[];
    for (final workout in all) {
      var importedLocalId = await _importRepo.localActivityIdFor(
        profileId: profile.id,
        sourceId: workout.sourceId,
      );
      if (importedLocalId == null) {
        final legacyLocalId = await _importRepo.legacyLocalActivityIdFor(
          workout.sourceId,
        );
        if (legacyLocalId != null) {
          final legacyRecord = await _localActivities.get(legacyLocalId);
          if (legacyRecord?.connectionOrigin == profile.origin) {
            await _importRepo.adoptLegacyImport(
              profileId: profile.id,
              sourceId: workout.sourceId,
            );
            importedLocalId = legacyLocalId;
          }
        }
      }
      if (importedLocalId != null) {
        // Discovery is read-only. A missing local record stays in Imported
        // history until the user explicitly restores it (or deletes it through
        // local history, which removes provenance as part of that workflow).
        continue;
      }
      candidates.add(workout);
    }

    await _ensureProfileUnchanged(profile);

    final mergedById = {
      for (final workout in _cursor.candidates) workout.sourceId: workout,
      for (final workout in candidates) workout.sourceId: workout,
    };
    _cursor.candidates = mergedById.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _cursor.nextPageEndExclusive = pageStart;
    _cursor.hasMore = pageStart.isAfter(bounds.startInclusive);
    _cursor.routeConsentDeniedCount += _adapter.routeConsentDeniedCount;
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.healthListImportable,
      details: {
        'total': all.length,
        'importable': candidates.where((w) => w.hasRoute).length,
        'no_route': candidates.where((w) => !w.hasRoute).length,
        'has_more': _cursor.hasMore,
      },
    );
    return HealthWorkoutPage(
      items: List.unmodifiable(_cursor.candidates),
      hasMore: _cursor.hasMore,
    );
  }

  Future<List<HealthWorkout>> _readWorkouts({
    required ConnectionProfile profile,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      return await _adapter.readWorkouts(start: start, end: end);
    } on AppException catch (error) {
      // HealthKit does not reveal read authorization status. If a persisted
      // connection can no longer read, require the user to reconnect so the
      // next explicit action can request authorization again.
      if (error.code == AppErrorCode.healthReadFailed) {
        await _syncSettings.setConnected(profile.id, false);
      }
      rethrow;
    }
  }

  Future<HealthImportedWorkoutPage> listImported({
    int offset = 0,
    int limit = _defaultImportedPageSize,
  }) {
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      final rows = await _importRepo.listImported(
        profileId: profile.id,
        offset: offset,
        limit: limit + 1,
      );
      final hasMore = rows.length > limit;
      final pageRows = rows.take(limit).toList();
      final localActivities = await _localActivities.getByIds(
        pageRows.map((entry) => entry.localActivityId).toSet(),
      );
      final localById = {
        for (final activity in localActivities) activity.id: activity,
      };
      await _ensureProfileUnchanged(profile);
      return HealthImportedWorkoutPage(
        items: [
          for (final entry in pageRows)
            HealthImportedWorkout(
              sourceId: entry.sourceId,
              localActivityId: entry.localActivityId,
              importedAt: entry.importedAt,
              localActivity: localById[entry.localActivityId],
            ),
        ],
        hasMore: hasMore,
      );
    });
  }

  Future<void> restoreMissingImport(HealthImportedWorkout imported) {
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      final activeLocalActivityId = await _importRepo.localActivityIdFor(
        profileId: profile.id,
        sourceId: imported.sourceId,
      );
      if (activeLocalActivityId != imported.localActivityId) {
        throw const AppException(AppErrorCode.healthImportFailed);
      }
      if (await _localActivities.get(imported.localActivityId) != null) {
        throw const AppException(AppErrorCode.healthImportFailed);
      }
      await _ensureProfileUnchanged(profile);
      await _importRepo.removeByLocalActivityId(imported.localActivityId);
    });
  }

  // ── Selective import ────────────────────────────────────────────────────

  /// Imports the workouts identified by [sourceIds].
  ///
  /// Resolves each ID against the most recent [loadAvailable] result. Skips
  /// IDs that are non-importable (no GPS route), already imported, or not in
  /// the current candidate list (idempotent / safe to call twice).
  ///
  /// Returns the number of workouts successfully imported. Per-workout
  /// failures are counted but do not abort the rest of the batch.
  Future<({int imported, int failed})> importWorkouts(
    Iterable<String> sourceIds,
  ) {
    if (!_healthSyncEnabled) {
      return Future.value((imported: 0, failed: 0));
    }

    final ids = Set<String>.of(sourceIds);
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      if (_cursor.profileId != profile.id) {
        await _loadAvailableForProfile(
          profile,
          range: HealthImportRange.defaultRange,
          reset: true,
        );
      }
      return _importSelected(profile, ids);
    });
  }

  Future<({int imported, int failed})> _importSelected(
    ConnectionProfile profile,
    Set<String> sourceIds,
  ) async {
    final candidates = List<HealthWorkout>.of(_cursor.candidates);

    final toImport = candidates
        .where((w) => sourceIds.contains(w.sourceId) && w.hasRoute)
        .toList();

    var imported = 0;
    var failed = 0;

    for (final workout in toImport) {
      if (await _importRepo.isImported(
        profileId: profile.id,
        sourceId: workout.sourceId,
      )) {
        continue;
      }
      try {
        await _ensureProfileUnchanged(profile);
        await _persistWorkout(profile, workout);
        imported++;
      } catch (error) {
        failed++;
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.healthImportWorkoutFailed,
          details: {'type': error.runtimeType.toString()},
        );
      }
    }

    if (imported > 0) {
      await _importRepo.setLastSyncAt(profile.id, _now());
      unawaited(_uploadQueue.drain());
    }

    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.healthImportWorkouts,
      details: {'imported': imported, 'failed': failed},
    );
    return (imported: imported, failed: failed);
  }

  /// Imports **all** route-bearing candidates discovered in the default
  /// 30-day range.
  ///
  /// Ignores any wider range from a prior [loadAvailable] preview and
  /// re-discovers the default range before importing. The resume path performs
  /// the same import through [autoSyncOnResume]; this is the unconditional
  /// entry point for one-shot "import everything" flows.
  Future<({int imported, int failed})> importAll() {
    if (!_healthSyncEnabled) {
      return Future.value((imported: 0, failed: 0));
    }
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      return _importDefaultRangeForProfile(profile);
    });
  }

  /// Runs the optional resume import against one pinned connection profile.
  ///
  /// Returns `null` when auto-sync is disabled or authorization is unavailable.
  Future<({int imported, int failed})?> autoSyncOnResume() {
    if (!_healthSyncEnabled) return Future.value(null);
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      if (!await _syncSettings.isAutoSyncOnResumeEnabled(profile.id)) {
        return null;
      }
      await _ensureProfileUnchanged(profile);
      final authorization = await _currentAuthorizationStatusFor(profile);
      if (authorization != HealthAuthorizationStatus.granted) return null;
      return _importDefaultRangeForProfile(profile);
    });
  }

  Future<({int imported, int failed})> _importDefaultRangeForProfile(
    ConnectionProfile profile,
  ) async {
    await _loadAvailableForProfile(
      profile,
      range: HealthImportRange.defaultRange,
      reset: true,
    );
    final ids = _cursor.candidates
        .where((workout) => workout.hasRoute)
        .map((workout) => workout.sourceId)
        .toSet();
    return _importSelected(profile, ids);
  }

  // ── Private ─────────────────────────────────────────────────────────────

  Future<void> _persistWorkout(
    ConnectionProfile profile,
    HealthWorkout workout,
  ) async {
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

  Future<ConnectionProfile> _requireActiveProfile() async {
    final profile = await _activeConnectionProfile();
    if (profile == null) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }
    return profile;
  }

  Future<void> _ensureProfileUnchanged(ConnectionProfile expected) async {
    final current = await _activeConnectionProfile();
    if (current?.id != expected.id || current?.origin != expected.origin) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }
  }

  String _localIdFor(String profileId, String sourceId) {
    return scopedStorageKey('health', '$profileId\n$sourceId');
  }

  Future<T> _serialize<T>(Future<T> Function() operation) =>
      _queue.run(operation);
}

/// Route-scoped discovery/pagination state for the importable-workout list.
///
/// Groups the candidate cache and paging bounds that back a single health-sync
/// route so this view state is a cohesive unit rather than seven loose fields
/// on the service. `HealthSyncService.clearDiscoveryCache` resets it when the
/// route is torn down.
class _DiscoveryCursor {
  List<HealthWorkout> candidates = const [];
  String? profileId;
  HealthImportRange? range;
  HealthImportBounds? bounds;
  DateTime? nextPageEndExclusive;
  bool hasMore = false;
  int routeConsentDeniedCount = 0;

  /// Starts a fresh discovery pass for [profileId] over [range]/[bounds].
  void begin({
    required String profileId,
    required HealthImportRange range,
    required HealthImportBounds bounds,
  }) {
    candidates = const [];
    this.profileId = profileId;
    this.range = range;
    this.bounds = bounds;
    nextPageEndExclusive = bounds.endExclusive;
    hasMore = bounds.endExclusive.isAfter(bounds.startInclusive);
    routeConsentDeniedCount = 0;
  }

  /// Drops all cursor state so no route-scoped candidates linger.
  void reset() {
    candidates = const [];
    profileId = null;
    range = null;
    bounds = null;
    nextPageEndExclusive = null;
    hasMore = false;
    routeConsentDeniedCount = 0;
  }
}
