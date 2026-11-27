import SwiftUI
import WatchKit

@main
struct EndurainWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(WorkoutManager.shared)
                .environment(PhoneLink.shared)
        }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        PhoneLink.shared.activate()
        WorkoutManager.shared.restoreUnfinishedRecording()
    }

    func applicationDidBecomeActive() {
        PhoneLink.shared.sendPending()
    }

    func handleActiveWorkoutRecovery() {
        WorkoutManager.shared.recoverActiveWorkout()
    }
}
