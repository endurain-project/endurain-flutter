import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_stats_calculator.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Richer post-recording summary shown once a recording completes, before or
/// after the activity is uploaded. It derives its figures from the completed
/// [ActivityRecordingState] track so it works even when the persisted record
/// has not been reloaded yet.
class ActivityCompletionSummary extends StatelessWidget {
  ActivityCompletionSummary({
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = this.formatter ?? context.statsFormatter;
    final theme = Theme.of(context);
    final stats = calculator.calculate(state.segments);
    final activityType = state.activityType ?? ActivityType.other;
    final durationSeconds = stats.durationSeconds > state.elapsedDurationSeconds
        ? stats.durationSeconds
        : state.elapsedDurationSeconds;
    final isRun = activityType == ActivityType.run;

    final tiles = <Widget>[
      _SummaryMetricTile(
        label: l10n.activityStatDuration,
        value: formatter.formatDuration(durationSeconds),
      ),
      _SummaryMetricTile(
        label: l10n.activityStatDistance,
        value: formatter.formatDistance(stats.distanceMeters, locale: locale),
      ),
      if (isRun)
        _SummaryMetricTile(
          label: l10n.activityStatPace,
          value: formatter.formatPace(stats.averageSpeedMetersPerSecond),
        )
      else
        _SummaryMetricTile(
          label: l10n.activityHistoryAverageSpeed,
          value: formatter.formatSpeed(
            stats.averageSpeedMetersPerSecond,
            locale: locale,
          ),
        ),
      _SummaryMetricTile(
        label: l10n.activityStatMaxSpeed,
        value: formatter.formatSpeed(
          stats.maxSpeedMetersPerSecond,
          locale: locale,
        ),
      ),
      if (stats.elevationGainMeters != null)
        _SummaryMetricTile(
          label: l10n.activityStatElevationGain,
          value: formatter.formatElevation(
            stats.elevationGainMeters,
            locale: locale,
          ),
        ),
      if (stats.averageHeartRateBpm != null)
        _SummaryMetricTile(
          label: l10n.activityStatAvgHeartRate,
          value: formatter.formatHeartRate(stats.averageHeartRateBpm),
        ),
      if (stats.averagePowerWatts != null)
        _SummaryMetricTile(
          label: l10n.activityStatAvgPower,
          value: formatter.formatPower(stats.averagePowerWatts),
        ),
      if (stats.averageCadenceRpm != null)
        _SummaryMetricTile(
          label: l10n.activityStatAvgCadence,
          value: formatter.formatCadence(stats.averageCadenceRpm),
        ),
      _SummaryMetricTile(
        label: l10n.activityHistoryPointCount,
        value: state.points.length.toString(),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.activityHistorySummary,
          style: theme.textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          activityType.localizedLabel(l10n),
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        if (state.startedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            formatLocalDateTime(context, state.startedAt!),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: tiles,
        ),
      ],
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({required this.label, required this.value});

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
