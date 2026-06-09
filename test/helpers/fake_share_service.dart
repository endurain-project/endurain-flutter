import 'dart:ui';

import 'package:endurain/core/services/share_service.dart';

class FakeShareService extends ShareService {
  FakeShareService({this.throwError});

  /// If set, [shareFiles] will throw this error instead of recording the call.
  final Object? throwError;

  final List<({List<String> paths, String? subject})> calls = [];

  @override
  Future<void> shareFiles(
    List<String> paths, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    if (throwError != null) {
      throw throwError!;
    }
    calls.add((paths: paths, subject: subject));
  }
}
