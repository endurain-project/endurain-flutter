import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';

class AdaptiveLoadingIndicator extends StatelessWidget {
  const AdaptiveLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformUtils.isApplePlatform
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
  }
}
