import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/features/activity/models/activity_upload_state.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class ActivityUploadStatusPanel extends StatelessWidget {
  const ActivityUploadStatusPanel({
    super.key,
    required this.status,
    required this.error,
    required this.onRetry,
    required this.onDone,
    required this.onDelete,
    this.onViewHistory,
  });

  final ActivityUploadStatus status;
  final AppException? error;
  final VoidCallback? onRetry;
  final VoidCallback? onDone;
  final VoidCallback? onDelete;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _statusText(l10n),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if ((status == ActivityUploadStatus.failed ||
                status == ActivityUploadStatus.cleanupFailed) &&
            error != null) ...[
          const SizedBox(height: 4),
          Text(
            localizedErrorMessage(error!, l10n),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        if (status == ActivityUploadStatus.failed ||
            status == ActivityUploadStatus.uploaded ||
            status == ActivityUploadStatus.cleanupFailed) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == ActivityUploadStatus.uploaded)
                AdaptiveButton(
                  label: l10n.activityDone,
                  onPressed: onDone,
                  icon: const AdaptiveIcon(
                    materialIcon: Icons.check,
                    cupertinoIcon: CupertinoIcons.check_mark,
                    size: 20,
                  ),
                ),
              if (status == ActivityUploadStatus.failed)
                AdaptiveButton(
                  label: l10n.activityRetryUpload,
                  onPressed: onRetry,
                  icon: const AdaptiveIcon(
                    materialIcon: Icons.refresh,
                    cupertinoIcon: CupertinoIcons.refresh,
                    size: 20,
                  ),
                ),
              if (onViewHistory != null)
                AdaptiveButton(
                  label: l10n.activityViewHistory,
                  onPressed: onViewHistory,
                  variant: AdaptiveButtonVariant.secondary,
                  icon: const AdaptiveIcon(
                    materialIcon: Icons.history,
                    cupertinoIcon: CupertinoIcons.time,
                    size: 20,
                  ),
                ),
              AdaptiveButton(
                label: l10n.activityDeleteLocal,
                onPressed: onDelete,
                destructive: true,
                variant: AdaptiveButtonVariant.secondary,
                icon: const AdaptiveIcon(
                  materialIcon: Icons.delete_outline,
                  cupertinoIcon: CupertinoIcons.delete,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _statusText(AppLocalizations l10n) {
    return switch (status) {
      ActivityUploadStatus.idle => l10n.activityUploadReady,
      ActivityUploadStatus.uploading => l10n.activityUploading,
      ActivityUploadStatus.uploaded => l10n.activityUploaded,
      ActivityUploadStatus.failed => l10n.activityUploadFailed,
      ActivityUploadStatus.cleanupFailed => l10n.activityUploadCleanupFailed,
    };
  }
}
