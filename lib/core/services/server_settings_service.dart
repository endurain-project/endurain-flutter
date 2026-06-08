import 'package:http/http.dart' as http;
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/base_http_client.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

/// Service for fetching server settings.
///
/// This service only fetches and returns data. Callers are responsible for
/// persisting any settings they need (e.g. map preferences via
/// MapSettingsRepository).
class ServerSettingsService {
  ServerSettingsService({
    SecureStorageService? storage,
    ServerUrlResolver? urlResolver,
    BaseHttpClient? baseClient,
    http.Client? httpClient,
  }) : _urlResolver =
           urlResolver ??
           ServerUrlResolver(storage: storage ?? SecureStorageService()),
       _http = baseClient ?? BaseHttpClient(httpClient: httpClient);

  final ServerUrlResolver _urlResolver;
  final BaseHttpClient _http;

  /// Fetches settings from the server and returns them.
  ///
  /// Does not persist any data. Callers that want to save map preferences
  /// should call `MapSettingsRepository.saveFromServerSettings` with the
  /// returned value.
  Future<ServerSettings> getServerSettings({String? serverUrl}) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    final apiUrl = Uri.parse('$url${ApiConstants.serverSettingsEndpoint}');

    try {
      final data = await _http.getJsonObject(
        apiUrl,
        failureCode: AppErrorCode.fetchServerSettingsFailed,
      );
      return ServerSettings.fromJson(data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(AppErrorCode.fetchServerSettingsFailed, cause: e);
    }
  }
}
