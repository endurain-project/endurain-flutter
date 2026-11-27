import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// One local activity in the history list, with its upload status and the
/// retry and delete actions.
class ActivityRecordTile extends StatelessWidget {
  const ActivityRecordTile({
    super.key,
    required this.record,
    required this.isBusy,
    required this.onTap,
    required this.onRetry,
    required this.onDelete,
    this.selected = false,
  });

  final LocalActivityRecord record;
  final bool isBusy;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = context.statsFormatter;
    final title = l10n.activityHistoryEntryTitle(
      record.activityType.localizedLabel(l10n),
      formatLocalDateTime(context, record.endedAt),
    );
    final subtitle = [
      l10n.activityHistoryDuration(
        formatter.formatDuration(record.elapsedDurationSeconds),
      ),
      l10n.activityHistoryDistance(
        formatter.formatDistance(record.distanceMeters, locale: locale),
      ),
      l10n.activityHistoryUploadStatus(
        _uploadStatusLabel(l10n, record.uploadStatus),
      ),
    ].join('\n');

    return AdaptiveListTile(
      leading: _statusIcon(record.uploadStatus),
      title: title,
      subtitle: subtitle,
      trailing: _RecordActions(
        isBusy: isBusy,
        onRetry: onRetry,
        onDelete: onDelete,
      ),
      onTap: onTap,
      selected: selected,
    );
  }

  Widget _statusIcon(LocalActivityUploadStatus status) {
    return switch (status) {
      LocalActivityUploadStatus.uploaded => const AdaptiveIcon(
        materialIcon: Icons.cloud_done,
        cupertinoIcon: CupertinoIcons.cloud_upload_fill,
      ),
      LocalActivityUploadStatus.pending => const AdaptiveIcon(
        materialIcon: Icons.cloud_upload,
        cupertinoIcon: CupertinoIcons.cloud_upload,
      ),
      LocalActivityUploadStatus.failed => const AdaptiveIcon(
        materialIcon: Icons.error_outline,
        cupertinoIcon: CupertinoIcons.exclamationmark_triangle,
      ),
    };
  }
}

class _RecordActions extends StatelessWidget {
  const _RecordActions({
    required this.isBusy,
    required this.onRetry,
    required this.onDelete,
  });

  final bool isBusy;
  final VoidCallback? onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBusy)
          const SizedBox.square(
            dimension: 28,
            child: AdaptiveLoadingIndicator(),
          )
        else ...[
          if (onRetry != null)
            _IconActionButton(
              tooltip: l10n.activityRetryUpload,
              materialIcon: Icons.refresh,
              cupertinoIcon: CupertinoIcons.refresh,
              onPressed: onRetry,
            ),
          _IconActionButton(
            tooltip: l10n.activityDeleteLocal,
            materialIcon: Icons.delete_outline,
            cupertinoIcon: CupertinoIcons.delete,
            onPressed: onDelete,
            destructive: true,
          ),
        ],
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.tooltip,
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.onPressed,
    this.destructive = false,
  });

  final String tooltip;
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? PlatformUtils.isApplePlatform
              ? CupertinoColors.systemRed
              : Theme.of(context).colorScheme.error
        : null;

    if (PlatformUtils.isApplePlatform) {
      return Tooltip(
        message: tooltip,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(32),
          onPressed: onPressed,
          child: Icon(cupertinoIcon, color: color, size: 22),
        ),
      );
    }

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: color,
      icon: Icon(materialIcon),
    );
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
