import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
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

/// How far a route point may be from the nearest heart rate reading and still
/// take its value. Readings are usually 1-5 s apart, so this covers occasional
/// gaps of up to 20 s without stretching a reading across a real dropout.
const int _heartRateMatchToleranceMs = 10000;

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
      throw const AppException(AppErrorCode.healthPermissionDenied);
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
    } catch (_) {
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
      final heartRateIndex = _HeartRateIndex(heartRate.samples);

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
  Future<({List<_HrSample> samples, String source})> _fetchHeartRate({
    required List<HealthDataPoint> workoutPoints,
  }) async {
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
        final samples = <_HrSample>[];
        for (final window in windows) {
          final readings = await reader.read(
            start: window.start,
            end: window.end,
          );
          for (final reading in readings) {
            samples.add(
              _HrSample.interval(
                start: reading.start,
                end: reading.end,
                bpm: reading.bpm.round(),
              ),
            );
          }
        }
        samples.sort(_HrSample.byStart);
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
  Future<List<_HrSample>> _fetchHeartRateSamples(
    List<({DateTime start, DateTime end})> windows,
  ) async {
    final samples = <_HrSample>[];
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
            _HrSample.interval(
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
    samples.sort(_HrSample.byStart);
    return samples;
  }

  /// Maps a WORKOUT [HealthDataPoint] into a [HealthWorkout].
  ///
  /// Returns `null` when the data point is not a workout type (should not
  /// happen in practice but guards against API changes).
  HealthWorkout? _mapWorkout({
    required HealthDataPoint point,
    required List<WorkoutRouteLocation> locations,
    required _HeartRateIndex heartRate,
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
  /// nearest one within [_heartRateMatchToleranceMs] of it.
  HealthRoutePoint _mergeHr({
    required WorkoutRouteLocation loc,
    required _HeartRateIndex heartRate,
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

/// Looks up the heart rate at a time in readings sorted by start.
///
/// Readings can overlap, for example when two sources recorded heart rate at
/// once, so the reading just before a time is not always the one that covers
/// it. [_maxEndMs] holds the latest end among the readings up to each index;
/// it never decreases, so a binary search over it finds the earliest reading
/// that covers a time.
class _HeartRateIndex {
  _HeartRateIndex(this._samples)
    : _maxEndMs = List.filled(_samples.length, 0),
      _maxEndIndex = List.filled(_samples.length, 0) {
    for (var i = 0; i < _samples.length; i++) {
      if (i > 0 && _maxEndMs[i - 1] >= _samples[i].endMs) {
        _maxEndMs[i] = _maxEndMs[i - 1];
        _maxEndIndex[i] = _maxEndIndex[i - 1];
      } else {
        _maxEndMs[i] = _samples[i].endMs;
        _maxEndIndex[i] = i;
      }
    }
  }

  final List<_HrSample> _samples;

  /// Latest `endMs` among `_samples[0..i]`.
  final List<int> _maxEndMs;

  /// Index of the earliest reading holding `_maxEndMs[i]`.
  final List<int> _maxEndIndex;

  /// Returns the heart rate at [targetMs], or `null` when no reading covers
  /// it or lies within [_heartRateMatchToleranceMs] of it.
  ///
  /// A reading that covers [targetMs] wins, the earliest-starting one if
  /// several do. Otherwise the nearest reading wins: the one ending last
  /// before [targetMs] or the first one starting after it, the earlier one on
  /// a tie.
  int? bpmAt(int targetMs) {
    // Readings [0, startedCount) start at or before targetMs.
    final startedCount = _firstIndexWhere(
      (i) => _samples[i].startMs > targetMs,
    );
    if (startedCount > 0) {
      // Earliest reading whose running max end reaches targetMs. The max
      // first reaches it at that reading, so the reading itself covers it.
      final covering = _firstIndexWhere(
        (i) => _maxEndMs[i] >= targetMs,
        end: startedCount,
      );
      if (covering < startedCount) return _samples[covering].bpm;
    }

    int? hr;
    var closest = _heartRateMatchToleranceMs + 1;
    if (startedCount > 0) {
      final before = _maxEndIndex[startedCount - 1];
      final distance = targetMs - _samples[before].endMs;
      if (distance < closest) {
        hr = _samples[before].bpm;
        closest = distance;
      }
    }
    if (startedCount < _samples.length) {
      final distance = _samples[startedCount].startMs - targetMs;
      if (distance < closest) hr = _samples[startedCount].bpm;
    }
    return hr;
  }

  /// First index in `[0, end)` for which the monotonic [test] holds, or [end].
  int _firstIndexWhere(bool Function(int index) test, {int? end}) {
    var low = 0;
    var high = end ?? _samples.length;
    while (low < high) {
      final middle = low + (high - low) ~/ 2;
      if (test(middle)) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }
    return low;
  }
}

/// Lightweight heart-rate reading covering `startMs..endMs` (private to this
/// file). An instant reading has `startMs == endMs`.
class _HrSample {
  const _HrSample._({
    required this.startMs,
    required this.endMs,
    required this.bpm,
  });

  factory _HrSample.interval({
    required DateTime start,
    required DateTime end,
    required int bpm,
  }) {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    return _HrSample._(
      startMs: startMs,
      endMs: endMs < startMs ? startMs : endMs,
      bpm: bpm,
    );
  }

  final int startMs;
  final int endMs;
  final int bpm;

  static int byStart(_HrSample a, _HrSample b) =>
      a.startMs.compareTo(b.startMs);
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

/// How far a route may lie outside a workout's window and still be given to it
/// when it overlaps no workout, absorbing clock/rounding differences between
/// the route and workout samples.
const int _routeMatchToleranceMs = 60000;

/// Returns the index in [workouts] of the workout that owns a GPS route, or
/// `null` when none does.
///
/// When the route carries its owning workout's UUID (Android / Health Connect)
/// the match is exact. On iOS `HKWorkoutRoute` does not expose that UUID, so
/// the route goes to the one workout it overlaps the most. A route that
/// overlaps none goes to the nearest workout within [_routeMatchToleranceMs],
/// so back-to-back workouts never share each other's tracks. A tie goes to the
/// workout whose start is closest to the route's.
@visibleForTesting
int? healthRouteOwnerIndex({
  required String? routeWorkoutUuid,
  required DateTime routeStart,
  required DateTime routeEnd,
  required List<({String uuid, DateTime start, DateTime end})> workouts,
}) {
  if (routeWorkoutUuid != null) {
    final index = workouts.indexWhere((w) => w.uuid == routeWorkoutUuid);
    return index < 0 ? null : index;
  }
  final routeStartMs = routeStart.millisecondsSinceEpoch;
  final routeEndMs = routeEnd.millisecondsSinceEpoch;
  int? owner;
  // Overlap in ms; negative values are the gap between route and workout.
  var bestOverlapMs = -_routeMatchToleranceMs - 1;
  var bestStartDistanceMs = 0;
  for (var i = 0; i < workouts.length; i++) {
    final workoutStartMs = workouts[i].start.millisecondsSinceEpoch;
    final workoutEndMs = workouts[i].end.millisecondsSinceEpoch;
    final overlapMs =
        (routeEndMs < workoutEndMs ? routeEndMs : workoutEndMs) -
        (routeStartMs > workoutStartMs ? routeStartMs : workoutStartMs);
    final startDistanceMs = (routeStartMs - workoutStartMs).abs();
    if (overlapMs > bestOverlapMs ||
        (owner != null &&
            overlapMs == bestOverlapMs &&
            startDistanceMs < bestStartDistanceMs)) {
      owner = i;
      bestOverlapMs = overlapMs;
      bestStartDistanceMs = startDistanceMs;
    }
  }
  return owner;
}
