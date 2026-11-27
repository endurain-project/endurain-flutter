import SwiftUI

struct RootView: View {
    @Environment(WorkoutManager.self) private var workout

    var body: some View {
        content
            .alert(
                "Endurain",
                isPresented: Binding(
                    get: { workout.errorMessage != nil },
                    set: { if !$0 { workout.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(workout.errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch workout.phase {
        case .idle, .starting:
            StartView()
        case .countingDown(let endsAt):
            CountdownView(endsAt: endsAt)
        case .running, .paused, .ending:
            ActiveWorkoutView()
        case .finished(let summary):
            SummaryView(summary: summary)
        }
    }
}

struct StartView: View {
    @Environment(WorkoutManager.self) private var workout
    @Environment(PhoneLink.self) private var phoneLink

    var body: some View {
        @Bindable var workout = workout
        return NavigationStack {
            List {
                Section {
                    ForEach(WatchActivityType.allCases, id: \.self) { type in
                        Button {
                            Task { await workout.start(type) }
                        } label: {
                            Label(type.title, systemImage: type.symbolName)
                        }
                        .disabled(workout.phase != .idle)
                    }
                }
                Section {
                    Picker("Countdown", selection: $workout.countdownSeconds) {
                        ForEach(WorkoutCountdown.options, id: \.self) { seconds in
                            Text(Self.countdownLabel(seconds)).tag(seconds)
                        }
                    }
                    .disabled(workout.phase != .idle)
                } footer: {
                    Text("Time to get ready before recording starts.")
                }
                if workout.isLocationDenied {
                    Section {
                        Text("Location is off for Endurain. Workouts without a GPS route can't be uploaded yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if phoneLink.waitingCount > 0 {
                    Section {
                        Text("Waiting for Endurain on your iPhone: \(phoneLink.waitingCount)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Endurain")
        }
    }

    private static func countdownLabel(_ seconds: Int) -> LocalizedStringKey {
        return seconds == 0 ? "Off" : "\(seconds) s"
    }
}

/// Counts down to the start of a workout. The watch taps the wrist for the
/// last seconds and once more when recording starts (see `WorkoutManager`).
struct CountdownView: View {
    @Environment(WorkoutManager.self) private var workout
    let endsAt: Date
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @ScaledMetric(relativeTo: .largeTitle) private var countdownFontSize: CGFloat = 64

    var body: some View {
        // The always-on display refreshes about once a second at most.
        TimelineView(.periodic(from: .now, by: isLuminanceReduced ? 1 : 0.25)) { context in
            let remaining = max(0, Int(endsAt.timeIntervalSince(context.date).rounded(.up)))
            VStack(spacing: 6) {
                if let type = workout.activityType {
                    Label(type.title, systemImage: type.symbolName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text("\(remaining)")
                    .font(.system(size: countdownFontSize, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                    .accessibilityLabel(Text("Seconds left: \(remaining)"))
                HStack {
                    Button {
                        workout.cancelCountdown()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("Cancel"))
                    Button {
                        workout.skipCountdown()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .tint(.green)
                    .accessibilityLabel(Text("Start now"))
                }
            }
        }
    }
}

struct ActiveWorkoutView: View {
    @Environment(WorkoutManager.self) private var workout
    @State private var page = 1
    @State private var confirmingEnd = false

    var body: some View {
        TabView(selection: $page) {
            controls.tag(0)
            MetricsView().tag(1)
        }
        .tabViewStyle(.page)
        .onChange(of: workout.phase) { _, phase in
            // Show the metrics again after resuming.
            if phase == .running {
                page = 1
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            if workout.phase == .paused {
                Button {
                    workout.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .tint(.green)
            } else {
                Button {
                    workout.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .tint(.yellow)
                .disabled(workout.phase != .running)
            }
            Button(role: .destructive) {
                confirmingEnd = true
            } label: {
                Label("End", systemImage: "xmark")
            }
            .disabled(workout.phase == .ending)
        }
        .confirmationDialog("End this workout?", isPresented: $confirmingEnd) {
            Button("End Workout", role: .destructive) {
                workout.end()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct MetricsView: View {
    @Environment(WorkoutManager.self) private var workout
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        // The always-on display refreshes once a minute, so it shows whole
        // minutes and the timeline does not wake the app every second.
        TimelineView(.periodic(from: .now, by: isLuminanceReduced ? 60 : 1)) { context in
            VStack(alignment: .leading, spacing: 2) {
                if let type = workout.activityType {
                    Label(type.title, systemImage: type.symbolName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                let elapsed = workout.elapsedSeconds(at: context.date)
                Text(isLuminanceReduced
                    ? WorkoutFormat.durationInMinutes(elapsed)
                    : WorkoutFormat.duration(elapsed))
                    .font(.system(.title, design: .rounded).monospacedDigit())
                    .foregroundStyle(workout.phase == .paused ? .yellow : .primary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Elapsed time"))
                    .accessibilityValue(Text(WorkoutFormat.spokenDuration(elapsed)))
                Text(WorkoutFormat.distance(workout.distanceMeters))
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Distance"))
                    .accessibilityValue(Text(WorkoutFormat.spokenDistance(workout.distanceMeters)))
                Label(
                    workout.heartRateBpm.map { "\($0)" } ?? "--",
                    systemImage: "heart.fill"
                )
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundStyle(.red)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(heartRateAccessibilityLabel)
                if workout.phase == .ending {
                    Text("Saving…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
}

extension MetricsView {
    private var heartRateAccessibilityLabel: Text {
        guard let bpm = workout.heartRateBpm else {
            return Text("Heart rate, not available")
        }
        return Text("Heart rate, \(bpm) beats per minute")
    }
}

struct SummaryView: View {
    @Environment(WorkoutManager.self) private var workout
    let summary: WorkoutManager.Summary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Label("Workout saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(WorkoutFormat.duration(summary.elapsedSeconds))
                    .font(.system(.title2, design: .rounded).monospacedDigit())
                if summary.distanceMeters != nil {
                    Text(WorkoutFormat.distance(summary.distanceMeters))
                        .font(.system(.title3, design: .rounded).monospacedDigit())
                }
                if summary.hasRoute {
                    Text("Endurain on your iPhone uploads it the next time it opens.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No GPS route was recorded, so this workout can't be uploaded yet. It stays saved in Health.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button("Done") {
                    workout.dismissSummary()
                }
            }
        }
    }
}

extension WatchActivityType {
    var title: LocalizedStringKey {
        switch self {
        case .run: return "Run"
        case .ride: return "Ride"
        case .walk: return "Walk"
        case .hike: return "Hike"
        }
    }

    var symbolName: String {
        switch self {
        case .run: return "figure.run"
        case .ride: return "figure.outdoor.cycle"
        case .walk: return "figure.walk"
        case .hike: return "figure.hiking"
        }
    }
}

enum WorkoutFormat {
    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// Elapsed time as whole minutes (for example "1h 12m"), for the
    /// always-on display, which does not show seconds.
    static func durationInMinutes(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int(seconds)) / 60
        return Duration.seconds(minutes * 60).formatted(
            .units(allowed: [.hours, .minutes], width: .narrow)
        )
    }

    /// Elapsed time as words for VoiceOver (for example "1 hour, 2 minutes").
    static func spokenDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        // Zero units are hidden, which would leave nothing to read at 0:00.
        return Duration.seconds(total).formatted(
            .units(
                allowed: [.hours, .minutes, .seconds],
                width: .wide,
                zeroValueUnits: total == 0 ? .show(length: 1) : .hide
            )
        )
    }

    /// Distance as words for VoiceOver (for example "1.25 kilometers").
    static func spokenDistance(_ meters: Double?) -> String {
        let measurement = Measurement(value: meters ?? 0, unit: UnitLength.meters)
        let usesMetric = Locale.current.measurementSystem == .metric
        let converted = measurement.converted(to: usesMetric ? .kilometers : .miles)
        return converted.formatted(
            .measurement(width: .wide, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(2)))
        )
    }

    /// Kilometres or miles, following the watch's region settings.
    static func distance(_ meters: Double?) -> String {
        let measurement = Measurement(value: meters ?? 0, unit: UnitLength.meters)
        let usesMetric = Locale.current.measurementSystem == .metric
        let converted = measurement.converted(to: usesMetric ? .kilometers : .miles)
        return converted.formatted(
            .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(2)))
        )
    }
}
