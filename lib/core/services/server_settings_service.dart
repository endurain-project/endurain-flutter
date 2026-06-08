import 'package:http/http.dart' as http;
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_response.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

/// Service for fetching and managing server settings
class ServerSettingsService {
  ServerSettingsService({
    SecureStorageService? storage,
    ServerUrlResolver? urlResolver,
    http.Client? httpClient,
  }) : _storage = storage ?? SecureStorageService(),
       _urlResolver =
           urlResolver ??
           ServerUrlResolver(storage: storage ?? SecureStorageService()),
       _httpClient = httpClient ?? http.Client();

  final SecureStorageService _storage;
  final ServerUrlResolver _urlResolver;
  final http.Client _httpClient;

  /// Fetch server settings from the server
  Future<ServerSettings> getServerSettings({String? serverUrl}) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    final apiUrl = Uri.parse('$url${ApiConstants.serverSettingsEndpoint}');

    try {
      final response = await _httpClient.get(
        apiUrl,
        headers: {ApiConstants.clientTypeHeader: ApiConstants.clientTypeValue},
      );

      if (response.statusCode == 200) {
        final data = ApiResponse.decodeJsonObject(response);
        final settings = ServerSettings.fromJson(data);

        // Store tile server settings for later use
        if (settings.tileserverUrl != null &&
            settings.tileserverUrl!.isNotEmpty) {
          await _storage.setTileServerUrl(settings.tileserverUrl!);
        }
        if (settings.tileserverAttribution != null &&
            settings.tileserverAttribution!.isNotEmpty) {
          await _storage.setTileServerAttribution(
            settings.tileserverAttribution!,
          );
        }
        if (settings.mapBackgroundColor != null &&
            settings.mapBackgroundColor!.isNotEmpty) {
          await _storage.setMapBackgroundColor(settings.mapBackgroundColor!);
        }

        return settings;
      } else {
        throw ApiResponse.failure(
          response,
          AppErrorCode.fetchServerSettingsFailed,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(AppErrorCode.fetchServerSettingsFailed, cause: e);
    }
  }
}
