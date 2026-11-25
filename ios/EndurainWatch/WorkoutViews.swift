import SwiftUI

struct RootView: View {
    @EnvironmentObject private var workout: WorkoutManager

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
        case .running, .paused, .ending:
            ActiveWorkoutView()
        case .finished(let summary):
            SummaryView(summary: summary)
        }
    }
}

struct StartView: View {
    @EnvironmentObject private var workout: WorkoutManager
    @EnvironmentObject private var phoneLink: PhoneLink

    var body: some View {
        NavigationStack {
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
}

struct ActiveWorkoutView: View {
    @EnvironmentObject private var workout: WorkoutManager
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
    @EnvironmentObject private var workout: WorkoutManager

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 2) {
                if let type = workout.activityType {
                    Label(type.title, systemImage: type.symbolName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(WorkoutFormat.duration(workout.elapsedSeconds(at: context.date)))
                    .font(.system(.title, design: .rounded).monospacedDigit())
                    .foregroundStyle(workout.phase == .paused ? .yellow : .primary)
                Text(WorkoutFormat.distance(workout.distanceMeters))
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                Label(
                    workout.heartRateBpm.map { "\($0)" } ?? "--",
                    systemImage: "heart.fill"
                )
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundStyle(.red)
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

struct SummaryView: View {
    @EnvironmentObject private var workout: WorkoutManager
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
