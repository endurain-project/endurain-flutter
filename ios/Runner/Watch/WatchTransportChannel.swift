// Flutter's Objective-C headers carry no concurrency annotations; every
// channel callback this file receives runs on the platform (main) thread.
@preconcurrency import Flutter
import Foundation

/// Serves the Dart `WatchTransportChannelContract` from
/// [WatchConnectivityBridge].
///
/// Methods: `linkStatus`, `drainHandoffs` and `acknowledgeHandoff`, each with
/// a `version` argument that must match [WatchProtocol.payloadVersion].
/// Events: `linkStatusChanged` and `handoffAvailable`.
///
/// Main-actor isolated like the Flutter channels it serves; inbox reads and
/// acknowledgements run off the main actor.
@MainActor
final class WatchTransportChannel: NSObject, @preconcurrency FlutterStreamHandler {
    static let methodChannelName = "endurain/watch_transport/methods"
    static let eventChannelName = "endurain/watch_transport/events"

    static let errorInvalidArguments = "invalid_arguments"
    static let errorUnsupportedVersion = "unsupported_version"
    static let errorStoreReadFailed = "store_read_failed"

    private let bridge: WatchConnectivityBridge
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    init(bridge: WatchConnectivityBridge = .shared) {
        self.bridge = bridge
        super.init()
    }

    func register(with messenger: FlutterBinaryMessenger) {
        let methods = FlutterMethodChannel(
            name: Self.methodChannelName,
            binaryMessenger: messenger
        )
        methods.setMethodCallHandler { [weak self] call, result in
            // Flutter calls method handlers on the platform thread.
            MainActor.assumeIsolated {
                self?.handle(call, result: result)
            }
        }
        methodChannel = methods

        let events = FlutterEventChannel(
            name: Self.eventChannelName,
            binaryMessenger: messenger
        )
        events.setStreamHandler(self)
        eventChannel = events

        bridge.onHandoffReceived = { [weak self] in
            self?.send(["type": "handoffAvailable"])
        }
        bridge.onLinkStatusChanged = { [weak self] status in
            self?.send(["type": "linkStatusChanged", "linkStatus": status])
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        let knownMethods = ["linkStatus", "drainHandoffs", "acknowledgeHandoff"]
        guard knownMethods.contains(call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard (arguments?["version"] as? NSNumber)?.intValue == WatchProtocol.payloadVersion else {
            result(FlutterError(
                code: Self.errorUnsupportedVersion,
                message: "Unsupported watch transport version",
                details: nil
            ))
            return
        }

        switch call.method {
        case "linkStatus":
            result(bridge.linkStatus)
        case "drainHandoffs":
            let inbox = bridge.inbox
            Task {
                switch await Self.readInboxInBackground(inbox) {
                case .success(let handoffs):
                    result(handoffs)
                case .failure:
                    result(FlutterError(
                        code: Self.errorStoreReadFailed,
                        message: "Could not read the watch inbox",
                        details: nil
                    ))
                }
            }
        default:
            guard let sessionId = arguments?["sessionId"] as? String, !sessionId.isEmpty else {
                result(FlutterError(
                    code: Self.errorInvalidArguments,
                    message: "Missing sessionId",
                    details: nil
                ))
                return
            }
            let bridge = bridge
            Task {
                await Self.acknowledgeInBackground(bridge, sessionId: sessionId)
                result(nil)
            }
        }
    }

    @concurrent
    nonisolated private static func readInboxInBackground(
        _ inbox: HandoffFileStore
    ) async -> sending Result<[[String: Any]], Error> {
        return readInbox(inbox)
    }

    @concurrent
    nonisolated private static func acknowledgeInBackground(
        _ bridge: WatchConnectivityBridge,
        sessionId: String
    ) async {
        bridge.acknowledge(sessionId: sessionId)
    }

    /// Every readable envelope in [inbox]. An unreadable file, or one from a
    /// newer watch app, is left in place (and skipped) so a later app version
    /// can still read it.
    nonisolated static func readInbox(_ inbox: HandoffFileStore) -> Result<[[String: Any]], Error> {
        let entries: [HandoffFileStore.Entry]
        do {
            entries = try inbox.entries()
        } catch {
            return .failure(error)
        }
        var handoffs: [[String: Any]] = []
        for entry in entries {
            guard let data = try? Data(contentsOf: entry.url),
                  let object = try? JSONSerialization.jsonObject(with: data),
                  let envelope = object as? [String: Any]
            else {
                continue
            }
            guard WatchProtocol.isSupported(version: envelope[WatchProtocol.keyVersion]) else {
                NSLog("Endurain watch transport: skipped a session from a newer watch app")
                continue
            }
            handoffs.append(envelope)
        }
        return .success(handoffs)
    }

    // MARK: - FlutterStreamHandler

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        send(["type": "linkStatusChanged", "linkStatus": bridge.linkStatus])
        let hasPending = !bridge.inbox.isEmpty
        if hasPending {
            send(["type": "handoffAvailable"])
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func send(_ event: [String: Any]) {
        eventSink?(event)
    }
}
