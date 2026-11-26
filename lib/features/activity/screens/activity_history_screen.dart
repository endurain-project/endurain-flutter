import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({
    super.key,
    this.controller,
    this.createController,
    this.uploadQueue,
    this.mapSettingsRepository,
  }) : assert(
         controller != null || createController != null,
         'Pass a controller or a factory for one.',
       );

  /// Injected controller (tests); otherwise one is built with
  /// [createController] and owned by the screen.
  final LocalActivityHistoryController? controller;
  final LocalActivityHistoryController Function()? createController;

  /// Drained when the app resumes, so uploads that failed offline retry while
  /// the list is on screen. Null disables that.
  final ActivityUploadQueue? uploadQueue;

  /// Supplies each record's tile server for the route preview. Null hides the
  /// preview map.
  final MapSettingsRepository? mapSettingsRepository;

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with WidgetsBindingObserver, OwnedControllers {
  late final LocalActivityHistoryController _controller;
  ActivityUploadQueue? _uploadQueue;
  MapSettingsRepository? _mapSettings;

  /// The record shown beside the list when there is room for both. Null, or
  /// a record no longer listed, shows the first one.
  String? _selectedRecordId;

  /// Keeps the list (and its scroll position) when the window changes between
  /// one pane and two, e.g. when an iPhone Duo is unfolded or rotated.
  final GlobalKey _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = registerController(
      widget.controller,
      () => widget.createController!(),
    );
    _uploadQueue = widget.uploadQueue;
    _mapSettings = widget.mapSettingsRepository;
    unawaited(_controller.load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_drainQueueAndRefresh());
    }
  }

  Future<void> _drainQueueAndRefresh() async {
    final queue = _uploadQueue;
    if (queue != null) {
      await queue.drain();
    }
    if (!mounted) {
      return;
    }
    await _controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _openDetails(LocalActivityRecord record) async {
    await adaptivePush<void>(
      context,
      (context) => ActivityDetailsScreen(
        recordId: record.id,
        controller: _controller,
        tileServerUrlProvider: _tileServerUrlProvider(record),
      ),
    );
  }

  Future<String> Function()? _tileServerUrlProvider(
    LocalActivityRecord record,
  ) {
    final mapSettings = _mapSettings;
    if (mapSettings == null) {
      return null;
    }
    return () => mapSettings.getTileServerUrl(origin: record.connectionOrigin);
  }

  /// The record for the details pane, or null when there are none.
  LocalActivityRecord? _paneRecord() {
    final records = _controller.records;
    if (records.isEmpty) {
      return null;
    }
    return records.where((r) => r.id == _selectedRecordId).firstOrNull ??
        records.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.activityHistoryTitle,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final paneRecord =
                constraints.maxWidth >= UIConstants.twoPaneMinWidth
                ? _paneRecord()
                : null;
            final list = KeyedSubtree(
              key: _listKey,
              child: Builder(
                builder: (context) =>
                    _buildList(context, l10n, selectedId: paneRecord?.id),
              ),
            );
            if (paneRecord == null) {
              return list;
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: UIConstants.listPaneWidth,
                  child: ReadableWidthScope(child: list),
                ),
                const _PaneDivider(),
                Expanded(
                  child: ReadableWidthScope(
                    child: ActivityDetailsScreen(
                      key: ValueKey(paneRecord.id),
                      recordId: paneRecord.id,
                      controller: _controller,
                      tileServerUrlProvider: _tileServerUrlProvider(paneRecord),
                      embedded: true,
                      onDeleted: () => setState(() => _selectedRecordId = null),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The history list. [selectedId] is the record shown beside it, or null
  /// when the list is on its own and tapping a record opens its page.
  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n, {
    required String? selectedId,
  }) {
    // The retention switch stays reachable whatever state the list is
    // in, so it sits above the records rather than inside them.
    return RefreshIndicator.adaptive(
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: readableContentPadding(context),
        children: [
          if (_controller.canConfigureGpxRetention) ...[
            AdaptiveListSection(
              children: [
                AdaptiveSwitchListTile(
                  title: l10n.activityRetainUploadedGpx,
                  subtitle: l10n.activityRetainUploadedGpxSubtitle,
                  value: _controller.retainUploadedGpx,
                  onChanged: _controller.setRetainUploadedGpx,
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingStandard),
          ],
          ..._buildRecords(l10n, selectedId: selectedId),
        ],
      ),
    );
  }

  List<Widget> _buildRecords(
    AppLocalizations l10n, {
    required String? selectedId,
  }) {
    if (_controller.isLoading && _controller.records.isEmpty) {
      return const [Center(child: AdaptiveLoadingIndicator())];
    }

    if (_controller.error != null && _controller.records.isEmpty) {
      return [
        _HistoryMessage(
          message: l10n.activityHistoryLoadFailed,
          actionLabel: l10n.activityHistoryRefresh,
          onAction: _controller.refresh,
        ),
      ];
    }

    if (_controller.records.isEmpty) {
      return [_HistoryMessage(message: l10n.activityHistoryEmpty)];
    }

    return [
      AdaptiveListSection(
        header: l10n.activityHistoryLocalActivities,
        children: [
          for (final record in _controller.records)
            _ActivityRecordTile(
              record: record,
              isBusy: _controller.isBusy(record.id),
              selected: record.id == selectedId,
              onTap: selectedId == null
                  ? () => _openDetails(record)
                  : () => setState(() => _selectedRecordId = record.id),
              onRetry: record.uploadStatus == LocalActivityUploadStatus.uploaded
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
            onPressed: _controller.isLoading ? null : _controller.loadMore,
          ),
        ),
        const SizedBox(height: UIConstants.paddingStandard),
      ],
    ];
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

/// The line between the list and details panes.
class _PaneDivider extends StatelessWidget {
  const _PaneDivider();

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return SizedBox(
        width: 0.5,
        child: ColoredBox(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.separator,
            context,
          ),
        ),
      );
    }
    return const VerticalDivider(width: 1);
  }
}

class _ActivityRecordTile extends StatelessWidget {
  const _ActivityRecordTile({
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
