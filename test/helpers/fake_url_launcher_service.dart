import 'package:endurain/core/services/platform/url_launcher_service.dart';

class FakeUrlLauncherService extends UrlLauncherService {
  FakeUrlLauncherService({required this.launched});

  final bool launched;
  final List<Uri> launchedUris = [];

  @override
  Future<bool> launchExternalApplication(Uri uri) async {
    launchedUris.add(uri);
    return launched;
  }
}
