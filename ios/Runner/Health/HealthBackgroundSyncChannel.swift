// Flutter's Objective-C headers carry no concurrency annotations; the method
// handler and the reply callbacks run on the platform (main) thread.
@preconcurrency import Flutter
import Foundation

/// The method channel between Dart and the background trigger of automatic
/// health import. Mirrors `HealthBackgroundSyncChannelContract` in
/// `lib/features/health/services/health_background_sync_adapter.dart`.
///
/// Registered on the app's engine (where Dart calls `listen` once it is ready
/// to run background syncs) and on every headless engine
/// `HealthBackgroundSync` starts (where Dart calls `reportFinished`).
@MainActor
final class HealthBackgroundSyncChannel {
    static let channelName = "endurain/health_background_sync"
    static let setScheduledMethod = "setScheduled"
    static let listenMethod = "listen"
    static let runMethod = "run"
    static let reportFinishedMethod = "reportFinished"
    static let scheduledArgument = "scheduled"
    static let succeededArgument = "succeeded"
    static let invalidArgumentsError = "invalid_arguments"
    static let scheduleFailedError = "schedule_failed"

    private let setScheduled: @MainActor (Bool) async throws -> Void
    private let onListen: @MainActor (HealthBackgroundSyncChannel) -> Void
    private let onFinished: @MainActor (Bool) -> Void
    private var channel: FlutterMethodChannel?

    init(
        setScheduled: @escaping @MainActor (Bool) async throws -> Void,
        onListen: @escaping @MainActor (HealthBackgroundSyncChannel) -> Void,
        onFinished: @escaping @MainActor (Bool) -> Void
    ) {
        self.setScheduled = setScheduled
        self.onListen = onListen
        self.onFinished = onFinished
    }

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            MainActor.assumeIsolated {
                self?.handle(call, result: result)
            }
        }
        self.channel = channel
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        switch call.method {
        case Self.setScheduledMethod:
            guard let scheduled = arguments?[Self.scheduledArgument] as? Bool else {
                result(Self.invalidArguments(Self.scheduledArgument))
                return
            }
            Task {
                do {
                    try await setScheduled(scheduled)
                    result(nil)
                } catch {
                    result(FlutterError(
                        code: Self.scheduleFailedError,
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        case Self.listenMethod:
            onListen(self)
            result(nil)
        case Self.reportFinishedMethod:
            guard let succeeded = arguments?[Self.succeededArgument] as? Bool else {
                result(Self.invalidArguments(Self.succeededArgument))
                return
            }
            onFinished(succeeded)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Asks this engine's Dart side to run one sync. `completion` gets whether
    /// it succeeded; `false` when it failed or Dart does not answer the method.
    func run(_ completion: @escaping @MainActor (Bool) -> Void) {
        guard let channel else {
            completion(false)
            return
        }
        channel.invokeMethod(Self.runMethod, arguments: nil) { reply in
            MainActor.assumeIsolated {
                completion((reply as? Bool) == true)
            }
        }
    }

    private static func invalidArguments(_ name: String) -> FlutterError {
        FlutterError(
            code: invalidArgumentsError,
            message: "\(name) must be a boolean",
            details: nil
        )
    }
}
