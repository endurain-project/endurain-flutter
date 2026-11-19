import Foundation

/// Builds the spoken sentence for one announcement from an
/// `AnnouncementStateData`'s localized templates and the concrete values at
/// the threshold instant.
///
/// Mirrors the Android `AnnouncementSpeechBuilder` object exactly — see its
/// doc comment for why a literal substring replace on Dart-rendered templates
/// is correct for every locale, and why only the decimal separator glyph of a
/// number is localized.
enum AnnouncementSpeechBuilder {
    private static let metersPerKilometer = 1000.0
    private static let metersPerMile = 1609.344

    /// Roughly 10.8 km/h; only ever used to render a settings preview.
    private static let sampleSpeedMetersPerSecond = 3.0

    private static let placeholderValue = "{value}"
    private static let placeholderDistance = "{distance}"
    private static let placeholderDuration = "{duration}"
    private static let placeholderLapMetric = "{lapMetric}"
    private static let placeholderOverallMetric = "{overallMetric}"

    /// - Parameters:
    ///   - distanceMeters: cumulative distance (in meters) at the
    ///     announcement instant, already interpolated to the exact threshold.
    ///   - elapsedSeconds: cumulative elapsed recording time (in seconds) at
    ///     the announcement instant, already interpolated to the exact
    ///     threshold.
    static func build(
        state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int
    ) -> String {
        let displayDistance = state.useImperialUnits
            ? distanceMeters / metersPerMile
            : distanceMeters / metersPerKilometer
        let distanceText = state.distanceUnitTemplate.replacingOccurrences(
            of: placeholderValue,
            with: formatDecimal(displayDistance, languageTag: state.languageTag)
        )
        let durationText = formatClock(elapsedSeconds)
        let lapMetricText = buildMetricText(
            state,
            distanceMeters: max(0, distanceMeters - state.lastAnnouncementDistanceMeters),
            elapsedSeconds: max(0, elapsedSeconds - state.lastAnnouncementElapsedSeconds)
        )
        let overallMetricText = buildMetricText(
            state,
            distanceMeters: distanceMeters,
            elapsedSeconds: elapsedSeconds
        )

        return state.messageTemplate
            .replacingOccurrences(of: placeholderDistance, with: distanceText)
            .replacingOccurrences(of: placeholderDuration, with: durationText)
            .replacingOccurrences(of: placeholderLapMetric, with: lapMetricText)
            .replacingOccurrences(of: placeholderOverallMetric, with: overallMetricText)
    }

    /// Builds the sample sentence spoken by the settings preview action.
    ///
    /// The milestone is the user's own configured interval, so the preview
    /// states what a real announcement will state. The other axis is derived
    /// from `sampleSpeedMetersPerSecond` purely so the pace/speed fragments are
    /// self-consistent — a preview has no recorded data to report.
    static func buildPreview(state: AnnouncementStateData) -> String {
        let distanceMeters: Double
        let elapsedSeconds: Int
        if state.isTimeBased {
            elapsedSeconds = state.timeIntervalSeconds
            distanceMeters = sampleSpeedMetersPerSecond * Double(elapsedSeconds)
        } else {
            distanceMeters = state.distanceIntervalMeters
            elapsedSeconds = Int((distanceMeters / sampleSpeedMetersPerSecond).rounded())
        }
        return build(state: state, distanceMeters: distanceMeters, elapsedSeconds: elapsedSeconds)
    }

    private static func buildMetricText(
        _ state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int
    ) -> String {
        let value = state.metric == AnnouncementStateData.metricSpeed
            ? formatSpeed(state, distanceMeters: distanceMeters, elapsedSeconds: elapsedSeconds)
            : formatPace(state, distanceMeters: distanceMeters, elapsedSeconds: elapsedSeconds)
        guard let value else {
            return state.metricLabel
        }
        let valueWithUnit = state.metricUnitTemplate.replacingOccurrences(
            of: placeholderValue,
            with: value
        )
        return "\(state.metricLabel) \(valueWithUnit)".trimmingCharacters(in: .whitespaces)
    }

    private static func formatPace(
        _ state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int
    ) -> String? {
        guard distanceMeters > 0 else {
            return nil
        }
        let unitMeters = state.useImperialUnits ? metersPerMile : metersPerKilometer
        let secondsPerUnit = Double(elapsedSeconds) / (distanceMeters / unitMeters)
        guard secondsPerUnit.isFinite, secondsPerUnit >= 0 else {
            return nil
        }
        return formatClock(Int(secondsPerUnit.rounded()))
    }

    private static func formatSpeed(
        _ state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int
    ) -> String? {
        guard distanceMeters >= 0, elapsedSeconds > 0 else {
            return nil
        }
        let unitMeters = state.useImperialUnits ? metersPerMile : metersPerKilometer
        let unitsPerHour = distanceMeters / unitMeters * 3600 / Double(elapsedSeconds)
        guard unitsPerHour.isFinite, unitsPerHour >= 0 else {
            return nil
        }
        return formatDecimal(unitsPerHour, languageTag: state.languageTag)
    }

    /// One decimal place, using `languageTag`'s decimal separator.
    private static func formatDecimal(_ value: Double, languageTag: String) -> String {
        let text = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), value)
        guard !languageTag.isEmpty,
              let separator = Locale(identifier: languageTag).decimalSeparator else {
            return text
        }
        return text.replacingOccurrences(of: ".", with: separator)
    }

    /// `H:MM:SS` once an hour has elapsed, otherwise `M:SS`.
    private static func formatClock(_ totalSeconds: Int) -> String {
        let safeSeconds = max(0, totalSeconds)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let seconds = safeSeconds % 60
        let posix = Locale(identifier: "en_US_POSIX")
        if hours > 0 {
            return String(format: "%d:%02d:%02d", locale: posix, hours, minutes, seconds)
        }
        return String(format: "%d:%02d", locale: posix, minutes, seconds)
    }
}
