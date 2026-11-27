import ActivityKit
import SwiftUI
import WidgetKit

/// Draws the Live Activity of a recording on the Lock Screen and in the
/// Dynamic Island: the elapsed time, which the system keeps counting, and
/// the distance and pace or speed the app last reported.
///
/// Every text comes from the app already localized, so the extension has no
/// strings of its own.
struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .padding()
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MetricView(label: state.metrics.distanceLabel, value: state.metrics.distanceValue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    MetricView(label: state.metrics.speedLabel, value: state.metrics.speedValue)
                }
                DynamicIslandExpandedRegion(.center) {
                    TitleView(state: state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ElapsedTimeView(state: state)
                        .font(.system(.title, design: .rounded).weight(.semibold))
                }
            } compactLeading: {
                StatusIcon(state: state, isStandalone: true)
            } compactTrailing: {
                ElapsedTimeView(state: state)
                    .frame(maxWidth: 64)
            } minimal: {
                StatusIcon(state: state, isStandalone: true)
            }
        }
    }
}

private struct LockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleView(state: state)
            HStack(alignment: .lastTextBaseline, spacing: 16) {
                ElapsedTimeView(state: state)
                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                Spacer(minLength: 0)
                MetricView(label: state.metrics.distanceLabel, value: state.metrics.distanceValue)
                MetricView(label: state.metrics.speedLabel, value: state.metrics.speedValue)
            }
        }
    }
}

/// The activity type, followed by the paused label while paused.
private struct TitleView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 6) {
            StatusIcon(state: state, isStandalone: false)
            Text(state.metrics.title)
                .font(.headline)
            if state.isPaused {
                Text(state.metrics.pausedLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
    }
}

/// The recorded time, counted by the system while recording and stopped at
/// the pause.
private struct ElapsedTimeView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        Text(
            timerInterval: state.timerStart...Date.distantFuture,
            pauseTime: state.pausedAt,
            countsDown: false,
            showsHours: true
        )
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
}

private struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
    }
}

/// Recording or paused, as a symbol.
private struct StatusIcon: View {
    let state: WorkoutActivityAttributes.ContentState

    /// Whether no text next to the symbol says the same, as in the compact
    /// and minimal Dynamic Island; VoiceOver then reads the activity type and
    /// the paused label instead.
    let isStandalone: Bool

    var body: some View {
        Image(systemName: state.isPaused ? "pause.fill" : "record.circle")
            .foregroundStyle(state.isPaused ? Color.secondary : Color.red)
            .accessibilityHidden(!isStandalone)
            .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard state.isPaused else {
            return state.metrics.title
        }
        return "\(state.metrics.title), \(state.metrics.pausedLabel)"
    }
}
