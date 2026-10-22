import 'dart:async';

import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:http/http.dart' as http;

/// An [http.Client] decorator that follows redirects under an explicit,
/// credential-safe policy.
///
/// `package:http`'s default behaviour (via `dart:io`'s `HttpClient`) is to
/// follow redirects automatically and re-send the original headers. Because
/// Endurain talks to user-supplied self-hosted origins — over plain `http://`
/// when the user accepts that — a hostile or merely misconfigured instance
/// could answer an authenticated request with `302 Location: http://attacker`
/// and receive the bearer token. Nothing in the app chooses to follow
/// redirects, so this was inherited behaviour rather than a decision.
///
/// The policy applied here:
/// 1. Redirects are never followed by the transport itself
///    (`followRedirects = false`); this class does it explicitly.
/// 2. A redirect that would downgrade `https` to `http` is refused outright —
///    there is no legitimate reason for a server to ask for that, and it is the
///    classic way to strip TLS before harvesting a credential.
/// 3. Credential headers ([ApiConstants.authorizationHeader], `Cookie`) are
///    dropped when the redirect crosses to a different origin
///    (scheme + host + port). Same-origin redirects keep them, which is what
///    makes a trailing-slash or canonical-host redirect keep working.
/// 4. At most [maxRedirects] hops, after which the request fails rather than
///    looping.
/// 5. Only requests whose body can be replayed are followed. Streamed bodies —
///    notably the multipart activity upload — are returned as-is, so an upload
///    is never re-sent (with or without its token) to a redirect target.
///
/// Method rewriting follows the usual convention: `303` always becomes `GET`,
/// `301`/`302` become `GET` for non-`GET`/`HEAD` methods, and `307`/`308`
/// preserve both method and body.
class RedirectPolicyClient extends http.BaseClient {
  RedirectPolicyClient(
    this._inner, {
    this.maxRedirects = ApiConstants.maxRedirects,
  });

  final http.Client _inner;
  final int maxRedirects;

  static const Set<int> _redirectStatuses = {301, 302, 303, 307, 308};

  /// Headers that must not survive a cross-origin redirect.
  static const Set<String> _credentialHeaders = {'authorization', 'cookie'};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var current = request;
    for (var hop = 0; ; hop++) {
      current.followRedirects = false;
      final response = await _inner.send(current);

      if (!_redirectStatuses.contains(response.statusCode)) {
        return response;
      }

      final location = response.headers['location'];
      if (location == null || location.isEmpty) {
        // A redirect status with no target is not actionable; hand it back and
        // let the caller's status check fail normally.
        return response;
      }

      // Only a replayable body can be re-sent. A streamed/multipart body has
      // already been consumed, so following would either fail or silently send
      // an empty body.
      if (current is! http.Request) {
        return response;
      }

      if (hop >= maxRedirects) {
        throw const AppException(AppErrorCode.tooManyRedirects);
      }

      final target = _resolve(current.url, location);
      if (target == null) {
        return response;
      }
      if (current.url.isScheme('https') && target.isScheme('http')) {
        throw const AppException(AppErrorCode.insecureRedirectRejected);
      }

      // Drain the redirect body so the connection can be reused.
      await response.stream.drain<void>();
      current = _nextRequest(current, target, response.statusCode);
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  static Uri? _resolve(Uri base, String location) {
    final parsed = Uri.tryParse(location);
    if (parsed == null) {
      return null;
    }
    return base.resolveUri(parsed);
  }

  /// Builds the follow-up request, applying method rewriting and dropping
  /// credentials on a cross-origin hop.
  static http.Request _nextRequest(
    http.Request previous,
    Uri target,
    int statusCode,
  ) {
    final becomesGet =
        statusCode == 303 ||
        ((statusCode == 301 || statusCode == 302) &&
            previous.method != 'GET' &&
            previous.method != 'HEAD');
    final method = becomesGet ? 'GET' : previous.method;

    final next = http.Request(method, target);
    final sameOrigin = _isSameOrigin(previous.url, target);
    previous.headers.forEach((name, value) {
      if (!sameOrigin && _credentialHeaders.contains(name.toLowerCase())) {
        return;
      }
      next.headers[name] = value;
    });
    if (!becomesGet) {
      next.bodyBytes = previous.bodyBytes;
    }
    next.followRedirects = false;
    next.persistentConnection = previous.persistentConnection;
    return next;
  }

  static bool _isSameOrigin(Uri a, Uri b) {
    return a.scheme == b.scheme &&
        a.host.toLowerCase() == b.host.toLowerCase() &&
        _port(a) == _port(b);
  }

  static int _port(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }
    return uri.isScheme('https') ? 443 : 80;
  }
}
