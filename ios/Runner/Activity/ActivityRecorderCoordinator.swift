import Foundation
import Flutter

/// Bridges native recorder events to the Flutter `EventChannel` sink.
///
/// Mirrors the Android `ActivityRecorderCoordinator`. Event payloads are
/// versioned and use the same `type`/`session`/`points`/`reason` keys the Dart
/// channel parser expects. All emissions are marshalled to the main thread,
/// which is where the platform channel expects to be driven. Never emits raw
/// coordinates in diagnostics; only structured, channel-bound payloads.
final class ActivityRecorderCoordinator {
    static let shared = ActivityRecorderCoordinator()

    private let payloadVersion = 1

    private var eventSink: FlutterEventSink?
    private var eventSinkGeneration = 0

    private init() {}

    func attach(_ sink: @escaping FlutterEventSink) {
        runOnMain { [weak self] in
            self?.eventSinkGeneration += 1
            self?.eventSink = sink
        }
    }

    func detach() {
        runOnMain { [weak self] in
            self?.eventSinkGeneration += 1
            self?.eventSink = nil
        }
    }

    func emitSession(type: String, session: ActiveActivitySessionData) {
        emit([
            "version": payloadVersion,
            "type": type,
            "session": session.toMap(),
        ])
    }

    func emitPointBatch(_ points: [RecordedActivityPointData]) {
        if points.isEmpty {
            return
        }
        emit([
            "version": payloadVersion,
            "type": ActivityRecorderCoordinator.eventPointBatchAvailable,
            "points": points.map { $0.toMap() },
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
        if Thread.isMainThread {
            eventSink?(payload)
        } else {
            var capturedGeneration = 0
            var hasSink = false
            DispatchQueue.main.sync { [weak self] in
                capturedGeneration = self?.eventSinkGeneration ?? 0
                hasSink = self?.eventSink != nil
            }
            guard hasSink else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard
                    let self = self,
                    self.eventSinkGeneration == capturedGeneration
                else {
                    return
                }
                self.eventSink?(payload)
            }
        }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
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
