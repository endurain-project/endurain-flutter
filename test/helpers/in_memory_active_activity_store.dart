import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/active_activity_store.dart';

/// Simple in-memory [ActiveActivityStore] for unit tests.
class InMemoryActiveActivityStore implements ActiveActivityStore {
  ActiveActivitySession? session;
  final List<RecordedActivityPoint> points = [];
  int clearCount = 0;
  int saveCount = 0;
  int completeCount = 0;

  @override
  Future<void> appendPoints(List<RecordedActivityPoint> newPoints) async {
    points.addAll(newPoints);
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    session = null;
    points.clear();
  }

  @override
  Future<void> complete(ActiveActivitySession value) async {
    completeCount += 1;
    session = value;
  }

  @override
  Future<ActiveActivitySession?> loadSession() async => session;

  @override
  Future<int> pointCount() async => points.length;

  @override
  Future<List<RecordedActivityPoint>> readPoints({int sinceOffset = 0}) async {
    return points.sublist(sinceOffset.clamp(0, points.length));
  }

  @override
  Future<void> replacePoints(List<RecordedActivityPoint> value) async {
    points
      ..clear()
      ..addAll(value);
  }

  @override
  Future<void> saveSession(ActiveActivitySession value) async {
    saveCount += 1;
    session = value;
  }
}
