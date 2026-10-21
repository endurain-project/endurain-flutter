import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// shared_preferences_android 2.5+ reaches Kotlin through JNI by class name, so
/// R8 must not rename these classes in release builds (flutter/flutter#194649).
/// Debug builds do not minify, so nothing else catches a regression: the app
/// would only fail in release, with every preferences read throwing.
void main() {
  const requiredKeeps = <String>[
    'kotlin.Unit',
    'kotlin.Result',
    r'kotlin.Result$Failure',
    'kotlin.coroutines.Continuation',
    'kotlin.coroutines.intrinsics.CoroutineSingletons',
    'kotlin.coroutines.intrinsics.IntrinsicsKt',
  ];

  test('release R8 rules keep the Kotlin classes used over JNI', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();
    for (final name in requiredKeeps) {
      expect(
        rules,
        contains('-keep class $name { *; }'),
        reason: '$name must be kept or release builds break preferences.',
      );
    }
  });

  test('release build type loads the rules file', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('proguardFiles("proguard-rules.pro")'));
  });
}
