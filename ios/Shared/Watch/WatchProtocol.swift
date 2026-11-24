import Foundation

/// Wire contract between the Endurain iPhone app and its Apple Watch app.
///
/// Compiled into both targets. The watch sends each finished session as a
/// JSON file (`WCSession.transferFile`) whose body is exactly the envelope the
/// Dart `WatchSessionHandoff.fromJson` reads. The phone keeps the file until
/// Dart has stored the activity, then sends an acknowledgement back
/// (`WCSession.transferUserInfo`) so the watch can drop its copy.
enum WatchProtocol {
    /// Mirrors `WatchSessionHandoff.currentPayloadVersion` in Dart. Bump both
    /// together when the envelope changes shape.
    static let payloadVersion = 1

    /// Mirrors the Dart `WatchSource.appleWatch` name.
    static let source = "appleWatch"

    /// Mirrors `ActiveActivitySession.currentSchemaVersion` in Dart.
    static let sessionSchemaVersion = 3

    /// Bundle identifier of the watch app. HealthKit reports it as the source
    /// of every workout the watch saves.
    static let watchAppBundleIdentifier = "com.endurain.endurain.watchkitapp"

    // Metadata of a file transfer and keys of a user-info transfer.
    static let keyKind = "kind"
    static let keyVersion = "version"
    static let keySessionId = "sessionId"

    /// A file transfer carrying one finished session.
    static let kindHandoff = "handoff"

    /// A user-info transfer confirming the phone stored a session.
    static let kindAcknowledgement = "ack"

    static func handoffMetadata(sessionId: String) -> [String: Any] {
        return [
            keyKind: kindHandoff,
            keyVersion: payloadVersion,
            keySessionId: sessionId,
        ]
    }

    static func acknowledgement(sessionId: String) -> [String: Any] {
        return [
            keyKind: kindAcknowledgement,
            keyVersion: payloadVersion,
            keySessionId: sessionId,
        ]
    }

    /// The session id an acknowledgement confirms, or nil for any other
    /// payload.
    static func acknowledgedSessionId(in userInfo: [String: Any]) -> String? {
        guard userInfo[keyKind] as? String == kindAcknowledgement,
              let sessionId = userInfo[keySessionId] as? String,
              !sessionId.isEmpty
        else {
            return nil
        }
        return sessionId
    }

    /// UTC ISO-8601 with milliseconds, the format the Dart models write.
    static func timestamp(_ date: Date) -> String {
        return isoFormatter.string(from: date)
    }

    static func date(fromTimestamp value: String) -> Date? {
        return isoFormatter.date(from: value)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
