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
