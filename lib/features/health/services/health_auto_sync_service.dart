import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:endurain/features/health/services/health_background_sync_adapter.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';

/// How far before the last successful sync a pass without a usable changes
/// token looks again.
///
/// Wearables can sync a workout into Health hours or days after it ended, so
/// the last-sync time alone would skip late arrivals.
const Duration _incrementalOverlap = Duration(hours: 48);

/// Imports new health workouts without the user asking: when the app returns
/// to the foreground and, where the platform allows, in the background
/// (WorkManager on Android, HealthKit background delivery on iOS).
///
/// One per-profile setting turns both on. Each pass reads only the workouts
/// added or changed since the previous pass, through the platform's changes
/// token. Without a usable token (the first pass, or one Health Connect
/// expired) it reads the window since the last sync, with an overlap, and
/// takes a new token. Passes never reach further back than the default
/// import range.
class HealthAutoSyncService {
  HealthAutoSyncService({
    required this._syncService,
    required this._adapter,
    required this._background,
    required this._settings,
    required this._importRepository,
    required this._uploadQueue,
    required this._diagnostics,
    required this._healthSyncEnabled,
    required this._activeConnectionProfile,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final HealthSyncService _syncService;
  final HealthPlatformAdapter _adapter;
  final HealthBackgroundSyncAdapter _background;
  final HealthSyncSettingsRepository _settings;
  final HealthImportRepository _importRepository;
  final ActivityUploadQueue _uploadQueue;
  final DiagnosticsRecorder _diagnostics;
  final bool _healthSyncEnabled;
  final Future<ConnectionProfile?> Function() _activeConnectionProfile;
  final DateTime Function() _now;
  final SerialTaskQueue _queue = SerialTaskQueue();

  /// Whether the active profile has automatic import turned on.
  Future<bool> isEnabled() async {
    final profile = await _activeConnectionProfile();
    if (profile == null) return false;
    return _settings.isAutoSyncEnabled(profile.id);
  }

  /// Turns automatic import on or off for the active profile.
  ///
  /// Turning it on asks for the Health Connect background permission where
  /// it is needed; the background trigger is only scheduled when it is held.
  /// Without it, workouts still import when the app returns to the
  /// foreground.
  Future<void> setEnabled(bool enabled) {
    return _queue.run(() async {
      final profile = await _activeConnectionProfile();
      if (profile == null) {
        throw const AppException(AppErrorCode.notAuthenticated);
      }
      final inBackground =
          enabled && await _adapter.requestBackgroundReadAccess();
      await _settings.setAutoSyncEnabled(profile.id, enabled);
      await _schedule(inBackground);
    });
  }

  /// Runs one pass when the app returns to the foreground, and brings the
  /// background trigger in line with the setting, the health authorization
  /// and the background permission, which may all have changed meanwhile.
  ///
  /// Returns `null` when automatic import is off, nobody is signed in, or
  /// health access is not granted.
  Future<({int imported, int failed})?> syncOnResume() {
    if (!_healthSyncEnabled) return Future.value(null);
    return _queue.run(() async {
      final result = await _pass();
      await _schedule(
        result != null && await _adapter.hasBackgroundReadAccess(),
      );
      return result;
    });
  }

  /// Runs one pass for the background trigger and waits for the uploads it
  /// queued, so the platform keeps the app running until they finish.
  ///
  /// Returns whether the pass ran without failures. A pass with nothing to
  /// do (automatic import off, signed out, access gone) turns the background
  /// trigger off; [syncOnResume] turns it back on when it applies again.
  /// Failures are recorded, never thrown: the platform only needs to know
  /// that the run is over.
  Future<bool> syncInBackground() async {
    try {
      final result = await _queue.run(() async {
        final result =
            _healthSyncEnabled && await _adapter.hasBackgroundReadAccess()
            ? await _pass()
            : null;
        if (result == null) await _schedule(false);
        return result;
      });
      if (result == null) return true;
      if (result.imported > 0) await _uploadQueue.drain();
      return result.failed == 0;
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthBackgroundSyncFailed,
        details: diagnosticErrorDetails(error),
      );
      return false;
    }
  }

  Future<({int imported, int failed})?> _pass() async {
    final profile = await _activeConnectionProfile();
    if (profile == null || !await _settings.isAutoSyncEnabled(profile.id)) {
      return null;
    }
    if (await _syncService.currentAuthorizationStatus() !=
        HealthAuthorizationStatus.granted) {
      return null;
    }

    final storedToken = await _settings.workoutChangesToken(profile.id);
    final changes = storedToken == null
        ? null
        : await _adapter.workoutChangesSince(storedToken);
    final String nextToken;
    final HealthImportBounds? bounds;
    if (changes?.nextToken case final token?) {
      nextToken = token;
      bounds = _boundsFrom(changes!.earliestStart);
    } else {
      // Taken before the window is read, so a workout saved while it is read
      // is reported by the next pass rather than missed.
      nextToken = await _adapter.workoutChangesToken();
      bounds = await _windowSinceLastSync(profile);
    }

    final result = await _syncService.importIncremental(profile, bounds);
    // A failed workout must be read again by the next pass.
    if (result.failed == 0) {
      await _settings.setWorkoutChangesToken(profile.id, nextToken);
    }
    return result;
  }

  /// The default range from [earliestStart] on, or `null` when nothing
  /// changed.
  HealthImportBounds? _boundsFrom(DateTime? earliestStart) {
    if (earliestStart == null) return null;
    final defaults = HealthImportRange.defaultRange.resolve(_now());
    final start = earliestStart.toUtc();
    return HealthImportBounds(
      startInclusive: start.isAfter(defaults.startInclusive)
          ? start
          : defaults.startInclusive,
      endExclusive: defaults.endExclusive,
    );
  }

  /// The default range, starting [_incrementalOverlap] before the last sync
  /// when that is later.
  Future<HealthImportBounds> _windowSinceLastSync(
    ConnectionProfile profile,
  ) async {
    final defaults = HealthImportRange.defaultRange.resolve(_now());
    final lastSyncAt = await _importRepository.lastSyncAt(profile.id);
    if (lastSyncAt == null) return defaults;
    final start = lastSyncAt.toUtc().subtract(_incrementalOverlap);
    if (!start.isAfter(defaults.startInclusive)) return defaults;
    return HealthImportBounds(
      startInclusive: start,
      endExclusive: defaults.endExclusive,
    );
  }

  /// Schedules or cancels the background trigger. A failure (for example a
  /// build without the HealthKit background delivery entitlement) is
  /// recorded and does not fail the caller: workouts still import when the
  /// app returns to the foreground.
  Future<void> _schedule(bool scheduled) async {
    try {
      await _background.setScheduled(scheduled);
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthBackgroundScheduleFailed,
        details: {'scheduled': scheduled, ...diagnosticErrorDetails(error)},
      );
    }
  }
}
