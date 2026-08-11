import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/gpx_route_parser.dart';
import 'package:endurain/features/activity/widgets/activity_route_map.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({
    super.key,
    required this.recordId,
    this.controller,
    this.repository,
    this.uploadService,
    this.retentionSettingsRepository,
    this.tileServerUrlProvider,
  });

  final String recordId;
  final LocalActivityHistoryController? controller;
  final LocalActivityRepository? repository;
  final ActivityUploadService? uploadService;
  final ActivityRetentionSettingsRepository? retentionSettingsRepository;

  /// Supplies the tile-server URL for the route preview map. When null, the map
  /// is not shown (e.g. in tests that do not exercise the map).
  final Future<String> Function()? tileServerUrlProvider;

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen>
    with OwnedControllers {
  late final LocalActivityHistoryController _controller;
  Future<_ActivityRouteMapData?>? _routeMapFuture;
  String? _routeMapKey;

  @override
  void initState() {
    super.initState();
    _controller = registerController(widget.controller, _createController);
    if (widget.controller == null) {
      _controller.loadRecord(widget.recordId);
    }
  }

  LocalActivityHistoryController _createController() {
    return AppScope.servicesOf(
      context,
      listen: false,
    ).createLocalActivityHistoryController(
      repository: widget.repository,
      uploadService: widget.uploadService,
      retentionSettingsRepository: widget.retentionSettingsRepository,
    );
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

  Future<void> _export(LocalActivityRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    // iOS UIActivityViewController requires a non-zero anchor rect.
    // Use the screen centre as a safe fallback for all device sizes.
    final screenSize = MediaQuery.of(context).size;
    final origin = Rect.fromCenter(
      center: screenSize.center(Offset.zero),
      width: 1,
      height: 1,
    );
    try {
      await _controller.exportGpx(
        record.id,
        subject: l10n.activityExportGpxSubject,
        sharePositionOrigin: origin,
      );
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
      return;
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.activityHistoryDetailsTitle,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final record = _controller.recordById(widget.recordId);
          if (_controller.isLoading && record == null) {
            return const Center(child: AdaptiveLoadingIndicator());
          }
          if (record == null) {
            return _DetailsMessage(message: l10n.activityHistoryDetailsMissing);
          }

          return ListView(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            children: [
              _RouteMapSection(future: _routeMapFor(record)),
              _SummarySection(record: record, controller: _controller),
              const SizedBox(height: UIConstants.paddingStandard),
              FutureBuilder<bool>(
                future: _controller.hasGpx(record),
                builder: (context, snapshot) {
                  return _ActionsSection(
                    record: record,
                    isBusy: _controller.isBusy(record.id),
                    onRetry:
                        record.uploadStatus ==
                            LocalActivityUploadStatus.uploaded
                        ? null
                        : () => _retry(record),
                    onExport: (snapshot.data ?? false)
                        ? () => _export(record)
                        : null,
                    onDelete: () => _delete(record),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Memoizes the route-map load per record so scrolling and controller
  /// notifications do not re-read and re-parse the GPX on every rebuild. The
  /// key includes the upload status so the map re-evaluates if the GPX is
  /// cleaned up after a successful upload.
  Future<_ActivityRouteMapData?> _routeMapFor(LocalActivityRecord record) {
    final key = '${record.id}:${record.uploadStatus.name}';
    if (_routeMapKey != key || _routeMapFuture == null) {
      _routeMapKey = key;
      _routeMapFuture = _loadRouteMap(record);
    }
    return _routeMapFuture!;
  }

  Future<_ActivityRouteMapData?> _loadRouteMap(
    LocalActivityRecord record,
  ) async {
    final provider = widget.tileServerUrlProvider;
    if (provider == null) {
      return null;
    }
    final route = await _controller.loadRoute(record);
    if (route == null) {
      return null;
    }
    final tileServerUrl = await provider();
    return _ActivityRouteMapData(route: route, tileServerUrl: tileServerUrl);
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _RouteMapSection extends StatelessWidget {
  const _RouteMapSection({required this.future});

  final Future<_ActivityRouteMapData?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ActivityRouteMapData?>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: UIConstants.paddingStandard),
          child: ActivityRouteMap(
            route: data.route,
            tileServerUrl: data.tileServerUrl,
          ),
        );
      },
    );
  }
}

class _ActivityRouteMapData {
  const _ActivityRouteMapData({
    required this.route,
    required this.tileServerUrl,
  });

  final GpxRoute route;
  final String tileServerUrl;
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.record, required this.controller});

  final LocalActivityRecord record;
  final LocalActivityHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = context.statsFormatter;

    return AdaptiveListSection(
      header: l10n.activityHistorySummary,
      children: [
        AdaptiveListTile(
          title: l10n.activityHistoryType,
          subtitle: record.activityType.localizedLabel(l10n),
        ),
        AdaptiveListTile(
          title: l10n.activityHistoryStartedAt,
          subtitle: formatLocalDateTime(context, record.startedAt),
        ),
        AdaptiveListTile(
          title: l10n.activityHistoryEndedAt,
          subtitle: formatLocalDateTime(context, record.endedAt),
        ),
        AdaptiveListTile(
          title: l10n.activityHistoryDurationLabel,
          subtitle: formatter.formatDuration(record.elapsedDurationSeconds),
        ),
        AdaptiveListTile(
          title: l10n.activityHistoryDistanceLabel,
          subtitle: formatter.formatDistance(
            record.distanceMeters,
            locale: locale,
          ),
        ),
        AdaptiveListTile(
          title: l10n.activityHistoryAverageSpeed,
          subtitle: formatter.formatSpeed(
            record.averageSpeedMetersPerSecond,
            locale: locale,
          ),
        ),
        if (record.maxSpeedMetersPerSecond != null)
          AdaptiveListTile(
            title: l10n.activityStatMaxSpeed,
            subtitle: formatter.formatSpeed(
              record.maxSpeedMetersPerSecond,
              locale: locale,
            ),
          ),
        if (record.elevationGainMeters != null)
          AdaptiveListTile(
            title: l10n.activityStatElevationGain,
            subtitle: formatter.formatElevation(
              record.elevationGainMeters,
              locale: locale,
            ),
          ),
        AdaptiveListTile(
          title: l10n.activityHistoryPointCount,
          subtitle: record.pointCount.toString(),
        ),
        AdaptiveListTile(
          title: l10n.activityHistoryUploadStatusLabel,
          subtitle: _uploadStatusDetails(context, l10n, record),
        ),
        FutureBuilder<bool>(
          future: controller.hasGpx(record),
          builder: (context, snapshot) {
            final hasGpx = snapshot.data ?? false;
            return AdaptiveListTile(
              title: l10n.activityHistoryGpxStatus,
              subtitle: hasGpx
                  ? l10n.activityHistoryGpxAvailable
                  : l10n.activityHistoryGpxMissing,
            );
          },
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.record,
    required this.isBusy,
    required this.onRetry,
    required this.onExport,
    required this.onDelete,
  });

  final LocalActivityRecord record;
  final bool isBusy;
  final VoidCallback? onRetry;
  final VoidCallback? onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveListSection(
      header: l10n.activityHistoryActions,
      children: [
        if (isBusy)
          const Padding(
            padding: EdgeInsets.all(UIConstants.paddingStandard),
            child: Center(child: AdaptiveLoadingIndicator()),
          )
        else ...[
          if (onRetry != null)
            AdaptiveListTile(
              leading: const AdaptiveIcon(
                materialIcon: Icons.refresh,
                cupertinoIcon: CupertinoIcons.refresh,
              ),
              title: l10n.activityRetryUpload,
              onTap: onRetry,
            ),
          if (onExport != null)
            AdaptiveListTile(
              leading: const AdaptiveIcon(
                materialIcon: Icons.ios_share,
                cupertinoIcon: CupertinoIcons.share,
              ),
              title: l10n.activityExportGpx,
              onTap: onExport,
            ),
          AdaptiveListTile(
            leading: const AdaptiveIcon(
              materialIcon: Icons.delete_outline,
              cupertinoIcon: CupertinoIcons.delete,
            ),
            title: l10n.activityDeleteLocal,
            destructive: true,
            onTap: onDelete,
          ),
        ],
      ],
    );
  }
}

String _uploadStatusDetails(
  BuildContext context,
  AppLocalizations l10n,
  LocalActivityRecord record,
) {
  final details = <String>[_uploadStatusLabel(l10n, record.uploadStatus)];
  if (record.lastUploadAttemptAt != null) {
    details.add(formatLocalDateTime(context, record.lastUploadAttemptAt!));
  }
  if (record.lastUploadErrorCode case final code?) {
    details.add(localizedErrorMessage(AppException(code), l10n));
  }
  return details.join('\n');
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
