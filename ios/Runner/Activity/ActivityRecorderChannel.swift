import Foundation
import Flutter

/// Hosts the method/event channels that bridge the Dart
/// `NativeActivityRecorderChannel` to the native CoreLocation recorder.
///
/// Channel names, method names, and payload keys mirror
/// `NativeActivityRecorderChannelContract` and the Android
/// `ActivityRecorderChannel`. Lifecycle transitions (start/pause/resume/stop/
/// discard) are owned here; point batches and collection failures are emitted
/// by the recorder via `ActivityRecorderCoordinator`. Drain/recover read
/// directly from the durable `ActiveActivityStore`.
final class ActivityRecorderChannel: NSObject, FlutterStreamHandler {
    private let store = ActiveActivityStore.shared
    private lazy var recorder = CoreLocationActivityRecorder(store: store)

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?

    /// Re-arms location collection after iOS relaunched the app in the
    /// background for a significant location change.
    ///
    /// Called by `AppDelegate` on a location-triggered launch so a recording
    /// that was interrupted by process termination keeps collecting, without
    /// waiting for Flutter to attach and drive `recover`.
    @discardableResult
    func resumeAfterRelaunch() -> Bool {
        return recorder.resumeAfterRelaunch()
    }

    func register(with messenger: FlutterBinaryMessenger) {
        let methodChannel = FlutterMethodChannel(
            name: ActivityRecorderChannel.methodChannelName,
            binaryMessenger: messenger
        )
        methodChannel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        let eventChannel = FlutterEventChannel(
            name: ActivityRecorderChannel.eventChannelName,
            binaryMessenger: messenger
        )
        eventChannel.setStreamHandler(self)
        self.methodChannel = methodChannel
        self.eventChannel = eventChannel
    }

    // MARK: - FlutterStreamHandler

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        ActivityRecorderCoordinator.shared.attach(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        ActivityRecorderCoordinator.shared.detach()
        return nil
    }

    // MARK: - Method dispatch

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case ActivityRecorderChannel.methodStart:
            handleStart(call, result: result)
        case ActivityRecorderChannel.methodPause:
            handlePause(result: result)
        case ActivityRecorderChannel.methodResume:
            handleResume(result: result)
        case ActivityRecorderChannel.methodStop:
            handleStop(result: result)
        case ActivityRecorderChannel.methodDiscard:
            handleDiscard(result: result)
        case ActivityRecorderChannel.methodDrain:
            handleDrain(call, result: result)
        case ActivityRecorderChannel.methodRecover:
            handleRecover(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleStart(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        if !isSupportedVersion(arguments) {
            result(FlutterError(
                code: ActivityRecorderChannel.errorVersion,
                message: "Unsupported payload version",
                details: nil
            ))
            return
        }
        guard
            let localSessionId = arguments?["localSessionId"] as? String,
            !localSessionId.isEmpty
        else {
            result(FlutterError(
                code: ActivityRecorderChannel.errorArgs,
                message: "Missing localSessionId",
                details: nil
            ))
            return
        }
        if store.hasRecoverableData() {
            result(FlutterError(
                code: ActivityRecorderChannel.errorState,
                message: "A recoverable session already exists",
                details: nil
            ))
            return
        }
        let activityType = (arguments?["activityType"] as? String) ?? ""
        let startedAt = (arguments?["startedAt"] as? String) ?? IsoTime.nowUtc()
        let connectionOrigin = arguments?["connectionOrigin"] as? String
        let connectionProfileId = arguments?["connectionProfileId"] as? String
        let heartRateDeviceId = arguments?["hrDeviceId"] as? String
        let powerDeviceId = arguments?["powerDeviceId"] as? String
        let cadenceDeviceId = arguments?["cadenceDeviceId"] as? String

        let session = ActiveActivitySessionData(
            localSessionId: localSessionId,
            activityType: activityType,
            status: ActiveActivitySessionData.statusRecording,
            startedAt: startedAt,
            connectionOrigin: connectionOrigin,
            connectionProfileId: connectionProfileId,
            heartRateDeviceId: heartRateDeviceId,
            powerDeviceId: powerDeviceId,
            cadenceDeviceId: cadenceDeviceId,
            currentSegmentIndex: 0
        )
        store.saveSession(session)

        if !recorder.startCollection() {
            // Collection never started, so no point was ever captured. Clear the
            // store rather than persisting an empty `failed` session: leaving it
            // behind makes `hasRecoverableData()` true forever, so every later
            // `start` is rejected with `invalid_state` and recording stays
            // broken until the app is relaunched.
            store.clear()
            result(FlutterError(
                code: ActivityRecorderChannel.errorService,
                message: "Unable to start recorder",
                details: nil
            ))
            return
        }

        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventStarted,
            session: session
        )
        result(nil)
    }

