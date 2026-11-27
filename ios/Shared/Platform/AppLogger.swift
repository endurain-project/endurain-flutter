import Foundation
import os

/// Loggers of the phone and watch apps, one per type.
///
/// The subsystem is the bundle identifier, so the phone app, the watch app
/// and the test host each log under their own. Interpolate only non-sensitive
/// codes with `privacy: .public`; error descriptions can carry paths or
/// identifiers, so they stay at the default (private) level.
enum AppLogger {
    static func make(category: String) -> Logger {
        return Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.endurain.endurain",
            category: category
        )
    }
}
