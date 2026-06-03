import 'dart:async';

import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:flutter/services.dart';

/// Channel names and method/event identifiers shared with the native Android
/// and iOS background recorder implementations.
class NativeActivityRecorderChannelContract {
  const NativeActivityRecorderChannelContract._();

  /// Schema version for method arguments and event payloads. Native code must
  /// reject or migrate mismatched versions.
  static const int payloadVersion = 1;

  static const String methodChannelName =
      'endurain/activity_recorder/methods';
  static const String eventChannelName = 'endurain/activity_recorder/events';

  // Method names.
  static const String start = 'start';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String stop = 'stop';
  static const String discard = 'discard';
  static const String drain = 'drain';
  static const String recover = 'recover';

  // Event payload keys.
  static const String eventType = 'type';
  static const String eventSession = 'session';
  static const String eventPoints = 'points';
  static const String eventReason = 'reason';

  // Event type values.
  static const String eventStarted = 'started';
  static const String eventPointBatchAvailable = 'pointBatchAvailable';
  static const String eventPaused = 'paused';
  static const String eventResumed = 'resumed';
  static const String eventStopped = 'stopped';
  static const String eventFailed = 'failed';
  static const String eventRecoverableStateChanged = 'recoverableStateChanged';
}

/// [ActivityLocationRecorder] backed by native platform channels.
///
/// This class isolates all platform-channel concerns from controllers and
/// widgets. The native side owns background collection and durable persistence;
/// Dart consumes versioned method results and event payloads only.
class NativeActivityRecorderChannel implements ActivityLocationRecorder {
  NativeActivityRecorderChannel({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _methodChannel =
          methodChannel ??
          const MethodChannel(
            NativeActivityRecorderChannelContract.methodChannelName,
          ),
      _eventChannel =
          eventChannel ??
          const EventChannel(
            NativeActivityRecorderChannelContract.eventChannelName,
          );

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<ActivityRecorderEvent>? _events;

  @override
  Stream<ActivityRecorderEvent> get events {
    return _events ??= _eventChannel
        .receiveBroadcastStream()
        .map(_parseEvent)
        .where((event) => event != null)
        .cast<ActivityRecorderEvent>();
  }

  @override
  Future<void> start(ActivityRecorderStartRequest request) {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.start,
      {
        'version': NativeActivityRecorderChannelContract.payloadVersion,
        'localSessionId': request.localSessionId,
        'activityType': request.activityType.apiValue,
        'startedAt': request.startedAt.toUtc().toIso8601String(),
        if (request.backgroundConfig != null) ...{
          'notificationTitle': request.backgroundConfig!.notificationTitle,
          'notificationText': request.backgroundConfig!.notificationText,
        },
      },
    );
  }

  @override
  Future<void> pause() {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.pause,
    );
  }

  @override
  Future<void> resume() {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.resume,
    );
  }

  @override
  Future<void> stop() {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.stop,
    );
  }

  @override
  Future<void> discard() {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.discard,
    );
  }

  @override
  Future<List<RecordedActivityPoint>> drain({int sinceOffset = 0}) async {
    final result = await _methodChannel.invokeMethod<List<Object?>>(
      NativeActivityRecorderChannelContract.drain,
      {'sinceOffset': sinceOffset},
    );
    return _parsePoints(result);
  }

  @override
  Future<ActiveActivitySession?> recoverActiveSession() async {
    final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
      NativeActivityRecorderChannelContract.recover,
    );
    if (result == null) {
      return null;
    }
    try {
      return ActiveActivitySession.fromJson(result);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> dispose() async {}

  ActivityRecorderEvent? _parseEvent(Object? payload) {
    if (payload is! Map) {
      return null;
    }
    final type = payload[NativeActivityRecorderChannelContract.eventType];
    final session = _parseSession(
      payload[NativeActivityRecorderChannelContract.eventSession],
    );
    switch (type) {
      case NativeActivityRecorderChannelContract.eventStarted:
        return session == null
            ? null
            : ActivityRecorderEvent.started(session);
      case NativeActivityRecorderChannelContract.eventPaused:
        return session == null
            ? null
            : ActivityRecorderEvent.paused(session);
      case NativeActivityRecorderChannelContract.eventResumed:
        return session == null
            ? null
            : ActivityRecorderEvent.resumed(session);
      case NativeActivityRecorderChannelContract.eventStopped:
        return session == null
            ? null
            : ActivityRecorderEvent.stopped(session);
      case NativeActivityRecorderChannelContract.eventPointBatchAvailable:
        return ActivityRecorderEvent.pointBatchAvailable(
          _parsePoints(
            payload[NativeActivityRecorderChannelContract.eventPoints],
          ),
        );
      case NativeActivityRecorderChannelContract.eventRecoverableStateChanged:
        return ActivityRecorderEvent.recoverableStateChanged(session);
      case NativeActivityRecorderChannelContract.eventFailed:
        return ActivityRecorderEvent.failed(
          _parseReason(
            payload[NativeActivityRecorderChannelContract.eventReason],
          ),
        );
      default:
        return null;
    }
  }

  ActiveActivitySession? _parseSession(Object? value) {
    if (value is! Map) {
      return null;
    }
    try {
      return ActiveActivitySession.fromJson(value);
    } on FormatException {
      return null;
    }
  }

  List<RecordedActivityPoint> _parsePoints(Object? value) {
    if (value is! List) {
      return const <RecordedActivityPoint>[];
    }
    final points = <RecordedActivityPoint>[];
    for (final entry in value) {
      if (entry is! Map) {
        continue;
      }
      try {
        points.add(RecordedActivityPoint.fromJson(entry));
      } on FormatException {
        continue;
      }
    }
    return points;
  }

  ActivityRecorderFailureReason _parseReason(Object? value) {
    for (final reason in ActivityRecorderFailureReason.values) {
      if (reason.name == value) {
        return reason;
      }
    }
    return ActivityRecorderFailureReason.locationStreamFailed;
  }
}
