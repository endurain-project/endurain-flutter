import 'package:endurain/core/services/redirect_policy_client.dart';
import 'package:http/http.dart' as http;

abstract class MultipartUploadAdapter {
  Future<http.StreamedResponse> uploadFile({
    required Uri url,
    required Map<String, String> headers,
    required String filePath,
    required String fieldName,
  });
}

class HttpMultipartUploadAdapter implements MultipartUploadAdapter {
  HttpMultipartUploadAdapter({http.Client? httpClient})
    : _client = RedirectPolicyClient(httpClient ?? http.Client());

  /// Long-lived: the returned [http.StreamedResponse] is read by the caller
  /// after this method returns, so the client must outlive the call. One
  /// instance is held for the app's lifetime rather than one per upload.
  final http.Client _client;

  @override
  Future<http.StreamedResponse> uploadFile({
    required Uri url,
    required Map<String, String> headers,
    required String filePath,
    required String fieldName,
  }) async {
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    // Sent through the redirect policy rather than `request.send()`, which uses
    // a bare client that would auto-follow a redirect and re-send the bearer
    // token. A multipart body cannot be replayed, so the policy returns the
    // redirect response unfollowed and the upload fails visibly instead of
    // shipping the token (and the GPX) to whatever the server pointed at.
    return _client.send(request);
  }
}
