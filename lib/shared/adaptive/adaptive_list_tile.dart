import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive_list_tile_subtitle.dart';

class AdaptiveListTile extends StatelessWidget {
  const AdaptiveListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isApplePlatform = PlatformUtils.isApplePlatform;
    final titleStyle = destructive
        ? TextStyle(
            color: isApplePlatform
                ? CupertinoColors.systemRed
                : Theme.of(context).colorScheme.error,
          )
        : null;

    if (isApplePlatform) {
      return CupertinoListTile(
        leading: leading,
        title: Text(title, style: titleStyle),
        subtitle: subtitle == null
            ? null
            : AdaptiveListTileSubtitle(child: Text(subtitle!)),
        trailing:
            trailing ??
            (onTap == null ? null : const CupertinoListTileChevron()),
        onTap: onTap,
      );
    }

    return ListTile(
      leading: leading,
      title: Text(title, style: titleStyle),
      subtitle: subtitle == null
          ? null
          : AdaptiveListTileSubtitle(child: Text(subtitle!)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
