import 'dart:async';

import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/sensor_reading_buffer.dart';

/// Captures external-sensor readings (heart rate, power, cadence) for one
/// recording: persists each sample through the recorder, keeps time-ordered
/// buffers, and stamps the nearest reading onto track points.
///
/// The owning service supplies its lifecycle through callbacks so this class
/// stays free of recording-state logic.
class RecordingSensorSession {
  RecordingSensorSession({
    required ActivitySensorRecorder? recorder,
    required Duration freshness,
    required String? Function() activeSessionId,
    required bool Function() isRecording,
    required bool Function() isDisposed,
    required void Function(Object error, StackTrace stackTrace) onWriteFailed,
    required void Function(RecordedSensorSample sample) onSampleRecorded,
  }) : _recorder = recorder,
       _activeSessionId = activeSessionId,
       _isRecording = isRecording,
       _isDisposed = isDisposed,
       _onWriteFailed = onWriteFailed,
       _onSampleRecorded = onSampleRecorded,
       _buffers = {
         for (final kind in RecordedSensorKind.values)
           kind: SensorReadingBuffer(freshness),
       };

  final ActivitySensorRecorder? _recorder;
  final String? Function() _activeSessionId;
  final bool Function() _isRecording;
  final bool Function() _isDisposed;
  final void Function(Object error, StackTrace stackTrace) _onWriteFailed;
  final void Function(RecordedSensorSample sample) _onSampleRecorded;
  final Map<RecordedSensorKind, SensorReadingBuffer> _buffers;

  Future<void> _writes = Future<void>.value();
  String? _captureSessionId;
  bool _writeFailed = false;

  /// Completes once every queued sample write has finished.
  Future<void> get pendingWrites => _writes;

  /// Begins accepting readings for [sessionId]; null stops accepting them.
  void startCapture(String? sessionId) {
    _captureSessionId = sessionId;
  }

  void stopCapture() {
    _captureSessionId = null;
  }

  /// Forgets everything from the previous recording.
  void reset() {
    _captureSessionId = null;
    _writeFailed = false;
    _clearBuffers();
  }

  /// Waits for queued writes; false when the session was disposed or a write
  /// failed, so the caller must not finalize.
  Future<bool> flush() async {
    await _writes;
    return !_isDisposed() && !_writeFailed;
  }

  void onReading(RecordedSensorSample sample) {
    // Only buffer while actively recording; readings while idle or paused are
    // not associated with any track point.
    final sessionId = _captureSessionId;
    if (!_isRecording() || sessionId == null) {
      return;
    }
    _writes = _writes.then((_) async {
      if (sessionId != _activeSessionId() || _writeFailed) {
        return;
      }
      try {
        await _recorder?.appendSensorSample(
          localSessionId: sessionId,
          sample: sample,
        );
      } catch (error, stackTrace) {
        if (!_isDisposed() && sessionId == _activeSessionId()) {
          _writeFailed = true;
          _onWriteFailed(error, stackTrace);
        }
        return;
      }
      if (!_isDisposed() && sessionId == _activeSessionId()) {
        _buffers[sample.kind]!.add(sample.timestamp, sample.value);
        _onSampleRecorded(sample);
      }
    });
  }

  /// Reloads the persisted samples of the active session into the buffers.
  Future<void> restore() async {
    final recorder = _recorder;
    final sessionId = _activeSessionId();
    if (recorder == null || sessionId == null) {
      return;
    }
    final samples = await recorder.drainSensorSamples(
      localSessionId: sessionId,
    );
    if (_isDisposed() || sessionId != _activeSessionId()) {
      return;
    }
    final ordered = samples.toList()
      ..sort((first, second) => first.timestamp.compareTo(second.timestamp));
    _clearBuffers();
    for (final sample in ordered) {
      _buffers[sample.kind]!.add(sample.timestamp, sample.value);
    }
    _writeFailed = false;
  }

  /// Overlays the nearest fresh reading of each kind onto [point], preserving
  /// values the recorder already persisted (e.g. heart rate stamped natively).
  ActivityTrackPoint overlay(ActivityTrackPoint point, DateTime timestamp) {
    var result = point;
    for (final entry in _buffers.entries) {
      final value = entry.value.nearest(timestamp);
      if (value != null) {
        result = result.withSensorValue(entry.key, value);
      }
    }
    return result;
  }

  void _clearBuffers() {
    for (final buffer in _buffers.values) {
      buffer.clear();
    }
  }
}
