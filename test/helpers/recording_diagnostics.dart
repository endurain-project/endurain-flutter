import 'package:endurain/core/diagnostics/diagnostics_service.dart';

/// Captures breadcrumbs in memory so tests can assert what was recorded.
class RecordingDiagnostics implements DiagnosticsRecorder {
  final List<String> events = [];
  final List<Map<String, Object?>> details = [];

  /// The details of the only breadcrumb recorded as [event].
  Map<String, Object?> single(String event) {
    final matches = [
      for (var i = 0; i < events.length; i++)
        if (events[i] == event) details[i],
    ];
    if (matches.length != 1) {
      throw StateError('Expected one $event, found ${matches.length}');
    }
    return matches.single;
  }

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    events.add(event);
    this.details.add(details);
  }

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {}
}
