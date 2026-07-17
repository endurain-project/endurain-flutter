import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/controllers/diagnostics_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, this.diagnostics});

  final DiagnosticsStore? diagnostics;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen>
    with OwnedControllers {
  late final DiagnosticsController _controller;

  @override
  void initState() {
    super.initState();
    // The screen always owns the controller; its test seam is the diagnostics
    // store (injected here) rather than the controller itself.
    _controller = registerController(
      null,
      () => DiagnosticsController(
        diagnostics:
            widget.diagnostics ??
            AppScope.servicesOf(context, listen: false).diagnostics,
      ),
    );
    _controller.load();
  }

  Future<void> _setEnabled(bool value) => _controller.setEnabled(value);

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
    await _controller.clearReport();
    if (!mounted) {
      return;
    }
    await DialogUtils.showMessage(context, l10n.diagnosticsCleared);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.diagnosticsTitle,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final report = _controller.report;
          return ListView(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            children: [
              AdaptiveListSection(
                header: l10n.diagnosticsCollection,
                children: [
                  AdaptiveSwitchListTile(
                    leading: const AdaptiveIcon(
                      materialIcon: Icons.bug_report,
                      cupertinoIcon: CupertinoIcons.waveform_path_ecg,
                    ),
                    title: l10n.diagnosticsEnable,
                    subtitle: l10n.diagnosticsEnableSubtitle,
                    value: _controller.isEnabled,
                    onChanged: _setEnabled,
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.paddingStandard),
              if (!_controller.isEnabled)
                AdaptiveEmptyStateText(message: l10n.diagnosticsDisabled)
              else if (_controller.isLoadingReport)
                const Center(child: AdaptiveLoadingIndicator())
              else if (report == null || report.isEmpty)
                AdaptiveEmptyStateText(message: l10n.diagnosticsEmpty)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ),
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
        : formatLocalDateTime(
            context,
            report.lastUpdatedAt!,
            includeSeconds: true,
          );

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
              subtitle: _eventSubtitle(context, event),
            ),
      ],
    );
  }

  String _eventSubtitle(BuildContext context, DiagnosticsBreadcrumb event) {
    final parts = <String>[];
    final at = event.at;
    if (at != null) {
      parts.add(formatLocalDateTime(context, at, includeSeconds: true));
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
            subtitle: _errorSubtitle(context, error),
          ),
      ],
    );
  }

  String _errorSubtitle(BuildContext context, DiagnosticsErrorEntry error) {
    final parts = <String>[];
    final at = error.at;
    if (at != null) {
      parts.add(formatLocalDateTime(context, at, includeSeconds: true));
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
