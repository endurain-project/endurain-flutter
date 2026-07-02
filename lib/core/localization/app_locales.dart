import 'package:flutter/widgets.dart';

/// The locales the app officially supports, expressed with their canonical
/// BCP 47 identity.
///
/// European Portuguese is advertised as `pt-PT` to stay consistent with the
/// Endurain backend and web client, which exchange locales as BCP 47 tags. The
/// translated resources are generated from the base `pt` ARB
/// (`lib/l10n/app_pt.arb`), which Flutter transparently resolves for `pt-PT` at
/// lookup time — so no redundant region-specific ARB file is needed (a lone
/// `app_pt_PT.arb` would be collapsed back to `pt` by `gen_l10n` anyway).
///
/// This is the list passed to the app widget's `supportedLocales` and offered
/// in the language picker. Keep its set of language subtags in sync with
/// `AppLocalizations.supportedLocales`; a guard test enforces this.
const List<Locale> appSupportedLocales = <Locale>[
  Locale('en'),
  Locale('pt', 'PT'),
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
