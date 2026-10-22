import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:endurain/app.dart';
import 'package:endurain/app/app_services.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// On-device smoke test: boots the real [App], signs in through the UI against
/// an in-process fake Endurain server, and checks the session was persisted
/// and the signed-in shell replaced the login screen.
///
/// The fake server runs in the same process as the app, so it is reachable at
/// the loopback address on both the Android emulator and the iOS simulator.
/// Run with `flutter test integration_test` against a booted device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late AppServices services;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(server.forEach(_handleRequest));
    services = AppServices();
    // Devices keep secure storage between runs; start signed out.
    await services.secureStorage.resetAll();
  });

  tearDown(() async {
    await server.close(force: true);
    await services.secureStorage.resetAll();
  });

  testWidgets('signs in with username and password', (tester) async {
    await tester.pumpWidget(App(services: services));
    await _pumpUntil(tester, find.byType(TextFormField));

    final l10n = AppLocalizations.of(tester.element(find.byType(App)))!;

    // Server step: the fake server speaks plain HTTP, so switch the protocol.
    await _selectHttp(tester);
    await tester.enterText(
      find.byType(TextFormField),
      '127.0.0.1:${server.port}',
    );
    await tester.tap(find.text(l10n.next));
    await _pumpUntil(tester, find.text(l10n.warnHttpServerUrlConfirm));
    await tester.tap(find.text(l10n.warnHttpServerUrlConfirm));

    // Credentials step.
    await _pumpUntil(tester, find.text(l10n.login));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'athlete');
    await tester.enterText(fields.at(1), 'correct-horse');
    await tester.tap(find.text(l10n.login));

    // The login screen is replaced by the signed-in shell.
    await _pumpUntil(tester, find.text(l10n.login), present: false);
    expect(await services.auth.hasStoredSession(), isTrue);
  });
}

Future<void> _selectHttp(WidgetTester tester) async {
  final dropdown = find.byType(DropdownButtonFormField<String>);
  if (dropdown.evaluate().isNotEmpty) {
    await tester.tap(dropdown);
    await tester.pump(const Duration(milliseconds: 500));
    // The open menu and the closed field both show the label; take the menu's.
    await tester.tap(find.text('HTTP').last);
  } else {
    await tester.tap(find.text('HTTP'));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps frames until [finder] is (or, with [present] false, is no longer)
/// found. Avoids `pumpAndSettle`, which never settles while the map animates.
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  bool present = true,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while ((finder.evaluate().isNotEmpty) != present) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure(
        'Timed out waiting for $finder to be ${present ? 'shown' : 'hidden'}',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  Object? body;
  if (path.endsWith('/public/server_settings')) {
    body = {'sso_enabled': false, 'local_login_enabled': true};
  } else if (path.endsWith('/auth/login')) {
    body = {'session_id': 'session-1'};
  } else if (path.endsWith('/session-1/tokens')) {
    body = {
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
      'session_id': 'session-1',
      'expires_in': 900,
    };
  } else if (path.endsWith('/profile')) {
    body = {'id': 1};
  } else if (path.endsWith('/public/idp')) {
    body = <Object>[];
  }
  if (body == null) {
    request.response.statusCode = HttpStatus.notFound;
  } else {
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
  }
  await request.response.close();
}
