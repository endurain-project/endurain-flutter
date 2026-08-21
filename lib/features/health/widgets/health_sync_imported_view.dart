import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/widgets/health_sync_inline_error.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

/// The "Imported" tab: previously imported workouts and their upload status.
class HealthSyncImportedView extends StatelessWidget {
  const HealthSyncImportedView({
    super.key,
    required this.controller,
    required this.state,
  });

  final HealthSyncController controller;
  final HealthSyncState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator.adaptive(
      onRefresh: controller.loadImported,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        children: [
          if (state.error != null) ...[
            HealthSyncInlineError(error: state.error!),
            Center(
              child: AdaptiveButton(
                label: l10n.activityHistoryRefresh,
                variant: AdaptiveButtonVariant.secondary,
                onPressed: state.isLoadingImported
                    ? null
                    : controller.loadImported,
              ),
            ),
            const SizedBox(height: UIConstants.paddingStandard),
          ],
          if (state.importedWorkouts.isEmpty && !state.isLoadingImported)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: UIConstants.paddingXLarge,
              ),
              child: Text(
                l10n.healthSyncImportedEmpty,
                textAlign: TextAlign.center,
              ),
            )
          else if (state.importedWorkouts.isNotEmpty)
            AdaptiveListSection(
              children: [
                for (final imported in state.importedWorkouts)
                  _ImportedWorkoutTile(
                    imported: imported,
                    onTap: imported.localActivity == null
                        ? null
                        : () => adaptivePush<void>(
                            context,
                            (_) => ActivityDetailsScreen(
                              recordId: imported.localActivityId,
                            ),
                          ),
                    onRestore: imported.localActivity == null
                        ? () => controller.restoreMissingImport(imported)
                        : null,
                  ),
              ],
            ),
          if (state.importedHasMore) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            Center(
              child: AdaptiveButton(
                label: l10n.activityHistoryLoadMore,
                variant: AdaptiveButtonVariant.secondary,
                onPressed: state.isLoadingImported
                    ? null
                    : () => controller.loadImported(reset: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportedWorkoutTile extends StatelessWidget {
  const _ImportedWorkoutTile({
    required this.imported,
    this.onTap,
    this.onRestore,
  });

  final HealthImportedWorkout imported;
  final VoidCallback? onTap;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activity = imported.localActivity;
    final title = activity == null
        ? l10n.activityHistoryGpxMissing
        : l10n.activityHistoryEntryTitle(
            activity.activityType.localizedLabel(l10n),
            DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
                .format(activity.endedAt.toLocal()),
          );
    final subtitle = [
      l10n.healthSyncImportedAt(
        formatLocalDateTime(context, imported.importedAt),
      ),
      if (activity != null)
        l10n.activityHistoryUploadStatus(
          _uploadStatusLabel(l10n, activity.uploadStatus),
        )
      else
        l10n.activityHistoryGpxMissing,
    ].join('\n');
    return AdaptiveListTile(
      title: title,
      subtitle: subtitle,
      leading: AdaptiveIcon(
        materialIcon: activity == null
            ? Icons.restore
            : _uploadStatusIcon(activity.uploadStatus),
        cupertinoIcon: activity == null
            ? CupertinoIcons.arrow_counterclockwise
            : _uploadStatusCupertinoIcon(activity.uploadStatus),
      ),
      trailing: onRestore == null
          ? null
          : AdaptiveButton(
              label: l10n.healthSyncRestore,
              variant: AdaptiveButtonVariant.secondary,
              onPressed: onRestore,
            ),
      onTap: onTap,
    );
  }

  IconData _uploadStatusIcon(LocalActivityUploadStatus status) {
    return switch (status) {
      LocalActivityUploadStatus.pending => Icons.cloud_upload_outlined,
      LocalActivityUploadStatus.uploaded => Icons.cloud_done,
      LocalActivityUploadStatus.failed => Icons.cloud_off,
    };
  }

  IconData _uploadStatusCupertinoIcon(LocalActivityUploadStatus status) {
    return switch (status) {
      LocalActivityUploadStatus.pending => CupertinoIcons.cloud_upload,
      LocalActivityUploadStatus.uploaded => CupertinoIcons.cloud_upload_fill,
      LocalActivityUploadStatus.failed =>
        CupertinoIcons.exclamationmark_triangle,
    };
  }
}

String _uploadStatusLabel(
  AppLocalizations l10n,
  LocalActivityUploadStatus status,
) {
  return switch (status) {
    LocalActivityUploadStatus.pending => l10n.activityUploadStatusPending,
    LocalActivityUploadStatus.uploaded => l10n.activityUploadStatusUploaded,
    LocalActivityUploadStatus.failed => l10n.activityUploadStatusFailed,
  };
}
