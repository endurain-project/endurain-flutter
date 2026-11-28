import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_changes.dart';
import 'package:endurain/features/health/services/health_heart_rate_index.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_read_failure.dart';
import 'package:endurain/features/health/services/health_read_window.dart';
import 'package:endurain/features/health/services/health_workout_changes_reader.dart';
import 'package:endurain/features/health/services/health_workout_mapper.dart';
import 'package:endurain/features/health/services/heart_rate_series_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

const _coreReadTypes = [
  HealthDataType.WORKOUT,
  HealthDataType.WORKOUT_ROUTE,
  HealthDataType.HEART_RATE,
];

/// Only what the import uses: Play rejects unused Health Connect reads.
const _androidWorkoutSummaryReadTypes = [HealthDataType.DISTANCE_DELTA];

/// [HealthPlatformAdapter] backed by the `health` Flutter package.
///
/// Connects to HealthKit on iOS and Health Connect on Android. Inject a
/// [Health] instance for unit testing (no native calls in tests).
///
/// When `heartRateSeriesReader` is given (iOS), heart rate is read through it
/// per workout instead of through the plugin, so readings HealthKit condensed
/// into a series are not reduced to one value each. If it fails, the plugin
/// read is used instead.
///
/// Workout changes are read through `workoutChangesReader` when given (iOS,
/// where the plugin has no change tracking), and otherwise through the
/// plugin's Health Connect changes token.
class HealthPackagePlatformAdapter implements HealthPlatformAdapter {
  HealthPackagePlatformAdapter({
    Health? health,
    DiagnosticsRecorder? diagnostics,
    TargetPlatform Function()? targetPlatform,
    DateTime Function()? now,
    HeartRateSeriesReader? heartRateSeriesReader,
    HealthWorkoutChangesReader? workoutChangesReader,
  }) : _health = health ?? Health(),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _targetPlatform = targetPlatform ?? _defaultTargetPlatform,
       _now = now ?? DateTime.now,
       _heartRateSeriesReader = heartRateSeriesReader,
       _injectedChangesReader = workoutChangesReader;

  final Health _health;
  final HeartRateSeriesReader? _heartRateSeriesReader;
  final HealthWorkoutChangesReader? _injectedChangesReader;
  late final HealthWorkoutChangesReader _changesReader =
      _injectedChangesReader ?? HealthConnectWorkoutChangesReader(_health);
  final DiagnosticsRecorder _diagnostics;
  final TargetPlatform Function() _targetPlatform;
  final DateTime Function() _now;
  int _routeConsentDeniedCount = 0;
  bool _historyAccessDeclined = false;
  Future<void>? _configureOnce;

  static TargetPlatform _defaultTargetPlatform() => defaultTargetPlatform;

  List<HealthDataType> get _readTypes => [
    ..._coreReadTypes,
    if (_targetPlatform() == TargetPlatform.android)
      ..._androidWorkoutSummaryReadTypes,
  ];

  List<HealthDataAccess> get _readAccess =>
      List.filled(_readTypes.length, HealthDataAccess.READ);

  @override
  int get routeConsentDeniedCount => _routeConsentDeniedCount;

  @override
  bool get historyAccessDeclined => _historyAccessDeclined;

  /// The `health` plugin requires [Health.configure] to be called exactly once
  /// before any other call. Without it, iOS HealthKit calls fail before a
  /// permission prompt can be shown. The future is cached so configuration
  /// runs only once for the lifetime of this adapter.
  Future<void> _ensureConfigured() {
    return _configureOnce ??= _health.configure();
  }

  // ── Status & authorization ──────────────────────────────────────────────

