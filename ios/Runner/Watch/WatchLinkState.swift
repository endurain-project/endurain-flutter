import Foundation

/// Maps the WatchConnectivity session state to a Dart `WatchLinkStatus` name.
///
/// Kept free of `WCSession` so the mapping can be unit-tested.
enum WatchLinkState {
    static func status(
        isSupported: Bool,
        isActivated: Bool,
        isPaired: Bool,
        isWatchAppInstalled: Bool,
        isReachable: Bool
    ) -> String {
        guard isSupported else {
            // iPad, or any device without WatchConnectivity.
            return "unsupported"
        }
        guard isActivated else {
            return "unavailable"
        }
        guard isPaired else {
            return "unpaired"
        }
        guard isWatchAppInstalled else {
            return "appNotInstalled"
        }
        return isReachable ? "connected" : "disconnected"
    }
}
