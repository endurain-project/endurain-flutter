import 'package:endurain/features/watch/models/watch_link_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchLinkStatus', () {
    test('only a connected watch is reachable', () {
      for (final status in WatchLinkStatus.values) {
        expect(status.isReachable, status == WatchLinkStatus.connected);
      }
    });

    test('round-trips through its JSON name', () {
      for (final status in WatchLinkStatus.values) {
        expect(WatchLinkStatus.fromJson(status.toJson()), status);
      }
    });

    test('an unknown or missing value is unsupported', () {
      expect(WatchLinkStatus.fromJson('nope'), WatchLinkStatus.unsupported);
      expect(WatchLinkStatus.fromJson(null), WatchLinkStatus.unsupported);
    });
  });
}
