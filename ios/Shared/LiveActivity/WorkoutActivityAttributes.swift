import ActivityKit
import Foundation

/// The Live Activity of a recording in progress on the iPhone, shown on the
/// Lock Screen and in the Dynamic Island.
///
/// Shared by the iPhone app, which starts and updates it
/// (`WorkoutLiveActivity`), and the Live Activity widget extension, which
/// draws it.
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the elapsed-time counter read zero: the recorded time is the
        /// time from here to now, or to [pausedAt] while paused. Lets the
        /// system count the time without an update every second.
        var timerStart: Date

        /// When the recording paused, which stops the counter; nil while it
        /// records.
        var pausedAt: Date?

        /// What the app shows for the recording, already localized.
        var metrics: Metrics

        var isPaused: Bool {
            return pausedAt != nil
        }
    }

    /// The localized labels and formatted values the app shows on its
    /// recording screen, handed over by Flutter so both read the same.
    struct Metrics: Codable, Hashable {
        /// The activity type's name.
        var title: String
        var distanceLabel: String
        var distanceValue: String
        /// "Pace" for a run, "Speed" otherwise, as in the app.
        var speedLabel: String
        var speedValue: String
        /// Shown while the recording is paused.
        var pausedLabel: String
    }

    /// The recording's local session ID.
    var localSessionId: String
}
