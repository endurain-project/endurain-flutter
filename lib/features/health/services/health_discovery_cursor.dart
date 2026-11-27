import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_workout.dart';

/// Route-scoped discovery/pagination state for the importable-workout list.
///
/// Groups the candidate cache and paging bounds that back a single health-sync
/// route so this view state is a cohesive unit rather than seven loose fields
/// on the service. `HealthSyncService.clearDiscoveryCache` resets it when the
/// route is torn down.
class HealthDiscoveryCursor {
  List<HealthWorkout> candidates = const [];
  String? profileId;
  HealthImportRange? range;
  HealthImportBounds? bounds;
  DateTime? nextPageEndExclusive;
  bool hasMore = false;
  int routeConsentDeniedCount = 0;

  /// Set once a read reports that older history is unreadable; stops paging.
  bool historyUnavailable = false;

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
    historyUnavailable = false;
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
    historyUnavailable = false;
  }
}
