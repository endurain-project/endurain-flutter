# UI and localization

## Adaptive UI

- Android renders Material 3 through `material_ui`; iOS renders through `cupertino_ui` where it supports the widget.
- Use the primitives in `lib/shared/adaptive/` before adding a platform branch; branch with `PlatformUtils`, not `Platform.isIOS` in a widget.
- Single-choice lists use `adaptive_choice_picker.dart` (an action sheet on Apple platforms, a dialog elsewhere).
- Add a new adaptive primitive only when the pattern repeats across features.
- Do not hand-roll platform visual effects, glass or blur surfaces, or lookalike widgets that the native Flutter families do not expose.
- Large screens use the helpers in `lib/shared/layout/` (readable width, large-screen layout) instead of per-screen breakpoints.
- Every map uses the shared tile layer in `lib/shared/map/`, which shows the tile source's attribution.
- Prefer Material icons (bundled with `material_ui`); add an icon package only when Material has no fitting icon.
- Use `const` constructors and values from `lib/core/theme/` and `lib/core/constants/`; no magic numbers or hardcoded colors.
- Every async screen has loading, empty and error states; user-facing errors come from `error_localizations.dart`.
- After an `await`, check `context.mounted` before using the `BuildContext` (`use_build_context_synchronously`).

## Flutter text (ARB)

- Never hardcode a user-facing string: widgets, dialogs, validators, snack bars, errors, button labels and semantics labels all use `AppLocalizations.of(context)`.
- `app_en.arb` is the source; add every new key to all 30 `lib/l10n/app_<code>.arb` files, translated (locales in `lib/core/localization/app_locales.dart`).
- `app_en.arb` and `app_pt.arb` carry the `@` metadata (`l10n.yaml` requires it); the description names the usage, `"Used in: <file>.dart"`.
- Place the key in its feature section (`lib/l10n/README.md`); use placeholders, never concatenated fragments.
- The app's delegates are `appLocalizationsDelegates`, never the generated `AppLocalizations.localizationsDelegates`.
- Run `flutter gen-l10n` after ARB changes; the generated `app_localizations*.dart` files are not hand-edited.
- Format dates, distances and durations with the helpers in `lib/core/utils/` and the user's unit system, not hardcoded patterns.
- The ARB parity tests in `test/l10n/` fail when a locale lacks a key.

## Native text

Text the OS shows outside Flutter (notifications, permission prompts, Health Connect rationale, the watch apps) is translated in the native resources, in the same 30 languages:

| Surface | File |
| --- | --- |
| Android phone app | `android/app/src/main/res/values-*/strings.xml` |
| Wear OS app | `android/wear/src/main/res/values-*/strings.xml` |
| iPhone permission prompts | `ios/Runner/InfoPlist.xcstrings` |
| Apple Watch app | `ios/EndurainWatch/Localizable.xcstrings`, `ios/EndurainWatch/InfoPlist.xcstrings` |

Native text follows the device or per-app system language; the in-app language picker does not change it.
