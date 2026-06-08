import 'package:endurain/core/utils/json_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jsonString', () {
    test('returns the string for a String value', () {
      expect(jsonString('hello'), 'hello');
    });

    test('returns null for a non-String value', () {
      expect(jsonString(42), isNull);
      expect(jsonString(null), isNull);
      expect(jsonString(3.14), isNull);
    });
  });

  group('jsonInt', () {
    test('returns the value for an int', () {
      expect(jsonInt(7), 7);
    });

    test('truncates a double to int', () {
      expect(jsonInt(3.9), 3);
    });

    test('returns null for non-numeric values', () {
      expect(jsonInt(null), isNull);
      expect(jsonInt('42'), isNull);
    });
  });

  group('jsonDouble', () {
    test('returns a double for a num', () {
      expect(jsonDouble(3), 3.0);
      expect(jsonDouble(3.14), 3.14);
    });

    test('returns null for non-finite values', () {
      expect(jsonDouble(double.nan), isNull);
      expect(jsonDouble(double.infinity), isNull);
    });

    test('returns null for non-numeric values', () {
      expect(jsonDouble(null), isNull);
      expect(jsonDouble('1.0'), isNull);
    });
  });

  group('jsonDateTime', () {
    test('parses a valid ISO-8601 string as UTC', () {
      final result = jsonDateTime('2024-03-15T10:30:00Z');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
      expect(result.year, 2024);
    });

    test('normalises non-UTC ISO strings to UTC', () {
      final result = jsonDateTime('2024-03-15T10:30:00+01:00');
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
    });

    test('returns null for invalid strings', () {
      expect(jsonDateTime('not-a-date'), isNull);
      expect(jsonDateTime(''), isNull);
    });

    test('returns null for non-String values', () {
      expect(jsonDateTime(null), isNull);
      expect(jsonDateTime(12345), isNull);
    });
  });
}
