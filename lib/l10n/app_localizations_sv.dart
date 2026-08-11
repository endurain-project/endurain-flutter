// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get error => 'Fel';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Avbryt';

  @override
  String get save => 'Spara';

  @override
  String get back => 'Tillbaka';

  @override
  String get requiredField => 'Det här fältet är obligatoriskt';

  @override
  String get invalidUrl => 'Ange en giltig URL';

  @override
  String get errorActivityUploadFailed =>
      'Det gick inte att ladda upp aktiviteten';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Det gick inte att ladda upp aktiviteten: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Uppladdning av aktiviteter är inte konfigurerad än';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Det gick inte att ta bort den tillfälliga aktivitetsfilen';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Det gick inte att förbereda filen för uppladdning av aktiviteten';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Det gick inte att hitta den här lokala aktiviteten';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Det gick inte att ta bort den lokala aktiviteten';

  @override
  String get errorActivityLocalGpxMissing =>
      'Den lokala GPX-filen är inte tillgänglig';

  @override
  String get errorActivityLocalLoadFailed =>
      'Det gick inte att läsa in lokala aktiviteter';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Det gick inte att spara den här aktiviteten';

  @override
  String get errorActivityLocalSaveFailed =>
      'Det gick inte att spara aktiviteten lokalt';

  @override
  String get errorFetchProvidersFailed =>
      'Det gick inte att läsa in inloggningsleverantörer';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Det gick inte att läsa in inloggningsleverantörer: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Det gick inte att läsa in serverinställningar';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Det gick inte att läsa in serverinställningar: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Det gick inte att konvertera träningen till GPX';

  @override
  String get errorHealthImportFailed =>
      'Det gick inte att importera träningspasset';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Det gick inte att importera träningspass: $details';
  }

  @override
  String get errorHealthPermissionDenied => 'Åtkomst till hälsodata nekades';

  @override
  String get errorHealthReadFailed => 'Kunde inte läsa hälsodata';

  @override
  String get errorLoginError => 'Det gick inte att logga in';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Det gick inte att logga in: $details';
  }

  @override
  String get errorLoginFailed => 'Inloggningen misslyckades';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Inloggningen misslyckades: $details';
  }

  @override
  String get errorMfaVerificationError =>
      'Det gick inte att verifiera MFA-koden';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Det gick inte att verifiera MFA-koden: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA-verifieringen misslyckades';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA-verifieringen misslyckades: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Inget sessions-ID togs emot från servern';

  @override
  String get errorNotAuthenticated => 'Du är inte inloggad';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Inloggningsverifieraren hittades inte. Börja om inloggningen.';

  @override
  String get errorServerUrlNotConfigured => 'Server-URL är inte konfigurerad';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Den här servern kräver en säker (HTTPS-)anslutning';

  @override
  String get errorSessionExpired => 'Din session har gått ut. Logga in igen.';

  @override
  String get errorSsoTokenExchangeError =>
      'Det gick inte att slutföra SSO-inloggningen';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Det gick inte att slutföra SSO-inloggningen: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Tokenutbytet misslyckades';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Tokenutbytet misslyckades: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Begäran tog för lång tid. Kontrollera din anslutning och försök igen.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Det går inte att ta bort från säker lagring. Enhetens lagring kanske inte är tillgänglig.';

  @override
  String get errorSecureStorageReadFailed =>
      'Det går inte att läsa från säker lagring. Enhetens lagring kanske inte är tillgänglig.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Det går inte att skriva till säker lagring. Enhetens lagring kanske inte är tillgänglig.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Servern returnerade ett oväntat svar';

  @override
  String get errorUnsupportedHttpMethod => 'HTTP-metoden stöds inte';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'HTTP-metoden stöds inte: $details';
  }

  @override
  String get loginTitle => 'Logga in';

  @override
  String get login => 'Logga in';

  @override
  String get logout => 'Logga ut';

  @override
  String get logoutConfirmTitle => 'Logga ut';

  @override
  String get logoutConfirmMessage => 'Är du säker på att du vill logga ut?';

  @override
  String get logoutServerFailedWarning =>
      'Det gick inte att logga ut från servern, men du loggades ut lokalt';

  @override
  String get ssoBrowserLaunchFailed =>
      'Det gick inte att öppna SSO-inloggningen i systemets webbläsare';

  @override
  String ssoSignInWith(String provider) {
    return 'Logga in med $provider';
  }

  @override
  String get ssoOrDivider => 'ELLER';

  @override
  String get next => 'Nästa';

  @override
  String get username => 'Användarnamn';

  @override
  String get usernameHint => 'Ange ditt användarnamn';

  @override
  String get password => 'Lösenord';

  @override
  String get passwordHint => 'Ange ditt lösenord';

  @override
  String get showPassword => 'Visa lösenord';

  @override
  String get mfaTitle => 'Tvåfaktorsautentisering';

  @override
  String get mfaCode => 'MFA-kod';

  @override
  String get mfaCodeHint => 'Ange den 6-siffriga koden';

  @override
  String get mfaCodeRequired => 'Ange MFA-koden';

  @override
  String get verify => 'Verifiera';

  @override
  String get activityDiscard => 'Släng';

  @override
  String get activityDiscardConfirmMessage =>
      'Detta tar bort de inspelade punkterna för den här aktiviteten.';

  @override
  String get activityDiscardConfirmTitle => 'Släng aktiviteten?';

  @override
  String get activityLocationPermissionDenied =>
      'Platsbehörighet krävs för att spela in en aktivitet.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Platsbehörigheten är blockerad. Öppna inställningarna för att tillåta platsåtkomst.';

  @override
  String get activityLocationServiceDisabled =>
      'Platstjänster är inaktiverade.';

  @override
  String get activityLocationStreamFailed =>
      'Platsuppdateringarna stoppades oväntat.';

  @override
  String get activityGpxGenerationFailed =>
      'Det gick inte att skapa aktivitetens GPX-fil.';

  @override
  String get activityLocalSaveFailed =>
      'Det gick inte att spara den här aktiviteten på den här enheten.';

  @override
  String get activityOpenSettings => 'Öppna inställningar';

  @override
  String get activityPause => 'Pausa';

  @override
  String get activityRecordingEmpty => 'Inga GPS-punkter spelades in.';

  @override
  String get activityRecordingFailed => 'Inspelningen misslyckades.';

  @override
  String get activityResume => 'Återuppta';

  @override
  String get activityRetryUpload => 'Försök ladda upp igen';

  @override
  String get activityDone => 'Klar';

  @override
  String get activityViewHistory => 'Visa historik';

  @override
  String get activityDeleteLocal => 'Ta bort lokal kopia';

  @override
  String get activityExportGpx => 'Dela GPX-fil';

  @override
  String get activityExportGpxSubject => 'Endurain-aktivitets-GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Ta bort lokal aktivitet?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Detta tar bort den lokala aktivitetsposten och GPX-filen från den här enheten.';

  @override
  String get activityStart => 'Starta';

  @override
  String get activityBackgroundPermissionTitle =>
      'Tillåt spårning i bakgrunden?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain behöver bakgrundsplats inställd på Alltid så att inspelningen fortsätter när appen är i bakgrunden, skärmen är låst eller du byter app.';

  @override
  String get activityBackgroundPermissionContinue => 'Fortsätt';

  @override
  String get activityBackgroundPermissionRequired =>
      'Spårning i bakgrunden på iPhone och iPad kräver att Plats är inställt på Alltid.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Spårning i bakgrunden är av';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'För att spela in tillförlitligt i bakgrunden eller med låst skärm, öppna Inställningar och ställ in Plats på Alltid för Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Spelar in aktivitet';

  @override
  String get activityTrackingNotificationText =>
      'Endurain spårar din plats för att spela in den här aktiviteten.';

  @override
  String get activityStatDistance => 'Distans';

  @override
  String get activityStatDuration => 'Tid';

  @override
  String get activityStatSpeed => 'Hastighet';

  @override
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Maxhastighet';

  @override
  String get activityStatElevationGain => 'Stigning';

  @override
  String get activityStatHeartRate => 'Puls';

  @override
  String get activityStatAvgHeartRate => 'Medelpuls';

  @override
  String get activityStatPower => 'Effekt';

  @override
  String get activityStatAvgPower => 'Medeleffekt';

  @override
  String get activityStatCadence => 'Kadens';

  @override
  String get activityStatAvgCadence => 'Medelkadens';

  @override
  String get activityStop => 'Stoppa';

  @override
  String get activityStopAndSave => 'Stoppa och spara';

  @override
  String get activityStopConfirmMessage =>
      'Välj om du vill behålla den här inspelningen eller slänga den.';

  @override
  String get activityStopConfirmTitle => 'Avsluta aktiviteten?';

  @override
  String get activityStopping => 'Stoppar';

  @override
  String get activityTypeHike => 'Vandring';

  @override
  String get activityTypeLabel => 'Aktivitetstyp';

  @override
  String get activityTypeOther => 'Annat';

  @override
  String get activityTypeRide => 'Cykling';

  @override
  String get activityTypeRun => 'Löpning';

  @override
  String get activityTypeWalk => 'Promenad';

  @override
  String get activityUploadFailed => 'Uppladdningen misslyckades';

  @override
  String get activityUploadCleanupFailed =>
      'Uppladdad, men rensningen misslyckades';

  @override
  String get activityUploadReady => 'Redo att laddas upp';

  @override
  String get activityUploaded => 'Uppladdad';

  @override
  String get activityUploading => 'Laddar upp';

  @override
  String get activityUploadStatusPending => 'Väntar';

  @override
  String get activityUploadStatusUploaded => 'Uppladdad';

  @override
  String get activityUploadStatusFailed => 'Misslyckades';

  @override
  String get activityHistoryTitle => 'Aktivitetshistorik';

  @override
  String get activityHistorySettingsSubtitle =>
      'Slutförda aktiviteter sparade på den här enheten';

  @override
  String get activityRetainUploadedGpx => 'Behåll uppladdade GPX-filer';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Sparar slutförda ruttfiler i appens privata lagring efter uppladdning.';

  @override
  String get activityHistoryEmpty =>
      'Inga slutförda aktiviteter sparade på den här enheten.';

  @override
  String get activityHistoryLoadFailed =>
      'Det gick inte att läsa in lokala aktiviteter.';

  @override
  String get activityHistoryRefresh => 'Uppdatera';

  @override
  String get activityHistoryLocalActivities => 'Lokala aktiviteter';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Varaktighet: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distans: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Uppladdning: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Läs in mer';

  @override
  String get activityHistoryDetailsTitle => 'Aktivitetsinformation';

  @override
  String get activityHistoryDetailsMissing =>
      'Den här lokala aktiviteten är inte längre tillgänglig.';

  @override
  String get activityHistorySummary => 'Sammanfattning';

  @override
  String get activityHistoryActions => 'Åtgärder';

  @override
  String get activityHistoryType => 'Typ';

  @override
  String get activityHistoryStartedAt => 'Startade';

  @override
  String get activityHistoryEndedAt => 'Avslutades';

  @override
  String get activityHistoryDurationLabel => 'Varaktighet';

  @override
  String get activityHistoryDistanceLabel => 'Distans';

  @override
  String get activityHistoryAverageSpeed => 'Genomsnittlig hastighet';

  @override
  String get activityHistoryPointCount => 'GPS-punkter';

  @override
  String get activityHistoryUploadStatusLabel => 'Uppladdning';

  @override
  String get activityHistoryGpxStatus => 'GPX-fil';

  @override
  String get activityHistoryGpxAvailable => 'Sparad på den här enheten';

  @override
  String get activityHistoryGpxMissing => 'Inte tillgänglig på den här enheten';

  @override
  String get mapTab => 'Karta';

  @override
  String get myLocation => 'Min plats';

  @override
  String get settingsTab => 'Inställningar';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® är ett registrerat varumärke som tillhör João Vitória Silva';

  @override
  String get settingsScreen => 'Inställningar';

  @override
  String get deviceAccessTitle => 'Enhetsåtkomst';

  @override
  String get deviceAccessSubtitle => 'Hantera plats- och hälsodataåtkomst';

  @override
  String get deviceAccessLocationSection => 'Plats';

  @override
  String get deviceAccessHealthSection => 'Hälsodata';

  @override
  String get deviceAccessLocationTitle => 'Platsåtkomst';

  @override
  String get deviceAccessHealthTitle => 'Tillgång till hälsodata';

  @override
  String get deviceAccessChecking => 'Kontrollerar åtkomst...';

  @override
  String get deviceAccessLocationServicesOff => 'Platstjänster är avstängda';

  @override
  String get deviceAccessLocationAlways => 'Tillåts hela tiden';

  @override
  String get deviceAccessLocationWhileUsing => 'Tillåtet när du använder appen';

  @override
  String get deviceAccessLocationBlocked => 'Blockerad i systeminställningar';

  @override
  String get deviceAccessLocationNotAllowed => 'Inte tillåtet';

  @override
  String get deviceAccessHealthUnavailable =>
      'Ej tillgängligt på den här enheten';

  @override
  String get deviceAccessHealthRequired => 'Health Connect krävs';

  @override
  String get deviceAccessHealthSetUp => 'Hälsoåtkomst ställs in';

  @override
  String get deviceAccessHealthNeedsAttention =>
      'Tillgång kräver uppmärksamhet';

  @override
  String get deviceAccessHealthNotConnected => 'Ej ansluten';

  @override
  String get language => 'Språk';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Logga in';

  @override
  String get signInConnectServerSubtitle =>
      'Spela in offline nu och synkronisera dina aktiviteter senare';

  @override
  String get serverSettingsTitle => 'Serverinställningar';

  @override
  String connectedToServer(String server) {
    return 'Ansluten till $server';
  }

  @override
  String get loggedIn => 'Inloggad';

  @override
  String get notConfigured => 'Inte konfigurerad';

  @override
  String get notLoggedIn => 'Inte inloggad';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverProtocol => 'Protokoll';

  @override
  String get serverUrlHint => 'https://exempel.com';

  @override
  String get warnHttpServerUrlTitle => 'Osäker anslutning';

  @override
  String get warnHttpServerUrlMessage =>
      'Den här server-URL:en använder vanlig HTTP. Dina inloggningsuppgifter och data överförs utan kryptering. Fortsätt bara om du förstår och accepterar risken.';

  @override
  String get warnHttpServerUrlConfirm => 'Fortsätt ändå';

  @override
  String get tileServerUrl => 'URL till kartruteserver';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Annan värd för kartruteserver';

  @override
  String get tileServerHostWarningMessage =>
      'Värden för kartruteservern skiljer sig från din Endurain-servers värd. Rutorna läses in från en tredjepartsserver. Vill du fortsätta?';

  @override
  String get savedSuccessfully => 'Inställningarna har sparats';

  @override
  String get diagnostics => 'Diagnostik';

  @override
  String get diagnosticsSubtitle => 'Lokal kraschkontext';

  @override
  String get sourceCode => 'Källkod';

  @override
  String get sourceCodeSubtitle =>
      'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Det gick inte att öppna länken';

  @override
  String get diagnosticsTitle => 'Diagnostik';

  @override
  String get diagnosticsCollection => 'Insamling';

  @override
  String get diagnosticsEnable => 'Samla in diagnostik';

  @override
  String get diagnosticsEnableSubtitle =>
      'Lagra appens senaste händelser och fel på den här enheten';

  @override
  String get diagnosticsDisabled =>
      'Insamling av diagnostik är avstängd. Slå på den för att börja registrera appens händelser och fel på den här enheten.';

  @override
  String get diagnosticsEmpty => 'Ingen diagnostik har fångats ännu.';

  @override
  String get diagnosticsCopy => 'Kopiera';

  @override
  String get diagnosticsCopied => 'Diagnostik kopierad';

  @override
  String get diagnosticsClear => 'Rensa';

  @override
  String get diagnosticsCleared => 'Diagnostik rensad';

  @override
  String get diagnosticsSummary => 'Sammanfattning';

  @override
  String get diagnosticsLastUpdated => 'Senast uppdaterad';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Händelser: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Fel: $count';
  }

  @override
  String get diagnosticsEvents => 'Händelser';

  @override
  String get diagnosticsNoEvents => 'Inga händelser fångade';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Händelse: $event';
  }

  @override
  String get diagnosticsErrors => 'Fel';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Fel: $type';
  }

  @override
  String get diagnosticsActions => 'Åtgärder';

  @override
  String get diagnosticsRawReport => 'Obearbetad rapport';

  @override
  String get healthSyncSettingsTitle => 'Hälsosynk';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importera träningspass från din hälsoplattform';

  @override
  String get healthSyncScreenTitle => 'Hälsosynk';

  @override
  String get healthAccessScreenTitle => 'Tillgång till hälsa';

  @override
  String get healthAccessRequestedData => 'Begärda uppgifter';

  @override
  String get healthAccessWorkouts => 'Träningspass';

  @override
  String get healthAccessWorkoutRoutes => 'Träningsvägar';

  @override
  String get healthAccessHeartRate => 'Puls';

  @override
  String get healthAccessWorkoutSummary => 'Träningsdistans, kalorier och steg';

  @override
  String get healthAccessAllowed => 'Tillåtet';

  @override
  String get healthAccessNeedsAttention => 'Behöver uppmärksamhet';

  @override
  String get healthAccessManagedBySystem => 'Hanteras i systeminställningar';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit avslöjar inte vilken data Endurain kan läsa. Granska åtkomst i Health-appen.';

  @override
  String get healthAccessReview => 'Granska hälsotillgång';

  @override
  String get healthAccessReviewIos => 'Hur man granskar åtkomst';

  @override
  String get healthAccessDisconnect => 'Koppla från hälsodata';

  @override
  String get healthAccessDisconnectTitle => 'Koppla från hälsodata?';

  @override
  String get healthAccessDisconnectMessage =>
      'Automatisk import och lokal importhistorik för den här servern återställs. Befintliga aktiviteter finns kvar i historiken.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Öppna Health-appen, tryck på din profilbild och sedan på Appar och tjänster. Välj Endurain och uppdatera datakategorierna.';

  @override
  String get healthSyncAuthorize => 'Anslut till hälsodata';

  @override
  String get healthSyncInstallProvider => 'Installera Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Health Connect krävs för att synkronisera träningspass. Installera den för att fortsätta.';

  @override
  String get healthSyncUnsupported =>
      'Hälsosynkronisering är inte tillgänglig på den här enheten.';

  @override
  String get healthSyncSelectAll => 'Välj alla';

  @override
  String get healthSyncClearSelection => 'Rensa';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importera vald ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Importerade $count träning(er).';
  }

  @override
  String get healthSyncNoRouteLabel => 'Ingen GPS-rutt';

  @override
  String get healthSyncEmptyState =>
      'Inga träningspass hittades under den valda perioden.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Vissa träningspass hoppades över eftersom tillgång till träningsväg inte beviljades. Öppna Health Connect → Behörigheter och tillåt träningsrutter för Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Vissa träningspass hoppades över eftersom Endurain inte kunde läsa deras GPS-rutter. Öppna din profil i Health-appen, sedan Appar och tjänster, välj Endurain och tillåt träningsrutter.';

  @override
  String get healthSyncReviewAccess => 'Granska åtkomst';

  @override
  String get healthSyncAutoSyncTitle => 'Automatisk synkronisering vid CV';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importera nya träningspass automatiskt när appen öppnas.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Dessa träningspass inkluderar inte en GPS-rutt, så de kan inte importeras. Vissa appar (som Garmin Connect) registrerar aktiviteter till Apple Health utan att dela rutten. Träningspass inspelade med Apple Watch inkluderar rutter och kan importeras.';

  @override
  String get healthSyncBadgeNonImportable => 'Ej importerbar';

  @override
  String get healthSyncViewAvailable => 'Tillgängliga';

  @override
  String get healthSyncViewImported => 'Importerade';

  @override
  String get healthSyncDateRange => 'Träningsperiod';

  @override
  String get healthSyncRange30Days => 'Senaste 30 dagarna';

  @override
  String get healthSyncRange3Months => 'Senaste 3 månaderna';

  @override
  String get healthSyncRange6Months => 'Senaste 6 månaderna';

  @override
  String get healthSyncRangeYear => 'Senaste året';

  @override
  String get healthSyncRangeAll => 'Hela historiken';

  @override
  String get healthSyncRangeCustom => 'Anpassad period';

  @override
  String get healthSyncImportedEmpty =>
      'Inga importerade träningspass för denna anslutning.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importerad: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Återställ';

  @override
  String get sensorsTitle => 'Sensorer';

  @override
  String get sensorsSettingsSubtitle => 'Pulsmätare och andra externa sensorer';

  @override
  String get sensorsHeartRateSection => 'Puls';

  @override
  String get sensorsHeartRateHelp =>
      'Parkoppla en Bluetooth-pulsmätare för att se din puls live.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth är av. Slå på det för att ansluta en sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Tillåt Bluetooth-åtkomst för att ansluta en sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Den här enheten stöder inte Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Sök efter sensorer';

  @override
  String get sensorsScanning => 'Söker…';

  @override
  String get sensorsStopScan => 'Stoppa';

  @override
  String get sensorsNoDevices => 'Inga pulssensorer hittades ännu.';

  @override
  String get sensorsAvailableSection => 'Tillgängliga sensorer';

  @override
  String get sensorsSavedSection => 'Sparad sensor';

  @override
  String get sensorsConnect => 'Anslut';

  @override
  String get sensorsConnecting => 'Ansluter…';

  @override
  String get sensorsConnected => 'Ansluten';

  @override
  String get sensorsDisconnect => 'Koppla från';

  @override
  String get sensorsForget => 'Glöm';

  @override
  String get sensorsConnectionFailed => 'Kunde inte ansluta. Försök igen.';

  @override
  String get sensorsPermissionRequired =>
      'Bluetooth-behörighet krävs för att hitta sensorer.';

  @override
  String get sensorsUnknownDevice => 'Okänd sensor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Effekt';

  @override
  String get sensorsPowerHelp =>
      'Parkoppla en Bluetooth-effektmätare för att se din effekt live.';

  @override
  String get sensorsNoPowerDevices => 'Inga effektmätare hittades ännu.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Kadens';

  @override
  String get sensorsCadenceHelp =>
      'Parkoppla en Bluetooth-kadenssensor för att se din kadens live.';

  @override
  String get sensorsNoCadenceDevices => 'Inga kadenssensorer hittades ännu.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Fjärrkraschrapportering';

  @override
  String get diagnosticsRemoteEnable => 'Skicka kraschrapporter';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Skicka krasch- och felrapporter till en diagnostikserver. Detta är skilt från lokal diagnostik — du kan aktivera båda, en eller ingen.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Fjärrkraschrapportering är inte tillgänglig i den här versionen.';

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
  String get unitsTitle => 'Enheter';

  @override
  String get unitsSubtitle => 'Enheter för distans, hastighet och höjd';

  @override
  String get unitsSystemDefault => 'Följ enhetens region';

  @override
  String get unitsMetric => 'Metriskt (km)';

  @override
  String get unitsImperial => 'Imperiellt (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';
}
