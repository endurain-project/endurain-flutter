import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/check_dead_code.dart';

const _source = '''
import 'dart:core';

void main() => Used().run();

class Used {
  Used();
  Used.named();
  int field = 0;
  int unusedField = 0;
  void run() {
    field++;
    helper();
  }

  void unusedMethod() {}

  @override
  String toString() => 'Used';
}

class Orphan {}

extension Ext on int {
  int get doubled => this * 2;
}

enum Color { red, green }

void helper() {
  final c = Color.red;
  print(c);
  print(3.doubled);
  Seams();
  Impl().send();
}

void unusedFunction() {}

abstract class Port {
  void send();
  void unusedPort();
}

class Impl implements Port {
  @override
  void send() {}

  @override
  void unusedPort() {}
}

const visibleForTesting = Object();

@visibleForTesting
void testSeamFunction() {}

class Seams {
  @visibleForTesting
  void seamMethod() {}
}

class _Private {
  void hidden() {}
}
''';

String? _dartSdk() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return null;
  final sdk = p.join(flutterRoot, 'bin', 'cache', 'dart-sdk');
  return Directory(sdk).existsSync() ? sdk : null;
}

void main() {
  group('parseAllowlist', () {
    test('ignores blanks and comments', () {
      final entries = parseAllowlist([
        '# header',
        '',
        'lib/a.dart:Foo  # inline reason',
        '  lib/b.dart:Bar.baz  ',
      ]);

      expect(entries, {'lib/a.dart:Foo', 'lib/b.dart:Bar.baz'});
    });
  });

  group('findUnreferenced', () {
    final sdk = _dartSdk();

    test(
      'reports public declarations nothing references',
      () async {
        final root = Directory.systemTemp.createTempSync('dead_code_test');
        addTearDown(() => root.deleteSync(recursive: true));
        Directory(p.join(root.path, 'lib')).createSync();
        File(p.join(root.path, 'lib', 'a.dart')).writeAsStringSync(_source);

        final findings = await findUnreferenced(root.path, sdkPath: sdk);

        expect(findings.map((f) => f.key).toSet(), {
          'lib/a.dart:Used.named',
          'lib/a.dart:Used.unusedField',
          'lib/a.dart:Used.unusedMethod',
          'lib/a.dart:Orphan',
          'lib/a.dart:Color.green',
          'lib/a.dart:unusedFunction',
          'lib/a.dart:Port.unusedPort',
        });
      },
      skip: sdk == null ? 'FLUTTER_ROOT with a Dart SDK is unavailable' : false,
    );
  });
}
