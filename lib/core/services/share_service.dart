import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Thin wrapper around `share_plus` so the OS share sheet can be mocked in
/// tests. Mirrors `UrlLauncherService`.
class ShareService {
  const ShareService();

  Future<void> shareFiles(
    List<String> paths, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: paths
            .map((path) => XFile(path, mimeType: 'application/gpx+xml'))
            .toList(),
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
