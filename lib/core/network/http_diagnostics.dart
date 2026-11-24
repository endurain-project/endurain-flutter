import 'package:endurain/core/diagnostics/diagnostics_service.dart';

/// Records a failed HTTP request (a `4xx`/`5xx` [status], or a transport
/// [error]) as a breadcrumb that identifies the endpoint but never the server
/// or anything secret in the address.
void recordHttpFailure(
  DiagnosticsRecorder diagnostics, {
  required String method,
  required Uri url,
  required Duration elapsed,
  int? status,
  Object? error,
}) {
  diagnostics.recordBreadcrumbSync(
    DiagnosticsEvents.httpRequestFailed,
    details: {
      'method': method,
      'endpoint': diagnosticEndpoint(url),
      'status': ?status,
      'ms': elapsed.inMilliseconds,
      if (error != null) ...diagnosticErrorDetails(error),
    },
  );
}

/// The path of [url] reduced to a template safe for a diagnostics report.
///
/// - The host and query are dropped: the host is the user's own server and
///   the query can carry tokens.
/// - Everything before the `api` segment is dropped, since a self-hosted
///   server may sit under a path the user chose.
/// - A segment is kept only when it reads as a route word (`auth`,
///   `password-change`, `v1`); anything else, and anything after `sessions`
///   or `jobs`, becomes `:id`, so ids, session ids and tokens never appear.
String diagnosticEndpoint(Uri url) {
  var segments = url.pathSegments.where((s) => s.isNotEmpty).toList();
  final apiIndex = segments.indexOf('api');
  if (apiIndex > 0) {
    segments = segments.sublist(apiIndex);
  }
  final template = <String>[];
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    final afterIdParent = i > 0 && _idParents.contains(segments[i - 1]);
    template.add(
      !afterIdParent && _routeWord.hasMatch(segment) ? segment : ':id',
    );
  }
  return '/${template.join('/')}';
}

final RegExp _routeWord = RegExp(r'^(?:[a-z][a-z_-]{0,39}|v\d{1,3})$');

const Set<String> _idParents = {'sessions', 'jobs'};
