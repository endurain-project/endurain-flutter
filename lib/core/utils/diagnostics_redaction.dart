/// Privacy redaction shared by local diagnostics and opt-in remote crash
/// reporting.
///
/// Both destinations must scrub the same sensitive material before anything is
/// persisted or transmitted, so the rules live here once rather than being
/// duplicated (and drifting) between the two. The redaction is deliberately
/// conservative: it strips bearer tokens and JWTs, secret-like `key=value`
/// pairs and JSON members, any query-string values, URL hosts and path ids
/// (a server address and the ids in `/sessions/<id>` identify the user),
/// absolute on-device file
/// paths (iOS/desktop home and container dirs, Android app-data and
/// external-storage dirs), and coordinate-looking pairs, then truncates to a
/// bounded length.
library;

/// Returns [value] with sensitive substrings redacted and truncated to
/// [maxLength].
String redactDiagnosticText(String value, {int maxLength = 500}) {
  var sanitized = value
      .replaceAll(
        RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
        'Bearer <redacted>',
      )
      // A JWT is a credential wherever it appears, with or without `Bearer `.
      .replaceAll(RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+'), '<redacted>')
      // `key=value`, `key: value` and JSON members such as
      // `"refresh_token": "value"`: an optional closing quote may sit between
      // the key and the separator, and a quoted value is redacted whole.
      .replaceAllMapped(
        RegExp(
          r'''([\w-]*(?:token|password|secret|authorization|cookie|session|verifier)[\w-]*)["']?\s*[=:]\s*("[^"]*"|'[^']*'|[^,\s]+)''',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)}=<redacted>',
      )
      .replaceAllMapped(
        RegExp(r'([?&][^=\s]+)=([^&\s]+)'),
        (match) => '${match.group(1)}=<redacted>',
      )
      .replaceAllMapped(_urlOrPath, (match) => _redactUrlOrPath(match[0]!))
      .replaceAll(RegExp(r'/Users/[^\s:]+'), '<path>')
      .replaceAll(RegExp(r'/private/var/containers/[^\s:]+'), '<path>')
      .replaceAll(RegExp(r'/data/user/[^\s:]+'), '<path>')
      .replaceAll(RegExp(r'/data/data/[^\s:]+'), '<path>')
      .replaceAll(RegExp(r'/storage/emulated/[^\s:]+'), '<path>')
      .replaceAll(
        RegExp(r'[-+]?\d{1,2}\.\d{4,}\s*,\s*[-+]?\d{1,3}\.\d{4,}'),
        '<coordinates>',
      );

  if (sanitized.length > maxLength) {
    sanitized = '${sanitized.substring(0, maxLength)}...';
  }
  return sanitized;
}

// A URL, or an absolute path starting with a letter (not `/Users`-style
// device paths, which are redacted whole afterwards).
final RegExp _urlOrPath = RegExp(
  r'''https?://[^\s"'<>]+|(?<![\w<>/.])/[A-Za-z][^\s"'<>?#,;)]*''',
  caseSensitive: false,
);

final RegExp _idSegment = RegExp(
  r'^(?:\d+|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[0-9a-f]{16,})$',
  caseSensitive: false,
);

// A long opaque token such as `Ab3_x-Q9...`: needs a digit and a letter so a
// long plain word stays readable.
final RegExp _opaqueSegment = RegExp(r'^(?=.*\d)(?=.*[A-Za-z])[\w-]{16,}$');

/// Replaces the host of a URL and the id-like segments of its path; the query
/// is left for the query-value rule.
String _redactUrlOrPath(String token) {
  var rest = token;
  var prefix = '';
  final scheme = RegExp(r'^https?://', caseSensitive: false).firstMatch(rest);
  if (scheme != null) {
    final afterScheme = rest.substring(scheme.end);
    final authorityEnd = afterScheme.indexOf(RegExp(r'[/?#]'));
    prefix = '${scheme[0]}<host>';
    rest = authorityEnd == -1 ? '' : afterScheme.substring(authorityEnd);
  }
  final suffixStart = rest.indexOf(RegExp(r'[?#]'));
  final path = suffixStart == -1 ? rest : rest.substring(0, suffixStart);
  final suffix = suffixStart == -1 ? '' : rest.substring(suffixStart);
  final redactedPath = path
      .split('/')
      .map(
        (segment) =>
            _idSegment.hasMatch(segment) || _opaqueSegment.hasMatch(segment)
            ? '<id>'
            : segment,
      )
      .join('/');
  return '$prefix$redactedPath$suffix';
}
