import SwiftUI
import WidgetKit

/// The widget extension of the iPhone app. It holds only the Live Activity of
/// a recording in progress; the app has no Home Screen widgets.
@main
struct EndurainLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}
