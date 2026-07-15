import 'package:endurain/core/utils/scoped_storage_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scopedStorageKey', () {
    test('formats as <prefix>_<64-char lowercase hex sha256>', () {
      final key = scopedStorageKey('tile_server_url', 'https://example.test');

      expect(
        key,
        'tile_server_url_'
        'f1e2c7da767e6e0fc3eac0819fdd3a622967f18748c6f0a875c3a5b0a165031e',
      );
    });

    test('pins the health import dedup identity format', () {
      // Guards the persisted local-id contract used for health-import
      // de-duplication: profileId + sourceId joined by a newline, hashed, and
      // prefixed with `health_`. Changing this silently orphans stored dedup
      // rows and re-imports every workout, so the vector is locked here.
      final key = scopedStorageKey('health', '42\nABC-123');

      expect(
        key,
        'health_'
        '15c848a992749b7f468a53a9eb5f0681c1e9c1213c2dde61590ba985e4dadad3',
      );
    });

    test('is deterministic for the same inputs', () {
      expect(
        scopedStorageKey('p', 'scope-value'),
        scopedStorageKey('p', 'scope-value'),
      );
    });

    test('produces different keys for different scopes', () {
      expect(
        scopedStorageKey('p', 'scope-a'),
        isNot(scopedStorageKey('p', 'scope-b')),
      );
    });

    test(
      'produces different keys for the same scope under different prefixes',
      () {
        expect(
          scopedStorageKey('a', 'same-scope'),
          isNot(scopedStorageKey('b', 'same-scope')),
        );
      },
    );
  });
}
