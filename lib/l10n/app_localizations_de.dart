// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get error => 'Fehler';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get back => 'Zurück';

  @override
  String get requiredField => 'Dieses Feld ist erforderlich';

  @override
  String get invalidUrl => 'Bitte gib eine gültige URL ein';

  @override
  String get errorActivityUploadFailed =>
      'Aktivität konnte nicht hochgeladen werden';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Aktivität konnte nicht hochgeladen werden: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Der Aktivitäts-Upload ist noch nicht konfiguriert';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Die temporäre Aktivitätsdatei konnte nicht gelöscht werden';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Die Datei für den Aktivitäts-Upload konnte nicht vorbereitet werden';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Diese lokale Aktivität konnte nicht gefunden werden';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Die lokale Aktivität konnte nicht gelöscht werden';

  @override
  String get errorActivityLocalGpxMissing =>
      'Die lokale GPX-Datei ist nicht verfügbar';

  @override
  String get errorActivityLocalLoadFailed =>
      'Lokale Aktivitäten konnten nicht geladen werden';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Diese Aktivität konnte nicht gespeichert werden';

  @override
  String get errorActivityLocalSaveFailed =>
      'Die Aktivität konnte nicht lokal gespeichert werden';

  @override
  String get errorFetchProvidersFailed =>
      'Anmeldeanbieter konnten nicht geladen werden';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Anmeldeanbieter konnten nicht geladen werden: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Servereinstellungen konnten nicht geladen werden';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Servereinstellungen konnten nicht geladen werden: $details';
  }

  @override
  String get errorLoginError => 'Anmeldung nicht möglich';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Anmeldung nicht möglich: $details';
  }

  @override
  String get errorLoginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Anmeldung fehlgeschlagen: $details';
  }

  @override
  String get errorMfaVerificationError =>
      'MFA-Code konnte nicht überprüft werden';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'MFA-Code konnte nicht überprüft werden: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA-Überprüfung fehlgeschlagen';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA-Überprüfung fehlgeschlagen: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Vom Server wurde keine Sitzungs-ID empfangen';

  @override
  String get errorNotAuthenticated => 'Du bist nicht angemeldet';

  @override
  String get errorPkceVerifierMissing =>
      'Der Anmelde-Verifier wurde nicht gefunden';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Der Anmelde-Verifier wurde nicht gefunden. Bitte starte die Anmeldung erneut.';

  @override
  String get errorServerUrlNotConfigured => 'Server-URL ist nicht konfiguriert';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Dieser Server erfordert eine sichere (HTTPS-)Verbindung';

  @override
  String get errorSessionExpired =>
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.';

  @override
  String get errorSsoTokenExchangeError =>
      'SSO-Anmeldung konnte nicht abgeschlossen werden';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'SSO-Anmeldung konnte nicht abgeschlossen werden: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Token-Austausch fehlgeschlagen';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Token-Austausch fehlgeschlagen: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Zeitüberschreitung der Anfrage. Überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Löschen aus dem sicheren Speicher nicht möglich. Der Gerätespeicher ist möglicherweise nicht verfügbar.';

  @override
  String get errorSecureStorageReadFailed =>
      'Lesen aus dem sicheren Speicher nicht möglich. Der Gerätespeicher ist möglicherweise nicht verfügbar.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Schreiben in den sicheren Speicher nicht möglich. Der Gerätespeicher ist möglicherweise nicht verfügbar.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Der Server hat eine unerwartete Antwort zurückgegeben';

  @override
  String get errorUnsupportedHttpMethod => 'Nicht unterstützte HTTP-Methode';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nicht unterstützte HTTP-Methode: $details';
  }

  @override
  String get loginTitle => 'Anmeldung';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get logoutConfirmTitle => 'Abmelden';

  @override
  String get logoutConfirmMessage => 'Möchtest du dich wirklich abmelden?';

  @override
  String get logoutServerFailedWarning =>
      'Abmeldung vom Server nicht möglich, aber lokal abgemeldet';

  @override
  String get ssoBrowserLaunchFailed =>
      'SSO-Anmeldung konnte im Systembrowser nicht geöffnet werden';

  @override
  String get ssoMissingSessionId =>
      'Der SSO-Rückruf enthielt keine Sitzungs-ID';

  @override
  String ssoSignInWith(String provider) {
    return 'Anmelden mit $provider';
  }

  @override
  String get ssoOrDivider => 'ODER';

  @override
  String get next => 'Weiter';

  @override
  String get username => 'Benutzername';

  @override
  String get usernameHint => 'Gib deinen Benutzernamen ein';

  @override
  String get password => 'Passwort';

  @override
  String get passwordHint => 'Gib dein Passwort ein';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get mfaTitle => 'Zwei-Faktor-Authentifizierung';

  @override
  String get mfaCode => 'MFA-Code';

  @override
  String get mfaCodeHint => '6-stelligen Code eingeben';

  @override
  String get mfaCodeRequired => 'Bitte gib den MFA-Code ein';

  @override
  String get verify => 'Überprüfen';

  @override
  String get activityDiscard => 'Verwerfen';

  @override
  String get activityDiscardConfirmMessage =>
      'Dadurch werden die aufgezeichneten Punkte dieser Aktivität gelöscht.';

  @override
  String get activityDiscardConfirmTitle => 'Aktivität verwerfen?';

  @override
  String get activityLocationPermissionDenied =>
      'Für die Aufzeichnung einer Aktivität ist die Standortberechtigung erforderlich.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Die Standortberechtigung ist blockiert. Öffne die Einstellungen, um den Standortzugriff zu erlauben.';

  @override
  String get activityLocationServiceDisabled =>
      'Die Standortdienste sind deaktiviert.';

  @override
  String get activityLocationStreamFailed =>
      'Die Standortaktualisierungen wurden unerwartet beendet.';

  @override
  String get activityGpxGenerationFailed =>
      'Die GPX-Datei der Aktivität konnte nicht erstellt werden.';

  @override
  String get activityLocalSaveFailed =>
      'Diese Aktivität konnte auf diesem Gerät nicht gespeichert werden.';

  @override
  String get activityOpenSettings => 'Einstellungen öffnen';

  @override
  String get activityPause => 'Pause';

  @override
  String get activityRecordingEmpty =>
      'Es wurden keine GPS-Punkte aufgezeichnet.';

  @override
  String get activityRecordingFailed => 'Aufzeichnung fehlgeschlagen.';

  @override
  String get activityResume => 'Fortsetzen';

  @override
  String get activityRetryUpload => 'Upload wiederholen';

  @override
  String get activityDone => 'Fertig';

  @override
  String get activityViewHistory => 'Verlauf anzeigen';

  @override
  String get activityDeleteLocal => 'Lokale Kopie löschen';

  @override
  String get activityExportGpx => 'GPX-Datei teilen';

  @override
  String get activityExportGpxSubject => 'Endurain-Aktivitäts-GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Lokale Aktivität löschen?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Dadurch werden der lokale Aktivitätseintrag und die GPX-Datei von diesem Gerät entfernt.';

  @override
  String get activityStart => 'Start';

  @override
  String get activityBackgroundPermissionTitle =>
      'Hintergrund-Tracking erlauben?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain benötigt den Hintergrundstandort auf „Immer“, damit die Aufzeichnung fortgesetzt wird, wenn die App im Hintergrund ist, der Bildschirm gesperrt ist oder du die App wechselst.';

  @override
  String get activityBackgroundPermissionContinue => 'Weiter';

  @override
  String get activityBackgroundPermissionRequired =>
      'Hintergrund-Tracking auf iPhone und iPad erfordert den Standort auf „Immer“.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Hintergrund-Tracking ist aus';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Um im Hintergrund oder bei gesperrtem Bildschirm zuverlässig aufzuzeichnen, öffne die Einstellungen und setze den Standort für Endurain auf „Immer“.';

  @override
  String get activityTrackingNotificationTitle =>
      'Aktivität wird aufgezeichnet';

  @override
  String get activityTrackingNotificationText =>
      'Endurain zeichnet deinen Standort auf, um diese Aktivität aufzuzeichnen.';

  @override
  String get activityStatDistance => 'Distanz';

  @override
  String get activityStatDuration => 'Zeit';

  @override
  String get activityStatSpeed => 'Geschwindigkeit';

  @override
  String get activityStop => 'Stopp';

  @override
  String get activityStopAndSave => 'Stoppen und speichern';

  @override
  String get activityStopConfirmMessage =>
      'Wähle, ob du diese Aufzeichnung behalten oder verwerfen möchtest.';

  @override
  String get activityStopConfirmTitle => 'Aktivität beenden?';

  @override
  String get activityStopping => 'Wird gestoppt';

  @override
  String get activityTypeHike => 'Wanderung';

  @override
  String get activityTypeLabel => 'Aktivitätstyp';

  @override
  String get activityTypeOther => 'Sonstiges';

  @override
  String get activityTypeRide => 'Radfahren';

  @override
  String get activityTypeRun => 'Laufen';

  @override
  String get activityTypeWalk => 'Gehen';

  @override
  String get activityUploadFailed => 'Upload fehlgeschlagen';

  @override
  String get activityUploadCleanupFailed =>
      'Hochgeladen, aber Bereinigung fehlgeschlagen';

  @override
  String get activityUploadReady => 'Bereit zum Hochladen';

  @override
  String get activityUploaded => 'Hochgeladen';

  @override
  String get activityUploading => 'Wird hochgeladen';

  @override
  String get activityUploadStatusPending => 'Ausstehend';

  @override
  String get activityUploadStatusUploaded => 'Hochgeladen';

  @override
  String get activityUploadStatusFailed => 'Fehlgeschlagen';

  @override
  String get activityHistoryTitle => 'Aktivitätsverlauf';

  @override
  String get activityHistorySettingsSubtitle =>
      'Abgeschlossene Aktivitäten auf diesem Gerät gespeichert';

  @override
  String get activityRetainUploadedGpx => 'Hochgeladene GPX-Dateien behalten';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Speichert abgeschlossene Routendateien nach dem Upload im privaten App-Speicher.';

  @override
  String get activityHistoryEmpty =>
      'Keine abgeschlossenen Aktivitäten auf diesem Gerät gespeichert.';

  @override
  String get activityHistoryLoadFailed =>
      'Lokale Aktivitäten konnten nicht geladen werden.';

  @override
  String get activityHistoryRefresh => 'Aktualisieren';

  @override
  String get activityHistoryLocalActivities => 'Lokale Aktivitäten';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Dauer: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distanz: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Upload: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Mehr laden';

  @override
  String get activityHistoryDetailsTitle => 'Aktivitätsdetails';

  @override
  String get activityHistoryDetailsMissing =>
      'Diese lokale Aktivität ist nicht mehr verfügbar.';

  @override
  String get activityHistorySummary => 'Zusammenfassung';

  @override
  String get activityHistoryActions => 'Aktionen';

  @override
  String get activityHistoryType => 'Typ';

  @override
  String get activityHistoryStartedAt => 'Gestartet';

  @override
  String get activityHistoryEndedAt => 'Beendet';

  @override
  String get activityHistoryDurationLabel => 'Dauer';

  @override
  String get activityHistoryDistanceLabel => 'Distanz';

  @override
  String get activityHistoryAverageSpeed => 'Durchschnittsgeschwindigkeit';

  @override
  String get activityHistoryPointCount => 'GPS-Punkte';

  @override
  String get activityHistoryUploadStatusLabel => 'Upload';

  @override
  String get activityHistoryGpxStatus => 'GPX-Datei';

  @override
  String get activityHistoryGpxAvailable => 'Auf diesem Gerät gespeichert';

  @override
  String get activityHistoryGpxMissing => 'Auf diesem Gerät nicht verfügbar';

  @override
  String get mapTab => 'Karte';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get settingsTab => 'Einstellungen';

  @override
  String get settingsScreen => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Anmelden';

  @override
  String get signInConnectServerSubtitle =>
      'Jetzt offline aufzeichnen und deine Aktivitäten später synchronisieren';

  @override
  String get serverSettingsTitle => 'Servereinstellungen';

  @override
  String get loggedIn => 'Angemeldet';

  @override
  String get notConfigured => 'Nicht konfiguriert';

  @override
  String get notLoggedIn => 'Nicht angemeldet';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverUrlHint => 'https://beispiel.com';

  @override
  String get warnHttpServerUrlTitle => 'Unsichere Verbindung';

  @override
  String get warnHttpServerUrlMessage =>
      'Diese Server-URL verwendet unverschlüsseltes HTTP. Deine Anmeldedaten und Daten werden unverschlüsselt übertragen. Fahre nur fort, wenn du das Risiko verstehst und akzeptierst.';

  @override
  String get warnHttpServerUrlConfirm => 'Trotzdem fortfahren';

  @override
  String get tileServerUrl => 'URL des Karten-Kachelservers';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Anderer Kachelserver-Host';

  @override
  String get tileServerHostWarningMessage =>
      'Der Host des Kachelservers unterscheidet sich von deinem Endurain-Server-Host. Die Kacheln werden von einem Drittanbieter-Server geladen. Möchtest du fortfahren?';

  @override
  String get savedSuccessfully => 'Einstellungen erfolgreich gespeichert';

  @override
  String get diagnostics => 'Diagnose';

  @override
  String get diagnosticsSubtitle => 'Lokaler Absturzkontext';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Der Link konnte nicht geöffnet werden';

  @override
  String get diagnosticsTitle => 'Diagnose';

  @override
  String get diagnosticsCollection => 'Erfassung';

  @override
  String get diagnosticsEnable => 'Diagnose erfassen';

  @override
  String get diagnosticsEnableSubtitle =>
      'Aktuelle App-Ereignisse und Fehler auf diesem Gerät speichern';

  @override
  String get diagnosticsDisabled =>
      'Die Diagnoseerfassung ist deaktiviert. Aktiviere sie, um App-Ereignisse und Fehler auf diesem Gerät zu erfassen.';

  @override
  String get diagnosticsEmpty => 'Es wurden noch keine Diagnosedaten erfasst.';

  @override
  String get diagnosticsCopy => 'Kopieren';

  @override
  String get diagnosticsCopied => 'Diagnose kopiert';

  @override
  String get diagnosticsClear => 'Löschen';

  @override
  String get diagnosticsCleared => 'Diagnose gelöscht';

  @override
  String get diagnosticsSummary => 'Zusammenfassung';

  @override
  String get diagnosticsLastUpdated => 'Zuletzt aktualisiert';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Ereignisse: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Fehler: $count';
  }

  @override
  String get diagnosticsEvents => 'Ereignisse';

  @override
  String get diagnosticsNoEvents => 'Keine Ereignisse erfasst';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Ereignis: $event';
  }

  @override
  String get diagnosticsErrors => 'Fehler';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Fehler: $type';
  }

  @override
  String get diagnosticsActions => 'Aktionen';

  @override
  String get diagnosticsRawReport => 'Rohbericht';
}
