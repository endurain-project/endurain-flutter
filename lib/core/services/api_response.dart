import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:endurain/core/models/app_exception.dart';

class ApiResponse {
  const ApiResponse._();

  static Object? decodeJson(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (error) {
      throw AppException(AppErrorCode.unexpectedResponseFormat, cause: error);
    }
  }

  static Map<String, dynamic> decodeJsonObject(http.Response response) {
    final data = decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const AppException(AppErrorCode.unexpectedResponseFormat);
  }

  static AppException failure(http.Response response, AppErrorCode code) {
    return AppException(code, details: errorDetail(response));
  }

  static String requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw const AppException(AppErrorCode.unexpectedResponseFormat);
  }

  static String? optionalString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return null;
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw const AppException(AppErrorCode.unexpectedResponseFormat);
  }

  static int requiredPositiveInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int && value > 0) {
      return value;
    }
    throw const AppException(AppErrorCode.unexpectedResponseFormat);
  }

  static String? errorDetail(http.Response response) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      final data = json.decode(response.body);
      if (data is Map) {
        final raw =
            data['detail']?.toString() ??
            data['message']?.toString() ??
            data['error']?.toString();
        return _bounded(raw);
      }
    } catch (_) {
      // Body is not JSON — return a bounded, sanitized snippet so a
      // misbehaving server cannot surface arbitrary HTML or large responses.
      return _bounded(response.body);
    }

    // JSON body but not a map (e.g. an array): do not surface raw content.
    return null;
  }

  // Maximum character length returned as an error detail. Long or HTML bodies
  // are truncated to prevent arbitrary server text reaching the UI.
  static const int _maxDetailLength = 200;

  static String? _bounded(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= _maxDetailLength) return trimmed;
    return '${trimmed.substring(0, _maxDetailLength)}\u2026';
  }
}
