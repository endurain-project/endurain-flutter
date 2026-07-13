import 'package:endurain/core/utils/platform_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  const AdaptiveSegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      final labelColor = CupertinoColors.label.resolveFrom(context);
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: selected,
          children: {
            for (final entry in labels.entries)
              entry.key: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  entry.value,
                  style: TextStyle(color: labelColor),
                  textAlign: TextAlign.center,
                ),
              ),
          },
          onValueChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      );
    }

    return SegmentedButton<T>(
      expandedInsets: EdgeInsets.zero,
      segments: [
        for (final entry in labels.entries)
          ButtonSegment<T>(value: entry.key, label: Text(entry.value)),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
