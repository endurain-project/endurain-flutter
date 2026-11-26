import 'dart:isolate';

import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_gpx_builder.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';

/// Turns a completed recording into a stored, upload-pending local activity:
/// builds the GPX, writes it, builds the summary and persists the record.
///
/// Shared by the phone recorder (`ActivityRecordingController`) and the watch
/// ingestion so both finalise activities identically.
class ActivityFinalizer {
  ActivityFinalizer({
    required LocalActivityRepository repository,
    required LocalActivitySummaryBuilder summaryBuilder,
    ActivityGpxBuilder gpxBuilder = const ActivityGpxBuilder(),
    DateTime Function()? now,
    this.isolateThresholdPoints = defaultIsolateThresholdPoints,
  }) : _repository = repository,
       _summaryBuilder = summaryBuilder,
       _gpxBuilder = gpxBuilder,
       _now = now ?? DateTime.now;

  /// Tracks with at least this many points are built on a worker isolate: a
  /// multi-hour recording has tens of thousands of points, and building the
  /// document (outlier filter plus XML) would otherwise stall the UI thread.
  /// Smaller tracks build inline, where spawning an isolate costs more than
  /// the work.
  static const int defaultIsolateThresholdPoints = 2000;

  final LocalActivityRepository _repository;
  final LocalActivitySummaryBuilder _summaryBuilder;
  final ActivityGpxBuilder _gpxBuilder;
  final DateTime Function() _now;

  /// Point count from which [buildGpx] uses a worker isolate.
  final int isolateThresholdPoints;

  /// Builds the GPX document for [state], off the UI thread for large tracks.
  ///
  /// Throws when the document cannot be built; callers map that to their own
  /// failure (the recorder keeps the session for a retry, the watch leaves the
  /// handoff queued).
  Future<String> buildGpx(ActivityRecordingState state) {
    if (state.points.length < isolateThresholdPoints) {
      return Future.sync(() => _gpxBuilder.build(state));
    }
    // The state and the builder are plain data, so they are copied into the
    // isolate; the builder is captured by value, never `this`.
    final builder = _gpxBuilder;
    return Isolate.run(() => builder.build(state));
  }

  /// Writes [gpx], builds the summary from [state] and persists the pending
  /// record for [id].
  Future<LocalActivityRecord> persist({
    required ActivityRecordingState state,
    required String id,
    required String gpx,
    String? connectionOrigin,
    String? connectionProfileId,
  }) async {
    final createdAt = _now().toUtc();
    final gpxFileName = await _repository.writeGpx(id: id, gpx: gpx);
    final record = _summaryBuilder
        .build(
          state: state,
          id: id,
          gpxFileName: gpxFileName,
          createdAt: createdAt,
        )
        .copyWith(
          connectionOrigin: connectionOrigin,
          connectionProfileId: connectionProfileId,
        );
    await _repository.upsert(record);
    return record;
  }

  /// [buildGpx] followed by [persist].
  Future<LocalActivityRecord> finalize({
    required ActivityRecordingState state,
    required String id,
    String? connectionOrigin,
    String? connectionProfileId,
  }) async => persist(
    state: state,
    id: id,
    gpx: await buildGpx(state),
    connectionOrigin: connectionOrigin,
    connectionProfileId: connectionProfileId,
  );
}
