import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, this.diagnostics});

  final DiagnosticsStore? diagnostics;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late final DiagnosticsStore _diagnostics;
  late Future<DiagnosticsReport?> _reportFuture;

  @override
  void initState() {
    super.initState();
    _diagnostics =
        widget.diagnostics ??
        AppScope.servicesOf(context, listen: false).diagnostics;
    _reportFuture = _diagnostics.readReport();
  }

  Future<void> _copyReport(DiagnosticsReport report) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: report.rawText));
    if (!mounted) {
      return;
    }
    await DialogUtils.showMessage(context, l10n.diagnosticsCopied);
  }

  Future<void> _clearReport() async {
    final l10n = AppLocalizations.of(context)!;
    await _diagnostics.clearReport();
    if (!mounted) {
      return;
    }
    setState(() {
      _reportFuture = _diagnostics.readReport();
    });
    await DialogUtils.showMessage(context, l10n.diagnosticsCleared);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.diagnosticsTitle,
      body: FutureBuilder<DiagnosticsReport?>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AdaptiveLoadingIndicator());
          }

          final report = snapshot.data;
          if (report == null || report.isEmpty) {
            return Center(
              child: AdaptiveEmptyStateText(message: l10n.diagnosticsEmpty),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            children: [
              _DiagnosticsSummarySection(report: report),
              const SizedBox(height: UIConstants.paddingStandard),
              _DiagnosticsEventsSection(events: report.breadcrumbs),
              if (report.errors.isNotEmpty) ...[
                const SizedBox(height: UIConstants.paddingStandard),
                _DiagnosticsErrorsSection(errors: report.errors),
              ],
              const SizedBox(height: UIConstants.paddingStandard),
              AdaptiveListSection(
                header: l10n.diagnosticsActions,
                children: [
                  AdaptiveListTile(
                    leading: const AdaptiveIcon(
                      materialIcon: Icons.copy,
                      cupertinoIcon: CupertinoIcons.doc_on_doc,
                    ),
                    title: l10n.diagnosticsCopy,
                    onTap: () => _copyReport(report),
                  ),
                  AdaptiveListTile(
                    leading: const AdaptiveIcon(
                      materialIcon: Icons.delete_outline,
                      cupertinoIcon: CupertinoIcons.trash,
                    ),
                    title: l10n.diagnosticsClear,
                    destructive: true,
                    onTap: _clearReport,
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.paddingStandard),
              _RawReportSection(report: report.rawText),
            ],
          );
        },
      ),
    );
  }
}

class _DiagnosticsSummarySection extends StatelessWidget {
  const _DiagnosticsSummarySection({required this.report});

  final DiagnosticsReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lastUpdated = report.lastUpdatedAt == null
        ? l10n.notConfigured
        : _formatDateTime(report.lastUpdatedAt!);

    return AdaptiveListSection(
      header: l10n.diagnosticsSummary,
      children: [
        AdaptiveListTile(
          title: l10n.diagnosticsLastUpdated,
          subtitle: lastUpdated,
        ),
        AdaptiveListTile(
          title: l10n.diagnosticsEventsCount(report.breadcrumbs.length),
          subtitle: l10n.diagnosticsErrorsCount(report.errors.length),
        ),
      ],
    );
  }
}

class _DiagnosticsEventsSection extends StatelessWidget {
  const _DiagnosticsEventsSection({required this.events});

  final List<DiagnosticsBreadcrumb> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleEvents = events.reversed.take(12).toList(growable: false);

    return AdaptiveListSection(
      header: l10n.diagnosticsEvents,
      children: [
        if (visibleEvents.isEmpty)
          AdaptiveListTile(title: l10n.diagnosticsNoEvents)
        else
          for (final event in visibleEvents)
            AdaptiveListTile(
              title: l10n.diagnosticsEventTitle(event.event),
              subtitle: _eventSubtitle(event),
            ),
      ],
    );
  }

  String _eventSubtitle(DiagnosticsBreadcrumb event) {
    final parts = <String>[];
    final at = event.at;
    if (at != null) {
      parts.add(_formatDateTime(at));
    }
    if (event.details.isNotEmpty) {
      parts.add(_formatDetails(event.details));
    }
    return parts.join('\n');
  }
}

class _DiagnosticsErrorsSection extends StatelessWidget {
  const _DiagnosticsErrorsSection({required this.errors});

  final List<DiagnosticsErrorEntry> errors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleErrors = errors.reversed.take(6).toList(growable: false);

    return AdaptiveListSection(
      header: l10n.diagnosticsErrors,
      children: [
        for (final error in visibleErrors)
          AdaptiveListTile(
            leading: const AdaptiveIcon(
              materialIcon: Icons.error_outline,
              cupertinoIcon: CupertinoIcons.exclamationmark_triangle,
            ),
            title: l10n.diagnosticsErrorTitle(error.type),
            subtitle: _errorSubtitle(error),
          ),
      ],
    );
  }

  String _errorSubtitle(DiagnosticsErrorEntry error) {
    final parts = <String>[];
    final at = error.at;
    if (at != null) {
      parts.add(_formatDateTime(at));
    }
    parts.add(error.source);
    if (error.message.isNotEmpty) {
      parts.add(error.message);
    }
    return parts.join('\n');
  }
}

class _RawReportSection extends StatelessWidget {
  const _RawReportSection({required this.report});

  final String report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = PlatformUtils.isApplePlatform
        ? CupertinoTheme.of(context).textTheme.textStyle.color
        : Theme.of(context).colorScheme.onSurface;
    final textStyle = TextStyle(
      color: textColor,
      fontFamily: 'monospace',
      fontSize: 12,
    );
    final contentPadding = PlatformUtils.isApplePlatform
        ? const EdgeInsets.symmetric(vertical: UIConstants.paddingStandard)
        : const EdgeInsets.all(UIConstants.paddingStandard);

    return AdaptiveListSection(
      header: l10n.diagnosticsRawReport,
      children: [
        Padding(
          padding: contentPadding,
          child: SizedBox(
            width: double.infinity,
            child: SelectableText(report, style: textStyle),
          ),
        ),
      ],
    );
  }
}

String _formatDetails(Map<String, Object?> details) {
  return details.entries
      .map((entry) => '${entry.key}: ${entry.value ?? ''}')
      .join(', ');
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
    local.second.toString().padLeft(2, '0'),
  ].join(':');
  return '$date $time';
}
