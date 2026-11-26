import Foundation
import WatchKit

/// The start countdown's wrist taps.
enum WorkoutCountdown {
    /// Start countdown choices in seconds; 0 starts right away.
    static let options = [0, 3, 5, 10]

    /// The last seconds of the countdown that tap the wrist.
    static let cueSeconds = 3

    /// Waits until [endsAt], tapping the wrist once for each of the last
    /// [cueSeconds] seconds. Returns early when the task is cancelled.
    @MainActor
    static func run(until endsAt: Date) async {
        var lastCue: Int?
        while !Task.isCancelled {
            let left = endsAt.timeIntervalSinceNow
            if left <= 0 {
                break
            }
            let seconds = Int(left.rounded(.up))
            if seconds <= cueSeconds, seconds != lastCue {
                lastCue = seconds
                WKInterfaceDevice.current().play(.click)
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
    }
}
