---
name: endurain-native
description: Conventions for the Kotlin and Swift code (phone recorders, Wear OS, Apple Watch, channels, native tests). Use when adding, changing or reviewing code in android/ or ios/, or a Dart channel or payload they mirror.
---

# Endurain native code

Repo-wide rules and the native invariants are in `AGENTS.md`.
Build, signing and release steps are in `README.md` ("Building from Source"); the recorder recovery contract is in `README.md` ("Active Recording Recovery Contract").

## Where code goes

| Code | Place |
| --- | --- |
| Android phone app: recorder, foreground service, Health Connect | `android/app/` |
| Wear OS app (separate Gradle build) | `android/wear/` |
| Kotlin used by the phone and Wear OS apps | `android/watch_shared/common/` |
| Kotlin used only by the Wear OS app | `android/watch_shared/watch/` |
| Android and Wear OS dependency, AGP and Kotlin versions | `android/gradle/libs.versions.toml` only |
| iPhone app: recorder, HealthKit, watch inbox | `ios/Runner/` |
| Apple Watch app | `ios/EndurainWatch/` |
| Swift shared by the iPhone and Apple Watch apps | `ios/Shared/` (`Watch/`, `Platform/`) |

## Core rules (always apply)

- A cross-language contract has one Dart source and a Kotlin and Swift mirror that names it (`NativeActivityRecorderChannelContract` and `ActivityRecorderChannel.kt`/`.swift`; the watch handoff `payloadVersion` and `sessionSchemaVersion` in `WatchProtocol.swift`).
  Change all sides in the same change and bump the version a payload carries; never accept an unknown version silently.
- A method-channel error code is a contract constant on every side; the Dart constants are listed in `.github/dead-code-allowlist.txt`.
- Logic computed natively and in Dart (distance, auto-pause, timing, BLE parsing, announcements) is pinned by `test/fixtures/*.json`; change the vectors and make the Dart, Kotlin (`SharedFixtures.kt`) and Swift (`NativeSharedVectorsTests.swift`) tests pass.
- File, database, sensor and network work runs off the main thread; the main thread only touches UI and platform APIs that require it.
- A recorder owns its active-session log: write it durably before reporting a point or state, and keep a paused or failed session paused on recovery.
- Kotlin and Swift sources stay under 500 lines (`test/architecture/file_size_guard_test.dart` checks them); split by responsibility.
- Every OS-visible string is a resource translated into all 30 languages (`res/values-*/strings.xml`, the `.xcstrings` catalogs).
- Permissions, entitlements, background modes and foreground-service types match what the code uses; change them only when asked, and update the rationale text with them.
- The phone app also builds without the Wear OS link (`-Pendurain.wearable=false`); keep the stub compiling.
- A release build is never signed with a debug key.
- KISS, YAGNI, DRY: put code used by two targets in `watch_shared/common` or `ios/Shared` instead of copying it.

## Before finishing

Android and Wear OS (the first command generates the Gradle configuration):

```bash
flutter build apk --config-only
(cd android && ./gradlew :app:testDebugUnitTest :app:lintDebug --console=plain)
(cd android && ./gradlew :app:compileDebugKotlin -Pendurain.wearable=false --console=plain)
(cd android && ./gradlew -p wear assembleDebug testDebugUnitTest lintDebug --console=plain)
```

iOS and watchOS (needs Xcode; pick simulators with `xcrun simctl list devices available`):

```bash
flutter build ios --simulator --debug --config-only
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=<iPhone simulator>' CODE_SIGNING_ALLOWED=NO
xcodebuild test -workspace ios/Runner.xcworkspace -scheme EndurainWatch \
  -destination 'platform=watchOS Simulator,name=<Apple Watch simulator>' CODE_SIGNING_ALLOWED=NO
```

Also run `flutter test` when a contract or a shared vector changed.
CI does not sign or run on a device: say so when a change depends on HealthKit, background location, Health Connect, BLE or entitlements, and list what needs a real-device check.

## Repo hygiene

- Dart side of a channel or feature: use the `endurain-flutter` skill.
- Commit messages, PRs and the changelog: use the `conventional-commits` skill.
