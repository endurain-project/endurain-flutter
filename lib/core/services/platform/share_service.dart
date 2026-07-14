import 'dart:ui';

import 'package:share_plus/share_plus.dart';

abstract class ShareAdapter {
  Future<void> share(ShareParams params);
}

class SharePlusAdapter implements ShareAdapter {
  const SharePlusAdapter();

  @override
  Future<void> share(ShareParams params) {
    return SharePlus.instance.share(params);
  }
}

/// Thin wrapper around `share_plus` so the OS share sheet can be mocked in
/// tests. Mirrors `UrlLauncherService`.
class ShareService {
  ShareService({ShareAdapter? adapter})
    : _adapter = adapter ?? const SharePlusAdapter();

  final ShareAdapter _adapter;

  Future<void> shareFiles(
    List<String> paths, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    await _adapter.share(
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
