import 'dart:async';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
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
import 'package:endurain/features/health/services/health_discovery_cursor.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';
import 'package:endurain/features/health/services/health_workout_importer.dart';
import 'package:flutter/foundation.dart';

const Duration _discoveryPageWindow = Duration(days: 30);

/// How far before the last successful sync an incremental pass looks again.
///
/// Wearables can sync a workout into Health hours or days after it ended, so
/// the watermark alone would skip late arrivals.
const Duration _incrementalOverlap = Duration(hours: 48);
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
    Future<bool> Function(String sourceId)? isRecordedElsewhere,
    DateTime Function()? now,
  }) : _importRepo = importRepository,
       _activeConnectionProfile = activeConnectionProfile,
       _isRecordedElsewhere = isRecordedElsewhere ?? _neverRecordedElsewhere,
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

  /// Whether another Endurain path already stored the health workout with
  /// this source id (a session handed over by the companion watch, which also
  /// saves its workout to the health platform). Such workouts are neither
  /// offered nor imported, so the same session is not uploaded twice.
  final Future<bool> Function(String sourceId) _isRecordedElsewhere;
  final DateTime Function() _now;

  static Future<bool> _neverRecordedElsewhere(String _) async => false;

  late final HealthWorkoutImporter _importer = HealthWorkoutImporter(
    importRepository: _importRepo,
    localActivities: _localActivities,
    gpxBuilder: _gpxBuilder,
    isRecordedElsewhere: _isRecordedElsewhere,
    now: _now,
  );

  final HealthDiscoveryCursor _cursor = HealthDiscoveryCursor();
  final SerialTaskQueue _queue = SerialTaskQueue();

  /// Number of workouts in the latest read whose route data could not be read.
  int get routeConsentDeniedCount => _cursor.routeConsentDeniedCount;

  /// Whether the importable list stopped paging back because workouts older
  /// than the platform's readable history window need a history access the
  /// user has not granted (Health Connect without `READ_HEALTH_DATA_HISTORY`).
  bool get olderWorkoutsUnavailable => _cursor.historyUnavailable;

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
  @visibleForTesting
  Future<List<HealthWorkout>> listImportable() {
    return loadAvailable().then((page) => page.items);
  }

  Future<HealthWorkoutPage> loadAvailable({
    HealthImportRange range = HealthImportRange.defaultRange,
  }) {
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      return _loadAvailableForProfile(
        profile,
        cursor: _cursor,
        range: range,
        reset: true,
      );
    });
  }

  Future<HealthWorkoutPage> loadMoreAvailable() {
    return _serialize(() async {
      final profile = await _requireActiveProfile();
      return _loadAvailableForProfile(
        profile,
        cursor: _cursor,
        range: _cursor.range ?? HealthImportRange.defaultRange,
        reset: false,
      );
    });
  }

  /// Reads the next page of importable workouts into [cursor].
  ///
  /// The Health Sync screen pages through the service's own cursor; one-shot
  /// imports ([importAll], [autoSyncOnResume]) pass a fresh one so they never
  /// disturb what the screen is showing.
  Future<HealthWorkoutPage> _loadAvailableForProfile(
    ConnectionProfile profile, {
    required HealthDiscoveryCursor cursor,
    required HealthImportRange range,
    required bool reset,
    HealthImportBounds? bounds,
  }) async {
    if (!_healthSyncEnabled) {
      cursor.reset();
      return const HealthWorkoutPage(items: [], hasMore: false);
    }

    if (reset || cursor.profileId != profile.id || cursor.range != range) {
      cursor.begin(
        profileId: profile.id,
        range: range,
        bounds: bounds ?? range.resolve(_now()),
      );
    }

    final cursorBounds = cursor.bounds!;
    final pageEndExclusive = cursor.nextPageEndExclusive!;
    if (!cursor.hasMore ||
        !pageEndExclusive.isAfter(cursorBounds.startInclusive)) {
      cursor.hasMore = false;
      return HealthWorkoutPage(
        items: List.unmodifiable(cursor.candidates),
        hasMore: false,
      );
    }

    final proposedStart = pageEndExclusive.subtract(_discoveryPageWindow);
    final pageStart = proposedStart.isBefore(cursorBounds.startInclusive)
        ? cursorBounds.startInclusive
        : proposedStart;
    final pageEndInclusive = pageEndExclusive.subtract(
      const Duration(microseconds: 1),
    );

    // Already-imported workouts and ones another Endurain path recorded are
    // skipped inside the read, before their heart rate is fetched. Discovery
    // is read-only: a missing local record stays in Imported history until
    // the user explicitly restores it (or deletes it through local history,
    // which removes provenance as part of that workflow).
    final candidates = await _readWorkouts(
      profile: profile,
      start: pageStart,
      end: pageEndInclusive,
      exclude: (sourceId) => _importer.isAlreadyHandled(profile, sourceId),
    );

    await _ensureProfileUnchanged(profile);

    final mergedById = {
      for (final workout in cursor.candidates) workout.sourceId: workout,
      for (final workout in candidates) workout.sourceId: workout,
    };
    cursor.candidates = mergedById.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    cursor.nextPageEndExclusive = pageStart;
    // Without history access, every older page would prompt again and come
    // back empty, so paging stops here.
    if (_adapter.historyAccessDeclined) cursor.historyUnavailable = true;
    cursor.hasMore =
        !cursor.historyUnavailable &&
        pageStart.isAfter(cursorBounds.startInclusive);
    cursor.routeConsentDeniedCount += _adapter.routeConsentDeniedCount;
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.healthListImportable,
      details: {
        'total': candidates.length,
        'importable': candidates.where((w) => w.hasRoute).length,
        'no_route': candidates.where((w) => !w.hasRoute).length,
        'has_more': cursor.hasMore,
        'history_unavailable': cursor.historyUnavailable,
      },
    );
    return HealthWorkoutPage(
      items: List.unmodifiable(cursor.candidates),
      hasMore: cursor.hasMore,
    );
  }

  Future<List<HealthWorkout>> _readWorkouts({
    required ConnectionProfile profile,
    required DateTime start,
    required DateTime end,
    required Future<bool> Function(String sourceId) exclude,
  }) async {
    try {
      return await _adapter.readWorkouts(
        start: start,
        end: end,
        exclude: exclude,
      );
    } on AppException catch (error) {
      // HealthKit does not reveal read authorization status. If the platform
      // refuses a read for lack of permission, require the user to reconnect
      // so the next explicit action can request authorization again. Any
      // other read failure (transient or not) says nothing about access, so
      // the connection is kept.
      if (error.code == AppErrorCode.healthPermissionDenied) {
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
  /// IDs that are non-importable (no GPS route) or already imported
  /// (idempotent / safe to call twice). An ID that is in neither the current
  /// candidate list nor the import history cannot be imported and counts as
  /// failed.
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
          cursor: _cursor,
          range: HealthImportRange.defaultRange,
          reset: true,
        );
      }
      return _importSelected(profile, ids, _cursor.candidates);
    });
  }

  Future<({int imported, int failed})> _importSelected(
    ConnectionProfile profile,
    Set<String> sourceIds,
    List<HealthWorkout> candidates, {
    bool incremental = false,
  }) async {
    final candidateIds = {for (final w in candidates) w.sourceId};
    final toImport = candidates
        .where((w) => sourceIds.contains(w.sourceId) && w.hasRoute)
        .toList();

    var imported = 0;
    var failed = 0;

    // A selected workout missing from the candidates has no data to import
    // here. Unless it was imported (or recorded elsewhere) meanwhile, report it
    // as failed instead of dropping it silently.
    for (final sourceId in sourceIds.difference(candidateIds)) {
      if (!await _importer.isAlreadyHandled(profile, sourceId)) failed++;
    }

    for (final workout in toImport) {
      if (await _importRepo.isImported(
            profileId: profile.id,
            sourceId: workout.sourceId,
          ) ||
          await _isRecordedElsewhere(workout.sourceId)) {
        continue;
      }
      try {
        await _ensureProfileUnchanged(profile);
        await _importer.persist(profile, workout);
        imported++;
      } catch (error) {
        failed++;
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.healthImportWorkoutFailed,
          details: diagnosticErrorDetails(error),
        );
      }
    }

    // An incremental pass only moves the watermark when nothing failed: a
    // failed workout must stay inside the next pass's window to be retried.
    final advanceWatermark = incremental ? failed == 0 : imported > 0;
    if (advanceWatermark) {
      await _importRepo.setLastSyncAt(profile.id, _now());
    }
    if (imported > 0) {
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
      return _importDefaultRangeForProfile(profile, incremental: true);
    });
  }

  /// Discovers and imports the default range with its own discovery state,
  /// leaving the Health Sync screen's list and paging untouched.
  ///
  /// With [incremental], discovery starts at the stored last-sync time minus
  /// [_incrementalOverlap] instead of re-reading the whole default range on
  /// every resume. It never reaches further back than the default range, and
  /// falls back to it when there is no prior sync.
  Future<({int imported, int failed})> _importDefaultRangeForProfile(
    ConnectionProfile profile, {
    bool incremental = false,
  }) async {
    final cursor = HealthDiscoveryCursor();
    final defaultBounds = HealthImportRange.defaultRange.resolve(_now());
    var bounds = defaultBounds;
    if (incremental) {
      final lastSyncAt = await _importRepo.lastSyncAt(profile.id);
      if (lastSyncAt != null) {
        final start = lastSyncAt.toUtc().subtract(_incrementalOverlap);
        if (start.isAfter(defaultBounds.startInclusive)) {
          bounds = HealthImportBounds(
            startInclusive: start,
            endExclusive: defaultBounds.endExclusive,
          );
        }
      }
    }
    await _loadAvailableForProfile(
      profile,
      cursor: cursor,
      range: HealthImportRange.defaultRange,
      reset: true,
      bounds: bounds,
    );
    final ids = cursor.candidates
        .where((workout) => workout.hasRoute)
        .map((workout) => workout.sourceId)
        .toSet();
    return _importSelected(
      profile,
      ids,
      cursor.candidates,
      incremental: incremental,
    );
  }

  // ── Private ─────────────────────────────────────────────────────────────

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

  Future<T> _serialize<T>(Future<T> Function() operation) =>
      _queue.run(operation);
}
