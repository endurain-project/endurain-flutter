// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get error => 'Feil';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Avbryt';

  @override
  String get save => 'Lagre';

  @override
  String get back => 'Tilbake';

  @override
  String get requiredField => 'Dette feltet er påkrevd';

  @override
  String get invalidUrl => 'Skriv inn en gyldig URL';

  @override
  String get errorActivityUploadFailed => 'Kunne ikke laste opp aktiviteten';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Kunne ikke laste opp aktiviteten: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Opplasting av aktiviteter er ikke konfigurert ennå';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Kunne ikke slette den midlertidige aktivitetsfilen';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Kunne ikke forberede filen for opplasting av aktiviteten';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Fant ikke denne lokale aktiviteten';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Kunne ikke slette den lokale aktiviteten';

  @override
  String get errorActivityLocalGpxMissing =>
      'Den lokale GPX-filen er ikke tilgjengelig';

  @override
  String get errorActivityLocalLoadFailed =>
      'Kunne ikke laste inn lokale aktiviteter';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Kunne ikke lagre denne aktiviteten';

  @override
  String get errorActivityLocalSaveFailed =>
      'Kunne ikke lagre aktiviteten lokalt';

  @override
  String get errorFetchProvidersFailed =>
      'Kunne ikke laste inn påloggingsleverandører';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Kunne ikke laste inn påloggingsleverandører: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Kunne ikke laste inn serverinnstillinger';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Kunne ikke laste inn serverinnstillinger: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Kunne ikke konvertere treningen til GPX';

  @override
  String get errorHealthImportFailed => 'Kunne ikke importere treningsøkten';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Kunne ikke importere treningsøkten: $details';
  }

  @override
  String get errorHealthPermissionDenied => 'Helsedatatilgang ble nektet';

  @override
  String get errorHealthReadFailed => 'Kunne ikke lese helsedata';

  @override
  String get errorLoginError => 'Kunne ikke logge inn';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Kunne ikke logge inn: $details';
  }

  @override
  String get errorLoginFailed => 'Pålogging mislyktes';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Pålogging mislyktes: $details';
  }

  @override
  String get errorMfaVerificationError => 'Kunne ikke verifisere MFA-koden';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Kunne ikke verifisere MFA-koden: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA-verifisering mislyktes';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA-verifisering mislyktes: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Ingen økt-ID ble mottatt fra serveren';

  @override
  String get errorNotAuthenticated => 'Du er ikke pålogget';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Påloggingsverifikatoren ble ikke funnet. Start påloggingen på nytt.';

  @override
  String get errorServerUrlNotConfigured => 'Server-URL er ikke konfigurert';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Denne serveren krever en sikker (HTTPS-)tilkobling';

  @override
  String get errorSessionExpired => 'Økten din er utløpt. Logg inn på nytt.';

  @override
  String get errorSsoTokenExchangeError => 'Kunne ikke fullføre SSO-pålogging';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Kunne ikke fullføre SSO-pålogging: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Tokenutveksling mislyktes';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Tokenutveksling mislyktes: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Forespørselen ble tidsavbrutt. Sjekk tilkoblingen og prøv igjen.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Kan ikke slette fra sikker lagring. Enhetens lagring er kanskje ikke tilgjengelig.';

  @override
  String get errorSecureStorageReadFailed =>
      'Kan ikke lese fra sikker lagring. Enhetens lagring er kanskje ikke tilgjengelig.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Kan ikke skrive til sikker lagring. Enhetens lagring er kanskje ikke tilgjengelig.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Serveren returnerte et uventet svar';

  @override
  String get errorUnsupportedHttpMethod => 'HTTP-metoden støttes ikke';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'HTTP-metoden støttes ikke: $details';
  }

  @override
  String get loginTitle => 'Logg inn';

  @override
  String get login => 'Logg inn';

  @override
  String get logout => 'Logg ut';

  @override
  String get logoutConfirmTitle => 'Logg ut';

  @override
  String get logoutConfirmMessage => 'Er du sikker på at du vil logge ut?';

  @override
  String get logoutServerFailedWarning =>
      'Kunne ikke logge ut fra serveren, men logget ut lokalt';

  @override
  String get ssoBrowserLaunchFailed =>
      'Kunne ikke åpne SSO-pålogging i systemnettleseren';

  @override
  String ssoSignInWith(String provider) {
    return 'Logg inn med $provider';
  }

  @override
  String get ssoOrDivider => 'ELLER';

  @override
  String get next => 'Neste';

  @override
  String get username => 'Brukernavn';

  @override
  String get usernameHint => 'Skriv inn brukernavnet ditt';

  @override
  String get password => 'Passord';

  @override
  String get passwordHint => 'Skriv inn passordet ditt';

  @override
  String get showPassword => 'Vis passord';

  @override
  String get mfaTitle => 'Tofaktorautentisering';

  @override
  String get mfaCode => 'MFA-kode';

  @override
  String get mfaCodeHint => 'Skriv inn den 6-sifrede koden';

  @override
  String get mfaCodeRequired => 'Skriv inn MFA-koden';

  @override
  String get verify => 'Verifiser';

  @override
  String get activityDiscard => 'Forkast';

  @override
  String get activityDiscardConfirmMessage =>
      'Dette sletter de registrerte punktene for denne aktiviteten.';

  @override
  String get activityDiscardConfirmTitle => 'Forkaste aktiviteten?';

  @override
  String get activityLocationPermissionDenied =>
      'Posisjonstillatelse kreves for å registrere en aktivitet.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Posisjonstillatelsen er blokkert. Åpne innstillingene for å tillate posisjonstilgang.';

  @override
  String get activityLocationServiceDisabled =>
      'Posisjonstjenester er deaktivert.';

  @override
  String get activityLocationStreamFailed =>
      'Posisjonsoppdateringene stoppet uventet.';

  @override
  String get activityGpxGenerationFailed =>
      'Kunne ikke opprette aktivitetens GPX-fil.';

  @override
  String get activityLocalSaveFailed =>
      'Kunne ikke lagre denne aktiviteten på denne enheten.';

  @override
  String get activityOpenSettings => 'Åpne innstillinger';

  @override
  String get activityPause => 'Pause';

  @override
  String get activityRecordingEmpty => 'Ingen GPS-punkter ble registrert.';

  @override
  String get activityRecordingFailed => 'Registreringen mislyktes.';

  @override
  String get activityResume => 'Fortsett';

  @override
  String get activityRetryUpload => 'Prøv opplasting på nytt';

  @override
  String get activityDone => 'Ferdig';

  @override
  String get activityViewHistory => 'Vis historikk';

  @override
  String get activityDeleteLocal => 'Slett lokal kopi';

  @override
  String get activityExportGpx => 'Del GPX-fil';

  @override
  String get activityExportGpxSubject => 'Endurain-aktivitets-GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Slette lokal aktivitet?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Dette fjerner den lokale aktivitetsoppføringen og GPX-filen fra denne enheten.';

  @override
  String get activityStart => 'Start';

  @override
  String get activityBackgroundPermissionTitle =>
      'Tillate sporing i bakgrunnen?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain trenger bakgrunnsposisjon satt til Alltid slik at registreringen fortsetter når appen er i bakgrunnen, skjermen er låst eller du bytter app.';

  @override
  String get activityBackgroundPermissionContinue => 'Fortsett';

  @override
  String get activityBackgroundPermissionRequired =>
      'Sporing i bakgrunnen på iPhone og iPad krever at Posisjon er satt til Alltid.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Sporing i bakgrunnen er av';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'For å registrere pålitelig i bakgrunnen eller med låst skjerm, åpne Innstillinger og sett Posisjon til Alltid for Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Registrerer aktivitet';

  @override
  String get activityTrackingNotificationText =>
      'Endurain sporer posisjonen din for å registrere denne aktiviteten.';

  @override
  String get activityStatDistance => 'Distanse';

  @override
  String get activityStatDuration => 'Tid';

  @override
  String get activityStatSpeed => 'Fart';

  @override
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Maks. fart';

  @override
  String get activityStatElevationGain => 'Stigning';

  @override
  String get activityStatHeartRate => 'Puls';

  @override
  String get activityStatAvgHeartRate => 'Gj.sn. puls';

  @override
  String get activityStatPower => 'Effekt';

  @override
  String get activityStatAvgPower => 'Gj.sn. effekt';

  @override
  String get activityStatCadence => 'Kadens';

  @override
  String get activityStatAvgCadence => 'Gj.sn. kadens';

  @override
  String get activityStop => 'Stopp';

  @override
  String get activityStopAndSave => 'Stopp og lagre';

  @override
  String get activityStopConfirmMessage =>
      'Velg om du vil beholde dette opptaket eller forkaste det.';

  @override
  String get activityStopConfirmTitle => 'Avslutte aktiviteten?';

  @override
  String get activityStopping => 'Stopper';

  @override
  String get activityTypeHike => 'Fottur';

  @override
  String get activityTypeLabel => 'Aktivitetstype';

  @override
  String get activityTypeOther => 'Annet';

  @override
  String get activityTypeRide => 'Sykling';

  @override
  String get activityTypeRun => 'Løping';

  @override
  String get activityTypeWalk => 'Gåtur';

  @override
  String get activityUploadFailed => 'Opplasting mislyktes';

  @override
  String get activityUploadCleanupFailed =>
      'Lastet opp, men opprydding mislyktes';

  @override
  String get activityUploadReady => 'Klar til opplasting';

  @override
  String get activityUploaded => 'Lastet opp';

  @override
  String get activityUploading => 'Laster opp';

  @override
  String get activityUploadStatusPending => 'Venter';

  @override
  String get activityUploadStatusUploaded => 'Lastet opp';

  @override
  String get activityUploadStatusFailed => 'Mislyktes';

  @override
  String get activityHistoryTitle => 'Aktivitetshistorikk';

  @override
  String get activityHistorySettingsSubtitle =>
      'Fullførte aktiviteter lagret på denne enheten';

  @override
  String get activityRetainUploadedGpx => 'Behold opplastede GPX-filer';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Lagrer fullførte rutefiler i appens private lagring etter opplasting.';

  @override
  String get activityHistoryEmpty =>
      'Ingen fullførte aktiviteter lagret på denne enheten.';

  @override
  String get activityHistoryLoadFailed =>
      'Kunne ikke laste inn lokale aktiviteter.';

  @override
  String get activityHistoryRefresh => 'Oppdater';

  @override
  String get activityHistoryLocalActivities => 'Lokale aktiviteter';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Varighet: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distanse: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Opplasting: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Last inn mer';

  @override
  String get activityHistoryDetailsTitle => 'Aktivitetsdetaljer';

  @override
  String get activityHistoryDetailsMissing =>
      'Denne lokale aktiviteten er ikke lenger tilgjengelig.';

  @override
  String get activityHistorySummary => 'Sammendrag';

  @override
  String get activityHistoryActions => 'Handlinger';

  @override
  String get activityHistoryType => 'Type';

  @override
  String get activityHistoryStartedAt => 'Startet';

  @override
  String get activityHistoryEndedAt => 'Avsluttet';

  @override
  String get activityHistoryDurationLabel => 'Varighet';

  @override
  String get activityHistoryDistanceLabel => 'Distanse';

  @override
  String get activityHistoryAverageSpeed => 'Gjennomsnittsfart';

  @override
  String get activityHistoryPointCount => 'GPS-punkter';

  @override
  String get activityHistoryUploadStatusLabel => 'Opplasting';

  @override
  String get activityHistoryGpxStatus => 'GPX-fil';

  @override
  String get activityHistoryGpxAvailable => 'Lagret på denne enheten';

  @override
  String get activityHistoryGpxMissing => 'Ikke tilgjengelig på denne enheten';

  @override
  String get mapTab => 'Kart';

  @override
  String get myLocation => 'Min posisjon';

  @override
  String get settingsTab => 'Innstillinger';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® er et registrert varemerke som tilhører João Vitória Silva';

  @override
  String get settingsScreen => 'Innstillinger';

  @override
  String get deviceAccessTitle => 'Enhetstilgang';

  @override
  String get deviceAccessSubtitle =>
      'Administrer tilgang til plassering og helsedata';

  @override
  String get deviceAccessLocationSection => 'Beliggenhet';

  @override
  String get deviceAccessHealthSection => 'Helsedata';

  @override
  String get deviceAccessLocationTitle => 'Stedstilgang';

  @override
  String get deviceAccessHealthTitle => 'Helsedatatilgang';

  @override
  String get deviceAccessChecking => 'Sjekker tilgang …';

  @override
  String get deviceAccessLocationServicesOff => 'Stedstjenester er slått av';

  @override
  String get deviceAccessLocationAlways => 'Tillatt hele tiden';

  @override
  String get deviceAccessLocationWhileUsing => 'Tillatt mens du bruker appen';

  @override
  String get deviceAccessLocationBlocked => 'Blokkert i systeminnstillingene';

  @override
  String get deviceAccessLocationNotAllowed => 'Ikke tillatt';

  @override
  String get deviceAccessHealthUnavailable =>
      'Ikke tilgjengelig på denne enheten';

  @override
  String get deviceAccessHealthRequired => 'Health Connect er påkrevd';

  @override
  String get deviceAccessHealthSetUp => 'Helsetilgang satt opp';

  @override
  String get deviceAccessHealthNeedsAttention =>
      'Tilgang trenger oppmerksomhet';

  @override
  String get deviceAccessHealthNotConnected => 'Ikke tilkoblet';

  @override
  String get language => 'Språk';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Logg inn';

  @override
  String get signInConnectServerSubtitle =>
      'Registrer offline nå og synkroniser aktivitetene senere';

  @override
  String get serverSettingsTitle => 'Serverinnstillinger';

  @override
  String connectedToServer(String server) {
    return 'Koblet til $server';
  }

  @override
  String get loggedIn => 'Pålogget';

  @override
  String get notConfigured => 'Ikke konfigurert';

  @override
  String get notLoggedIn => 'Ikke pålogget';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverProtocol => 'Protokoll';

  @override
  String get serverUrlHint => 'https://eksempel.com';

  @override
  String get warnHttpServerUrlTitle => 'Usikker tilkobling';

  @override
  String get warnHttpServerUrlMessage =>
      'Denne server-URL-en bruker vanlig HTTP. Påloggingsinformasjonen og dataene dine overføres uten kryptering. Fortsett bare hvis du forstår og godtar risikoen.';

  @override
  String get warnHttpServerUrlConfirm => 'Fortsett likevel';

  @override
  String get tileServerUrl => 'URL for kartflisserver';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Annen flisserververt';

  @override
  String get tileServerHostWarningMessage =>
      'Verten til flisserveren er forskjellig fra verten til Endurain-serveren din. Fliser lastes fra en tredjepartsserver. Vil du fortsette?';

  @override
  String get savedSuccessfully => 'Innstillingene ble lagret';

  @override
  String get diagnostics => 'Diagnostikk';

  @override
  String get diagnosticsSubtitle => 'Lokal krasjkontekst';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Kunne ikke åpne lenken';

  @override
  String get diagnosticsTitle => 'Diagnostikk';

  @override
  String get diagnosticsCollection => 'Innsamling';

  @override
  String get diagnosticsEnable => 'Samle inn diagnostikk';

  @override
  String get diagnosticsEnableSubtitle =>
      'Lagre nylige apphendelser og feil på denne enheten';

  @override
  String get diagnosticsDisabled =>
      'Innsamling av diagnostikk er av. Slå den på for å begynne å registrere apphendelser og feil på denne enheten.';

  @override
  String get diagnosticsEmpty => 'Ingen diagnostikk er fanget opp ennå.';

  @override
  String get diagnosticsCopy => 'Kopier';

  @override
  String get diagnosticsCopied => 'Diagnostikk kopiert';

  @override
  String get diagnosticsClear => 'Tøm';

  @override
  String get diagnosticsCleared => 'Diagnostikk tømt';

  @override
  String get diagnosticsSummary => 'Sammendrag';

  @override
  String get diagnosticsLastUpdated => 'Sist oppdatert';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Hendelser: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Feil: $count';
  }

  @override
  String get diagnosticsEvents => 'Hendelser';

  @override
  String get diagnosticsNoEvents => 'Ingen hendelser fanget opp';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Hendelse: $event';
  }

  @override
  String get diagnosticsErrors => 'Feil';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Feil: $type';
  }

  @override
  String get diagnosticsActions => 'Handlinger';

  @override
  String get diagnosticsRawReport => 'Rårapport';

  @override
  String get healthSyncSettingsTitle => 'Helsesynkronisering';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importer treningsøkter fra helseplattformen din';

  @override
  String get healthSyncScreenTitle => 'Helsesynkronisering';

  @override
  String get healthAccessScreenTitle => 'Helsetilgang';

  @override
  String get healthAccessRequestedData => 'Forespurte data';

  @override
  String get healthAccessWorkouts => 'Treninger';

  @override
  String get healthAccessWorkoutRoutes => 'Treningsruter';

  @override
  String get healthAccessHeartRate => 'Hjertefrekvens';

  @override
  String get healthAccessWorkoutSummary =>
      'Treningsdistanse, kalorier og skritt';

  @override
  String get healthAccessAllowed => 'Tillatt';

  @override
  String get healthAccessNeedsAttention => 'Trenger oppmerksomhet';

  @override
  String get healthAccessManagedBySystem =>
      'Administrert i systeminnstillinger';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit avslører ikke hvilke data Endurain kan lese. Se gjennom tilgangen i Helse-appen.';

  @override
  String get healthAccessReview => 'Gjennomgå helsetilgang';

  @override
  String get healthAccessReviewIos => 'Hvordan vurdere tilgang';

  @override
  String get healthAccessDisconnect => 'Koble fra helsedata';

  @override
  String get healthAccessDisconnectTitle => 'Koble fra helsedata?';

  @override
  String get healthAccessDisconnectMessage =>
      'Automatisk import og lokal importhistorikk for denne serveren tilbakestilles. Eksisterende aktiviteter blir værende i historikken.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Åpne Helse-appen, trykk på profilbildet ditt og deretter Apper og tjenester. Velg Endurain og oppdater datakategoriene.';

  @override
  String get healthSyncAuthorize => 'Koble til helsedata';

  @override
  String get healthSyncInstallProvider => 'Installer Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Health Connect kreves for å synkronisere treningsøkter. Installer den for å fortsette.';

  @override
  String get healthSyncUnsupported =>
      'Helsesynkronisering er ikke tilgjengelig på denne enheten.';

  @override
  String get healthSyncSelectAll => 'Velg alle';

  @override
  String get healthSyncClearSelection => 'Klart';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importer valgt ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Importerte $count trening(er).';
  }

  @override
  String get healthSyncNoRouteLabel => 'Ingen GPS-rute';

  @override
  String get healthSyncEmptyState =>
      'Ingen treningsøkter funnet i den valgte perioden.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Noen treningsøkter ble hoppet over fordi tilgang til treningsruter ikke ble gitt. Åpne Health Connect → Tillatelser og tillat treningsruter for Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Noen treningsøkter ble hoppet over fordi Endurain ikke kunne lese GPS-rutene deres. I Helse-appen åpner du profilen din, deretter Apper og tjenester, velg Endurain og tillat treningsruter.';

  @override
  String get healthSyncReviewAccess => 'Gjennomgå tilgang';

  @override
  String get healthSyncAutoSyncTitle => 'Automatisk synkronisering ved CV';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importer nye treningsøkter automatisk når appen åpnes.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Disse treningsøktene inkluderer ikke en GPS-rute, så de kan ikke importeres. Noen apper (som Garmin Connect) registrerer aktiviteter til Apple Health uten å dele ruten. Treningsøkter tatt opp med Apple Watch inkluderer ruter og kan importeres.';

  @override
  String get healthSyncBadgeNonImportable => 'Ikke-importerbar';

  @override
  String get healthSyncViewAvailable => 'Tilgjengelige';

  @override
  String get healthSyncViewImported => 'Importerte';

  @override
  String get healthSyncDateRange => 'Treningsperiode';

  @override
  String get healthSyncRange30Days => 'Siste 30 dager';

  @override
  String get healthSyncRange3Months => 'Siste 3 måneder';

  @override
  String get healthSyncRange6Months => 'Siste 6 måneder';

  @override
  String get healthSyncRangeYear => 'Siste år';

  @override
  String get healthSyncRangeAll => 'Hele historikken';

  @override
  String get healthSyncRangeCustom => 'Egendefinert periode';

  @override
  String get healthSyncImportedEmpty =>
      'Ingen importerte treninger for denne tilkoblingen.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importert: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Gjenopprett';

  @override
  String get sensorsTitle => 'Sensorer';

  @override
  String get sensorsSettingsSubtitle => 'Pulsmålere og andre eksterne sensorer';

  @override
  String get sensorsHeartRateSection => 'Puls';

  @override
  String get sensorsHeartRateHelp =>
      'Koble til en Bluetooth-pulsmåler for å se pulsen din live.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth er av. Slå det på for å koble til en sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Tillat Bluetooth-tilgang for å koble til en sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Denne enheten støtter ikke Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Søk etter sensorer';

  @override
  String get sensorsScanning => 'Søker…';

  @override
  String get sensorsStopScan => 'Stopp';

  @override
  String get sensorsNoDevices => 'Ingen pulssensorer funnet ennå.';

  @override
  String get sensorsAvailableSection => 'Tilgjengelige sensorer';

  @override
  String get sensorsSavedSection => 'Lagret sensor';

  @override
  String get sensorsConnect => 'Koble til';

  @override
  String get sensorsConnecting => 'Kobler til…';

  @override
  String get sensorsConnected => 'Tilkoblet';

  @override
  String get sensorsDisconnect => 'Koble fra';

  @override
  String get sensorsForget => 'Glem';

  @override
  String get sensorsConnectionFailed => 'Kunne ikke koble til. Prøv igjen.';

  @override
  String get sensorsPermissionRequired =>
      'Bluetooth-tillatelse kreves for å finne sensorer.';

  @override
  String get sensorsUnknownDevice => 'Ukjent sensor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Effekt';

  @override
  String get sensorsPowerHelp =>
      'Koble til en Bluetooth-effektmåler for å se effekten din live.';

  @override
  String get sensorsNoPowerDevices => 'Ingen effektmålere funnet ennå.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Kadens';

  @override
  String get sensorsCadenceHelp =>
      'Koble til en Bluetooth-kadenssensor for å se kadensen din live.';

  @override
  String get sensorsNoCadenceDevices => 'Ingen kadenssensorer funnet ennå.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Ekstern krasjrapportering';

  @override
  String get diagnosticsRemoteEnable => 'Send krasjrapporter';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Send krasj- og feilrapporter til en diagnoseserver. Dette er atskilt fra lokal diagnostikk; du kan slå på begge, én eller ingen.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Ekstern krasjrapportering er ikke tilgjengelig i denne versjonen.';

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
  String get unitsSubtitle => 'Enheter for distanse, hastighet og høyde';

  @override
  String get unitsSystemDefault => 'Følg enhetens region';

  @override
  String get unitsMetric => 'Metrisk (km)';

  @override
  String get unitsImperial => 'Imperisk (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';
}
