import 'package:endurain/core/utils/platform_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveCheckboxListTile extends StatelessWidget {
  const AdaptiveCheckboxListTile({
    super.key,
    required this.value,
    required this.title,
    this.subtitle,
    this.secondary,
    this.onChanged,
    this.showControl = true,
  });

  final bool value;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final ValueChanged<bool?>? onChanged;
  final bool showControl;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      final enabled = onChanged != null;
      return MergeSemantics(
        child: Semantics(
          checked: showControl ? value : null,
          enabled: enabled,
          child: CupertinoListTile(
            leading: secondary,
            title: title,
            subtitle: subtitle,
            trailing: showControl
                ? SizedBox.square(
                    dimension: 24,
                    child: value
                        ? Icon(
                            CupertinoIcons.check_mark,
                            color: CupertinoTheme.of(context).primaryColor,
                            size: 20,
                          )
                        : null,
                  )
                : null,
            onTap: enabled ? () => onChanged?.call(!value) : null,
          ),
        ),
      );
    }

    if (!showControl) {
      return ListTile(leading: secondary, title: title, subtitle: subtitle);
    }

    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      enabled: onChanged != null,
      secondary: secondary,
      title: title,
      subtitle: subtitle,
    );
  }
}
