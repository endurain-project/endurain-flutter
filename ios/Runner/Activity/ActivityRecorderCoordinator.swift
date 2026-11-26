import Foundation
// Flutter's Objective-C headers carry no concurrency annotations; the event
// sink is only ever called on the main actor here.
@preconcurrency import Flutter

/// Bridges native recorder events to the Flutter `EventChannel` sink.
///
/// Mirrors the Android `ActivityRecorderCoordinator`. Event payloads are
/// versioned and use the same `type`/`session`/`points`/`reason` keys the Dart
/// channel parser expects. Main-actor isolated, which is where the platform
/// channel expects to be driven: the recorder, the recorder channel and the
/// active store all emit from the main actor. Never emits raw coordinates in
/// diagnostics; only structured, channel-bound payloads.
@MainActor
final class ActivityRecorderCoordinator {
    static let shared = ActivityRecorderCoordinator()

    private let payloadVersion = 2

    private var eventSink: FlutterEventSink?

    private init() {}

    func attach(_ sink: @escaping FlutterEventSink) {
        eventSink = sink
    }

    func detach() {
        eventSink = nil
    }

    func emitSession(type: String, session: ActiveActivitySessionData) {
        emit([
            "version": payloadVersion,
            "type": type,
            "session": session.toMap(),
        ])
    }

    func emitPointBatch(
        _ points: [RecordedActivityPointData],
        localSessionId: String,
        pointOffset: Int
    ) {
        if points.isEmpty {
            return
        }
        emit([
            "version": payloadVersion,
            "type": ActivityRecorderCoordinator.eventPointBatchAvailable,
            "points": points.map { $0.toMap() },
            "localSessionId": localSessionId,
            "pointOffset": pointOffset,
        ])
    }

    func emitRecoverableStateChanged(_ session: ActiveActivitySessionData?) {
        var payload: [String: Any] = [
            "version": payloadVersion,
            "type": ActivityRecorderCoordinator.eventRecoverableStateChanged,
        ]
        if let session = session {
            payload["session"] = session.toMap()
        }
        emit(payload)
    }

    func emitFailed(_ reason: String) {
        emit([
            "version": payloadVersion,
            "type": ActivityRecorderCoordinator.eventFailed,
            "reason": reason,
        ])
    }

    private func emit(_ payload: [String: Any]) {
        eventSink?(payload)
    }

    static let eventStarted = "started"
    static let eventPointBatchAvailable = "pointBatchAvailable"
    static let eventPaused = "paused"
    static let eventResumed = "resumed"
    static let eventAutoPaused = "autoPaused"
    static let eventAutoResumed = "autoResumed"
    static let eventStopped = "stopped"
    static let eventFailed = "failed"
    static let eventRecoverableStateChanged = "recoverableStateChanged"

    static let reasonLocationStreamFailed = "locationStreamFailed"
    static let reasonLocationUnavailable = "locationUnavailable"
    static let reasonPermissionLost = "permissionLost"
    static let reasonPersistenceFailed = "persistenceFailed"
    static let reasonUnsupportedPlatform = "unsupportedPlatform"
}
