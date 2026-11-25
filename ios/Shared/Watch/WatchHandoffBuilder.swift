import Foundation

/// Builds the handoff envelope for a finished watch workout.
///
/// The result is exactly what the Dart `WatchSessionHandoff.fromJson` reads:
/// the session in the shape of `ActiveActivitySession` and the points in the
/// shape of `RecordedActivityPoint`.
enum WatchHandoffBuilder {
    static func envelope(
        recording: WatchRecording,
        points: [WatchRecordedPoint],
        endedAt: Date,
        elapsedSeconds: TimeInterval,
        healthWorkoutId: String?
    ) -> [String: Any] {
        let session: [String: Any] = [
            "schemaVersion": WatchProtocol.sessionSchemaVersion,
            "localSessionId": recording.sessionId,
            "activityType": recording.activityType.rawValue,
            "status": "completed",
            "startedAt": WatchProtocol.timestamp(recording.startedAt),
            "endedAt": WatchProtocol.timestamp(max(endedAt, recording.startedAt)),
            "elapsedDurationSeconds": max(0, Int(elapsedSeconds.rounded())),
            "currentSegmentIndex": recording.segmentIndex,
            "autoPauseEnabled": false,
            "autoPauseDelaySeconds": 5,
            "pausedAutomatically": false,
        ]
        var envelope: [String: Any] = [
            "version": WatchProtocol.payloadVersion,
            "source": WatchProtocol.source,
            "session": session,
            "points": points
                .sorted { $0.timestamp < $1.timestamp }
                .map { $0.jsonObject() },
        ]
        if let healthWorkoutId, !healthWorkoutId.isEmpty {
            envelope["healthWorkoutId"] = healthWorkoutId
        }
        return envelope
    }

    static func data(
        recording: WatchRecording,
        points: [WatchRecordedPoint],
        endedAt: Date,
        elapsedSeconds: TimeInterval,
        healthWorkoutId: String?
    ) throws -> Data {
        return try JSONSerialization.data(withJSONObject: envelope(
            recording: recording,
            points: points,
            endedAt: endedAt,
            elapsedSeconds: elapsedSeconds,
            healthWorkoutId: healthWorkoutId
        ))
    }

    /// When a recording that was cut short ended: its last point, or the
    /// start when it has none.
    static func endOfInterruptedRecording(
        _ recording: WatchRecording,
        points: [WatchRecordedPoint]
    ) -> Date {
        let lastPoint = points.map { $0.timestamp }.max()
        return max(lastPoint ?? recording.startedAt, recording.startedAt)
    }
}
