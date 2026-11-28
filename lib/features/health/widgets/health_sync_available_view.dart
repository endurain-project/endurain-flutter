import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/activity/widgets/lazy_list_section.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/widgets/health_sync_inline_error.dart';
import 'package:endurain/features/health/widgets/health_workout_row.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: paddedSlivers(readableContentPadding(context), [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      value: state.autoSync,
                      onChanged: state.isImporting || state.isUpdatingAutoSync
                          ? null
                          : controller.setAutoSync,
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
                if (state.olderWorkoutsUnavailable)
                  _buildHistoryAccessNotice(context, l10n),
                if (state.error != null)
                  HealthSyncInlineError(error: state.error!),
                _buildToolbar(context, l10n, state),
                if (state.importableWorkouts.isEmpty)
                  _buildEmptyList(l10n, state),
              ],
            ),
          ),
          if (state.importableWorkouts.isNotEmpty)
            _buildWorkoutList(context, l10n, state),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
          ),
        ]),
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
    final preset = await showAdaptiveChoicePicker<HealthImportRangePreset>(
      context: context,
      title: l10n.healthSyncDateRange,
      cancelLabel: l10n.cancel,
      selected: current.preset,
      choices: [
        for (final entry in labels.entries)
          AdaptiveChoice(value: entry.key, label: entry.value),
      ],
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

  /// Explains why paging stopped early: on Android, workouts older than the
  /// default window need Health Connect's history permission, which the user
  /// declined.
  Widget _buildHistoryAccessNotice(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingStandard,
        vertical: UIConstants.paddingSmall,
      ),
      child: Text(
        l10n.healthSyncHistoryAccessGuidance,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
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
    final workouts = state.importableWorkouts;
    return LazyListSection(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return HealthWorkoutRow(
          workout: workout,
          title: _formatTitle(context, l10n, workout),
          subtitle: _formatSubtitle(context, workout),
          isSelected: state.selectedSourceIds.contains(workout.sourceId),
          noRouteLabel: l10n.healthSyncNoRouteLabel,
          onChanged: workout.hasRoute && !state.isImporting
              ? (_) => controller.toggleSelection(workout.sourceId)
              : null,
        );
      },
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
    final formatter = context.statsFormatter;
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
            onPressed: canImport ? controller.importSelected : null,
            expand: true,
          ),
        ],
      ),
    );
  }
}
