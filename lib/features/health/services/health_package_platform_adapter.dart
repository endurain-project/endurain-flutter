import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_heart_rate_index.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_route_correlation.dart';
import 'package:endurain/features/health/services/heart_rate_series_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

const _coreReadTypes = [
  HealthDataType.WORKOUT,
  HealthDataType.WORKOUT_ROUTE,
  HealthDataType.HEART_RATE,
];

const _androidWorkoutSummaryReadTypes = [
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.TOTAL_CALORIES_BURNED,
  HealthDataType.STEPS,
];

const _healthConnectHistoryWindow = Duration(days: 30);

/// Health platform source ids (the writing app's bundle id or package name)
/// of Endurain's own companion watch apps.
///
/// Their workouts reach the phone through the watch transport, so Health Sync
/// never offers or imports them. Filtering by source (rather than only by the
/// health workout id a handoff carries) also covers a workout that syncs to
/// the phone's health store before the watch's own transfer arrives.
const companionWatchHealthSourceIds = {'com.endurain.endurain.watchkitapp'};

/// Absorbs the small skew between when a caller computes a read window and when
/// this adapter actually reaches Health Connect. Reading exactly the last 30
/// days must never depend on (or prompt for) the history permission, and the
/// native read rejects the whole window if its start slips a moment past the
/// rolling cutoff. Trimming the oldest few minutes of an unauthorized window is
/// negligible next to guaranteeing recent workouts still load.
const _historyCutoffSafetyMargin = Duration(minutes: 5);

/// Padding around each workout when reading its heart rate series, so a
/// reading just before the start or after the end can still reach the first
/// or last route points.
const _heartRateWindowPadding = Duration(minutes: 1);

/// [HealthPlatformAdapter] backed by the `health` Flutter package.
///
/// Connects to HealthKit on iOS and Health Connect on Android. Inject a
/// [Health] instance for unit testing (no native calls in tests).
///
/// When `heartRateSeriesReader` is given (iOS), heart rate is read through it
/// per workout instead of through the plugin, so readings HealthKit condensed
/// into a series are not reduced to one value each. If it fails, the plugin
/// read is used instead.
class HealthPackagePlatformAdapter implements HealthPlatformAdapter {
  HealthPackagePlatformAdapter({
    Health? health,
    DiagnosticsRecorder? diagnostics,
    TargetPlatform Function()? targetPlatform,
    DateTime Function()? now,
    HeartRateSeriesReader? heartRateSeriesReader,
  }) : _health = health ?? Health(),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _targetPlatform = targetPlatform ?? _defaultTargetPlatform,
       _now = now ?? DateTime.now,
       _heartRateSeriesReader = heartRateSeriesReader;

