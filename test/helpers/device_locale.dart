import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// A metric region, used to pin unit-dependent widget tests.
const Locale metricDeviceLocale = Locale('en', 'AU');

/// An imperial region, used to assert the imperial rendering path.
const Locale imperialDeviceLocale = Locale('en', 'US');

/// Pins the *device* locale reported to the app for the current test.
///
/// The displayed unit system is derived from the device locale's region (see
/// `ActivityStatsFormatterScope.deviceLocale`), not from the app's resolved
/// language-only locale. `flutter_test` reports `en-US` by default, which is an
/// imperial region — so any test asserting metric strings must pin a metric
/// region explicitly rather than relying on the harness default.
///
/// Registers its own teardown, so call it from `setUp` or inside a test.
void useDeviceLocale(Locale locale) {
  final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
  dispatcher.localeTestValue = locale;
  dispatcher.localesTestValue = <Locale>[locale];
  addTearDown(dispatcher.clearLocaleTestValue);
  addTearDown(dispatcher.clearLocalesTestValue);
}
