// Flutter's Objective-C headers carry no concurrency annotations; the method
// handler runs on the platform (main) thread.
@preconcurrency import Flutter
import Foundation
import HealthKit

/// The HealthKit query anchors a workout changes token stands for: one for
/// workouts and one for workout routes, since a route is often saved after
/// its workout. Each anchor is kept archived, so the token stays `Sendable`.
///
/// Wire form: base64 of the JSON of the archived anchors. Dart treats it as
/// opaque, stores it per profile and hands it back.
struct HealthWorkoutChangesToken: Codable, Equatable, Sendable {
    var workouts: Data?
    var routes: Data?

    func encoded() throws -> String {
        try JSONEncoder().encode(self).base64EncodedString()
    }

    /// The token `encoded()` produced, or `nil` when `token` is not one (the
    /// caller then reads a time window instead).
    static func decode(_ token: String) -> HealthWorkoutChangesToken? {
        guard let data = Data(base64Encoded: token),
              let decoded = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        do {
            _ = try anchor(from: decoded.workouts)
            _ = try anchor(from: decoded.routes)
        } catch {
            return nil
        }
        return decoded
    }

    static func archive(_ anchor: HKQueryAnchor?) throws -> Data? {
        guard let anchor else { return nil }
        return try NSKeyedArchiver.archivedData(
            withRootObject: anchor,
            requiringSecureCoding: true
        )
    }

    /// The anchor archived in `data`, or `nil` without one (read from the
    /// start). Throws when `data` holds no anchor.
    static func anchor(from data: Data?) throws -> HKQueryAnchor? {
        guard let data else { return nil }
        guard let anchor = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: HKQueryAnchor.self,
            from: data
        ) else {
            throw CocoaError(.coderReadCorrupt)
        }
        return anchor
    }
}

/// Reads which workouts and workout routes HealthKit saved since a changes
/// token, with anchored queries, for the automatic import on iOS (the
/// `health` plugin has no change tracking there). Mirrors
/// `MethodChannelHealthWorkoutChangesReader` in
/// `lib/features/health/services/health_workout_changes_reader.dart`.
///
/// - `currentToken` replies the token for the changes from now on.
/// - `changesSince` replies `{nextToken, earliestStartMs}`, the start of the
///   earliest sample saved since `token` (absent when none was), or
///   `{nextToken: null}` when `token` is not readable.
///
/// It reads under the workout and route read permissions Health Sync already
/// requests.
@MainActor
final class HealthWorkoutChangesChannel {
    static let channelName = "endurain/health_workout_changes"
    static let currentTokenMethod = "currentToken"
    static let changesSinceMethod = "changesSince"

    private let healthStore: HKHealthStore
    private var channel: FlutterMethodChannel?

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            // Flutter calls method handlers on the platform thread.
            MainActor.assumeIsolated {
                self?.handle(call, result: result)
            }
        }
        self.channel = channel
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Self.currentTokenMethod:
            reply(result, since: HealthWorkoutChangesToken()) { token, _ in
                try token.encoded()
            }
        case Self.changesSinceMethod:
            guard let raw = (call.arguments as? [String: Any])?["token"] as? String else {
                result(FlutterError(
                    code: "INVALID_ARGUMENT",
                    message: "token is required",
                    details: nil
                ))
                return
            }
            guard let token = HealthWorkoutChangesToken.decode(raw) else {
                result(["nextToken": NSNull()])
                return
            }
            reply(result, since: token) { next, earliestStart in
                var reply: [String: Any] = ["nextToken": try next.encoded()]
                if let earliestStart {
                    reply["earliestStartMs"] = (earliestStart.timeIntervalSince1970 * 1000).rounded()
                }
                return reply
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func reply(
        _ result: @escaping FlutterResult,
        since token: HealthWorkoutChangesToken,
        encode: @escaping (HealthWorkoutChangesToken, Date?) throws -> Any
    ) {
        let healthStore = healthStore
        Task {
            do {
                async let workouts = Self.read(
                    HKObjectType.workoutType(),
                    since: token.workouts,
                    in: healthStore
                )
                async let routes = Self.read(
                    HKSeriesType.workoutRoute(),
                    since: token.routes,
                    in: healthStore
                )
                let (workoutChanges, routeChanges) = try await (workouts, routes)
                let next = HealthWorkoutChangesToken(
                    workouts: workoutChanges.anchor,
                    routes: routeChanges.anchor
                )
                let earliestStart = [workoutChanges.earliestStart, routeChanges.earliestStart]
                    .compactMap { $0 }
                    .min()
                result(try encode(next, earliestStart))
            } catch {
                result(FlutterError(
                    code: HealthKitErrorCode.code(for: error),
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }

    /// Runs an anchored query for the samples of `type` saved after the
    /// archived `anchor` (all of them without one) and returns the next
    /// archived anchor and the earliest start among them. HealthKit runs it
    /// on its own background queue.
    nonisolated private static func read(
        _ type: HKSampleType,
        since anchor: Data?,
        in healthStore: HKHealthStore
    ) async throws -> (anchor: Data?, earliestStart: Date?) {
        guard HKHealthStore.isHealthDataAvailable() else {
            return (anchor, nil)
        }
        let start = try HealthWorkoutChangesToken.anchor(from: anchor)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: type,
                predicate: nil,
                anchor: start,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, newAnchor, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                do {
                    continuation.resume(returning: (
                        try HealthWorkoutChangesToken.archive(newAnchor) ?? anchor,
                        samples?.map(\.startDate).min()
                    ))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            healthStore.execute(query)
        }
    }
}
