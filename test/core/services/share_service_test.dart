import 'dart:ui';

import 'package:endurain/core/services/share_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('ShareService', () {
    test('builds GPX share params for all file paths', () async {
      final adapter = _FakeShareAdapter();
      final service = ShareService(adapter: adapter);
      const rect = Rect.fromLTWH(8, 16, 24, 32);

      await service.shareFiles(
        const ['/tmp/first.gpx', '/tmp/second.gpx'],
        subject: 'Morning run',
        sharePositionOrigin: rect,
      );

      expect(adapter.calls, hasLength(1));
      final params = adapter.calls.single;
      final files = params.files!;
      expect(params.subject, 'Morning run');
      expect(params.sharePositionOrigin, rect);
      expect(files, hasLength(2));
      expect(files[0].path, '/tmp/first.gpx');
      expect(files[1].path, '/tmp/second.gpx');
      expect(files[0].mimeType, 'application/gpx+xml');
      expect(files[1].mimeType, 'application/gpx+xml');
    });

    test('allows sharing without optional subject and origin', () async {
      final adapter = _FakeShareAdapter();
      final service = ShareService(adapter: adapter);

      await service.shareFiles(const ['/tmp/activity.gpx']);

      final params = adapter.calls.single;
      final files = params.files!;
      expect(params.subject, isNull);
      expect(params.sharePositionOrigin, isNull);
      expect(files.single.path, '/tmp/activity.gpx');
    });

    test('propagates share adapter failures', () async {
      final adapter = _FakeShareAdapter(error: StateError('share failed'));
      final service = ShareService(adapter: adapter);

      expect(
        () => service.shareFiles(const ['/tmp/activity.gpx']),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _FakeShareAdapter implements ShareAdapter {
  _FakeShareAdapter({this.error});

  final Object? error;
  final List<ShareParams> calls = [];

  @override
  Future<void> share(ShareParams params) async {
    if (error != null) {
      throw error!;
    }
    calls.add(params);
  }
}