  @override
  Future<HealthSdkStatus> getSdkStatus() async {
    try {
      await _ensureConfigured();
      if (_targetPlatform() == TargetPlatform.iOS) {
        return HealthSdkStatus.available;
      }
      if (_targetPlatform() != TargetPlatform.android) {
        return HealthSdkStatus.unsupported;
      }

      final status = await _health.getHealthConnectSdkStatus();
      // Record the raw platform SDK status (sanitized enum name only) so the
      // Diagnostics screen shows the ground-truth Health Connect availability.
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthConnectSdkStatus,
        details: {'status': status?.name ?? 'null'},
      );
      return switch (status) {
        HealthConnectSdkStatus.sdkAvailable => HealthSdkStatus.available,
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
          HealthSdkStatus.needsProviderInstall,
        _ => HealthSdkStatus.unsupported,
      };
    } catch (_) {
      return HealthSdkStatus.unsupported;
    }
  }

  @override
  Future<HealthAuthorizationStatus> requestAuthorization() async {
    try {
      await _ensureConfigured();
      var granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readAccess,
      );
      if (granted && _targetPlatform() == TargetPlatform.android) {
        granted =
            await _health.hasPermissions(
              _readTypes,
              permissions: _readAccess,
            ) ==
            true;
      }
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthRequestAuthorization,
        details: {'granted': granted},
      );
      return granted
          ? HealthAuthorizationStatus.granted
          : HealthAuthorizationStatus.denied;
    } catch (e) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthRequestAuthorizationError,
        details: diagnosticErrorDetails(e),
      );
      if (isHealthPlatformUnavailable(e)) {
        throw AppException(AppErrorCode.healthUnavailable, cause: e);
      }
      if (e is HealthException &&
          e.errorCode != HealthErrorCode.permissionDenied) {
        throw healthReadFailed(e);
      }
      throw AppException(AppErrorCode.healthPermissionDenied, cause: e);
    }
  }

  @override
  Future<HealthAuthorizationStatus> currentAuthorizationStatus() async {
    try {
      await _ensureConfigured();
      final hasPermissions = await _health.hasPermissions(
        _readTypes,
        permissions: _readAccess,
      );
      return switch (hasPermissions) {
        true => HealthAuthorizationStatus.granted,
        false => HealthAuthorizationStatus.denied,
        null => HealthAuthorizationStatus.notDetermined,
      };
    } catch (error) {
      // A missing platform is not a denial: surfacing it lets the caller offer
      // an install or an explanation instead of a permission prompt.
      if (isHealthPlatformUnavailable(error)) {
        throw AppException(AppErrorCode.healthUnavailable, cause: error);
      }
      return HealthAuthorizationStatus.denied;
    }
  }

  @override
  Future<HealthDataAccessDetails> getAccessDetails() async {
    // HealthKit deliberately hides read grants, including when authorization
    // has succeeded. Never infer or display individual iOS read permissions.
    if (_targetPlatform() == TargetPlatform.iOS) {
      return const HealthDataAccessDetails.systemManaged();
    }
    if (_targetPlatform() != TargetPlatform.android) {
      return const HealthDataAccessDetails.systemManaged();
    }

    try {
      await _ensureConfigured();
      final results = await Future.wait(
        _readTypes.map(
          (type) => _health.hasPermissions(
            [type],
            permissions: const [HealthDataAccess.READ],
          ),
        ),
      );
      return HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
        workouts: healthAccessStatus(results[0]),
        workoutRoutes: healthAccessStatus(results[1]),
        heartRate: healthAccessStatus(results[2]),
      );
    } catch (_) {
      return const HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
      );
    }
  }

  @override
  Future<void> installHealthConnect() async {
    if (_targetPlatform() != TargetPlatform.android) return;
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.healthInstallProviderRequested,
    );
    await _health.installHealthConnect();
  }

  @override
  Future<void> revokePermissions() async {
    try {
      await _ensureConfigured();
      await _health.revokePermissions();
    } catch (error) {
      throw AppException(AppErrorCode.healthPermissionDenied, cause: error);
    }
  }

  // ── Workout reading ─────────────────────────────────────────────────────

  @override
  Future<List<HealthWorkout>> readWorkouts({
    required DateTime start,
    required DateTime end,
    Future<bool> Function(String sourceId)? exclude,
  }) async {
    // Reset per-read state first, so an early return or a failure never
    // leaves the previous read's values behind.
    _routeConsentDeniedCount = 0;
    _historyAccessDeclined = false;
    try {
      await _ensureConfigured();
      final window = await resolveHealthReadWindow(
        requestedStart: start,
        now: _now(),
        isAndroid: _targetPlatform() == TargetPlatform.android,
        hasHistoryAccess: _hasHistoryAccess,
      );
      _historyAccessDeclined = window.historyClamped;
      final effectiveStart = window.start;
      // An unauthorized historical page can clamp its start past [end]; reading
      // an inverted window would only return an empty list, so skip it.
      if (!effectiveStart.isBefore(end)) return const [];
      // Step 1 — Fetch workout metadata.
      final allWorkoutPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: effectiveStart,
        endTime: end,
      );
      final partition = await partitionHealthWorkoutPoints(
        allWorkoutPoints,
        exclude: exclude,
      );
      final workoutPoints = partition.importable;
      if (workoutPoints.isEmpty) return const [];

      // Step 2 — Fetch GPS routes for the same window and give each one to
      // the single workout that owns it. Every workout in the window takes
      // part, including skipped ones, so a skipped workout's route is never
      // handed to a neighbour.
      final routes = await _fetchRoutes(
        start: effectiveStart,
        end: end,
        workoutCount: workoutPoints.length,
      );
      final routesByWorkout = assignHealthRoutes(
        routes: routes,
        workoutPoints: allWorkoutPoints,
      );

      // Step 3 — Fetch heart rate readings for the remaining workouts only.
      final heartRate = await _fetchHeartRate(workoutPoints: workoutPoints);
      final heartRateIndex = HealthHeartRateIndex(heartRate.samples);

      // Step 4 — Map each workout data point to a HealthWorkout.
      final workouts = workoutPoints
          .map(
            (pt) => mapHealthWorkout(
              point: pt,
              locations: routesByWorkout[pt.uuid] ?? const [],
              heartRate: heartRateIndex,
            ),
          )
          .whereType<HealthWorkout>()
          .toList();

      // Sanitized observability (counts only, never coordinates/PII): lets the
      // Diagnostics screen show where route correlation may be failing.
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthReadWorkouts,
        details: healthReadDiagnosticsDetails(
          workouts: workouts,
          routes: routes,
          routeConsentDenied: _routeConsentDeniedCount,
          historyClamped: window.historyClamped,
          companionSkipped: partition.companionSkipped,
          excludedSkipped: partition.excludedSkipped,
          heartRateReadings: heartRate.samples.length,
          heartRateSource: heartRate.source,
        ),
      );

      return workouts;
    } on AppException {
      rethrow;
    } catch (e) {
      throw healthReadFailed(e);
    }
  }

  // ── Change tracking & background access ─────────────────────────────────

  @override
  Future<String> workoutChangesToken() async {
    try {
      await _ensureConfigured();
      return await _changesReader.currentToken();
    } catch (error) {
      throw healthReadFailed(error);
    }
  }

  @override
  Future<HealthWorkoutChanges> workoutChangesSince(String token) async {
    try {
      await _ensureConfigured();
      return await _changesReader.changesSince(token);
    } catch (error) {
      throw healthReadFailed(error);
    }
  }

  @override
  Future<bool> hasBackgroundReadAccess() async {
    if (_targetPlatform() == TargetPlatform.iOS) return true;
    if (_targetPlatform() != TargetPlatform.android) return false;
    try {
      await _ensureConfigured();
      return await _health.isHealthDataInBackgroundAvailable() &&
          await _health.isHealthDataInBackgroundAuthorized();
    } catch (error) {
      throw healthReadFailed(error);
    }
  }

  @override
  Future<bool> requestBackgroundReadAccess() async {
    if (_targetPlatform() == TargetPlatform.iOS) return true;
    if (_targetPlatform() != TargetPlatform.android) return false;
    try {
      await _ensureConfigured();
      // Without the feature (an older Health Connect), reads only work while
      // the app is in the foreground.
      if (!await _health.isHealthDataInBackgroundAvailable()) return false;
      if (await _health.isHealthDataInBackgroundAuthorized()) return true;
      return await _health.requestHealthDataInBackgroundAuthorization();
    } catch (error) {
      if (isHealthPlatformUnavailable(error)) {
        throw AppException(AppErrorCode.healthUnavailable, cause: error);
      }
      throw AppException(AppErrorCode.healthPermissionDenied, cause: error);
    }
  }

  /// Whether Endurain can read Health Connect data older than the 30-day window.
  ///
  /// Devices without the history feature do not enforce the window, so older
  /// data is already readable. Otherwise the permission must be held, requesting
  /// it when it has not yet been granted.
  Future<bool> _hasHistoryAccess() async {
    if (!await _health.isHealthDataHistoryAvailable()) return true;
    if (await _health.isHealthDataHistoryAuthorized()) return true;
    return _health.requestHealthDataHistoryAuthorization();
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Fetches GPS route samples for the window.
  ///
  /// Each route is returned with its own time window so it can be correlated
  /// to a workout either by `workoutUuid` (Android / Health Connect) or, when
  /// that is absent, by time overlap (iOS — `HKWorkoutRoute` does not expose
  /// the owning workout's UUID).
  ///
  /// If the platform returns a consent-required error for third-party app
  /// routes, the affected workouts will simply have no route points
  /// (handled gracefully rather than throwing).
  Future<List<HealthRouteData>> _fetchRoutes({
    required DateTime start,
    required DateTime end,
    required int workoutCount,
  }) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT_ROUTE],
        startTime: start,
        endTime: end,
      );
      final parsed = parseHealthRoutes(points);
      _routeConsentDeniedCount += parsed.consentDenied;
      return parsed.routes;
    } catch (error) {
      throw healthReadFailed(error);
    }
  }

  /// Fetches heart rate readings for [workoutPoints], sorted by start.
  ///
  /// Reads each workout's own window (padded by [healthHeartRateWindowPadding])
  /// rather than the whole page. Uses the series reader when one is injected
  /// (iOS) and falls back to the plugin read when it fails. `source` names
  /// where the readings came from, for diagnostics: `series`, `samples`, or
  /// `samples_fallback`.
  ///
  /// A failed plugin read throws (see [healthReadFailed]) instead of returning no
  /// readings, so a workout is never imported without its heart rate because
  /// of a passing failure.
  Future<({List<HealthHeartRateSample> samples, String source})>
  _fetchHeartRate({required List<HealthDataPoint> workoutPoints}) async {
    final windows = healthHeartRateWindows(workoutPoints);
    final reader = _heartRateSeriesReader;
    if (reader != null) {
      try {
        final samples = <HealthHeartRateSample>[];
        for (final window in windows) {
          final readings = await reader.read(
            start: window.start,
            end: window.end,
          );
          samples.addAll(heartRateSamplesFromReadings(readings));
        }
        samples.sort(HealthHeartRateSample.byStart);
        return (samples: samples, source: 'series');
      } catch (error) {
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.healthHeartRateSeriesFailed,
          details: diagnosticErrorDetails(error),
        );
        return (
          samples: await _fetchHeartRateSamples(windows),
          source: 'samples_fallback',
        );
      }
    }
    return (samples: await _fetchHeartRateSamples(windows), source: 'samples');
  }

  /// Fetches heart rate samples for each window through the plugin and returns
  /// them sorted by start.
  ///
  /// On iOS a condensed series arrives here as one sample spanning the whole
  /// series with a single summary value; it still covers its full interval.
  Future<List<HealthHeartRateSample>> _fetchHeartRateSamples(
    List<({DateTime start, DateTime end})> windows,
  ) async {
    final samples = <HealthHeartRateSample>[];
    try {
      for (final window in windows) {
        final points = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: window.start,
          endTime: window.end,
        );
        samples.addAll(heartRateSamplesFromPoints(points));
      }
    } catch (error) {
      throw healthReadFailed(error);
    }
    samples.sort(HealthHeartRateSample.byStart);
    return samples;
  }
}
