import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/widgets/health_sync_inline_error.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The "Available" tab: import range, auto-sync toggle, notices, and the list
/// of health-platform workouts eligible for import.
class HealthSyncAvailableView extends StatelessWidget {
  const HealthSyncAvailableView({
    super.key,
    required this.controller,
    required this.state,
  });

  final HealthSyncController controller;
  final HealthSyncState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final automationSubtitle = [
      l10n.healthSyncAutoSyncSubtitle,
      if (state.lastSyncAt != null)
        l10n.healthSyncImportedAt(
          formatLocalDateTime(context, state.lastSyncAt!),
        ),
    ].join('\n');
    return RefreshIndicator.adaptive(
      onRefresh: controller.loadImportableWorkouts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        children: [
          AdaptiveListSection(
            children: [_buildRangeSelector(context, l10n, state)],
          ),
          const SizedBox(height: UIConstants.paddingStandard),
          AdaptiveListSection(
            children: [
              AdaptiveSwitchListTile(
                title: l10n.healthSyncAutoSyncTitle,
                subtitle: automationSubtitle,
                value: state.autoSyncOnResume,
                onChanged: state.isImporting || state.isUpdatingAutoSync
                    ? null
                    : controller.setAutoSyncOnResume,
              ),
            ],
          ),
          if (state.importedCount > 0) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            Text(
              l10n.healthSyncImportedCount(state.importedCount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (state.routeConsentDeniedCount > 0)
            _buildRouteConsentNotice(context, l10n),
          if (_showNoRoutesExplanation(state))
            _buildNoRoutesNotice(context, l10n),
          if (state.error != null) HealthSyncInlineError(error: state.error!),
          _buildToolbar(context, l10n, state),
          _buildWorkoutList(context, l10n, state),
          if (state.availableHasMore) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            Center(
              child: AdaptiveButton(
                label: l10n.activityHistoryLoadMore,
                variant: AdaptiveButtonVariant.secondary,
                onPressed: state.isLoadingMoreAvailable
                    ? null
                    : controller.loadMoreAvailable,
              ),
            ),
          ],
          _buildImportActions(context, l10n, state),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    return AdaptiveListTile(
      title: l10n.healthSyncDateRange,
      subtitle: _rangeLabel(context, l10n, state.selectedRange),
      leading: const AdaptiveIcon(
        materialIcon: Icons.date_range,
        cupertinoIcon: CupertinoIcons.calendar,
      ),
      onTap: () => _selectRange(context, l10n, state.selectedRange),
    );
  }

  Future<void> _selectRange(
    BuildContext context,
    AppLocalizations l10n,
    HealthImportRange current,
  ) async {
    final labels = <HealthImportRangePreset, String>{
      HealthImportRangePreset.last30Days: l10n.healthSyncRange30Days,
      HealthImportRangePreset.last3Months: l10n.healthSyncRange3Months,
      HealthImportRangePreset.last6Months: l10n.healthSyncRange6Months,
      HealthImportRangePreset.lastYear: l10n.healthSyncRangeYear,
      HealthImportRangePreset.allHistory: l10n.healthSyncRangeAll,
      HealthImportRangePreset.custom: l10n.healthSyncRangeCustom,
    };
    final preset = PlatformUtils.isApplePlatform
        ? await showCupertinoModalPopup<HealthImportRangePreset>(
            context: context,
            builder: (context) => CupertinoActionSheet(
              title: Text(l10n.healthSyncDateRange),
              actions: [
                for (final entry in labels.entries)
                  CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context, entry.key),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (entry.key == current.preset) ...[
                          const Icon(CupertinoIcons.check_mark, size: 18),
                          const SizedBox(width: UIConstants.paddingCompact),
                        ],
                        Text(entry.value),
                      ],
                    ),
                  ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ),
          )
        : await showDialog<HealthImportRangePreset>(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(l10n.healthSyncDateRange),
              children: [
                for (final entry in labels.entries)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, entry.key),
                    child: Text(entry.value),
                  ),
              ],
            ),
          );
    if (!context.mounted || preset == null) return;
    if (preset != HealthImportRangePreset.custom) {
      await controller.setRange(_rangeForPreset(preset));
      return;
    }

    final now = DateTime.now();
    final custom = current.preset == HealthImportRangePreset.custom;
    final selected = await showAdaptiveDateRangePicker(
      context: context,
      initialStart: custom
          ? current.customStartDate!
          : now.subtract(const Duration(days: 30)),
      initialEnd: custom ? current.customEndDate! : now,
      firstDate: DateTime(1970),
      lastDate: now,
      startLabel: l10n.activityHistoryStartedAt,
      endLabel: l10n.activityHistoryEndedAt,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.ok,
    );
    if (selected == null) return;
    await controller.setRange(
      HealthImportRange.custom(
        startDate: selected.start,
        endDate: selected.end,
      ),
    );
  }

  HealthImportRange _rangeForPreset(HealthImportRangePreset preset) {
    return switch (preset) {
      HealthImportRangePreset.last30Days =>
        const HealthImportRange.last30Days(),
      HealthImportRangePreset.last3Months =>
        const HealthImportRange.last3Months(),
      HealthImportRangePreset.last6Months =>
        const HealthImportRange.last6Months(),
      HealthImportRangePreset.lastYear => const HealthImportRange.lastYear(),
      HealthImportRangePreset.allHistory =>
        const HealthImportRange.allHistory(),
      HealthImportRangePreset.custom => throw StateError('Custom needs dates.'),
    };
  }

  String _rangeLabel(
    BuildContext context,
    AppLocalizations l10n,
    HealthImportRange range,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return switch (range.preset) {
      HealthImportRangePreset.last30Days => l10n.healthSyncRange30Days,
      HealthImportRangePreset.last3Months => l10n.healthSyncRange3Months,
      HealthImportRangePreset.last6Months => l10n.healthSyncRange6Months,
      HealthImportRangePreset.lastYear => l10n.healthSyncRangeYear,
      HealthImportRangePreset.allHistory => l10n.healthSyncRangeAll,
      HealthImportRangePreset.custom =>
        '${DateFormat.yMd(locale).format(range.customStartDate!)} - '
            '${DateFormat.yMd(locale).format(range.customEndDate!)}',
    };
  }

  Widget _buildRouteConsentNotice(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingStandard,
        vertical: UIConstants.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _routeConsentGuidance(l10n),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            AdaptiveButton(
              label: l10n.healthSyncReviewAccess,
              variant: AdaptiveButtonVariant.secondary,
              onPressed: () => DialogUtils.showMessage(
                context,
                l10n.healthAccessReviewIosInstructions,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoRoutesNotice(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingStandard,
        vertical: UIConstants.paddingSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdaptiveIcon(
            materialIcon: Icons.info_outline,
            cupertinoIcon: CupertinoIcons.info_circle,
            size: 18,
          ),
          const SizedBox(width: UIConstants.paddingSmall),
          Expanded(
            child: Text(
              l10n.healthSyncNoRoutesExplanation,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows guidance when workouts were found but none carry a GPS route (e.g.
  /// activities written to the health platform by apps like Garmin Connect
  /// that don't share routes). Suppressed while loading and when the absence is
  /// already explained by the route-consent guidance.
  bool _showNoRoutesExplanation(HealthSyncState state) {
    return !state.isLoadingWorkouts &&
        state.routeConsentDeniedCount == 0 &&
        state.importableWorkouts.isNotEmpty &&
        !state.importableWorkouts.any((w) => w.hasRoute);
  }

  String _routeConsentGuidance(AppLocalizations l10n) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => l10n.healthSyncRouteConsentGuidanceIos,
      _ => l10n.healthSyncRouteConsentGuidance,
    };
  }

  Widget _buildToolbar(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    final hasImportable = state.importableWorkouts.any((w) => w.hasRoute);
    if (!hasImportable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.paddingStandard,
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: UIConstants.paddingCompact,
        runSpacing: UIConstants.paddingSmall,
        children: [
          AdaptiveButton(
            label: l10n.healthSyncSelectAll,
            variant: AdaptiveButtonVariant.secondary,
            onPressed: state.isImporting ? null : controller.selectAll,
          ),
          AdaptiveButton(
            label: l10n.healthSyncClearSelection,
            variant: AdaptiveButtonVariant.secondary,
            onPressed: state.selectedSourceIds.isEmpty || state.isImporting
                ? null
                : controller.clearSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    if (state.importableWorkouts.isEmpty) {
      return _buildEmptyList(l10n, state);
    }
    return AdaptiveListSection(
      children: [
        for (final workout in state.importableWorkouts)
          _WorkoutRow(
            workout: workout,
            title: _formatTitle(context, l10n, workout),
            subtitle: _formatSubtitle(context, workout),
            isSelected: state.selectedSourceIds.contains(workout.sourceId),
            noRouteLabel: l10n.healthSyncNoRouteLabel,
            onChanged: workout.hasRoute && !state.isImporting
                ? (_) => controller.toggleSelection(workout.sourceId)
                : null,
          ),
      ],
    );
  }

  /// Empty message within the parent scrollable refresh surface.
  Widget _buildEmptyList(AppLocalizations l10n, HealthSyncState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingXLarge),
      child: Text(
        state.isLoadingWorkouts ? '' : l10n.healthSyncEmptyState,
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTitle(
    BuildContext context,
    AppLocalizations l10n,
    HealthWorkout workout,
  ) {
    final typeLabel = workout.type.toActivityType().localizedLabel(l10n);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateStr = DateFormat.yMd(locale).format(workout.startedAt.toLocal());
    return '$typeLabel · $dateStr';
  }

  String? _formatSubtitle(BuildContext context, HealthWorkout workout) {
    const formatter = ActivityStatsFormatter();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parts = <String>[
      formatter.formatDuration(
        workout.endedAt.difference(workout.startedAt).inSeconds,
      ),
    ];
    if (workout.distanceMeters != null) {
      parts.add(
        formatter.formatDistance(workout.distanceMeters!, locale: locale),
      );
    }
    return parts.join(' · ');
  }

  Widget _buildImportActions(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    final selectedCount = state.selectedSourceIds.length;
    final canImport = selectedCount > 0 && !state.isImporting;
    return Padding(
      padding: const EdgeInsets.only(top: UIConstants.paddingStandard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveButton(
            label: l10n.healthSyncImportSelected(selectedCount),
            onPressed: canImport ? () => controller.importSelected() : null,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({
    required this.workout,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.noRouteLabel,
    this.onChanged,
  });

  final HealthWorkout workout;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final String noRouteLabel;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveCheckboxListTile(
      value: workout.hasRoute ? isSelected : false,
      onChanged: onChanged,
      showControl: workout.hasRoute,
      secondary: _workoutIcon(workout.type),
      title: workout.hasRoute
          ? Text(title)
          : Wrap(
              spacing: UIConstants.paddingCompact,
              runSpacing: UIConstants.paddingSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title),
                _NonImportableBadge(
                  label: AppLocalizations.of(
                    context,
                  )!.healthSyncBadgeNonImportable,
                ),
              ],
            ),
      subtitle: workout.hasRoute
          ? (subtitle == null ? null : Text(subtitle!))
          : Text(
              noRouteLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  Widget _workoutIcon(HealthWorkoutType type) {
    final icon = switch (type) {
      HealthWorkoutType.run => Icons.directions_run,
      HealthWorkoutType.ride => Icons.directions_bike,
      HealthWorkoutType.walk => Icons.directions_walk,
      HealthWorkoutType.hike => Icons.hiking,
      HealthWorkoutType.other => Icons.fitness_center,
    };
    return Icon(icon);
  }
}

class _NonImportableBadge extends StatelessWidget {
  const _NonImportableBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foreground, letterSpacing: 0),
      ),
    );
  }
}
