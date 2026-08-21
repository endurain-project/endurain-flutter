import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';

class AdaptiveBackButton extends StatelessWidget {
  const AdaptiveBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: const Icon(CupertinoIcons.back),
      );
    }

    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: onPressed);
  }
}
