/// Health Connect only grants access to the last 30 days unless the app holds
/// `READ_HEALTH_DATA_HISTORY`.
const healthConnectHistoryWindow = Duration(days: 30);

/// Absorbs the small skew between when a caller computes a read window and when
/// the adapter actually reaches Health Connect. Reading exactly the last 30
/// days must never depend on (or prompt for) the history permission, and the
/// native read rejects the whole window if its start slips a moment past the
/// rolling cutoff. Trimming the oldest few minutes of an unauthorized window is
/// negligible next to guaranteeing recent workouts still load.
const healthHistoryCutoffSafetyMargin = Duration(minutes: 5);

/// The start an import read can actually use, and whether history access
/// forced it later than requested.
typedef HealthReadWindow = ({DateTime start, bool historyClamped});

/// Resolves the widest start Endurain can actually read for [requestedStart].
///
/// Reading a window that begins before the rolling 30-day cutoff without the
/// history permission makes Health Connect reject the whole request (the
/// plugin then returns an empty list), so recent workouts would silently
/// vanish too. [hasHistoryAccess] is asked (and may prompt) only when a window
/// genuinely reaches older data; the result clamps to the safe recent start
/// when that access is unavailable or declined, never throwing, so the
/// readable window always loads. Outside Android there is no such window.
Future<HealthReadWindow> resolveHealthReadWindow({
  required DateTime requestedStart,
  required DateTime now,
  required bool isAndroid,
  required Future<bool> Function() hasHistoryAccess,
}) async {
  if (!isAndroid) {
    return (start: requestedStart, historyClamped: false);
  }
  final cutoff = now.toUtc().subtract(healthConnectHistoryWindow);
  final safeRecentStart = cutoff.add(healthHistoryCutoffSafetyMargin);
  // Comfortably inside the always-readable 30-day window: never touch (or
  // prompt for) the history permission.
  if (!requestedStart.isBefore(safeRecentStart)) {
    return (start: requestedStart, historyClamped: false);
  }
  // Wants data meaningfully older than the cutoff (beyond clock skew): Health
  // Connect needs the history permission to return it.
  final wantsHistory = requestedStart.isBefore(
    cutoff.subtract(healthHistoryCutoffSafetyMargin),
  );
  if (wantsHistory && await hasHistoryAccess()) {
    return (start: requestedStart, historyClamped: false);
  }
  // Either history is needed but unavailable/declined, or the requested start
  // straddles the boundary where skew could push the native read just outside
  // the window. Clamp so the readable recent workouts still load.
  return (start: safeRecentStart, historyClamped: wantsHistory);
}
