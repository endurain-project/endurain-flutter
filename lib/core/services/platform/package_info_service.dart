import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoService {
  const PackageInfoService();

  Future<PackageInfo> fromPlatform() {
    return PackageInfo.fromPlatform();
  }
}
