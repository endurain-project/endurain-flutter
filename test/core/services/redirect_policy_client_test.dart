import 'dart:convert';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/redirect_policy_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('RedirectPolicyClient', () {
    test('returns a non-redirect response untouched', () async {
      final client = RedirectPolicyClient(_ScriptedClient([_ok('done')]));

      final response = await _get(client, 'https://a.test/x');

      expect(response.statusCode, 200);
      expect(await response.stream.bytesToString(), 'done');
    });

    test('follows a same-origin redirect and keeps the bearer token', () async {
      final inner = _ScriptedClient([
        _redirect(302, 'https://a.test/moved'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      final response = await _get(
        client,
        'https://a.test/x',
        headers: {'Authorization': 'Bearer secret'},
      );

      expect(response.statusCode, 200);
      expect(inner.requests, hasLength(2));
      expect(inner.requests[1].url.toString(), 'https://a.test/moved');
      // Same origin: the credential is still required by the target.
      expect(inner.requests[1].headers['Authorization'], 'Bearer secret');
    });

    test('strips the bearer token on a cross-origin redirect', () async {
      final inner = _ScriptedClient([
        _redirect(302, 'https://evil.test/collect'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      await _get(
        client,
        'https://a.test/x',
        headers: {'Authorization': 'Bearer secret', 'Cookie': 'sid=1'},
      );

      expect(inner.requests, hasLength(2));
      final followed = inner.requests[1];
      expect(followed.url.host, 'evil.test');
      expect(followed.headers.containsKey('Authorization'), isFalse);
      expect(followed.headers.containsKey('Cookie'), isFalse);
    });

    test('treats a different port as a different origin', () async {
      final inner = _ScriptedClient([
        _redirect(302, 'https://a.test:8443/moved'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      await _get(
        client,
        'https://a.test/x',
        headers: {'Authorization': 'Bearer secret'},
      );

      expect(inner.requests[1].headers.containsKey('Authorization'), isFalse);
    });

    test('rejects an https to http downgrade outright', () async {
      final inner = _ScriptedClient([_redirect(302, 'http://a.test/moved')]);
      final client = RedirectPolicyClient(inner);

      await expectLater(
        _get(
          client,
          'https://a.test/x',
          headers: {'Authorization': 'Bearer secret'},
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.insecureRedirectRejected,
          ),
        ),
      );
      // The follow-up request was never issued.
      expect(inner.requests, hasLength(1));
    });

    test('allows http to http for self-hosted instances', () async {
      final inner = _ScriptedClient([
        _redirect(302, 'http://nas.local/moved'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      final response = await _get(client, 'http://nas.local/x');

      expect(response.statusCode, 200);
      expect(inner.requests, hasLength(2));
    });

    test('fails once the redirect budget is exhausted', () async {
      final inner = _ScriptedClient([
        for (var i = 0; i < 10; i++) _redirect(302, 'https://a.test/hop$i'),
      ]);
      final client = RedirectPolicyClient(inner, maxRedirects: 3);

      await expectLater(
        _get(client, 'https://a.test/x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.tooManyRedirects,
          ),
        ),
      );
      // Initial request plus exactly `maxRedirects` follow-ups.
      expect(inner.requests, hasLength(4));
    });

    test('303 rewrites the method to GET and drops the body', () async {
      final inner = _ScriptedClient([
        _redirect(303, 'https://a.test/result'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      final request = http.Request('POST', Uri.parse('https://a.test/submit'))
        ..body = 'payload';
      await client.send(request);

      final followed = inner.requests[1] as http.Request;
      expect(followed.method, 'GET');
      expect(followed.body, isEmpty);
    });

    test('307 preserves the method and body', () async {
      final inner = _ScriptedClient([
        _redirect(307, 'https://a.test/result'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      final request = http.Request('POST', Uri.parse('https://a.test/submit'))
        ..body = 'payload';
      await client.send(request);

      final followed = inner.requests[1] as http.Request;
      expect(followed.method, 'POST');
      expect(followed.body, 'payload');
    });

    test('302 on a POST becomes a GET, per convention', () async {
      final inner = _ScriptedClient([
        _redirect(302, 'https://a.test/result'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      final request = http.Request('POST', Uri.parse('https://a.test/submit'))
        ..body = 'payload';
      await client.send(request);

      expect((inner.requests[1] as http.Request).method, 'GET');
    });

    test('resolves a relative Location against the current URL', () async {
      final inner = _ScriptedClient([
        _redirect(302, '/v2/resource'),
        _ok('done'),
      ]);
      final client = RedirectPolicyClient(inner);

      await _get(client, 'https://a.test/v1/resource');

      expect(inner.requests[1].url.toString(), 'https://a.test/v2/resource');
    });

    test('does not follow a redirect for a non-replayable body', () async {
      // A multipart upload cannot be re-sent, so the redirect is surfaced
      // rather than followed — the token and file never reach the target.
      final inner = _ScriptedClient([
        _redirect(302, 'https://evil.test/collect'),
      ]);
      final client = RedirectPolicyClient(inner);

      final request =
          http.MultipartRequest('POST', Uri.parse('https://a.test/upload'))
            ..headers['Authorization'] = 'Bearer secret'
            ..files.add(http.MultipartFile.fromString('file', 'gpx'));

      final response = await client.send(request);

      expect(response.statusCode, 302);
      expect(inner.requests, hasLength(1));
    });

    test('returns a redirect that carries no Location header', () async {
      final inner = _ScriptedClient([
        http.StreamedResponse(const Stream<List<int>>.empty(), 302),
      ]);
      final client = RedirectPolicyClient(inner);

      final response = await _get(client, 'https://a.test/x');

      expect(response.statusCode, 302);
      expect(inner.requests, hasLength(1));
    });

    test('disables transport-level redirect following', () async {
      final inner = _ScriptedClient([_ok('done')]);
      final client = RedirectPolicyClient(inner);

      await _get(client, 'https://a.test/x');

      // Without this the underlying dart:io client would follow redirects
      // itself and re-send the Authorization header.
      expect(inner.requests.single.followRedirects, isFalse);
    });
  });
}

Future<http.StreamedResponse> _get(
  http.Client client,
  String url, {
  Map<String, String> headers = const {},
}) {
  final request = http.Request('GET', Uri.parse(url));
  request.headers.addAll(headers);
  return client.send(request);
}

http.StreamedResponse _ok(String body) {
  return http.StreamedResponse(Stream<List<int>>.value(utf8.encode(body)), 200);
}

http.StreamedResponse _redirect(int status, String location) {
  return http.StreamedResponse(
    const Stream<List<int>>.empty(),
    status,
    headers: {'location': location},
  );
}

/// Returns queued responses in order and records what was actually sent.
class _ScriptedClient extends http.BaseClient {
  _ScriptedClient(this._responses);

  final List<http.StreamedResponse> _responses;
  final List<http.BaseRequest> requests = [];
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    if (_index >= _responses.length) {
      throw StateError('Unexpected request to ${request.url}');
    }
    return _responses[_index++];
  }
}
