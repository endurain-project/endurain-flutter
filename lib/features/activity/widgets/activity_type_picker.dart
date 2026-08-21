import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class ActivityTypePicker extends StatelessWidget {
  const ActivityTypePicker({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.enabled = true,
  });

  final ActivityType selectedType;
  final ValueChanged<ActivityType>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (PlatformUtils.isApplePlatform) {
      return _CupertinoActivityTypePicker(
        selectedType: selectedType,
        onChanged: onChanged,
        enabled: enabled,
        l10n: l10n,
      );
    }

    final theme = Theme.of(context);
    final disabled = !enabled || onChanged == null;
    final borderColor = theme.colorScheme.outline;
    final labelColor = disabled
        ? theme.disabledColor
        : theme.colorScheme.onSurfaceVariant;
    final valueColor = disabled
        ? theme.disabledColor
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      label: l10n.activityTypeLabel,
      value: selectedType.localizedLabel(l10n),
      child: Container(
        key: const ValueKey('activityTypePickerMaterialField'),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.activityTypeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: labelColor),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<ActivityType>(
                value: selectedType,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(8),
                iconEnabledColor: valueColor,
                iconDisabledColor: theme.disabledColor,
                style: theme.textTheme.bodyLarge?.copyWith(color: valueColor),
                onChanged: disabled
                    ? null
                    : (value) {
                        if (value != null) {
                          onChanged!(value);
                        }
                      },
                items: ActivityType.values
                    .map((type) {
                      return DropdownMenuItem<ActivityType>(
                        value: type,
                        child: Text(type.localizedLabel(l10n)),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoActivityTypePicker extends StatelessWidget {
  const _CupertinoActivityTypePicker({
    required this.selectedType,
    required this.onChanged,
    required this.enabled,
    required this.l10n,
  });

  final ActivityType selectedType;
  final ValueChanged<ActivityType>? onChanged;
  final bool enabled;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final borderColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGrey3,
      context,
    );
    final textColor = CupertinoDynamicColor.resolve(
      enabled ? CupertinoColors.label : CupertinoColors.inactiveGray,
      context,
    );

    return Semantics(
      button: true,
      label: l10n.activityTypeLabel,
      value: selectedType.localizedLabel(l10n),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: enabled && onChanged != null
              ? () => _showTypeActions(context)
              : null,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.activityTypeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedType.localizedLabel(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_down, color: textColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTypeActions(BuildContext context) async {
    final selected = await showCupertinoModalPopup<ActivityType>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(l10n.activityTypeLabel),
          actions: ActivityType.values
              .map((type) {
                return CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context, type),
                  child: Text(type.localizedLabel(l10n)),
                );
              })
              .toList(growable: false),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        );
      },
    );

    if (selected != null) {
      onChanged!(selected);
    }
  }
}
