import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/shared/adaptive/adaptive_icon.dart';
import 'package:endurain/shared/adaptive/adaptive_list_tile.dart';
import 'package:material_ui/material_ui.dart';

/// A row of a single-choice list (language, units, ...): the chosen row shows
/// a check mark, the others show nothing.
///
/// On Apple platforms the unselected rows carry no disclosure chevron, since
/// tapping them chooses rather than navigates. The selected state is also
/// exposed to assistive technology.
class AdaptiveSelectableListTile extends StatelessWidget {
  const AdaptiveSelectableListTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      selected: selected,
      child: AdaptiveListTile(
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        // A non-null trailing suppresses the Cupertino disclosure chevron so
        // the check mark alone signals selection.
        trailing: selected
            ? AdaptiveIcon(
                materialIcon: Icons.check,
                cupertinoIcon: CupertinoIcons.check_mark,
                color: Theme.of(context).colorScheme.primary,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
