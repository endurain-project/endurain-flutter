import Foundation

/// Builds the spoken sentence for one announcement from an
/// `AnnouncementStateData`'s localized templates and the concrete values at
/// the threshold instant.
///
/// Mirrors the Android `AnnouncementSpeechBuilder` object exactly — see its
/// doc comment for why a literal substring replace on Dart-rendered templates
/// is correct for every locale, and why numbers are formatted with a fixed
/// `en_US_POSIX` decimal point.
enum AnnouncementSpeechBuilder {
    private static let metersPerKilometer = 1000.0
    private static let metersPerMile = 1609.344

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
            with: formatDecimal(displayDistance)
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
        return formatDecimal(unitsPerHour)
    }

    /// One decimal place, fixed POSIX locale (always a `.` separator).
    private static func formatDecimal(_ value: Double) -> String {
        return String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), value)
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
