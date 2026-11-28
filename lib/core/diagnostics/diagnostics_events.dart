import 'package:flutter/foundation.dart';

class DiagnosticsSources {
  const DiagnosticsSources._();

  static const String flutter = 'flutter';
  static const String platformDispatcher = 'platform_dispatcher';
  static const String rootZone = 'root_zone';
  static const String uncaught = 'uncaught';
  static const String activityRecorder = 'activity_recorder';
}

class DiagnosticsEvents {
  const DiagnosticsEvents._();

  static const String appStarted = 'app.started';
  static const String appLifecycleChanged = 'app.lifecycle_changed';
  static const String activityStartRequested = 'activity.start_requested';
  static const String activityStarted = 'activity.started';
  static const String activityStartFailed = 'activity.start_failed';
  static const String activityPaused = 'activity.paused';
  static const String activityResumed = 'activity.resumed';
  static const String activityAutoPaused = 'activity.auto_paused';
  static const String activityAutoResumed = 'activity.auto_resumed';
  static const String activityStopped = 'activity.stopped';
  static const String activityStopFailed = 'activity.stop_failed';
  static const String secureStorageServerUrlFallback =
      'secure_storage.server_url_fallback';
  static const String activityDiscarded = 'activity.discarded';
  static const String activityFailed = 'activity.failed';
  static const String activityGpxGenerationFailed =
      'activity.gpx_generation_failed';
  static const String activityPointMilestone = 'activity.point_milestone';
  // Emitted only by the test geolocator recorder helper
  // (test/helpers/geolocator_activity_location_recorder.dart); production
  // recording runs in the native recorder.
  @visibleForTesting
  static const String activityRecorderStarted = 'activity.recorder_started';
  @visibleForTesting
  static const String activityRecorderPaused = 'activity.recorder_paused';
  @visibleForTesting
  static const String activityRecorderResumed = 'activity.recorder_resumed';
  @visibleForTesting
  static const String activityRecorderAutoPaused =
      'activity.recorder_auto_paused';
  @visibleForTesting
  static const String activityRecorderAutoResumed =
      'activity.recorder_auto_resumed';
  @visibleForTesting
  static const String activityRecorderStopped = 'activity.recorder_stopped';
  static const String activityActiveSessionRecovered =
      'activity.active_session_recovered';
  static const String activityStaleSessionCleared =
      'activity.stale_session_cleared';
  @visibleForTesting
  static const String activityPointBatchDrained =
      'activity.point_batch_drained';
  @visibleForTesting
  static const String activityTrackingStall = 'activity.tracking_stall';
  static const String activityUploadQueueDrainStarted =
      'activity.upload_queue_drain_started';
  static const String activityUploadQueueDrainFinished =
      'activity.upload_queue_drain_finished';
  static const String activityUploadQueueDrainFailed =
      'activity.upload_queue_drain_failed';
  static const String activityRouteLoadFailed = 'activity.route_load_failed';
  static const String activityLiveActivityUpdateFailed =
      'activity.live_activity_update_failed';
  static const String activityUploadQueueRecordFailed =
      'activity.upload_queue_record_failed';
  static const String activityUploadRetryFailed =
      'activity.upload_retry_failed';
  static const String healthAutoSyncFailed = 'health.auto_sync_failed';
  static const String healthBackgroundSyncFailed =
      'health.background_sync_failed';
  static const String healthBackgroundScheduleFailed =
      'health.background_schedule_failed';
  static const String healthAuthRequested = 'health.auth_requested';
  static const String healthListImportable = 'health.list_importable';
  static const String healthImportWorkouts = 'health.import_workouts';
  static const String healthImportWorkoutFailed =
      'health.import_workout_failed';
  static const String healthConnectSdkStatus = 'health.connect_sdk_status';
  static const String healthRequestAuthorization =
      'health.request_authorization';
  static const String healthRequestAuthorizationError =
      'health.request_authorization_error';
  static const String healthInstallProviderRequested =
      'health.install_provider_requested';
  static const String healthReadWorkouts = 'health.read_workouts';
  static const String healthHeartRateSeriesFailed =
      'health.heart_rate_series_failed';
  static const String healthLoadStatusFailed = 'health.load_status_failed';
  static const String healthAutoSyncSettingFailed =
      'health.auto_sync_setting_failed';
  static const String healthRequestAccessFailed =
      'health.request_access_failed';
  static const String healthInstallProviderFailed =
      'health.install_provider_failed';
  static const String healthDisconnectFailed = 'health.disconnect_failed';
  static const String healthLoadImportableFailed =
      'health.load_importable_failed';
  static const String healthImportSelectedFailed =
      'health.import_selected_failed';
  static const String ssoProvidersFetchFailed = 'sso.providers_fetch_failed';
  static const String watchSyncStarted = 'watch.sync_started';
  static const String watchSyncFinished = 'watch.sync_finished';
  static const String watchSyncFailed = 'watch.sync_failed';
  static const String watchSessionIngested = 'watch.session_ingested';
  static const String watchSessionIngestFailed = 'watch.session_ingest_failed';
  static const String watchSessionDeferred = 'watch.session_deferred';
  static const String ssoRedirectNotAllowed = 'sso.redirect_not_allowed';
  static const String ssoLoginStarted = 'sso.login_started';
  static const String ssoBrowserLaunchFailed = 'sso.browser_launch_failed';
  static const String ssoCallbackIgnored = 'sso.callback_ignored';
  static const String ssoCallbackReceived = 'sso.callback_received';
  static const String ssoCallbackError = 'sso.callback_error';
  static const String ssoCallbackMissingSession =
      'sso.callback_missing_session';
  static const String ssoExchangeSucceeded = 'sso.exchange_succeeded';
  static const String ssoExchangeFailed = 'sso.exchange_failed';
  static const String navigationChanged = 'nav.changed';
  static const String navigationRedirected = 'nav.redirected';
  static const String navigationTabChanged = 'nav.tab_changed';
  static const String uiErrorShown = 'ui.error_shown';
  static const String sessionModeChanged = 'session.mode_changed';
  static const String sessionRevalidateFailed = 'session.revalidate_failed';
  static const String authRefreshFailed = 'auth.refresh_failed';
  static const String authSessionCleared = 'auth.session_cleared';

  /// A refresh succeeded but secure storage rejected the new tokens; they stay
  /// current in memory and the write is retried on the next read.
  static const String authRefreshPersistPending =
      'auth.refresh_persist_pending';
  static const String authServerSettingsSaveFailed =
      'auth.server_settings_save_failed';
  static const String httpRequestFailed = 'http.request_failed';
  static const String legacyProfileAdopted = 'account.legacy_profile_adopted';
  static const String legacyProfileDeclined = 'account.legacy_profile_declined';
  static const String legacyProfileMigrationFailed =
      'account.legacy_profile_migration_failed';
}
