import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/settings/controllers/audio_announcement_settings_controller.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user turn spoken progress announcements on/off, choose whether
/// other audio should duck while an announcement plays, and configure how
/// often a recording announces distance/time/pace for each activity type.
///
/// Mirrors `UnitsSettingsScreen`: the app-lifetime
/// [AudioAnnouncementSettingsController] is written to immediately (so a
/// change is reflected the next time a recording starts, even without
/// reopening this screen), and the controller drives the whole subtree via
/// [ListenableBuilder].
class AudioAnnouncementSettingsScreen extends StatelessWidget {
  const AudioAnnouncementSettingsScreen({
    super.key,
    this.controller,
    this.measurementSystemController,
  });

  /// Optional override for tests; otherwise resolved from [AppScope].
  final AudioAnnouncementSettingsController? controller;

  /// Optional override for tests; otherwise resolved from [AppScope].
  final MeasurementSystemController? measurementSystemController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsController =
        controller ??
        AppScope.servicesOf(
          context,
          listen: false,
        ).audioAnnouncementSettingsController;
    final measurement =
        measurementSystemController ??
        AppScope.servicesOf(context, listen: false).measurementSystemController;
    final measurementSystem = measurement.resolve(context.deviceLocale);

    return AdaptiveScaffold(
      title: l10n.audioAnnouncementsTitle,
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) {
          final settings = settingsController.settings;
          return ListView(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            children: [
              AdaptiveListSection(
                children: [
                  AdaptiveSwitchListTile(
                    title: l10n.audioAnnouncementsMasterSwitch,
                    subtitle: l10n.audioAnnouncementsMasterSwitchSubtitle,
                    value: settings.masterEnabled,
                    onChanged: settingsController.setMasterEnabled,
                  ),
                  AdaptiveSwitchListTile(
                    title: l10n.audioAnnouncementsDuckSwitch,
                    subtitle: l10n.audioAnnouncementsDuckSwitchSubtitle,
                    value: settings.duckOtherAudio,
                    onChanged: settingsController.setDuckOtherAudio,
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.paddingLarge),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: UIConstants.paddingCompact,
                ),
                child: Text(
                  l10n.audioAnnouncementsIntervalsHeader,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              for (final type in ActivityType.values) ...[
                _IntervalCard(
                  activityType: type,
                  interval: settings.intervalFor(type),
                  measurementSystem: measurementSystem,
                  enabled: settings.masterEnabled,
                  onChanged: (interval) =>
                      settingsController.setInterval(type, interval),
                ),
                const SizedBox(height: UIConstants.paddingMedium),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _IntervalCard extends StatelessWidget {
  const _IntervalCard({
    required this.activityType,
    required this.interval,
    required this.measurementSystem,
    required this.enabled,
    required this.onChanged,
  });

  final ActivityType activityType;
  final AudioAnnouncementInterval interval;
  final MeasurementSystem measurementSystem;
  final bool enabled;
  final ValueChanged<AudioAnnouncementInterval> onChanged;

  /// Distance step: 0.5 km, or 0.5 mi when imperial (converted to metres).
  double get _distanceStepMeters =>
      measurementSystem == MeasurementSystem.imperial
      ? 0.5 * UnitConversions.metersPerMile
      : 500;

  static const int _timeStepSeconds = 60;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: AdaptiveListSection(
          header: activityType.localizedLabel(l10n),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.paddingStandard,
                vertical: UIConstants.paddingCompact,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdaptiveSegmentedControl<AudioAnnouncementIntervalUnit>(
                    labels: {
                      AudioAnnouncementIntervalUnit.distance:
                          l10n.audioAnnouncementsByDistance,
                      AudioAnnouncementIntervalUnit.time:
                          l10n.audioAnnouncementsByTime,
                    },
                    selected: interval.unit,
                    onChanged: (unit) =>
                        onChanged(interval.copyWith(unit: unit)),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l10n.audioAnnouncementsDecreaseInterval,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _step(context, -1),
                      ),
                      Expanded(
                        child: Text(
                          _describe(context, l10n),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.audioAnnouncementsIncreaseInterval,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _step(context, 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _step(BuildContext context, int direction) {
    if (interval.unit == AudioAnnouncementIntervalUnit.distance) {
      onChanged(
        interval.copyWith(
          distanceMeters:
              interval.distanceMeters + direction * _distanceStepMeters,
        ),
      );
    } else {
      onChanged(
        interval.copyWith(
          timeSeconds: interval.timeSeconds + direction * _timeStepSeconds,
        ),
      );
    }
  }

  String _describe(BuildContext context, AppLocalizations l10n) {
    if (interval.unit == AudioAnnouncementIntervalUnit.time) {
      final minutes = (interval.timeSeconds / 60).round();
      return l10n.audioAnnouncementsIntervalTime('$minutes');
    }
    final isImperial = measurementSystem == MeasurementSystem.imperial;
    final displayValue = isImperial
        ? UnitConversions.metersToMiles(interval.distanceMeters)
        : UnitConversions.metersToKilometers(interval.distanceMeters);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatted = NumberFormat('0.0', locale).format(displayValue);
    final unit = isImperial ? l10n.unitMile('') : l10n.unitKilometer('');
    return l10n.audioAnnouncementsIntervalDistance(formatted, unit.trim());
  }
}
