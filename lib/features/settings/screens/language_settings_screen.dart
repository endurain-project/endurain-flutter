import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

/// Native names (autonyms) for the supported languages, shown in each
/// language's own script as is conventional for a language picker. Keyed by
/// the locale's canonical BCP 47 tag ([Locale.toLanguageTag]) so script/region
/// variants (e.g. `zh-Hans` vs `zh-Hant`, `pt-PT`) are distinguished.
const Map<String, String> _languageAutonyms = {
  'en': 'English',
  'pt-PT': 'Português',
  'bg': 'Български',
  'ca': 'Català',
  'cs': 'Čeština',
  'da': 'Dansk',
  'de': 'Deutsch',
  'el': 'Ελληνικά',
  'es': 'Español',
  'et': 'Eesti',
  'fi': 'Suomi',
  'fr': 'Français',
  'gl': 'Galego',
  'hr': 'Hrvatski',
  'hu': 'Magyar',
  'it': 'Italiano',
  'lt': 'Lietuvių',
  'lv': 'Latviešu',
  'nb': 'Norsk bokmål',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'ro': 'Română',
  'sk': 'Slovenčina',
  'sl': 'Slovenščina',
  'sr': 'Српски',
  'sv': 'Svenska',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'zh-Hans': '简体中文',
  'zh-Hant': '繁體中文',
};

/// The picker label for [locale]: its autonym when known, otherwise its BCP 47
/// tag as a safe fallback.
String languageDisplayName(Locale locale) =>
    _languageAutonyms[locale.toLanguageTag()] ?? locale.toLanguageTag();

/// Lets the user override the app language, following the device locale by
/// default. Selections are persisted as BCP 47 tags via [LocaleController].
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key, this.localeController});

  /// Overrides the app-scoped controller (used in tests).
  final LocaleController? localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        localeController ??
        AppScope.servicesOf(context, listen: false).localeController;

    return AdaptiveScaffold(
      title: l10n.language,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final selected = controller.locale;
          return ListView(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            children: [
              AdaptiveListSection(
                children: [
                  _LanguageOptionTile(
                    label: l10n.languageSystemDefault,
                    selected: selected == null,
                    onTap: () => _select(context, controller, null),
                  ),
                  for (final locale in appSupportedLocales)
                    _LanguageOptionTile(
                      label: languageDisplayName(locale),
                      selected:
                          selected != null &&
                          selected.toLanguageTag() == locale.toLanguageTag(),
                      onTap: () => _select(context, controller, locale),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _select(
    BuildContext context,
    LocaleController controller,
    Locale? locale,
  ) {
    // Notifies synchronously (updating the whole app); the write is durable but
    // does not need to block dismissing the picker.
    unawaited(controller.setLocale(locale));
    Navigator.of(context).pop();
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      title: label,
      onTap: onTap,
      // A non-null trailing suppresses the Cupertino disclosure chevron so the
      // checkmark alone signals selection.
      trailing: selected
          ? AdaptiveIcon(
              materialIcon: Icons.check,
              cupertinoIcon: CupertinoIcons.check_mark,
              color: Theme.of(context).colorScheme.primary,
            )
          : const SizedBox.shrink(),
    );
  }
}
