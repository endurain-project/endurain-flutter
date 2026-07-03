import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_ca.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gl.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_it.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
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
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Generic error title - Used in: dialog_utils.dart
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// OK button label - Used in: dialog_utils.dart
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Cancel button label - Used in: dialog_utils.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button label - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Back button label - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Validation message for required fields - Used in: validators.dart
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// Validation message for invalid URL - Used in: validators.dart
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get invalidUrl;

  /// Generic activity upload error - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not upload activity'**
  String get errorActivityUploadFailed;

  /// Activity upload error with safe status details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not upload activity: {details}'**
  String errorActivityUploadFailedWithDetails(String details);

  /// Activity upload blocked because endpoint and multipart field are not configured - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Activity upload is not configured yet'**
  String get errorActivityUploadNotConfigured;

  /// Activity GPX temporary file cleanup error without exposing file paths - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not delete the temporary activity file'**
  String get errorActivityGpxCleanupFailed;

  /// Activity GPX temporary file write error without exposing file paths - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the activity upload file'**
  String get errorActivityGpxFileWriteFailed;

  /// Local activity record not found error without exposing storage details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not find this local activity'**
  String get errorActivityLocalActivityNotFound;

  /// Local activity delete error without exposing file paths - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not delete the local activity'**
  String get errorActivityLocalDeleteFailed;

  /// Local activity GPX missing error without exposing file paths - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'The local GPX file is not available'**
  String get errorActivityLocalGpxMissing;

  /// Local activity load error without exposing file paths - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not load local activities'**
  String get errorActivityLocalLoadFailed;

  /// Local activity metadata validation error - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not save this activity'**
  String get errorActivityLocalRecordInvalid;

  /// Local activity save error without exposing file paths - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not save the activity locally'**
  String get errorActivityLocalSaveFailed;

  /// Generic sign-in provider loading error - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not load sign-in providers'**
  String get errorFetchProvidersFailed;

  /// Sign-in provider loading error with server details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not load sign-in providers: {details}'**
  String errorFetchProvidersFailedWithDetails(String details);

  /// Generic server settings loading error - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not load server settings'**
  String get errorFetchServerSettingsFailed;

  /// Server settings loading error with server details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not load server settings: {details}'**
  String errorFetchServerSettingsFailedWithDetails(String details);

  /// Generic login error - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not sign in'**
  String get errorLoginError;

  /// Login error with technical details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not sign in: {details}'**
  String errorLoginErrorWithDetails(String details);

  /// Generic login failure - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get errorLoginFailed;

  /// Login failure with server details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {details}'**
  String errorLoginFailedWithDetails(String details);

  /// Generic MFA verification error - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not verify MFA code'**
  String get errorMfaVerificationError;

  /// MFA verification error with technical details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not verify MFA code: {details}'**
  String errorMfaVerificationErrorWithDetails(String details);

  /// Generic MFA verification failure - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'MFA verification failed'**
  String get errorMfaVerificationFailed;

  /// MFA verification failure with server details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'MFA verification failed: {details}'**
  String errorMfaVerificationFailedWithDetails(String details);

  /// Error when auth succeeds without session ID - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'No session ID was received from the server'**
  String get errorNoSessionIdReceived;

  /// Error when an authenticated request has no token - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'You are not signed in'**
  String get errorNotAuthenticated;

  /// Error when PKCE verifier is missing - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'The sign-in verifier was not found'**
  String get errorPkceVerifierMissing;

  /// Recoverable PKCE error asking user to restart login - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'The sign-in verifier was not found. Please start sign-in again.'**
  String get errorPkceVerifierMissingRestartLogin;

  /// Error when no server URL is configured - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Server URL is not configured'**
  String get errorServerUrlNotConfigured;

  /// Error when an http:// URL is used for an origin that requires HTTPS (the Endurain Cloud origin) - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'This server requires a secure (HTTPS) connection'**
  String get errorInsecureTransportNotAllowed;

  /// Error when token refresh fails - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get errorSessionExpired;

  /// Generic SSO token exchange error - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not complete SSO sign-in'**
  String get errorSsoTokenExchangeError;

  /// SSO token exchange error with technical details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Could not complete SSO sign-in: {details}'**
  String errorSsoTokenExchangeErrorWithDetails(String details);

  /// Generic token exchange failure - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Token exchange failed'**
  String get errorTokenExchangeFailed;

  /// Token exchange failure with server details - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Token exchange failed: {details}'**
  String errorTokenExchangeFailedWithDetails(String details);

  /// Error shown when an API request or upload exceeds the time limit - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Check your connection and try again.'**
  String get errorRequestTimeout;

  /// Error shown when the platform keychain or secure storage fails to delete - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Unable to delete from secure storage. Your device storage may be unavailable.'**
  String get errorSecureStorageDeleteFailed;

  /// Error shown when the platform keychain or secure storage fails to read (distinct from a missing key) - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Unable to read from secure storage. Your device storage may be unavailable.'**
  String get errorSecureStorageReadFailed;

  /// Error shown when the platform keychain or secure storage fails to write - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Unable to write to secure storage. Your device storage may be unavailable.'**
  String get errorSecureStorageWriteFailed;

  /// Error for unsupported API response shape - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'The server returned an unexpected response'**
  String get errorUnexpectedResponseFormat;

  /// Error for unsupported HTTP method - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Unsupported HTTP method'**
  String get errorUnsupportedHttpMethod;

  /// Unsupported HTTP method error with method name - Used in: error_localizations.dart
  ///
  /// In en, this message translates to:
  /// **'Unsupported HTTP method: {details}'**
  String errorUnsupportedHttpMethodWithDetails(String details);

  /// Title for login screen
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button label - Used in: settings_screen.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation dialog title - Used in: dialog_utils.dart (via server_settings_screen)
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// Logout confirmation dialog message - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// Warning shown when server logout fails but local logout succeeds - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Could not logout from server, but logged out locally'**
  String get logoutServerFailedWarning;

  /// Error shown when SSO system browser launch fails - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Could not open SSO sign-in in the system browser'**
  String get ssoBrowserLaunchFailed;

  /// Error shown when the SSO callback URL lacks a session_id - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'SSO callback did not include a session ID'**
  String get ssoMissingSessionId;

  /// SSO provider button label - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider}'**
  String ssoSignInWith(String provider);

  /// Divider text between SSO and traditional login - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get ssoOrDivider;

  /// Next button label for multi-step flows - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Username field label - Used in: login_screen.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Username field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// Password field label - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Show/hide password toggle label
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// MFA screen title
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get mfaTitle;

  /// MFA code field label
  ///
  /// In en, this message translates to:
  /// **'MFA code'**
  String get mfaCode;

  /// MFA code field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get mfaCodeHint;

  /// MFA code validation error message
  ///
  /// In en, this message translates to:
  /// **'Please enter MFA code'**
  String get mfaCodeRequired;

  /// MFA verification button label
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Discard activity button label - Used in: activity_stop_confirmation_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get activityDiscard;

  /// Discard activity confirmation message - Used in: activity_stop_confirmation_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'This will delete the recorded points for this activity.'**
  String get activityDiscardConfirmMessage;

  /// Discard activity confirmation dialog title - Used in: activity_stop_confirmation_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'Discard activity?'**
  String get activityDiscardConfirmTitle;

  /// Recording error shown when location permission is denied - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to record an activity.'**
  String get activityLocationPermissionDenied;

  /// Recording error shown when location permission is permanently denied - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Open settings to allow location access.'**
  String get activityLocationPermissionDeniedForever;

  /// Recording error shown when device location services are disabled - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get activityLocationServiceDisabled;

  /// Recording error shown when GPS stream fails - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Location updates stopped unexpectedly.'**
  String get activityLocationStreamFailed;

  /// Recording error shown when GPX generation fails after stopping - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Could not create the activity GPX file.'**
  String get activityGpxGenerationFailed;

  /// Recording error shown when retained local activity storage fails - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Could not save this activity on this device.'**
  String get activityLocalSaveFailed;

  /// Button label to open app settings for location permission - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get activityOpenSettings;

  /// Pause recording button label and tooltip - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get activityPause;

  /// Recording error shown when stopping without GPS points - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'No GPS points were recorded.'**
  String get activityRecordingEmpty;

  /// Fallback recording error message - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Recording failed.'**
  String get activityRecordingFailed;

  /// Resume recording button label and tooltip - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get activityResume;

  /// Retry activity upload button label - Used in: activity_upload_status_panel.dart, activity_history_screen.dart, activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get activityRetryUpload;

  /// Non-destructive completion action after an activity is retained locally - Used in: activity_upload_status_panel.dart
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get activityDone;

  /// Action to open local activity history - Used in: activity_upload_status_panel.dart
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get activityViewHistory;

  /// Destructive action for deleting a retained local activity and GPX - Used in: activity_upload_status_panel.dart, map_screen.dart, activity_history_screen.dart, activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Delete local copy'**
  String get activityDeleteLocal;

  /// Action that opens the OS share sheet with the activity GPX file. Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Share GPX file'**
  String get activityExportGpx;

  /// Subject line used when sharing a GPX file. Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Endurain activity GPX'**
  String get activityExportGpxSubject;

  /// Confirmation dialog title for deleting a retained local activity - Used in: map_screen.dart, activity_history_screen.dart, activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Delete local activity?'**
  String get activityDeleteLocalConfirmTitle;

  /// Confirmation dialog message for deleting a retained local activity - Used in: map_screen.dart, activity_history_screen.dart, activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'This removes the local activity record and GPX file from this device.'**
  String get activityDeleteLocalConfirmMessage;

  /// Start recording button label and tooltip - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get activityStart;

  /// Dialog title explaining why background location is required before recording - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Allow background tracking?'**
  String get activityBackgroundPermissionTitle;

  /// Dialog message explaining why background location is required before recording - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Endurain needs background location set to Always so recording continues when the app is in the background, the screen is locked, or you switch apps.'**
  String get activityBackgroundPermissionMessage;

  /// Dialog action to continue with the background location permission request - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get activityBackgroundPermissionContinue;

  /// Recording error shown when Apple background permission is not strong enough for uninterrupted tracking - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Background tracking on iPhone and iPad needs Location set to Always.'**
  String get activityBackgroundPermissionRequired;

  /// Dialog title shown when the user needs to open settings to enable Always location - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Background tracking is off'**
  String get activityBackgroundPermissionSettingsTitle;

  /// Dialog message shown when the user needs to open settings to enable Always location - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'To record reliably in the background or with the screen locked, open Settings and set Location to Always for Endurain.'**
  String get activityBackgroundPermissionSettingsMessage;

  /// Title of the persistent notification shown while tracking continues in the background - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Recording activity'**
  String get activityTrackingNotificationTitle;

  /// Body of the persistent notification shown while tracking continues in the background - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Endurain is tracking your location to record this activity.'**
  String get activityTrackingNotificationText;

  /// Recording stats distance label - Used in: activity_stats_display.dart
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get activityStatDistance;

  /// Recording stats duration label - Used in: activity_stats_display.dart
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get activityStatDuration;

  /// Recording stats speed label - Used in: activity_stats_display.dart
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get activityStatSpeed;

  /// Stop recording button label and tooltip - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get activityStop;

  /// Stop and keep activity button label - Used in: activity_stop_confirmation_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'Stop and save'**
  String get activityStopAndSave;

  /// Stop activity confirmation message - Used in: activity_stop_confirmation_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'Choose whether to keep this recording or discard it.'**
  String get activityStopConfirmMessage;

  /// Stop activity confirmation dialog title - Used in: activity_stop_confirmation_dialog.dart
  ///
  /// In en, this message translates to:
  /// **'End activity?'**
  String get activityStopConfirmTitle;

  /// Disabled stop button label while a recording is stopping - Used in: activity_recording_controls.dart
  ///
  /// In en, this message translates to:
  /// **'Stopping'**
  String get activityStopping;

  /// Activity type label for hiking - Used in: activity_type_picker.dart
  ///
  /// In en, this message translates to:
  /// **'Hike'**
  String get activityTypeHike;

  /// Dropdown label for selecting the activity type before recording - Used in: activity_type_picker.dart
  ///
  /// In en, this message translates to:
  /// **'Activity type'**
  String get activityTypeLabel;

  /// Activity type label for uncategorized activities - Used in: activity_type_picker.dart
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get activityTypeOther;

  /// Activity type label for cycling - Used in: activity_type_picker.dart
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get activityTypeRide;

  /// Activity type label for running - Used in: activity_type_picker.dart
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get activityTypeRun;

  /// Activity type label for walking - Used in: activity_type_picker.dart
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get activityTypeWalk;

  /// Activity upload failed status label - Used in: activity_upload_status_panel.dart
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get activityUploadFailed;

  /// Activity upload status shown when the server upload succeeded but temporary GPX cleanup failed - Used in: activity_upload_status_panel.dart
  ///
  /// In en, this message translates to:
  /// **'Uploaded, but cleanup failed'**
  String get activityUploadCleanupFailed;

  /// Activity upload pending status label - Used in: activity_upload_status_panel.dart
  ///
  /// In en, this message translates to:
  /// **'Ready to upload'**
  String get activityUploadReady;

  /// Activity uploaded status label - Used in: activity_upload_status_panel.dart
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get activityUploaded;

  /// Activity uploading status label - Used in: activity_upload_status_panel.dart
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get activityUploading;

  /// Local activity upload status label - Used in: activity_history_screen.dart, activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get activityUploadStatusPending;

  /// Local activity uploaded status label - Used in: activity_history_screen.dart, activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get activityUploadStatusUploaded;

  /// Local activity failed upload status label - Used in: activity_history_screen.dart, activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get activityUploadStatusFailed;

  /// Local activity history screen title and settings navigation label - Used in: activity_history_screen.dart, settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Activity history'**
  String get activityHistoryTitle;

  /// Settings subtitle for local activity history - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Completed activities saved on this device'**
  String get activityHistorySettingsSubtitle;

  /// Settings switch label for local uploaded GPX retention - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Keep uploaded GPX files'**
  String get activityRetainUploadedGpx;

  /// Settings switch subtitle explaining private local GPX retention - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Stores completed route files in private app storage after upload.'**
  String get activityRetainUploadedGpxSubtitle;

  /// Empty state for local activity history - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'No completed activities saved on this device.'**
  String get activityHistoryEmpty;

  /// Load failure state for local activity history - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Could not load local activities.'**
  String get activityHistoryLoadFailed;

  /// Refresh action for local activity history - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get activityHistoryRefresh;

  /// List section header for retained local activities - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Local activities'**
  String get activityHistoryLocalActivities;

  /// Local activity list item title - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'{activityType} • {endedAt}'**
  String activityHistoryEntryTitle(String activityType, String endedAt);

  /// Local activity list duration line - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String activityHistoryDuration(String duration);

  /// Local activity list distance line - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance}'**
  String activityHistoryDistance(String distance);

  /// Local activity list upload status line - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Upload: {status}'**
  String activityHistoryUploadStatus(String status);

  /// Button to load the next page of activities in the history list - Used in: activity_history_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get activityHistoryLoadMore;

  /// Local activity details screen title - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Activity details'**
  String get activityHistoryDetailsTitle;

  /// Missing local activity details state - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'This local activity is no longer available.'**
  String get activityHistoryDetailsMissing;

  /// Local activity details summary section header - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get activityHistorySummary;

  /// Local activity details actions section header - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get activityHistoryActions;

  /// Local activity details type label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get activityHistoryType;

  /// Local activity details started time label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get activityHistoryStartedAt;

  /// Local activity details ended time label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get activityHistoryEndedAt;

  /// Local activity details duration label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get activityHistoryDurationLabel;

  /// Local activity details distance label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get activityHistoryDistanceLabel;

  /// Local activity details average speed label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get activityHistoryAverageSpeed;

  /// Local activity details point count label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'GPS points'**
  String get activityHistoryPointCount;

  /// Local activity details upload status label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get activityHistoryUploadStatusLabel;

  /// Local activity details GPX availability label - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'GPX file'**
  String get activityHistoryGpxStatus;

  /// Local activity details GPX available status - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get activityHistoryGpxAvailable;

  /// Local activity details GPX missing status - Used in: activity_details_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get activityHistoryGpxMissing;

  /// Map tab label - Used in: app_bottom_nav.dart
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// Tooltip for the map button that centers on the user's location - Used in: map_screen.dart
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// Settings tab label - Used in: app_bottom_nav.dart
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// Settings screen title - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreen;

  /// Language settings entry and screen title - Used in: settings_screen.dart, language_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language option that follows the device locale - Used in: settings_screen.dart, language_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Server settings navigation label - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverSettings;

  /// Settings entry shown in offline guest mode to sign in / connect a server - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInConnectServer;

  /// Subtitle for the offline guest sign-in entry - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Record offline now and sync your activities later'**
  String get signInConnectServerSubtitle;

  /// Server settings screen title - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get serverSettingsTitle;

  /// Logged in section header - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get loggedIn;

  /// Fallback shown when server settings have no configured value - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// Fallback shown when no username is stored - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// Server URL field label - Used in: login_screen.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// Server URL field hint text - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get serverUrlHint;

  /// Warning dialog title shown when user enters an http:// server URL - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Insecure connection'**
  String get warnHttpServerUrlTitle;

  /// Warning dialog body when user enters an http:// server URL - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'This server URL uses plain HTTP. Your login credentials and data will be transmitted without encryption. Continue only if you understand and accept the risk.'**
  String get warnHttpServerUrlMessage;

  /// Confirm button for the HTTP server URL warning dialog - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get warnHttpServerUrlConfirm;

  /// Tile server URL field label - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Map tile server URL'**
  String get tileServerUrl;

  /// Tile server URL field hint text
  ///
  /// In en, this message translates to:
  /// **'https://tile.openstreetmap.org/...'**
  String get tileServerUrlHint;

  /// Title for tile server host mismatch warning dialog - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Different tile server host'**
  String get tileServerHostWarningTitle;

  /// Body of tile server host mismatch warning dialog - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'The tile server host is different from your Endurain server host. Tiles will be loaded from a third-party server. Do you want to continue?'**
  String get tileServerHostWarningMessage;

  /// Settings save success message - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get savedSuccessfully;

  /// Diagnostics settings navigation label - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// Diagnostics settings navigation subtitle - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Local crash context'**
  String get diagnosticsSubtitle;

  /// Settings entry that opens the project's public source repository - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// Subtitle showing the destination of the source code entry; the repository host is not translated - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'codeberg.org/endurain-project'**
  String get sourceCodeSubtitle;

  /// Error shown when an external link cannot be opened in the browser - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get openLinkFailed;

  /// Diagnostics screen title - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// Empty state for diagnostics report - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'No diagnostics have been captured yet.'**
  String get diagnosticsEmpty;

  /// Copy diagnostics report button label - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get diagnosticsCopy;

  /// Message shown after copying diagnostics report - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied'**
  String get diagnosticsCopied;

  /// Clear diagnostics report button label - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get diagnosticsClear;

  /// Message shown after clearing diagnostics report - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Diagnostics cleared'**
  String get diagnosticsCleared;

  /// Diagnostics summary section header - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get diagnosticsSummary;

  /// Diagnostics last updated label - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get diagnosticsLastUpdated;

  /// Diagnostics event count label - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Events: {count}'**
  String diagnosticsEventsCount(int count);

  /// Diagnostics error count label - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Errors: {count}'**
  String diagnosticsErrorsCount(int count);

  /// Diagnostics events section header - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get diagnosticsEvents;

  /// Diagnostics empty events row - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'No events captured'**
  String get diagnosticsNoEvents;

  /// Diagnostics event row title - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Event: {event}'**
  String diagnosticsEventTitle(String event);

  /// Diagnostics errors section header - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get diagnosticsErrors;

  /// Diagnostics error row title - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Error: {type}'**
  String diagnosticsErrorTitle(String type);

  /// Diagnostics actions section header - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get diagnosticsActions;

  /// Diagnostics raw report section header - Used in: diagnostics_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Raw report'**
  String get diagnosticsRawReport;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bg',
    'ca',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gl',
    'hr',
    'hu',
    'it',
    'lt',
    'lv',
    'nb',
    'nl',
    'pl',
    'pt',
    'ro',
    'sk',
    'sl',
    'sr',
    'sv',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'ca':
      return AppLocalizationsCa();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'gl':
      return AppLocalizationsGl();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'it':
      return AppLocalizationsIt();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'nb':
      return AppLocalizationsNb();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'sk':
      return AppLocalizationsSk();
    case 'sl':
      return AppLocalizationsSl();
    case 'sr':
      return AppLocalizationsSr();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
