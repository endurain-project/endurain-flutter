import SwiftUI
import WatchKit

@main
struct EndurainWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @StateObject private var workout = WorkoutManager.shared
    @StateObject private var phoneLink = PhoneLink.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(workout)
                .environmentObject(phoneLink)
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
