import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';

/// Durable store for an in-progress (active) recording.
///
/// The store keeps active-recording session metadata and track points in
/// app-private storage so a recording can be recovered after the Flutter
/// isolate is paused, killed, or restarted. Implementations must surface
/// failures as app-owned exceptions (`AppException`) rather than leaking raw IO
/// errors, and must never log raw coordinates or file paths.
abstract class ActiveActivityStore {
  /// Persists the active session metadata, replacing any existing metadata.
  Future<void> saveSession(ActiveActivitySession session);

  /// Loads the active session metadata, or `null` when none exists.
  Future<ActiveActivitySession?> loadSession();

  /// Appends a batch of recorded points to durable storage.
  Future<void> appendPoints(List<RecordedActivityPoint> points);

  /// Reads stored points starting at [sinceOffset] (0-based point index).
  Future<List<RecordedActivityPoint>> readPoints({int sinceOffset = 0});

  /// Returns the number of stored points.
  Future<int> pointCount();

  /// Replaces all stored points, e.g. after re-segmenting a recovered session.
  Future<void> replacePoints(List<RecordedActivityPoint> points);

  /// Marks the active session as completed, persisting final [session] state.
  Future<void> complete(ActiveActivitySession session);

  /// Clears the active session metadata and all stored points.
  Future<void> clear();
}
