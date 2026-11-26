import 'package:endurain/features/activity/models/append_only_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppendOnlyList', () {
    test('appended returns a longer list and leaves the original alone', () {
      final base = AppendOnlyList<int>.of([1, 2]);

      final grown = base.appended([3, 4]);

      expect(grown, [1, 2, 3, 4]);
      expect(base, [1, 2]);
      expect(identical(grown, base), isFalse);
    });

    test('a fork of an older list copies instead of clobbering the tip', () {
      final base = AppendOnlyList<int>.of([1]);
      final tip = base.appended([2]);

      final fork = base.appended([99]);

      expect(tip, [1, 2]);
      expect(fork, [1, 99]);
      expect(base, [1]);
    });

    test('is unmodifiable', () {
      final list = AppendOnlyList<int>.of([1]);

      expect(() => list.add(2), throwsUnsupportedError);
      expect(() => list[0] = 2, throwsUnsupportedError);
      expect(list.clear, throwsUnsupportedError);
      expect(() => list[1], throwsRangeError);
    });

    test('appending many batches stays linear', () {
      var list = AppendOnlyList<int>();
      for (var i = 0; i < 20000; i++) {
        list = list.appended([i]);
      }

      expect(list, hasLength(20000));
      expect(list.last, 19999);
    });
  });
}
