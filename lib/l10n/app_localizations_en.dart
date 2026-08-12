// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidUrl => 'Please enter a valid URL';

  @override
  String get errorActivityUploadFailed => 'Could not upload activity';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Could not upload activity: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Activity upload is not configured yet';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Could not delete the temporary activity file';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Could not prepare the activity upload file';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Could not find this local activity';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Could not delete the local activity';

  @override
  String get errorActivityLocalGpxMissing =>
      'The local GPX file is not available';

  @override
  String get errorActivityLocalLoadFailed => 'Could not load local activities';

  @override
  String get errorActivityLocalRecordInvalid => 'Could not save this activity';

  @override
  String get errorActivityLocalSaveFailed =>
      'Could not save the activity locally';

  @override
  String get errorFetchProvidersFailed => 'Could not load sign-in providers';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Could not load sign-in providers: $details';
  }

  @override
  String get errorFetchServerSettingsFailed => 'Could not load server settings';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Could not load server settings: $details';
  }

  @override
  String get errorHealthGpxBuildFailed => 'Could not convert workout to GPX';

  @override
  String get errorHealthImportFailed => 'Could not import workout';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Could not import workout: $details';
  }

  @override
  String get errorHealthPermissionDenied => 'Health data access was denied';

  @override
  String get errorHealthReadFailed => 'Could not read health data';

  @override
  String get errorLoginError => 'Could not sign in';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Could not sign in: $details';
  }

  @override
  String get errorLoginFailed => 'Sign-in failed';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Sign-in failed: $details';
  }

  @override
  String get errorMfaVerificationError => 'Could not verify MFA code';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Could not verify MFA code: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA verification failed';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA verification failed: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'No session ID was received from the server';

  @override
  String get errorNotAuthenticated => 'You are not signed in';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'The sign-in verifier was not found. Please start sign-in again.';

  @override
  String get errorServerUrlNotConfigured => 'Server URL is not configured';

  @override
  String get errorInsecureTransportNotAllowed =>
      'This server requires a secure (HTTPS) connection';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get errorSsoTokenExchangeError => 'Could not complete SSO sign-in';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Could not complete SSO sign-in: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Token exchange failed';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Token exchange failed: $details';
  }

  @override
  String get errorRequestTimeout =>
      'The request timed out. Check your connection and try again.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Unable to delete from secure storage. Your device storage may be unavailable.';

  @override
  String get errorSecureStorageReadFailed =>
      'Unable to read from secure storage. Your device storage may be unavailable.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Unable to write to secure storage. Your device storage may be unavailable.';

  @override
  String get errorUnexpectedResponseFormat =>
      'The server returned an unexpected response';

  @override
  String get errorUnsupportedHttpMethod => 'Unsupported HTTP method';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Unsupported HTTP method: $details';
  }

  @override
  String get loginTitle => 'Login';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout?';

  @override
  String get logoutServerFailedWarning =>
      'Could not logout from server, but logged out locally';

  @override
  String get ssoBrowserLaunchFailed =>
      'Could not open SSO sign-in in the system browser';

  @override
  String ssoSignInWith(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String get ssoOrDivider => 'OR';

  @override
  String get next => 'Next';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get showPassword => 'Show password';

  @override
  String get mfaTitle => 'Two-Factor Authentication';

  @override
  String get mfaCode => 'MFA code';

  @override
  String get mfaCodeHint => 'Enter 6-digit code';

  @override
  String get mfaCodeRequired => 'Please enter MFA code';

  @override
  String get verify => 'Verify';

  @override
  String get activityDiscard => 'Discard';

  @override
  String get activityDiscardConfirmMessage =>
      'This will delete the recorded points for this activity.';

  @override
  String get activityDiscardConfirmTitle => 'Discard activity?';

  @override
  String get activityLocationPermissionDenied =>
      'Location permission is required to record an activity.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Location permission is blocked. Open settings to allow location access.';

  @override
  String get activityLocationServiceDisabled =>
      'Location services are disabled.';

  @override
  String get activityLocationStreamFailed =>
      'Location updates stopped unexpectedly.';

  @override
  String get activityGpxGenerationFailed =>
      'Could not create the activity GPX file.';

  @override
  String get activityLocalSaveFailed =>
      'Could not save this activity on this device.';

  @override
  String get activityOpenSettings => 'Open settings';

  @override
  String get activityPause => 'Pause';

  @override
  String get activityRecordingEmpty => 'No GPS points were recorded.';

  @override
  String get activityRecordingFailed => 'Recording failed.';

  @override
  String get activityResume => 'Resume';

  @override
  String get activityRetryUpload => 'Retry upload';

  @override
  String get activityDone => 'Done';

  @override
  String get activityViewHistory => 'View history';

  @override
  String get activityDeleteLocal => 'Delete local copy';

  @override
  String get activityExportGpx => 'Share GPX file';

  @override
  String get activityExportGpxSubject => 'Endurain activity GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Delete local activity?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'This removes the local activity record and GPX file from this device.';

  @override
  String get activityStart => 'Start';

  @override
  String get activityBackgroundPermissionTitle => 'Allow background tracking?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain needs background location set to Always so recording continues when the app is in the background, the screen is locked, or you switch apps.';

  @override
  String get activityBackgroundPermissionContinue => 'Continue';

  @override
  String get activityBackgroundPermissionRequired =>
      'Background tracking on iPhone and iPad needs Location set to Always.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Background tracking is off';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'To record reliably in the background or with the screen locked, open Settings and set Location to Always for Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Recording activity';

  @override
  String get activityTrackingNotificationText =>
      'Endurain is tracking your location to record this activity.';

  @override
  String get activityStatDistance => 'Distance';

  @override
  String get activityStatDuration => 'Time';

  @override
  String get activityStatSpeed => 'Speed';

  @override
  String get activityStatPace => 'Pace';

  @override
  String get activityStatMaxSpeed => 'Max speed';

  @override
  String get activityStatElevationGain => 'Elevation gain';

  @override
  String get activityStatHeartRate => 'Heart rate';

  @override
  String get activityStatAvgHeartRate => 'Avg heart rate';

  @override
  String get activityStatPower => 'Power';

  @override
  String get activityStatAvgPower => 'Avg power';

  @override
  String get activityStatCadence => 'Cadence';

  @override
  String get activityStatAvgCadence => 'Avg cadence';

  @override
  String get activityStop => 'Stop';

  @override
  String get activityStopAndSave => 'Stop and save';

  @override
  String get activityStopConfirmMessage =>
      'Choose whether to keep this recording or discard it.';

  @override
  String get activityStopConfirmTitle => 'End activity?';

  @override
  String get activityStopping => 'Stopping';

  @override
  String get activityTypeHike => 'Hike';

  @override
  String get activityTypeLabel => 'Activity type';

  @override
  String get activityTypeOther => 'Other';

  @override
  String get activityTypeRide => 'Ride';

  @override
  String get activityTypeRun => 'Run';

  @override
  String get activityTypeWalk => 'Walk';

  @override
  String get activityUploadFailed => 'Upload failed';

  @override
  String get activityUploadCleanupFailed => 'Uploaded, but cleanup failed';

  @override
  String get activityUploadReady => 'Ready to upload';

  @override
  String get activityUploaded => 'Uploaded';

  @override
  String get activityUploading => 'Uploading';

  @override
  String get activityUploadStatusPending => 'Pending';

  @override
  String get activityUploadStatusUploaded => 'Uploaded';

  @override
  String get activityUploadStatusFailed => 'Failed';

  @override
  String get activityHistoryTitle => 'Activity history';

  @override
  String get activityHistorySettingsSubtitle =>
      'Completed activities saved on this device';

  @override
  String get activityRetainUploadedGpx => 'Keep uploaded GPX files';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Stores completed route files in private app storage after upload.';

  @override
  String get activityHistoryEmpty =>
      'No completed activities saved on this device.';

  @override
  String get activityHistoryLoadFailed => 'Could not load local activities.';

  @override
  String get activityHistoryRefresh => 'Refresh';

  @override
  String get activityHistoryLocalActivities => 'Local activities';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distance: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Upload: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Load more';

  @override
  String get activityHistoryDetailsTitle => 'Activity details';

  @override
  String get activityHistoryDetailsMissing =>
      'This local activity is no longer available.';

  @override
  String get activityHistorySummary => 'Summary';

  @override
  String get activityHistoryActions => 'Actions';

  @override
  String get activityHistoryType => 'Type';

  @override
  String get activityHistoryStartedAt => 'Started';

  @override
  String get activityHistoryEndedAt => 'Ended';

  @override
  String get activityHistoryDurationLabel => 'Duration';

  @override
  String get activityHistoryDistanceLabel => 'Distance';

  @override
  String get activityHistoryAverageSpeed => 'Average speed';

  @override
  String get activityHistoryPointCount => 'GPS points';

  @override
  String get activityHistoryUploadStatusLabel => 'Upload';

  @override
  String get activityHistoryGpxStatus => 'GPX file';

  @override
  String get activityHistoryGpxAvailable => 'Saved on this device';

  @override
  String get activityHistoryGpxMissing => 'Not available on this device';

  @override
  String get mapTab => 'Map';

  @override
  String get myLocation => 'My Location';

  @override
  String get settingsTab => 'Settings';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® is a registered trademark of João Vitória Silva';

  @override
  String get settingsScreen => 'Settings';

  @override
  String get deviceAccessTitle => 'Device access';

  @override
  String get deviceAccessSubtitle => 'Manage location and health data access';

  @override
  String get deviceAccessLocationSection => 'Location';

  @override
  String get deviceAccessHealthSection => 'Health data';

  @override
  String get deviceAccessLocationTitle => 'Location access';

  @override
  String get deviceAccessHealthTitle => 'Health data access';

  @override
  String get deviceAccessChecking => 'Checking access…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Location services are turned off';

  @override
  String get deviceAccessLocationAlways => 'Allowed all the time';

  @override
  String get deviceAccessLocationWhileUsing => 'Allowed while using the app';

  @override
  String get deviceAccessLocationBlocked => 'Blocked in system settings';

  @override
  String get deviceAccessLocationNotAllowed => 'Not allowed';

  @override
  String get deviceAccessHealthUnavailable => 'Not available on this device';

  @override
  String get deviceAccessHealthRequired => 'Health Connect is required';

  @override
  String get deviceAccessHealthSetUp => 'Health access set up';

  @override
  String get deviceAccessHealthNeedsAttention => 'Access needs attention';

  @override
  String get deviceAccessHealthNotConnected => 'Not connected';

  @override
  String get language => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Sign in';

  @override
  String get signInConnectServerSubtitle =>
      'Record offline now and sync your activities later';

  @override
  String get serverSettingsTitle => 'Server settings';

  @override
  String connectedToServer(String server) {
    return 'Connected to $server';
  }

  @override
  String get loggedIn => 'Logged in';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverProtocol => 'Protocol';

  @override
  String get serverUrlHint => 'example.com';

  @override
  String get warnHttpServerUrlTitle => 'Insecure connection';

  @override
  String get warnHttpServerUrlMessage =>
      'This server URL uses plain HTTP. Your login credentials and data will be transmitted without encryption. Continue only if you understand and accept the risk.';

  @override
  String get warnHttpServerUrlConfirm => 'Continue anyway';

  @override
  String get tileServerUrl => 'Map tile server URL';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Different tile server host';

  @override
  String get tileServerHostWarningMessage =>
      'The tile server host is different from your Endurain server host. Tiles will be loaded from a third-party server. Do you want to continue?';

  @override
  String get savedSuccessfully => 'Settings saved successfully';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get diagnosticsSubtitle => 'Local crash context';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Could not open the link';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsCollection => 'Collection';

  @override
  String get diagnosticsEnable => 'Collect diagnostics';

  @override
  String get diagnosticsEnableSubtitle =>
      'Store recent app events and errors on this device';

  @override
  String get diagnosticsDisabled =>
      'Diagnostics collection is off. Turn it on to start capturing app events and errors on this device.';

  @override
  String get diagnosticsEmpty => 'No diagnostics have been captured yet.';

  @override
  String get diagnosticsCopy => 'Copy';

  @override
  String get diagnosticsCopied => 'Diagnostics copied';

  @override
  String get diagnosticsClear => 'Clear';

  @override
  String get diagnosticsCleared => 'Diagnostics cleared';

  @override
  String get diagnosticsSummary => 'Summary';

  @override
  String get diagnosticsLastUpdated => 'Last updated';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Events: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Errors: $count';
  }

  @override
  String get diagnosticsEvents => 'Events';

  @override
  String get diagnosticsNoEvents => 'No events captured';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Event: $event';
  }

  @override
  String get diagnosticsErrors => 'Errors';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Error: $type';
  }

  @override
  String get diagnosticsActions => 'Actions';

  @override
  String get diagnosticsRawReport => 'Raw report';

  @override
  String get healthSyncSettingsTitle => 'Health sync';

  @override
  String get healthSyncSettingsSubtitle =>
      'Import workouts from your health platform';

  @override
  String get healthSyncScreenTitle => 'Health sync';

  @override
  String get healthAccessScreenTitle => 'Health access';

  @override
  String get healthAccessRequestedData => 'Requested data';

  @override
  String get healthAccessWorkouts => 'Workouts';

  @override
  String get healthAccessWorkoutRoutes => 'Workout routes';

  @override
  String get healthAccessHeartRate => 'Heart rate';

  @override
  String get healthAccessWorkoutSummary =>
      'Workout distance, calories, and steps';

  @override
  String get healthAccessAllowed => 'Allowed';

  @override
  String get healthAccessNeedsAttention => 'Needs attention';

  @override
  String get healthAccessManagedBySystem => 'Managed in system settings';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit does not disclose which data Endurain can read. Review access in the Health app.';

  @override
  String get healthAccessReview => 'Review health access';

  @override
  String get healthAccessReviewIos => 'How to review access';

  @override
  String get healthAccessDisconnect => 'Disconnect health data';

  @override
  String get healthAccessDisconnectTitle => 'Disconnect health data?';

  @override
  String get healthAccessDisconnectMessage =>
      'Automatic import and local import history for this server will be reset. Existing activities stay in your history.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Open the Health app, tap your profile picture, then Apps and Services. Select Endurain and update the data categories.';

  @override
  String get healthSyncAuthorize => 'Connect to health data';

  @override
  String get healthSyncInstallProvider => 'Install Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Health Connect is required to sync workouts. Install it to continue.';

  @override
  String get healthSyncUnsupported =>
      'Health sync is not available on this device.';

  @override
  String get healthSyncSelectAll => 'Select all';

  @override
  String get healthSyncClearSelection => 'Clear';

  @override
  String healthSyncImportSelected(int count) {
    return 'Import selected ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Imported $count workout(s).';
  }

  @override
  String get healthSyncNoRouteLabel => 'No GPS route';

  @override
  String get healthSyncEmptyState =>
      'No workouts found in the selected date range.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Some workouts were skipped because exercise-route access was not granted. Open Health Connect → Permissions and allow exercise routes for Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Some workouts were skipped because Endurain could not read their GPS routes. In the Health app, open your profile, then Apps and Services, select Endurain, and allow Workout Routes.';

  @override
  String get healthSyncReviewAccess => 'Review access';

  @override
  String get healthSyncAutoSyncTitle => 'Auto-sync on resume';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Import new workouts automatically when the app opens.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'These workouts don\'t include a GPS route, so they can\'t be imported. Some apps (like Garmin Connect) record activities to Apple Health without sharing the route. Workouts recorded with Apple Watch include routes and can be imported.';

  @override
  String get healthSyncBadgeNonImportable => 'Non-importable';

  @override
  String get healthSyncViewAvailable => 'Available';

  @override
  String get healthSyncViewImported => 'Imported';

  @override
  String get healthSyncDateRange => 'Workout date range';

  @override
  String get healthSyncRange30Days => 'Last 30 days';

  @override
  String get healthSyncRange3Months => 'Last 3 months';

  @override
  String get healthSyncRange6Months => 'Last 6 months';

  @override
  String get healthSyncRangeYear => 'Last year';

  @override
  String get healthSyncRangeAll => 'All history';

  @override
  String get healthSyncRangeCustom => 'Custom range';

  @override
  String get healthSyncImportedEmpty =>
      'No imported workouts for this connection.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Imported: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Restore';

  @override
  String get sensorsTitle => 'Sensors';

  @override
  String get sensorsSettingsSubtitle =>
      'Heart rate monitors and other external sensors';

  @override
  String get sensorsHeartRateSection => 'Heart rate';

  @override
  String get sensorsHeartRateHelp =>
      'Pair a Bluetooth heart rate monitor to see your live heart rate.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth is off. Turn it on to connect a sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Allow Bluetooth access to connect a sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'This device doesn\'t support Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Scan for sensors';

  @override
  String get sensorsScanning => 'Scanning…';

  @override
  String get sensorsStopScan => 'Stop';

  @override
  String get sensorsNoDevices => 'No heart rate sensors found yet.';

  @override
  String get sensorsAvailableSection => 'Available sensors';

  @override
  String get sensorsSavedSection => 'Saved sensor';

  @override
  String get sensorsConnect => 'Connect';

  @override
  String get sensorsConnecting => 'Connecting…';

  @override
  String get sensorsConnected => 'Connected';

  @override
  String get sensorsDisconnect => 'Disconnect';

  @override
  String get sensorsForget => 'Forget';

  @override
  String get sensorsConnectionFailed => 'Couldn\'t connect. Try again.';

  @override
  String get sensorsPermissionRequired =>
      'Bluetooth permission is required to find sensors.';

  @override
  String get sensorsUnknownDevice => 'Unknown sensor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Power';

  @override
  String get sensorsPowerHelp =>
      'Pair a Bluetooth power meter to see your live power.';

  @override
  String get sensorsNoPowerDevices => 'No power meters found yet.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadence';

  @override
  String get sensorsCadenceHelp =>
      'Pair a Bluetooth cadence sensor to see your live cadence.';

  @override
  String get sensorsNoCadenceDevices => 'No cadence sensors found yet.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Remote crash reporting';

  @override
  String get diagnosticsRemoteEnable => 'Send crash reports';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Send crash and error reports to a diagnostics server. This is separate from local diagnostics; you can enable either, both, or neither.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Remote crash reporting isn\'t available in this build.';

  @override
  String unitMeter(String value) {
    return '$value m';
  }

  @override
  String unitKilometer(String value) {
    return '$value km';
  }

  @override
  String unitFoot(String value) {
    return '$value ft';
  }

  @override
  String unitMile(String value) {
    return '$value mi';
  }

  @override
  String unitKilometersPerHour(String value) {
    return '$value km/h';
  }

  @override
  String unitMilesPerHour(String value) {
    return '$value mph';
  }

  @override
  String unitMinutesPerKilometer(String value) {
    return '$value min/km';
  }

  @override
  String unitMinutesPerMile(String value) {
    return '$value min/mi';
  }

  @override
  String unitBpm(String value) {
    return '$value bpm';
  }

  @override
  String unitWatt(String value) {
    return '$value W';
  }

  @override
  String unitRpm(String value) {
    return '$value rpm';
  }

  @override
  String get unitsTitle => 'Units';

  @override
  String get unitsSubtitle => 'Distance, speed, and elevation units';

  @override
  String get unitsSystemDefault => 'Follow device region';

  @override
  String get unitsMetric => 'Metric (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';
}
