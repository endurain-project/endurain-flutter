/// Privacy redaction shared by local diagnostics and opt-in remote crash
/// reporting.
///
/// Both destinations must scrub the same sensitive material before anything is
/// persisted or transmitted, so the rules live here once rather than being
/// duplicated (and drifting) between the two. The redaction is deliberately
/// conservative: it strips bearer tokens and JWTs, secret-like `key=value`
/// pairs and JSON members, any query-string values, absolute on-device file
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
          r'''(token|password|secret|authorization|cookie|session)["']?\s*[=:]\s*("[^"]*"|'[^']*'|[^,\s]+)''',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)}=<redacted>',
      )
      .replaceAllMapped(
        RegExp(r'([?&][^=\s]+)=([^&\s]+)'),
        (match) => '${match.group(1)}=<redacted>',
      )
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