    private func handlePause(result: @escaping FlutterResult) {
        guard let session = store.loadSession() else {
            result(FlutterError(
                code: ActivityRecorderChannel.errorState,
                message: "No active session",
                details: nil
            ))
            return
        }
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let updated = session.copyWith(
            status: ActiveActivitySessionData.statusPaused,
            pausedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(nowMillis) / 1000))),
            elapsedDurationSeconds: elapsedSeconds(session, referenceMillis: nowMillis)
        )
        store.saveSession(updated)
        recorder.stopCollection()
        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventPaused,
            session: updated
        )
        result(nil)
    }

    private func handleResume(result: @escaping FlutterResult) {
        guard let session = store.loadSession() else {
            result(FlutterError(
                code: ActivityRecorderChannel.errorState,
                message: "No active session",
                details: nil
            ))
            return
        }
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let updated = session.copyWith(
            status: ActiveActivitySessionData.statusRecording,
            resumedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(nowMillis) / 1000))),
            pausedAt: .some(nil)
        )
        store.saveSession(updated)
        recorder.markResumed()
        if !recorder.startCollection() {
            store.saveSession(updated.copyWith(status: ActiveActivitySessionData.statusFailed))
            result(FlutterError(
                code: ActivityRecorderChannel.errorService,
                message: "Unable to resume recorder",
                details: nil
            ))
            return
        }
        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventResumed,
            session: updated
        )
        result(nil)
    }

    private func handleStop(result: @escaping FlutterResult) {
        let session = store.loadSession()
        recorder.stopCollection()
        guard let session = session else {
            result(nil)
            return
        }
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let updated = session.copyWith(
            status: ActiveActivitySessionData.statusCompleted,
            endedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(nowMillis) / 1000))),
            elapsedDurationSeconds: elapsedSeconds(session, referenceMillis: nowMillis)
        )
        store.saveSession(updated)
        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventStopped,
            session: updated
        )
        result(nil)
    }

    private func handleDiscard(result: @escaping FlutterResult) {
        recorder.stopCollection()
        store.clear()
        ActivityRecorderCoordinator.shared.emitRecoverableStateChanged(nil)
        result(nil)
    }

    private func handleDrain(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        let sinceOffset = JsonScalar.int(arguments?["sinceOffset"]) ?? 0
        do {
            let points = try store.readPoints(sinceOffset: sinceOffset).map { $0.toMap() }
            result(points)
        } catch {
            result(FlutterError(
                code: ActivityRecorderChannel.errorStore,
                message: "Unable to read persisted recording points",
                details: nil
            ))
        }
    }

    private func handleRecover(result: @escaping FlutterResult) {
        guard let session = store.loadSession() else {
            result(nil)
            return
        }
        guard session.status == ActiveActivitySessionData.statusRecording else {
            result(session.toMap())
            return
        }
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let recoveryMillis = store.lastPoint().flatMap { IsoTime.toEpochMillis($0.timestamp) }
            ?? nowMillis
        let paused = session.copyWith(
            status: ActiveActivitySessionData.statusPaused,
            pausedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(nowMillis) / 1000))),
            elapsedDurationSeconds: elapsedSeconds(session, referenceMillis: recoveryMillis)
        )
        // Save the pause before stopping Core Location so an in-flight update
        // is rejected by the recorder's recording-state guard.
        store.saveSession(paused)
        recorder.stopCollection()
        result(paused.toMap())
    }

    /// Accumulated elapsed seconds, mirroring the Dart geolocator recorder:
    /// paused sessions keep their stored value; otherwise add the current
    /// segment's running time from `resumedAt ?? startedAt`.
    private func elapsedSeconds(
        _ session: ActiveActivitySessionData,
        referenceMillis: Int64
    ) -> Int {
        if session.status == ActiveActivitySessionData.statusPaused {
            return session.elapsedDurationSeconds
        }
        guard let anchor = IsoTime.toEpochMillis(session.resumedAt ?? session.startedAt) else {
            return session.elapsedDurationSeconds
        }
        let segmentSeconds = Int((referenceMillis - anchor) / 1000)
        return session.elapsedDurationSeconds + max(0, segmentSeconds)
    }

    private func isSupportedVersion(_ arguments: [String: Any]?) -> Bool {
        guard let version = JsonScalar.int(arguments?["version"]) else {
            return true
        }
        return version == ActivityRecorderChannel.payloadVersion
    }

    static let payloadVersion = 1

    static let methodChannelName = "endurain/activity_recorder/methods"
    static let eventChannelName = "endurain/activity_recorder/events"

    static let methodStart = "start"
    static let methodPause = "pause"
    static let methodResume = "resume"
    static let methodStop = "stop"
    static let methodDiscard = "discard"
    static let methodDrain = "drain"
    static let methodRecover = "recover"

    static let errorArgs = "invalid_arguments"
    static let errorState = "invalid_state"
    static let errorService = "service_start_failed"
    static let errorVersion = "unsupported_version"
    static let errorStore = "store_read_failed"
}
