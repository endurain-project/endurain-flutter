import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({
    super.key,
    this.controller,
    this.repository,
    this.uploadService,
    this.retentionSettingsRepository,
  });

  final LocalActivityHistoryController? controller;
  final LocalActivityRepository? repository;
  final ActivityUploadService? uploadService;
  final ActivityRetentionSettingsRepository? retentionSettingsRepository;

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  late final LocalActivityHistoryController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? _createController();
    _controller.load();
  }

  LocalActivityHistoryController _createController() {
    final services = AppScope.servicesOf(context, listen: false);
    return LocalActivityHistoryController(
      repository: widget.repository ?? services.localActivities,
      uploadService: widget.uploadService ?? services.activityUpload,
      retentionSettingsRepository:
          widget.retentionSettingsRepository ??
          services.activityRetentionSettings,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _retry(LocalActivityRecord record) async {
    try {
      await _controller.retryUpload(record.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await DialogUtils.showErrorDialog(context, error);
    }
  }

  Future<void> _delete(LocalActivityRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: l10n.activityDeleteLocalConfirmTitle,
      message: l10n.activityDeleteLocalConfirmMessage,
      confirmText: l10n.activityDeleteLocal,
      isDestructive: true,
    );
    if (!mounted || !confirmed) {
      return;
    }
    try {
      await _controller.delete(record.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await DialogUtils.showErrorDialog(context, error);
    }
  }

  void _openDetails(LocalActivityRecord record) {
    adaptivePush<void>(
      context,
      (context) =>
          ActivityDetailsScreen(recordId: record.id, controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.activityHistoryTitle,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.records.isEmpty) {
            return const Center(child: AdaptiveLoadingIndicator());
          }

          if (_controller.error != null && _controller.records.isEmpty) {
            return _HistoryMessage(
              message: l10n.activityHistoryLoadFailed,
              actionLabel: l10n.activityHistoryRefresh,
              onAction: _controller.refresh,
            );
          }

          if (_controller.records.isEmpty) {
            return _HistoryMessage(message: l10n.activityHistoryEmpty);
          }

          return RefreshIndicator.adaptive(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.all(UIConstants.paddingStandard),
              children: [
                AdaptiveListSection(
                  header: l10n.activityHistoryLocalActivities,
                  children: [
                    for (final record in _controller.records)
                      _ActivityRecordTile(
                        record: record,
                        isBusy: _controller.isBusy(record.id),
                        onTap: () => _openDetails(record),
                        onRetry:
                            record.uploadStatus ==
                                LocalActivityUploadStatus.uploaded
                            ? null
                            : () => _retry(record),
                        onDelete: () => _delete(record),
                      ),
                  ],
                ),
                if (_controller.hasMore) ...[
                  const SizedBox(height: UIConstants.paddingStandard),
                  Center(
                    child: AdaptiveButton(
                      label: l10n.activityHistoryLoadMore,
                      onPressed:
                          _controller.isLoading ? null : _controller.loadMore,
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingStandard),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveEmptyStateText(message: message),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: UIConstants.paddingStandard),
              AdaptiveButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: const AdaptiveIcon(
                  materialIcon: Icons.refresh,
                  cupertinoIcon: CupertinoIcons.refresh,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRecordTile extends StatelessWidget {
  const _ActivityRecordTile({
    required this.record,
    required this.isBusy,
    required this.onTap,
    required this.onRetry,
    required this.onDelete,
  });

  final LocalActivityRecord record;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const formatter = ActivityStatsFormatter();
    final title = l10n.activityHistoryEntryTitle(
      record.activityType.localizedLabel(l10n),
      _formatDateTime(record.endedAt),
    );
    final subtitle = [
      l10n.activityHistoryDuration(
        formatter.formatDuration(record.elapsedDurationSeconds),
      ),
      l10n.activityHistoryDistance(
        formatter.formatDistance(record.distanceMeters),
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date = [
    local.year.toString().padLeft(4, '0'),
    local.month.toString().padLeft(2, '0'),
    local.day.toString().padLeft(2, '0'),
  ].join('-');
  final time = [
    local.hour.toString().padLeft(2, '0'),
    local.minute.toString().padLeft(2, '0'),
  ].join(':');
  return '$date $time';
}