  final Health _health;
  final HeartRateSeriesReader? _heartRateSeriesReader;
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
      if (_isPlatformUnavailable(e)) {
        throw AppException(AppErrorCode.healthUnavailable, cause: e);
      }
      if (e is HealthException &&
          e.errorCode != HealthErrorCode.permissionDenied) {
        throw _readFailed(e);
      }
      throw AppException(AppErrorCode.healthPermissionDenied, cause: e);
    }
  }

  /// Whether [error] says the health platform itself is missing or
  /// unsupported, not that the user refused access.
  ///
  /// The plugin reports Health Connect missing altogether as an
  /// [UnsupportedError], and a data type the device cannot serve as
  /// [HealthErrorCode.notSupported].
  static bool _isPlatformUnavailable(Object error) {
    return error is UnsupportedError ||
        (error is HealthException &&
            error.errorCode == HealthErrorCode.notSupported);
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
      if (_isPlatformUnavailable(error)) {
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
        workouts: _accessStatus(results[0]),
        workoutRoutes: _accessStatus(results[1]),
        heartRate: _accessStatus(results[2]),
      );
    } catch (_) {
      return const HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
      );
    }
  }

  HealthDataAccessStatus _accessStatus(bool? granted) {
    return granted == true
        ? HealthDataAccessStatus.allowed
        : HealthDataAccessStatus.needsAttention;
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
      final window = await _resolveReadWindow(start);
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
      final workoutPoints = <HealthDataPoint>[];
      var companionWorkouts = 0;
      var excludedWorkouts = 0;
      for (final point in allWorkoutPoints) {
        if (companionWatchHealthSourceIds.contains(point.sourceId)) {
          companionWorkouts++;
        } else if (exclude != null && await exclude(point.uuid)) {
          excludedWorkouts++;
        } else {
          workoutPoints.add(point);
        }
      }
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
      final routesByWorkout = _assignRoutes(
        routes: routes,
        workoutPoints: allWorkoutPoints,
      );

      // Step 3 — Fetch heart rate readings for the remaining workouts only.
      final heartRate = await _fetchHeartRate(workoutPoints: workoutPoints);
      final heartRateIndex = HealthHeartRateIndex(heartRate.samples);

      // Step 4 — Map each workout data point to a HealthWorkout.
      final workouts = workoutPoints
          .map(
            (pt) => _mapWorkout(
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
        details: {
          'workouts': workouts.length,
          'route_samples': routes.length,
          'route_locations': routes.fold<int>(
            0,
            (sum, r) => sum + r.locations.length,
          ),
          'routes_with_uuid': routes.where((r) => r.workoutUuid != null).length,
          'workouts_with_route': workouts.where((w) => w.hasRoute).length,
          'route_read_failed': _routeConsentDeniedCount > 0,
          'history_clamped': window.historyClamped,
          'companion_watch_skipped': companionWorkouts,
          'already_handled_skipped': excludedWorkouts,
          'heart_rate_readings': heartRate.samples.length,
          'heart_rate_source': heartRate.source,
          'route_points_with_heart_rate': workouts.fold<int>(
            0,
            (sum, w) => sum + w.route.where((p) => p.heartRate != null).length,
          ),
        },
      );

      return workouts;
    } on AppException {
      rethrow;
    } catch (e) {
      throw _readFailed(e);
    }
  }

  /// Maps a read failure to an [AppException].
  ///
  /// A missing permission becomes [AppErrorCode.healthPermissionDenied], the
  /// only failure that means access was lost. Anything else is
  /// [AppErrorCode.healthReadFailed], flagged as transient when the plugin
  /// reports it as retryable (rate limit, Health Connect busy, iOS device
  /// locked).
  static AppException _readFailed(Object error) {
    if (error is HealthException &&
        error.errorCode == HealthErrorCode.permissionDenied) {
      return AppException(AppErrorCode.healthPermissionDenied, cause: error);
    }
    return AppException(
      AppErrorCode.healthReadFailed,
      cause: error,
      isTransient: error is HealthException && error.isRetryable,
    );
  }

  /// Resolves the widest start Endurain can actually read for [requestedStart].
  ///
  /// Health Connect only grants access to the last [_healthConnectHistoryWindow]
  /// unless the app holds `READ_HEALTH_DATA_HISTORY`. Reading a window that
  /// begins before that rolling cutoff without the permission makes Health
  /// Connect reject the whole request (the plugin then returns an empty list),
  /// so recent workouts would silently vanish too. This requests history access
  /// only when a window genuinely reaches older data, and clamps to the safe
  /// recent start when that access is unavailable or declined — never throwing,
  /// so the readable window always loads.
  Future<({DateTime start, bool historyClamped})> _resolveReadWindow(
    DateTime requestedStart,
  ) async {
    if (_targetPlatform() != TargetPlatform.android) {
      return (start: requestedStart, historyClamped: false);
    }
    final cutoff = _now().toUtc().subtract(_healthConnectHistoryWindow);
    final safeRecentStart = cutoff.add(_historyCutoffSafetyMargin);
    // Comfortably inside the always-readable 30-day window: never touch (or
    // prompt for) the history permission.
    if (!requestedStart.isBefore(safeRecentStart)) {
      return (start: requestedStart, historyClamped: false);
    }
    // Wants data meaningfully older than the cutoff (beyond clock skew): Health
    // Connect needs the history permission to return it.
    final wantsHistory = requestedStart.isBefore(
      cutoff.subtract(_historyCutoffSafetyMargin),
    );
    if (wantsHistory && await _hasHistoryAccess()) {
      return (start: requestedStart, historyClamped: false);
    }
    // Either history is needed but unavailable/declined, or the requested start
    // straddles the boundary where skew could push the native read just outside
    // the window. Clamp so the readable recent workouts still load.
    return (start: safeRecentStart, historyClamped: wantsHistory);
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
  Future<List<_RouteData>> _fetchRoutes({
    required DateTime start,
    required DateTime end,
    required int workoutCount,
  }) async {
    final result = <_RouteData>[];
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT_ROUTE],
        startTime: start,
        endTime: end,
      );
      for (final pt in points) {
        final value = pt.value;
        if (value is! WorkoutRouteHealthValue) continue;
        final metadata = pt.metadata;
        if (metadata?['route_requires_consent'] == true) {
          _routeConsentDeniedCount++;
          continue;
        }
        if (value.locations.isEmpty) continue;
        result.add(
          _RouteData(
            start: pt.dateFrom.toUtc(),
            end: pt.dateTo.toUtc(),
            workoutUuid:
                metadata?['workout_uuid'] as String? ?? value.workoutUuid,
            locations: value.locations,
          ),
        );
      }
    } catch (error) {
      throw _readFailed(error);
    }
    return result;
  }

  /// Gives each route to the workout in [workoutPoints] that owns it (see
  /// [healthRouteOwnerIndex]), keyed by workout uuid.
  Map<String, List<WorkoutRouteLocation>> _assignRoutes({
    required List<_RouteData> routes,
    required List<HealthDataPoint> workoutPoints,
  }) {
    final windows = [
      for (final point in workoutPoints)
        (
          uuid: point.uuid,
          start: point.dateFrom.toUtc(),
          end: point.dateTo.toUtc(),
        ),
    ];
    final byWorkout = <String, List<WorkoutRouteLocation>>{};
    for (final route in routes) {
      final owner = healthRouteOwnerIndex(
        routeWorkoutUuid: route.workoutUuid,
        routeStart: route.start,
        routeEnd: route.end,
        workouts: windows,
      );
      if (owner == null) continue;
      (byWorkout[windows[owner].uuid] ??= []).addAll(route.locations);
    }
    return byWorkout;
  }

  /// Fetches heart rate readings for [workoutPoints], sorted by start.
  ///
  /// Reads each workout's own window (padded by [_heartRateWindowPadding])
  /// rather than the whole page. Uses the series reader when one is injected
  /// (iOS) and falls back to the plugin read when it fails. `source` names
  /// where the readings came from, for diagnostics: `series`, `samples`, or
  /// `samples_fallback`.
  ///
  /// A failed plugin read throws (see [_readFailed]) instead of returning no
  /// readings, so a workout is never imported without its heart rate because
  /// of a passing failure.
  Future<({List<HealthHeartRateSample> samples, String source})>
  _fetchHeartRate({required List<HealthDataPoint> workoutPoints}) async {
    final windows = [
      for (final point in workoutPoints)
        (
          start: point.dateFrom.toUtc().subtract(_heartRateWindowPadding),
          end: point.dateTo.toUtc().add(_heartRateWindowPadding),
        ),
    ];
    final reader = _heartRateSeriesReader;
    if (reader != null) {
      try {
        final samples = <HealthHeartRateSample>[];
        for (final window in windows) {
          final readings = await reader.read(
            start: window.start,
            end: window.end,
          );
          for (final reading in readings) {
            samples.add(
              HealthHeartRateSample.interval(
                start: reading.start,
                end: reading.end,
                bpm: reading.bpm.round(),
              ),
            );
          }
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
        for (final pt in points) {
          final value = pt.value;
          if (value is! NumericHealthValue) continue;
          samples.add(
            HealthHeartRateSample.interval(
              start: pt.dateFrom,
              end: pt.dateTo,
              bpm: value.numericValue.round(),
            ),
          );
        }
      }
    } catch (error) {
      throw _readFailed(error);
    }
    samples.sort(HealthHeartRateSample.byStart);
    return samples;
  }

  /// Maps a WORKOUT [HealthDataPoint] into a [HealthWorkout].
  ///
  /// Returns `null` when the data point is not a workout type (should not
  /// happen in practice but guards against API changes).
  HealthWorkout? _mapWorkout({
    required HealthDataPoint point,
    required List<WorkoutRouteLocation> locations,
    required HealthHeartRateIndex heartRate,
  }) {
    final value = point.value;
    if (value is! WorkoutHealthValue) return null;

    final type = HealthWorkoutType.fromPlatformValue(
      value.workoutActivityType.name,
    );

    // Convert total distance to meters.
    double? distanceMeters;
    final rawDist = value.totalDistance;
    if (rawDist != null) {
      distanceMeters = switch (value.totalDistanceUnit) {
        HealthDataUnit.METER => rawDist.toDouble(),
        HealthDataUnit.MILE => rawDist * UnitConversions.metersPerMile,
        _ => rawDist.toDouble(), // default: assume metres
      };
    }

    // Convert total energy to kilocalories.
    double? energyKcal;
    final rawEnergy = value.totalEnergyBurned;
    if (rawEnergy != null) {
      energyKcal = switch (value.totalEnergyBurnedUnit) {
        HealthDataUnit.KILOCALORIE => rawEnergy.toDouble(),
        HealthDataUnit.JOULE => rawEnergy / 4184.0,
        _ => rawEnergy.toDouble(), // default: assume kcal
      };
    }

    final workoutStart = point.dateFrom.toUtc();
    final workoutEnd = point.dateTo.toUtc();

    // Merge GPS route + HR. A workout can own several route samples, which
    // arrive in no particular order, so the points are sorted by time.
    final route =
        locations
            .map((loc) => _mergeHr(loc: loc, heartRate: heartRate))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));

    return HealthWorkout(
      sourceId: point.uuid,
      type: type,
      startedAt: workoutStart,
      endedAt: workoutEnd,
      distanceMeters: distanceMeters,
      energyKilocalories: energyKcal,
      route: route,
    );
  }

  /// Attaches the heart rate reading that covers a route point, or the
  /// nearest one within the match tolerance of it.
  HealthRoutePoint _mergeHr({
    required WorkoutRouteLocation loc,
    required HealthHeartRateIndex heartRate,
  }) {
    return HealthRoutePoint(
      latitude: loc.latitude,
      longitude: loc.longitude,
      time: loc.timestamp.toUtc(),
      elevation: loc.altitude,
      heartRate: heartRate.bpmAt(loc.timestamp.millisecondsSinceEpoch),
    );
  }
}

/// A GPS route sample with its own time window, used to correlate it to a
/// workout (private to this file).
class _RouteData {
  const _RouteData({
    required this.start,
    required this.end,
    required this.workoutUuid,
    required this.locations,
  });
  final DateTime start;
  final DateTime end;
  final String? workoutUuid;
  final List<WorkoutRouteLocation> locations;
}
