import 'dart:ui';

import 'package:endurain/core/services/platform/share_service.dart';

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
      Error.throwWithStackTrace(throwError!, StackTrace.current);
    }
    calls.add((paths: paths, subject: subject));
  }
}
