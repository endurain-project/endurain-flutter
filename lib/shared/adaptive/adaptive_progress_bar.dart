import 'package:endurain/core/utils/platform_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class AdaptiveProgressBar extends StatelessWidget {
  const AdaptiveProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return const LinearProgressIndicator();
  }
}
