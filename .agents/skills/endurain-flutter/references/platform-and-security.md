# Platform, network and security

## Server API and errors

- Call the server through the typed `ApiClient` helpers and `ApiResponse` parsing; never hand a raw HTTP response to a feature.
- Endpoint paths come from `lib/core/config/api_endpoints.dart`.
- Map failures to `AppException` with an `AppErrorCode`; services stay language-free and the UI localizes through `error_localizations.dart`.
- A new `AppErrorCode` gets an ARB message in every locale.
- Catch at a boundary that records or recovers (platform, plugin, fire-and-forget work), never to silence a failure upstream.

## Auth and session

- Tokens and session state are persisted only through the auth session store; nothing else reads or writes them.
- A refresh failure clears the session the same way everywhere.
- An SSO callback is handled only while a sign-in is pending.
- Secrets live only in `flutter_secure_storage`; preferences in `AppPreferencesStore` never hold a token, password or key.

## Diagnostics

- Logs, diagnostics and crash reports go through `lib/core/diagnostics/`, whose sanitizer redacts tokens, hosts, IP addresses and `Authorization` credentials (`diagnostics_sanitizer.dart`, `lib/core/utils/diagnostics_redaction.dart`); a new sensitive value gets a redaction rule and a test.
- Never log a token, password, server URL with credentials, or location trace in clear; `avoid_print` is on.
- Crash reporting is opt-in and its DSN is a build-time value, never committed.

## Platform adapters

- A plugin call sits behind an injectable adapter (`lib/core/services/platform/`, or `services/…_adapter.dart` in its feature) before a controller or screen sees it.
- An adapter has an `Unsupported…` fallback for platforms or builds without the capability, and tests use a fake from `test/helpers/`.
- Handle denied and permanently blocked permissions, unavailable services and platform exceptions as states the UI shows, with a path to the system settings when the OS no longer shows the dialog.
- Request a permission right before the feature needs it, not at launch.
- Permission declarations (Android manifest, Health Connect, `Info.plist`) match what the app uses; adding one also updates its rationale text and `android_manifest_test.dart` where it applies.

## Dependencies

- `pubspec.yaml` is the list; add a package only when no existing one or a small local implementation covers the need.
- Prefer well-maintained open-source packages; a proprietary or store-specific SDK needs a clear product, platform or security benefit, a stated rationale, and an injectable adapter.
- A package that pins a version for a reason has a comment saying why; keep it.
- Do not add a code-generation dependency for something plain Dart covers.
