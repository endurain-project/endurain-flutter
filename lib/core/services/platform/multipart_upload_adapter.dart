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
  const HttpMultipartUploadAdapter();

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
    return request.send();
  }
}
