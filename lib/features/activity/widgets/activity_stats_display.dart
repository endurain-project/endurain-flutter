import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_stats_calculator.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class ActivityStatsDisplay extends StatelessWidget {
  ActivityStatsDisplay({
    super.key,
    required this.state,
    ActivityStatsCalculator? calculator,
    this.formatter,
  }) : calculator = calculator ?? ActivityStatsCalculator();

  final ActivityRecordingState state;
  final ActivityStatsCalculator calculator;

  /// Optional override (tests). When null the formatter is resolved from the
  /// active locale and unit preference.
  final ActivityStatsFormatter? formatter;

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowStats) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = this.formatter ?? context.statsFormatter;
    final stats = calculator.calculate(state.segments);
    final durationSeconds = stats.durationSeconds > state.elapsedDurationSeconds
        ? stats.durationSeconds
        : state.elapsedDurationSeconds;
    // Prefer the live sensor reading so a current bpm shows immediately, even
    // before the next distance-filtered GPS point lands. Fall back to the
    // per-point value (e.g. Android, where the native recorder stamps points).
    final heartRateBpm = state.currentHeartRateBpm ?? stats.currentHeartRateBpm;
    final powerWatts = state.currentPowerWatts ?? stats.currentPowerWatts;
    final cadenceRpm = state.currentCadenceRpm ?? stats.currentCadenceRpm;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _StatItem(
          label: l10n.activityStatDuration,
          value: formatter.formatDuration(durationSeconds),
        ),
        _StatItem(
          label: l10n.activityStatDistance,
          value: formatter.formatDistance(stats.distanceMeters, locale: locale),
        ),
        _StatItem(
          label: state.activityType == ActivityType.run
              ? l10n.activityStatPace
              : l10n.activityStatSpeed,
          value: state.activityType == ActivityType.run
              ? formatter.formatPace(
                  stats.currentSpeedMetersPerSecond ??
                      stats.averageSpeedMetersPerSecond,
                )
              : formatter.formatSpeed(
                  stats.currentSpeedMetersPerSecond ??
                      stats.averageSpeedMetersPerSecond,
                  locale: locale,
                ),
        ),
        // Always shown (like pace/speed): displays "-" until a reading arrives.
        _StatItem(
          label: l10n.activityStatHeartRate,
          value: formatter.formatHeartRate(heartRateBpm),
        ),
        // Power and cadence are shown only once a reading arrives, so users
        // without those sensors are not shown perpetually empty tiles.
        if (powerWatts != null)
          _StatItem(
            label: l10n.activityStatPower,
            value: formatter.formatPower(powerWatts),
          ),
        if (cadenceRpm != null)
          _StatItem(
            label: l10n.activityStatCadence,
            value: formatter.formatCadence(cadenceRpm),
          ),
      ],
    );
  }

  bool get _shouldShowStats {
    return state.status == ActivityRecordingStatus.recording ||
        state.status == ActivityRecordingStatus.paused ||
        state.status == ActivityRecordingStatus.stopping ||
        state.status == ActivityRecordingStatus.completed;
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
