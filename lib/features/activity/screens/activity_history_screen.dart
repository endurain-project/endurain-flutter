import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/widgets/activity_record_tile.dart';
import 'package:endurain/features/activity/widgets/lazy_list_section.dart';
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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: paddedSlivers(readableContentPadding(context), [
          if (_controller.canConfigureGpxRetention)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: UIConstants.paddingStandard,
                ),
                child: AdaptiveListSection(
                  children: [
                    AdaptiveSwitchListTile(
                      title: l10n.activityRetainUploadedGpx,
                      subtitle: l10n.activityRetainUploadedGpxSubtitle,
                      value: _controller.retainUploadedGpx,
                      onChanged: _controller.setRetainUploadedGpx,
                    ),
                  ],
                ),
              ),
            ),
          ..._buildRecords(l10n, selectedId: selectedId),
        ]),
      ),
    );
  }

  List<Widget> _buildRecords(
    AppLocalizations l10n, {
    required String? selectedId,
  }) {
    if (_controller.isLoading && _controller.records.isEmpty) {
      return const [
        SliverToBoxAdapter(child: Center(child: AdaptiveLoadingIndicator())),
      ];
    }

    if (_controller.error != null && _controller.records.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _HistoryMessage(
            message: l10n.activityHistoryLoadFailed,
            actionLabel: l10n.activityHistoryRefresh,
            onAction: _controller.refresh,
          ),
        ),
      ];
    }

    if (_controller.records.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _HistoryMessage(message: l10n.activityHistoryEmpty),
        ),
      ];
    }

    final records = _controller.records;
    return [
      LazyListSection(
        header: l10n.activityHistoryLocalActivities,
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return ActivityRecordTile(
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
          );
        },
      ),
      if (_controller.hasMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: UIConstants.paddingStandard,
            ),
            child: Center(
              child: AdaptiveButton(
                label: l10n.activityHistoryLoadMore,
                onPressed: _controller.isLoading ? null : _controller.loadMore,
              ),
            ),
          ),
        ),
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
