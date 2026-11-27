# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A "Start workout" tile on Wear OS that opens the app.
- During a Wear OS workout, the ongoing activity on the watch face and in recents shows the elapsed time and whether the workout is paused.
- Starting a workout on Wear OS while another app is recording one asks for confirmation first, because Health Services ends the other app's workout.
- When Precise Location is off, the iPhone and Apple Watch apps ask for temporary precise location while recording. Recording continues if the user declines.
- On iPhone, a recording in progress shows its elapsed time, distance and pace (or speed) on the Lock Screen and in the Dynamic Island, and whether it is paused. It can be turned off in the iPhone's Settings for Endurain under Live Activities.
- Every map shows its tile source's attribution: the OpenStreetMap credit for the default source, and the server's attribution (or the host name) for a custom one.
- The Health access screen opens the Health Connect permission screen when Android no longer shows the permission dialog. The sensor screens, and a new Bluetooth row on Device Access, open the system settings when Bluetooth access is blocked.
- The Health Connect permission rationale screen links to the [mobile app privacy policy](https://docs.endurain.com/privacy/mobile-app-privacy-policy/), in every language.
- CI changes:
  - CI lints the Android phone app (`:app:lintDebug`), as it already did for the Wear OS app.
  - A dead-code check (`tool/check_dead_code.dart`) fails when a public declaration in `lib/` is referenced nowhere in `lib/`. Justified exceptions are listed, each with a reason, in `.github/dead-code-allowlist.txt`.
  - The iOS workflow also runs on pull requests that change iOS, watchOS, `lib/` or the shared test vectors, and it runs the new Apple Watch unit tests (`ios/EndurainWatchTests`).
- Architecture tests that stop the sign-in feature from importing the map feature, the settings feature from importing activity code or health internals, and the activity feature from importing the map feature.

### Changed

- The minimum iOS version is now 17.0. The Apple Watch app still needs watchOS 10.0.
- The iPhone recorder uses the newer Core Location live updates. After iOS terminates the app during a recording, iOS now relaunches it by resuming those updates instead of by a significant location change. With auto-pause on, a recording still auto-pauses when the iPhone stops reporting fixes because it is standing still.
- The two-factor sign-in step shows one box per character. An authenticator code takes six digits only, and "Use a backup code" switches to eight boxes of letters and digits, which the app sends as `XXXX-XXXX`. Pasted or autofilled codes with spaces or a dash fill the boxes, and password managers can still fill authenticator codes. The code is sent as soon as the last box is filled. If the server rejects it, the boxes clear and the reason shows under them, so the user can type the next code straight away.
- In the Wear OS app:
  - In ambient mode the workout screen shows only the elapsed time. Heart rate and distance arrive in batches while the screen is dimmed, so they could be out of date.
  - The workout pager shows a page indicator, so the pause and end page is easier to find.
  - TalkBack reads heart rate as "Heart rate, N beats per minute".
  - The countdown shows the GPS status while Health Services warms up.
  - The app uses Material 3 components with a transforming list, and the "Start workout" tile uses the Material 3 tile layout.
- In the Apple Watch app:
  - VoiceOver reads each metric with its label.
  - With the always-on display dimmed, the metrics refresh once a minute and the countdown once a second.
  - The countdown number scales with Dynamic Type.
  - The app uses the Observation framework (`@Observable`) instead of `ObservableObject`.
- The Apple Watch app resends a workout the iPhone has not confirmed after 10 minutes, then waits twice as long each time, up to 24 hours, instead of resending every 10 minutes forever. It still never deletes an unconfirmed workout.
- On Android:
  - The notification permission is requested right before the first recording or start countdown instead of at launch. Recording does not depend on the answer.
  - The recording notification shows as soon as a recording starts, with a monochrome status-bar icon.
  - The app uses the Android 12+ splash screen. Its launcher icon is a transparent glyph with a monochrome layer, so Android 13+ themed icons show the logo, and the splash uses a matching icon.
  - Spoken announcements use the same audio attributes as the request that lowers other apps' audio.
- The Android and iPhone recorders keep the active session in memory instead of reading it from disk on every GPS fix. The Android recorder and the Wear OS app do their file and sensor work off the main thread.
- An upload waiting out a retry delay is retried by a timer while the app stays open, instead of waiting for a resume or a connectivity change.
- The iPhone privacy manifest declares crash and diagnostic data, which opt-in crash reporting sends.
- The activity history and Health Sync lists build rows as they scroll into view. Long lists are now grouped into cards of 20 rows.
- The app loads its language, units, audio and crash-reporting settings in parallel at startup.
- Selected rows on the language and units screens are announced as selected, and the units screen no longer shows a disclosure arrow on iPhone.
- The GitLab mirror runs only for `main` and `v*` tags. It pushes only branches and tags, so GitHub's pull-request refs no longer make it fail.
- Android and Wear OS dependencies, the Android Gradle plugin and the Kotlin version are declared once, in the Gradle version catalog `android/gradle/libs.versions.toml`.
- Internal changes:
  - Audio announcement settings moved into the activity feature.
  - Settings repositories share typed preference helpers.
  - The upload queue and watch sync share one single-flight helper, and both databases share one open helper.
  - Auto-pause handling moved out of the recording service, and import and discovery out of the Health Sync service.
  - Files that grew past the size limit are split, including the Android recorder service, the Wear OS main screen and recorder, the Apple Watch workout manager and the health platform adapter. The file-size guard checks the native sources too.
  - `android/watch_shared` is split into `common` (compiled by the phone and Wear OS builds) and `watch` (Wear OS only).
  - `MapSettingsRepository` moved to `lib/core/services`. A shared map tile layer and a shared adaptive choice picker replace duplicated code.
- The README, CONTRIBUTING, SECURITY, the localization guide and the contributor instructions match the code again. The fixes cover project structure, schema version, HealthKit write access, the Kotlin version, build commands, CI checks, minimum OS versions and architecture rules. `dart-defines.json` is git-ignored as documented.

### Fixed

- After finishing an activity while signed out, the summary no longer leaves the map without a way to start a new recording. It says the activity is saved on the device and uploads after sign-in, and every settled upload state (including a failed one) offers Done, View history and Delete. Starting a new recording also dismisses a finished activity's summary.
- On Android, resuming a recording no longer leaves the saved session marked as recording when the system refuses to restart the recorder. The session stays paused and can be resumed again.
- A Wear OS workout no longer stays on "Saving…" when Health Services never reports that it ended. The app finishes with what it recorded after 20 seconds.
- A Wear OS recording that cannot be read after a crash is cleared instead of being left on the watch to fail the same way on every launch.
- The Wear OS app requests approximate location together with precise location. Some Android 12 releases ignore a request for precise location on its own.
- A long unfinished Wear OS workout no longer slows the app's launch. It is now loaded off the main thread.
- The map's location spinner and the device access screen no longer stay loading forever when a location check fails.
- A BLE sensor scan stops when it times out, including when the scan is cancelled while it is still starting, and a second tap or leaving the screen no longer starts a scan that is never stopped.
- GPX files are written atomically, so an interrupted write can no longer leave a truncated file.
- Two parts of the app opening the same database at once share one connection.

### Security

- Reinstalling the iPhone app starts signed out. iOS keeps keychain items after an app is uninstalled, so a reinstall used to restore the previous session. Upgrades stay signed in.
- Diagnostics and crash reports redact email addresses, host names and IP addresses in socket errors, and the credentials of `Authorization` values (`Bearer`, `Basic` and `Digest`).
- A single sign-on callback, success or error, is ignored when no sign-in is in progress, so another app can no longer cancel or reset a sign-in that hasn't started.
- The GitLab mirror passes its tokens in request headers instead of in remote URLs.

### Removed

- Unused code:
  - The `AppScope` widget and `ActivityGpxFileWriter`.
  - Unused theme tokens and constants.
  - The client's unused PUT and DELETE requests.
  - The legacy token setters.
  - The unused geolocator background-location settings.
  - Getters and members that only tests read.
- Unused status and reason constants in the native Android and iOS recorders, and the duplicate Android launch background.

## [v0.12.3+25] - 2026-11-26

This release requests only the health data the apps use, after Google Play rejected 0.12.2 under its Health Connect minimum-scope policy, and updates the dependencies.

### Changed

- Health Sync on Android no longer asks for step counts or calories, which no feature used. It still imports workouts, routes, heart rate and distance. The Health Connect privacy text no longer lists steps or calories in any language.
- The Apple Watch app no longer asks to read workouts or active energy. It reads only heart rate and distance, which the workout screen shows, and still saves energy with the workout. The Health read description no longer mentions energy in any language.
- A manifest test fails if the Android app declares a Health Connect permission outside the expected set.
- Dependency updates:
  - `universal_ble` 3.4.1, `connectivity_plus` 7.3.2 and `flutter_svg` 2.5.1. A `dbus` override lets them resolve alongside `geolocator_linux`, whose latest release still requires `dbus` 0.7; the app does not build for Linux.
  - Android Gradle plugin 9.5.3 for the phone and Wear OS builds.
  - Compose BOM 2026.11.01 for the Wear OS app, which now compiles against SDK 37.1. The CI builder image installs that platform.

### Removed

- The `READ_STEPS` and `READ_TOTAL_CALORIES_BURNED` Health Connect permissions, and the unused calories field of imported workouts.

## [v0.12.2+24] - 2026-11-26

This release adapts the app to large screens and fixes the findings of a full review of the app, its native code and CI. Recording stays smooth on long activities, watch workouts are safer, and the iOS app meets App Store privacy requirements.

### Added

- Privacy manifests (`PrivacyInfo.xcprivacy`) for the iPhone and Apple Watch apps, which App Store Connect requires. They declare the required-reason APIs the apps use (file timestamps, system boot time and `UserDefaults`), and the health and location data they collect.
- Ambient (always-on) mode in the Wear OS app. During a workout the dimmed screen shows only the metrics and updates on each ambient tick instead of every second.
- The Wear OS workout screen shows when GPS is acquiring or lost, and when heart rate is unavailable.
- Settings shows "Not secure (HTTP)" for a server that uses plain HTTP, under the account and in Server settings.
- Shared test vectors (`test/fixtures/*_vectors.json`) for logic implemented on more than one platform. They cover distance, session timing, audio announcement thresholds, scheduling and speech, and BLE sensor parsing, and the Dart, Kotlin and Swift tests load the same files.
- Architecture tests that:
  - stop features from reaching into `AppServices`;
  - limit what the map imports from the activity feature;
  - cap source file size, so large files can only shrink.

### Changed

- Screens fit large displays such as an unfolded iPhone Duo, a tablet or a phone in landscape. Settings, sign-in, health and activity screens keep their content at most 640pt wide and centred instead of stretching edge to edge, and the side margins still scroll.
- When there is room for both (840pt or wider, such as an unfolded iPhone Duo in landscape), the activity history shows the list and the selected activity side by side. Narrower windows open an activity on its own page as before, and the list keeps its scroll position when the device is folded, unfolded or rotated.
- The iOS workflow builds and tests with Xcode 27.2 on GitHub's Xcode 27 runner image and runs on an iPhone Duo simulator when one is available. The macOS 26 image only has Xcode 26, and from April 2027 App Store uploads must be built with the iOS 27 SDK.
- The map no longer rebuilds every second during a recording. Only the stats update each second, and the route is redrawn when it gains points. New points are appended without copying the whole track, so long recordings stay smooth.
- Large GPX files are built and parsed off the UI thread. Route parsing accepts track point attributes in any order and with either quote style.
- Health Sync's auto-sync on resume reads only workouts since the last successful sync, with a 48-hour overlap, instead of the whole default range.
- Failed uploads wait before retrying: 1 minute at first, doubling up to 6 hours. The retry state survives restarts (database schema version 10), and a manual retry is never delayed.
- The map stops its location updates while the app is in the background.
- Changing units updates only the screens that show units, instead of rebuilding the whole app.
- On Android:
  - The recorder service renews its wake lock every few minutes instead of holding one with no timeout.
  - BLE sensors reconnect with backoff after a connection error.
  - The app declares support for predictive back.
  - The stop-recording dialog lists its buttons in the same order as on iPhone.
- The diagnostics file moved into the app's private folder, which is excluded from device backups. An existing file is moved there on first launch.
- The native iOS and watchOS code builds in Swift 6 language mode, with strict concurrency checks.
- Internal changes:
  - Screens receive their dependencies through their constructors.
  - The BLE clients, dialogs, API requests and diagnostics each share one implementation instead of copies.
  - The largest files are split.
  - The geolocator recorder, used only by tests, moved to test helpers.
- CI changes:
  - Every job has a timeout.
  - Android builds cache Gradle dependencies.
  - Dependabot also updates the Wear OS build.
  - The Flutter version lives in `.flutter-version`, and the coverage exclusions in `.github/coverage-excludes.txt`, each with one source of truth.
  - The Gradle wrapper is checked against its checksum.
  - The iOS workflow pins Flutter to a commit.
  - The `discarded_futures` and `only_throw_errors` lints are on.
- The README says the iOS workflow runs only on pushes to `main` and on manual runs, not on pull requests.

### Fixed

- A Wear OS workout is no longer cut short when Health Services reports a temporary error while the watch app relaunches. The app retries, keeps the saved workout, and does not let a new workout replace it.
- Workouts no longer stay on the watch when a confirmation from the phone was missed. The Wear OS app checks for the phone's confirmations when it launches, and both watch apps accept confirmations from a newer phone app.
- Spoken distances and speeds round the same way on Android and iPhone. For 1.25 km, Android said "1.3 km" and iPhone said "1.2 km".
- On Android, a BLE heart-rate packet whose energy field is cut short is now rejected, as the app's other parser already did.
- On Android, destructive confirmations show their action in the error colour.
- On iPhone, a watch confirmation is no longer lost if the app stops while sending it.
- Health Connect being missing or unavailable is reported as such, not as permission denied.
- A route that fails to load, or a failure while processing the upload queue, is recorded in diagnostics instead of failing silently or as an unhandled error.

### Security

- Release builds pass the signing passwords only to the steps that sign, check out without saved credentials, and attach APKs from a separate job that is the only one allowed to write to the repository.
- Diagnostics redact server hostnames and ids in URL paths, and more credential keys such as `session_id` and `code_verifier`.
- Watch payloads larger than 32 MB are dropped instead of being read into memory. Payloads from a newer watch protocol version stay on the watch until the phone app can read them.

### Removed

- The legacy `NSLocationAlwaysUsageDescription` key on iPhone.
- `android:usesCleartextTraffic` from the Android manifest. The network security config still allows HTTP for self-hosted servers.
- Unused helpers and the Wear OS app's unused `lifecycle-service` dependency.

## [v0.12.1+23] - 2026-11-25

This release fixes how the Wear OS app is built and how the iOS workflow runs. The apps behave the same as in 0.12.0.

### Fixed

- The iOS workflow passes again. Since the Apple Watch app was added, rebuilding the app for the simulator takes about two minutes longer, which pushed the integration-test step past its 12-minute limit while the app was launching. The step now allows 20 minutes, and checks the booted simulator with `xcrun simctl list devices booted` instead of `flutter devices`, whose search for wireless devices took over three minutes on the runner.

### Changed

- The Wear OS app builds with the Kotlin support built into Android Gradle Plugin 9, without the `org.jetbrains.kotlin.android` plugin. Its standalone build no longer sets `android.builtInKotlin=false` and `android.newDsl=false`, which it had copied from the phone build, so it builds without deprecation warnings. The phone build keeps both settings, because the Flutter Gradle plugin still uses the legacy variant API.
- The README says the Wear OS bundle goes on a Wear OS track of the Play listing; Google Play rejects a watch bundle on a phone track.

## [v0.12.0+22] - 2026-11-24

This release adds watch apps for Apple Watch and Wear OS. Each records outdoor workouts on the watch and hands them to Endurain on the phone, which uploads them like any other activity. It also adds an optional countdown before a recording starts, on the phone and on both watches.

### Added

- An Apple Watch app (watchOS 10 or newer), installed with the iPhone app. It records outdoor runs, rides, walks and hikes with GPS, heart rate and distance, and saves each workout and its route to Health. Pausing starts a new track segment.
  - The finished workout is sent to the iPhone in the background, even if the phone is out of range when the workout ends. Endurain stores it as a local activity and uploads it like a workout recorded on the phone.
  - A workout interrupted by a crash or a forced quit is resumed when the app relaunches. If watchOS ended it, the app finishes and sends what was recorded instead.
  - The watch app, its permission prompts included, is available in all the app's languages.
- A Wear OS app (Wear OS 3 or newer), built with Health Services and Compose for Wear OS. It records outdoor runs, rides, walks and hikes with GPS, heart rate and distance, and shows the workout as an ongoing activity on the watch face. Pausing starts a new track segment.
  - The finished workout is sent to the phone over the Wearable Data Layer, which delivers it whenever the devices connect, even if Endurain is not running.
  - A workout interrupted by a killed process is picked up again when the app relaunches. If Health Services ended it, the app finishes and sends what was recorded instead.
  - The Wear OS app is available in all the app's languages. It is a separate build (`android/wear`) published under the same Play listing. GitHub releases attach it as `wear-release.apk`, next to the phone's `app-release.apk`, signed with the same key.
- Phone-side support for companion watch apps. A watch app hands finished workouts to the phone over a platform channel (`endurain/watch_transport`). It is served by a WatchConnectivity bridge on iPhone and a Wearable Data Layer bridge on Android. Each keeps every received workout in a durable inbox until it has been stored.
- A watch session is confirmed back to the watch only once the phone has stored it. These sessions stay queued on the watch instead:
  - sessions that are not finished yet;
  - sessions whose points this app version cannot read;
  - workouts with a duration but no GPS route, such as one recorded with location turned off. The server does not accept a GPX without track points yet.
  - The Apple Watch keeps every workout until the iPhone confirms it, and sends a delivered workout again if the iPhone has not confirmed it within 10 minutes. On Wear OS, a workout the phone never confirmed is dropped from the watch after 90 days, since the phone keeps its own copy.
- Duplicate protection for watch workouts:
  - The app remembers the last 1,000 sessions it received. A session the watch sends again is not uploaded twice, even if its local copy was deleted.
  - Health Sync never offers or imports a workout the Endurain watch app saved to Health, even when it reaches Health before the watch's own transfer arrives. It also skips any HealthKit or Health Connect workout that a received watch session already covers.
- Watch sync runs when the app starts, when it returns to the foreground, and when the watch signals new sessions. Only one sync runs at a time, with one extra pass for sessions that arrive during a sync.
- Local diagnostics breadcrumbs for watch syncs that have pending sessions, and for sessions left on the watch. Builds without a watch record none.
- An optional countdown before a recording starts, to put the phone away or get into the saddle first ([#47](https://github.com/endurain-project/endurain-flutter/issues/47)). Turn it on under Settings → Recording → Start countdown and pick 3, 5, 10, 15 or 30 seconds. It is off by default.
  - The countdown screen shows the seconds left, with buttons to start now, add 10 seconds or cancel.
  - The last three seconds are spoken, followed by "Recording started" once recording begins. The voice can be turned off, and it uses the language and ducking settings of audio announcements.
  - Location updates run during the countdown and are thrown away, so GPS has a fix for the first point. They also keep the app running in the background, so the countdown does not stall:
    - On iPhone, this covers a locked screen.
    - On Android, it runs in the recorder's foreground service, which also covers switching to another app. The recording then starts inside that same service, so it starts on time even with another app in front.
  - Location permission is settled before the countdown starts, so a permission prompt never appears after the phone is put away.
- A start countdown on the Apple Watch and Wear OS apps, set on the watch itself: Off, 3, 5 or 10 seconds. It is off by default.
  - The watch taps the wrist for the last three seconds and once more when recording starts. The countdown screen has Start now and Cancel buttons.
  - The workout session is prepared during the countdown (`HKWorkoutSession.prepare()` on Apple Watch, `prepareExerciseAsync` on Wear OS). This keeps the app running with the wrist lowered and warms up GPS and heart rate. Nothing is recorded or saved until the countdown ends, and cancelling leaves nothing behind.

### Fixed

- A temporary health-platform read error no longer disconnects Health Sync. That covers a rate limit, Health Connect being busy, and a locked iPhone. Since `health` 14 these errors are raised instead of returning an empty list of workouts. Only a permission error now disconnects Health Sync; other read errors are shown without disconnecting.
- Health Sync on iPhone now imports every heart rate reading of a workout, not one value per ~5 minutes ([#39](https://github.com/endurain-project/endurain-flutter/issues/39)). HealthKit stores heart rate from some recordings, such as Apple Workout, as condensed series, and the `health` plugin read each series as a single value. Endurain now reads each workout's readings with `HKQuantitySeriesSampleQuery` over its own platform channel (`endurain/health_heart_rate`), and falls back to the plugin read if that fails.
- A route point now takes the heart rate reading whose time interval covers it, or the nearest reading within 10 seconds (was 5 seconds, measured from the reading's start only). Short gaps between readings no longer leave route points without heart rate, on iPhone and Android.
- The `health.read_workouts` diagnostics breadcrumb now records the number of heart rate readings, where they came from, and how many route points got one. A failed series read records `health.heart_rate_series_failed`.
- **Sign-in:** a storage error during a token refresh no longer signs you out, and a late refresh failure can no longer end a newer sign-in. When the server ends a session, the app switches to guest mode right away. Sign-out errors are shown, and a sign-in no longer reports failure after it succeeded.
- **Uploads:** an expired sign-in no longer leaves pending activities stuck; they upload after the next sign-in. HTTP 408 and 429 are retried. An activity that was already saved is no longer uploaded again after recovery.
- **Recording:**
  - A recording is no longer marked failed when a sensor reading, a pause or an auto-pause arrives at the wrong moment.
  - Tapping Pause during an auto-pause now pauses for real.
  - Long recordings no longer slow the app down over time.
  - On iPhone, a recording continues after iOS terminates the app. Resuming from auto-pause restarts time announcements, and cached or invalid GPS fixes no longer add distance.
  - On Android, a recording interrupted in the background shows a notification and no longer counts the gap as moving time. The recorder no longer starts without location permission, and the GPS warm-up stops when the app is closed during a countdown.
- **Health Sync:**
  - Returning to the app no longer replaces the workout list you are browsing, and a selected workout that cannot be found is reported as failed.
  - On iPhone, back-to-back workouts no longer share GPS routes.
  - A failed heart-rate read no longer imports workouts without heart rate.
  - On Android, loading older workouts stops once Health Connect history access is declined, with a message explaining why, instead of asking again on every page.
- **Sensors:**
  - A Bluetooth sensor that drops out reconnects automatically.
  - Two reconnect attempts at launch no longer cancel each other.
  - Cadence shows 0 while coasting, and stale heart-rate and power readings are no longer recorded on Android.
- **Settings:** Settings shows the current server after signing in to another one.
- **Watches:**
  - The Wear OS app starts a workout when only some permissions are granted.
  - Its workout notification no longer stays up after a restore, and a failed start no longer leaves the exercise running.
  - The Apple Watch no longer creates a duplicate workout when session recovery fails, or loses a point after a crash.
- **Privacy:** diagnostics redact JSON-quoted secrets and bare tokens, and redirects to another server no longer resend request bodies.
- **Android 8:** reading the device's unit system no longer crashes the app on Android 8.x, which lacks the API it used.

### Changed

- Settings is now grouped into sections: Account, General, Recording, Devices & integrations, Data, and Privacy & support. Before, every entry was in one long list.
- The "Keep uploaded GPX files" switch moved from the main Settings list to the top of Settings → Activity history. It is shown even when the history is empty.
- The map tile server URL moved from Settings → Server to its own Settings → Map tiles screen, so the Server screen only shows the account and Log out. The URL is still stored per server, so Map tiles is hidden in guest mode. Signing in again replaces it with the server's tile setting only when the server has one, so a custom URL is no longer cleared by an empty server setting. The URL must contain `{z}`, `{x}` and `{y}`, and only supported placeholders. The map picks up a new URL without restarting.
- On iPhone, recording works with While Using location access. Always access is only needed to continue a recording after iOS terminates the app; switching from Always to While Using mid-recording keeps recording.
- Uploads wait for the server's `Retry-After` (up to a minute) before retrying; a longer wait leaves the activity queued for the next automatic upload.
- Text shown by the system outside the Flutter UI is now translated into all the app's languages: Android notifications and the Health Connect explanation, iPhone permission prompts, and the Wear OS and Apple Watch apps. On Android 13 and newer the app's languages appear in the system's per-app language setting. Devices set to Brazilian Portuguese get the Portuguese text.
- Translations were reviewed in every language. Health Sync and device-access text that had been machine-translated now reads naturally (for example, "Clear" a selection no longer reads as "obvious"), brand names such as Health Connect are no longer translated or transliterated, each language uses one consistent form of address, and second counts use proper plural forms.
- The Android app now includes Google Play Services' Wearable Data Layer (`play-services-wearable`) for the Wear OS link. Builds can leave it out with `--android-project-arg=endurain.wearable=false`; the watch link then reports "unsupported" and nothing else changes. The app still contains `play-services-location`, which `geolocator` already brought in.
- Updated dependencies: `health` 14.0.0, `sentry` 10.6.0 and `flutter_svg` 2.5.0, plus their transitive updates.
- Android builds now use Gradle 9.9.2 and Android Gradle Plugin 9.5.2.
- The CI builder image and workflows use Flutter 3.50.1, on a refreshed Java 25 base image.

## [v0.11.1+21] - 2026-11-24

### Fixed

- Single sign-on now finishes signing in. Flutter's built-in deep linking also handed the SSO callback to the app's router, which sent it to the home screen and closed the login screen before the sign-in could complete. The app now leaves incoming links to `app_links` alone, on Android and iOS.
- Local diagnostics no longer turn themselves off after the app is closed and opened again. Closing the app could interrupt a write of the report, leaving a file the next launch could not read, and the opt-in is stored in that file. The report is now written atomically, so an interrupted write keeps the previous one.

### Added

- A header in the local diagnostics report with the app version, build mode, platform, OS version, and device model, read with `device_info_plus`. The device's name and identifiers are never read into the report.
- More local diagnostics breadcrumbs: each step of a single sign-on, screen changes and router redirects, tab changes, session changes with their reason (signed in, signed out, session ended, unreadable storage), failed token refreshes, failed HTTP requests by endpoint template and status, and every error shown to the user. Failure breadcrumbs now include the error code, HTTP status, and cause instead of only the error type.

### Changed

- The local diagnostics report keeps 150 breadcrumbs instead of 40, and up to 10 errors instead of 8. Consecutive lifecycle changes are folded into one breadcrumb, so a trip to the background no longer pushes out six older entries.
- The diagnostics report format is now version 2, which adds the header.
- Auth, SSO, server settings and API requests share one HTTP client.
- The README documents the `com.endurain.endurain:/auth/sso/callback` address and the diagnostics report's contents.

## [v0.11.0+20] - 2026-11-17

This release requires Endurain server v0.21 or newer, and older app versions cannot sign in to a v0.21 server. If your server sets `ALLOWED_REDIRECT_URIS`, it must include `com.endurain.endurain:/auth/sso/callback` for single sign-on to work.

### Security

- Crash reports sent to Sentry now drop request data, user information, extras and breadcrumbs, and redact event messages and tags, keeping only device, OS, app and runtime context.
- Error text from an SSO sign-in callback is no longer shown to the user, since any app can trigger that deep link. A generic localized error is shown instead, or a specific one when the link carries one of the server's documented failure codes.
- The refresh token is sent in the request body instead of the `Authorization` header, as Endurain v0.21 requires.
- Secure storage is configured with explicit hardened options: Keychain items are available after first unlock and stay on the device, and a transient Android Keystore failure no longer silently erases the stored server and session.

### Fixed

- Remembered heart rate sensors now reconnect reliably on Android. Native Bluetooth addresses are normalized so they match the stored device IDs, and cold starts and returning to the foreground retry the reconnect instead of trying once (#38).
- The configured server URL now survives a secure storage failure or reset thanks to a non-secret mirror. Falling back to the mirror is recorded in diagnostics.
- A missing multi-factor session now shows its own error instead of an unrelated one.
- Activity uploads no longer poll a finished job until they give up and retry, and the app now waits the interval the server asks for between checks.
- Failed uploads and sign-in steps now say why: the file is too large or of an unsupported type, an administrator requires two-step verification the account has not set up, or there were too many sign-in attempts.

### Changed

- Compatibility with Endurain server v0.21: sign-in follows the server's steps (including a second factor after single sign-on), uses the new token exchange route and PKCE form fields, accepts UUID account and provider ids, reads the paged provider list and the renamed public settings route, loads uploaded provider icons, and stores and sends the device id so a sign-in from this app is not reported as a new device each time. Uploads follow the new `/jobs/{id}` API, and an upload refused because the server already has 10 in progress is retried later.
- The single sign-on callback is now `com.endurain.endurain:/auth/sso/callback` on Android and iOS, and the app checks the server allows it before opening the browser. Links to the old `endurain://` address no longer open the app.
- Android release builds no longer need the temporary ProGuard rules. `shared_preferences_android` is now required at 2.5.2 or newer, which ships its own consumer rules.
- Internal restructuring: the app wiring and navigation moved to `lib/app/`, the core services were split into `auth`, `network`, `diagnostics` and `location` packages, and the recording service and map screen were broken into smaller focused components. There are no user-visible changes.
- Stricter lint rules (`avoid_dynamic_calls`, `directives_ordering`, `unnecessary_lambdas`) and sorted imports.
- Updated localized error and health access strings.
- Updated dependencies and raised the minimum to Flutter 3.50.0 (Dart 3.14.0); the CI builder image and workflows use it. Android builds now use Gradle 9.9.1, Android Gradle Plugin 9.5.1 and Kotlin 2.4.21, and the Flutter build image uses Java 25.

### Added

- Activities and health imports saved before the server moved to Endurain v0.21 follow their account to its new id. They are moved silently when the username matches, and the user is asked when it cannot be matched, so queued uploads still go out and no health workout is imported twice.
- A "choose a new password" step at sign-in, for accounts whose password an administrator set.
- Live heart rate from HealthKit during iOS recordings (iOS 26+). Sources such as AirPods Pro 3 now fill heart rate on recorded points; readings from a connected Bluetooth sensor still take priority (#23).
- On-device login flow smoke tests (`integration_test/`), run in CI on an Android emulator and an iOS simulator, plus Dependabot configuration.
- Unit tests for the recording clock, permission gate and sensor session.

## [v0.10.2+19] - 2026-10-21

### Fixed

- Wrong max speed and pace spikes (#11). GPS fixes that imply a speed the activity cannot reach (for example 80 km/h while running), including a poor first fix after a pause, are now dropped before the GPX is uploaded and before on-device stats are computed. Max speed is also taken from a short median window so a single glitch can no longer set it.
- Android release builds getting stuck on a blank splash screen at launch, and language, units, audio and sensor settings failing to load. R8 minification renamed the Kotlin classes that `shared_preferences_android` 2.5 (introduced with v0.10.0) looks up by name over JNI, so every preferences read failed (flutter/flutter#194649). ProGuard rules now keep those classes (temporary, until `shared_preferences_android` 2.5.2 ships its own), a failing or stalled crash-reporting start can no longer prevent the app from starting, and launch no longer waits on the network to confirm a stored session: the session is restored immediately and verified in the background.
- The app no longer hangs on the splash screen when secure storage cannot be read at launch. It starts in guest mode and restores the signed-in session when the storage becomes readable again. Signing in recovers from an unusable store (for example an invalidated Android Keystore key), logout still clears local data when the stored session cannot be read, and queued activity uploads retry instead of failing (#27).

### Changed

- Stronger elevation smoothing (9-sample median, 21-sample moving average) for the elevation gain shown on the device, matching the updated Endurain server so both report the same value (#17).

## [v0.10.1+18] - 2026-10-20

### Fixed

- Added vertical padding to iOS list tiles with subtitles so wrapped subtitle text no longer touches the top and bottom edges (for example in Audio Announcements settings).

## [v0.10.0+17] - 2026-10-20

### Added

- Auto-pause and auto-resume for recordings. Recording pauses automatically when you stop moving and resumes when you start again, with a configurable delay and optional audio announcements (localized).

### Changed

- Compatibility with Endurain v0.20.0: uploads now wait for the server to finish importing the activity before marking it as uploaded, so failed imports are no longer reported as successful. Import errors are shown as localized messages.
- Updated dependencies, including `sentry` 10.1.0 and `universal_ble` 3.1.0.

## [v0.9.2+16] - 2026-10-07

### Fixed

- Reconnect to active native recordings after reopening the app without pausing them or creating a replacement activity. Restart interrupted collection within the same session and keep explicit pauses unchanged.
- Preserve recordings before their first GPS fix and after recorder failures. Failed recordings require an explicit stop before saving or uploading, and remain available for resume or discard.
- Replay persisted and live GPS points once using session-scoped offsets, retain connection ownership, and support retrying local finalization without replacing the recording.
- Preserve captured iOS heart-rate, power, and cadence readings across recording relaunches using a session-scoped durable sensor log.
- Reject unsuccessful iOS recording-state writes instead of acknowledging failed start, pause, resume, or stop transitions.

### Changed

- Show Resume and Stop controls for recoverable failed recordings, and allow the stop confirmation (save or discard) to open for them.
- Updated `cupertino_icons` to 2.0.0, refreshed locked dependencies, and bumped `actions/upload-artifact` to v7.0.2 in the Android APK workflow.
- Added Robolectric-based Android native recorder tests, expanded iOS recorder tests, and documented the active recording recovery contract and manual relaunch QA in the README.

## [v0.9.1+15] - 2026-09-11

### Fixed

- Corrected distance announcement interval options and snapping so 0.5 is available instead of 0.6.
- Prevented an audio announcement preview crash when no `ScaffoldMessenger` is available.
- Aligned Flutter and Dart versions to Flutter 3.47.3 and Dart 3.13.3 across the app, Docker builder, and CI workflows.

## [v0.9.0+14] - 2026-09-04

### Added

- Added configurable activity auto-pause and auto-resume with movement detection, resume hysteresis, and process-recovery support.
- Added localized, on-device audio announcements for distance or elapsed-time milestones during foreground and background activity recording, including distance, duration, lap plus overall pace or speed, and automatic pause or resume cues.
- Added audio announcement settings with a master switch, per-activity enablement and distance/time intervals, metric/imperial defaults, optional audio ducking, and an audible per-activity preview.
- Added durable milestone tracking and privacy-safe native failure logging so delayed updates and recorder restarts do not replay stale milestones, while speech failures cannot interrupt activity recording.
- Added a contributor license agreement, pull request attestation, and required-status workflow for relicensing rights over accepted external contributions.

## [v0.8.2+13] - 2026-08-30

### Fixed

- Unified the duration shown in completion, history, and activity details, and calculated running pace from total time over distance.
- Kept the HealthKit connection marker device-local so restored preferences cannot be mistaken for authorization on another device.

### Changed

- Moved the "keep uploaded GPX files" and health auto-sync settings out of the platform keychain into the regular preference store. These two preferences reset to their defaults once on upgrade.
- Updated `go_router` to 18.0.0, `material_ui` to 1.1.0, `cupertino_ui` to 1.0.1, and `androidx.core:core-ktx` to 1.19.0.

### Security

- Added build-time managed-cloud HTTPS policy and tile-server host allowlist configuration, with Android and iOS transport-policy parity checks.

## [v0.8.1+12] - 2026-08-26

### Fixed

- Activity metrics calculations, including elevation, speed, and average speed, with expanded test coverage.

### Changed

- Updated `flutter_secure_storage` to 11.0.0 and adjusted Android SDK compile options accordingly.
- Updated the Android Gradle Plugin to 9.1.1 and the Android platform/`compileSdk` version, with related Dockerfile updates for additional platform support.

## [v0.8.0+11] - 2026-08-21

### Changed

- Upgraded to Flutter 3.47.x and migrated the adaptive UI layer to the `material` and `cupertino` design libraries.
- Updated localization delegates and test imports to match the migration.
- Removed the unused `Podfile` and related CocoaPods configuration.
- Cleaned up build configuration, dependencies, and Dockerfile comments/directory naming.

### Fixed

- `flutter_secure_storage_darwin` checksum in `Podfile.lock`.
- Release tagging logic in the CI workflow.

## [v0.7.3+10] - 2026-08-12

### Fixed

- Diagnostics remote-enable subtitle localization consistency across languages.

### Changed

- Added `.dockerignore` and updated the CI workflow to respect it.

## [v0.7.2+9] - 2026-08-12

### Added

- `AdaptiveListTileSubtitle` widget for consistent subtitle styling in adaptive list tiles.
- `DeviceMeasurementSystemChannel` for locale-based measurement system (metric/imperial) resolution.

### Fixed

- Device measurement system service integration with app infrastructure.

## [v0.7.1+8] - 2026-08-11

### Added

- Imperial units support.
- CI workflows for validating Conventional Commits and building the CI Docker image.
- `FUNDING.yml`.
- GitLab mirror workflow for repository synchronization.

### Fixed

- Recording blockers preventing activity recording in certain conditions (#14).
- Missing `ITSAppUsesNonExemptEncryption` key and unclear HealthKit usage description in `Info.plist`.
- GitHub repository/GPX documentation links after migrating the project from Codeberg to GitHub.

### Changed

- Updated Android build configuration and Dockerfile for improved compatibility.
- Migrated project URLs and localization strings from Codeberg to GitHub.

## [v0.7.0+7] - 2026-07-23

### Added

- Remote crash diagnostics with opt-in reporting (#13).

## [v0.6.0+6] - 2026-07-21

### Added

- Recording of power and cadence from external Bluetooth sensors (#12).

## [v0.5.2+5] - 2026-07-20

### Added

- Health Connect permissions and enhanced health data handling.

## [v0.5.1+4] - 2026-07-19

### Added

- Autofill support in the login form.

## [v0.5.0+3] - 2026-07-17

### Added

- Bluetooth heart rate sensor support (#11).

## [v0.4.0+2] - 2026-07-15

### Added

- Richer post-recording activity summary, persisted metrics, and route map (#10).

### Fixed

- `apksigner` path resolution using `ANDROID_SDK_ROOT` in the Android release workflow.

## [v0.3.0+1] - 2026-07-14

### Added

- Health data integration (read/write) with permission handling.
- Regression tests for Android 15 edge-to-edge enforcement in `AdaptiveScaffold`.
- Guest recordings now bind to the active connection on sign-in.

### Changed

- Modernized the Android CI pipeline and enhanced the Android release workflow with version inputs and signing checks (#9).

### Fixed

- CI runner memory tuning for build stability.
- Profile fetch retry after PKCE token exchange.

## [v0.2.0] - 2026-06-29

### Added

- Language selection with locale persistence, including European Portuguese and additional language support.
- Offline guest mode and session management.
- Diagnostics on/off switch with translations.
- Comprehensive tests for map features and settings.

### Changed

- `CupertinoListSection` now uses a transparent background.

## [v0.1.0] - 2026-06-01

### Added

- Core activity recording: GPS tracking, stats calculation, GPX generation, and direct upload to the Endurain server.
- Background location tracking during recording, including low-accuracy fix filtering on Android.
- Local SQLite-backed activity store (`SqfliteActivityStore`) with pagination, migration from the legacy manifest format, and schema versioning.
- Durable upload recovery with retry and idempotency handling, including automatic retries on app resume and network restoration.
- GPX export/share for recorded activities.
- Diagnostics screen with local report sections.
- Adaptive UI components (Material/Cupertino) for cross-platform consistency.
- Managed transport policy: rejects insecure HTTP and validates tile-server/API hosts in managed deployments.
- CI workflows for automated builds, Android APK signing, and a prebuilt Docker builder image.

### Fixed

- Distance creep across paused recording segments in `ActivityStatsCalculator`.
- Various secure storage, refresh-token, and Android provider-disabled recording edge cases.
- iOS share sheet position origin for the GPX share sheet.

### Security

- Bound `ApiResponse.errorDetail` to prevent arbitrary server text from being rendered in the UI.
- Single-flight refresh token mechanism in `AuthService`.

## [v0.0.1] - 2025-12-11

### Added

- Initial Flutter mobile app scaffold for Endurain, including SSO/PKCE authentication, server settings, and README documentation.
