import 'package:flutter/widgets.dart';

/// The locales the app officially supports, expressed with their canonical
/// BCP 47 identity.
///
/// Region- and script-qualified identities are advertised here (e.g. European
/// Portuguese as `pt-PT`, Chinese as `zh-Hans`/`zh-Hant`) to stay consistent
/// with the Endurain backend and web client, which exchange locales as BCP 47
/// tags. Translated resources are generated from base-language ARBs
/// (`lib/l10n/app_pt.arb`, `lib/l10n/app_zh.arb` = Simplified Chinese, …), which
/// Flutter transparently resolves for the qualified identities at lookup time —
/// so no redundant region/script ARB files are needed (a lone `app_pt_PT.arb`
/// or `app_zh_Hans.arb` would be collapsed back to its base by `gen_l10n`).
///
/// This is the list passed to the app widget's `supportedLocales` and offered
/// in the language picker. Keep its set of language subtags in sync with
/// `AppLocalizations.supportedLocales`; a guard test enforces this.
const List<Locale> appSupportedLocales = <Locale>[
  Locale('en'),
  Locale('pt', 'PT'),
  Locale('bg'),
  Locale('ca'),
  Locale('cs'),
  Locale('da'),
  Locale('de'),
  Locale('el'),
  Locale('es'),
  Locale('et'),
  Locale('fi'),
  Locale('fr'),
  Locale('gl'),
  Locale('hr'),
  Locale('hu'),
  Locale('it'),
  Locale('lt'),
  Locale('lv'),
  Locale('nb'),
  Locale('nl'),
  Locale('pl'),
  Locale('ro'),
  Locale('sk'),
  Locale('sl'),
  Locale('sr'),
  Locale('sv'),
  Locale('tr'),
  Locale('uk'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
];

/// Resolves the device's preferred locales against [appSupportedLocales],
/// coercing every Portuguese variant (e.g. `pt`, `pt-BR`) to European
/// Portuguese (`pt-PT`).
///
/// European Portuguese is currently the only Portuguese translation the app
/// ships, so Brazilian and unqualified Portuguese speakers are served `pt-PT`
/// instead of falling back to English. Remove this coercion once a dedicated
/// `pt-BR` translation exists.
///
/// Non-Portuguese preferences keep Flutter's standard
/// [basicLocaleListResolution] behaviour, so an English-first user is
/// unaffected. Wire this into every app widget's `localeListResolutionCallback`
/// so both the system locale and an explicit in-app selection are normalized.
Locale appLocaleListResolution(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  final resolved = basicLocaleListResolution(
    preferredLocales,
    supportedLocales,
  );
  if (resolved.languageCode == 'pt') {
    return const Locale('pt', 'PT');
  }
  return resolved;
}
