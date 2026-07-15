import 'package:endurain/core/utils/id_generation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('id_generation', () {
    test('uniqueSuffix has a <timestamp>_<hex> shape', () {
      expect(uniqueSuffix(), matches(RegExp(r'^\d+_[0-9a-f]+$')));
    });

    test('localActivityId is prefixed and unique', () {
      final first = localActivityId();
      final second = localActivityId();
      expect(first, startsWith('activity_'));
      expect(second, startsWith('activity_'));
      expect(first, isNot(second));
    });

    test('recordingSessionId is prefixed and unique', () {
      final first = recordingSessionId();
      final second = recordingSessionId();
      expect(first, startsWith('session_'));
      expect(second, startsWith('session_'));
      expect(first, isNot(second));
    });

    test('connectionRevision is non-empty and unique', () {
      final first = connectionRevision();
      final second = connectionRevision();
      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
      expect(first, isNot(second));
    });

    test('generates unique suffixes across many rapid calls', () {
      final suffixes = <String>{
        for (var index = 0; index < 500; index++) uniqueSuffix(),
      };
      expect(suffixes, hasLength(500));
    });
  });
}
