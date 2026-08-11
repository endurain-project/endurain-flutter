// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get error => 'Pogreška';

  @override
  String get ok => 'U redu';

  @override
  String get cancel => 'Odustani';

  @override
  String get save => 'Spremi';

  @override
  String get back => 'Natrag';

  @override
  String get requiredField => 'Ovo je polje obavezno';

  @override
  String get invalidUrl => 'Unesite valjani URL';

  @override
  String get errorActivityUploadFailed => 'Aktivnost nije moguće prenijeti';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Aktivnost nije moguće prenijeti: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Prijenos aktivnosti još nije konfiguriran';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Privremenu datoteku aktivnosti nije moguće izbrisati';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Datoteku za prijenos aktivnosti nije moguće pripremiti';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Ovu lokalnu aktivnost nije moguće pronaći';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Lokalnu aktivnost nije moguće izbrisati';

  @override
  String get errorActivityLocalGpxMissing =>
      'Lokalna GPX datoteka nije dostupna';

  @override
  String get errorActivityLocalLoadFailed =>
      'Lokalne aktivnosti nije moguće učitati';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Ovu aktivnost nije moguće spremiti';

  @override
  String get errorActivityLocalSaveFailed =>
      'Aktivnost nije moguće spremiti lokalno';

  @override
  String get errorFetchProvidersFailed =>
      'Davatelje prijave nije moguće učitati';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Davatelje prijave nije moguće učitati: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Postavke poslužitelja nije moguće učitati';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Postavke poslužitelja nije moguće učitati: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Nije moguće pretvoriti vježbanje u GPX';

  @override
  String get errorHealthImportFailed => 'Nije moguće uvesti vježbanje';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Nije moguće uvesti vježbu: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Pristup zdravstvenim podacima je odbijen';

  @override
  String get errorHealthReadFailed =>
      'Nije moguće pročitati zdravstvene podatke';

  @override
  String get errorLoginError => 'Prijava nije uspjela';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Prijava nije uspjela: $details';
  }

  @override
  String get errorLoginFailed => 'Neuspješna prijava';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Neuspješna prijava: $details';
  }

  @override
  String get errorMfaVerificationError => 'MFA kôd nije moguće provjeriti';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'MFA kôd nije moguće provjeriti: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Provjera MFA nije uspjela';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Provjera MFA nije uspjela: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Od poslužitelja nije primljen ID sesije';

  @override
  String get errorNotAuthenticated => 'Niste prijavljeni';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Verifikator prijave nije pronađen. Ponovno započnite prijavu.';

  @override
  String get errorServerUrlNotConfigured =>
      'URL poslužitelja nije konfiguriran';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Ovaj poslužitelj zahtijeva sigurnu (HTTPS) vezu';

  @override
  String get errorSessionExpired =>
      'Vaša je sesija istekla. Ponovno se prijavite.';

  @override
  String get errorSsoTokenExchangeError =>
      'Prijavu putem SSO-a nije moguće dovršiti';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Prijavu putem SSO-a nije moguće dovršiti: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Razmjena tokena nije uspjela';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Razmjena tokena nije uspjela: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Zahtjev je istekao. Provjerite vezu i pokušajte ponovno.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Nije moguće izbrisati iz sigurne pohrane. Pohrana uređaja možda nije dostupna.';

  @override
  String get errorSecureStorageReadFailed =>
      'Nije moguće čitati iz sigurne pohrane. Pohrana uređaja možda nije dostupna.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Nije moguće pisati u sigurnu pohranu. Pohrana uređaja možda nije dostupna.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Poslužitelj je vratio neočekivani odgovor';

  @override
  String get errorUnsupportedHttpMethod => 'Nepodržana HTTP metoda';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nepodržana HTTP metoda: $details';
  }

  @override
  String get loginTitle => 'Prijava';

  @override
  String get login => 'Prijava';

  @override
  String get logout => 'Odjava';

  @override
  String get logoutConfirmTitle => 'Odjava';

  @override
  String get logoutConfirmMessage => 'Jeste li sigurni da se želite odjaviti?';

  @override
  String get logoutServerFailedWarning =>
      'Odjava s poslužitelja nije uspjela, ali ste odjavljeni lokalno';

  @override
  String get ssoBrowserLaunchFailed =>
      'Prijavu putem SSO-a nije moguće otvoriti u sistemskom pregledniku';

  @override
  String ssoSignInWith(String provider) {
    return 'Prijava putem $provider';
  }

  @override
  String get ssoOrDivider => 'ILI';

  @override
  String get next => 'Dalje';

  @override
  String get username => 'Korisničko ime';

  @override
  String get usernameHint => 'Unesite svoje korisničko ime';

  @override
  String get password => 'Lozinka';

  @override
  String get passwordHint => 'Unesite svoju lozinku';

  @override
  String get showPassword => 'Prikaži lozinku';

  @override
  String get mfaTitle => 'Dvofaktorska autentifikacija';

  @override
  String get mfaCode => 'MFA kôd';

  @override
  String get mfaCodeHint => 'Unesite 6-znamenkasti kôd';

  @override
  String get mfaCodeRequired => 'Unesite MFA kôd';

  @override
  String get verify => 'Provjeri';

  @override
  String get activityDiscard => 'Odbaci';

  @override
  String get activityDiscardConfirmMessage =>
      'Time će se izbrisati zabilježene točke ove aktivnosti.';

  @override
  String get activityDiscardConfirmTitle => 'Odbaciti aktivnost?';

  @override
  String get activityLocationPermissionDenied =>
      'Za snimanje aktivnosti potrebno je dopuštenje za lokaciju.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Dopuštenje za lokaciju je blokirano. Otvorite postavke da biste dopustili pristup lokaciji.';

  @override
  String get activityLocationServiceDisabled =>
      'Lokacijske usluge su onemogućene.';

  @override
  String get activityLocationStreamFailed =>
      'Ažuriranja lokacije neočekivano su prestala.';

  @override
  String get activityGpxGenerationFailed =>
      'GPX datoteku aktivnosti nije moguće stvoriti.';

  @override
  String get activityLocalSaveFailed =>
      'Ovu aktivnost nije moguće spremiti na ovaj uređaj.';

  @override
  String get activityOpenSettings => 'Otvori postavke';

  @override
  String get activityPause => 'Pauziraj';

  @override
  String get activityRecordingEmpty => 'Nije zabilježena nijedna GPS točka.';

  @override
  String get activityRecordingFailed => 'Snimanje nije uspjelo.';

  @override
  String get activityResume => 'Nastavi';

  @override
  String get activityRetryUpload => 'Pokušaj prijenos ponovno';

  @override
  String get activityDone => 'Gotovo';

  @override
  String get activityViewHistory => 'Prikaži povijest';

  @override
  String get activityDeleteLocal => 'Izbriši lokalnu kopiju';

  @override
  String get activityExportGpx => 'Podijeli GPX datoteku';

  @override
  String get activityExportGpxSubject => 'GPX aktivnosti Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Izbrisati lokalnu aktivnost?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Time se s ovog uređaja uklanjaju zapis lokalne aktivnosti i GPX datoteka.';

  @override
  String get activityStart => 'Započni';

  @override
  String get activityBackgroundPermissionTitle =>
      'Dopustiti praćenje u pozadini?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain treba lokaciju u pozadini postavljenu na Uvijek kako bi se snimanje nastavilo kada je aplikacija u pozadini, zaslon je zaključan ili promijenite aplikaciju.';

  @override
  String get activityBackgroundPermissionContinue => 'Nastavi';

  @override
  String get activityBackgroundPermissionRequired =>
      'Praćenje u pozadini na iPhoneu i iPadu zahtijeva lokaciju postavljenu na Uvijek.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Praćenje u pozadini je isključeno';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Za pouzdano snimanje u pozadini ili sa zaključanim zaslonom otvorite Postavke i postavite Lokaciju na Uvijek za Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Snimanje aktivnosti';

  @override
  String get activityTrackingNotificationText =>
      'Endurain prati vašu lokaciju kako bi snimio ovu aktivnost.';

  @override
  String get activityStatDistance => 'Udaljenost';

  @override
  String get activityStatDuration => 'Vrijeme';

  @override
  String get activityStatSpeed => 'Brzina';

  @override
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Maks. brzina';

  @override
  String get activityStatElevationGain => 'Uspon';

  @override
  String get activityStatHeartRate => 'Puls';

  @override
  String get activityStatAvgHeartRate => 'Prosj. puls';

  @override
  String get activityStatPower => 'Snaga';

  @override
  String get activityStatAvgPower => 'Prosj. snaga';

  @override
  String get activityStatCadence => 'Kadenca';

  @override
  String get activityStatAvgCadence => 'Prosj. kadenca';

  @override
  String get activityStop => 'Zaustavi';

  @override
  String get activityStopAndSave => 'Zaustavi i spremi';

  @override
  String get activityStopConfirmMessage =>
      'Odaberite želite li zadržati ovo snimanje ili ga odbaciti.';

  @override
  String get activityStopConfirmTitle => 'Završiti aktivnost?';

  @override
  String get activityStopping => 'Zaustavljanje';

  @override
  String get activityTypeHike => 'Planinarenje';

  @override
  String get activityTypeLabel => 'Vrsta aktivnosti';

  @override
  String get activityTypeOther => 'Ostalo';

  @override
  String get activityTypeRide => 'Biciklizam';

  @override
  String get activityTypeRun => 'Trčanje';

  @override
  String get activityTypeWalk => 'Hodanje';

  @override
  String get activityUploadFailed => 'Prijenos nije uspio';

  @override
  String get activityUploadCleanupFailed =>
      'Preneseno, ali čišćenje nije uspjelo';

  @override
  String get activityUploadReady => 'Spremno za prijenos';

  @override
  String get activityUploaded => 'Preneseno';

  @override
  String get activityUploading => 'Prijenos';

  @override
  String get activityUploadStatusPending => 'Na čekanju';

  @override
  String get activityUploadStatusUploaded => 'Preneseno';

  @override
  String get activityUploadStatusFailed => 'Neuspješno';

  @override
  String get activityHistoryTitle => 'Povijest aktivnosti';

  @override
  String get activityHistorySettingsSubtitle =>
      'Dovršene aktivnosti spremljene na ovom uređaju';

  @override
  String get activityRetainUploadedGpx => 'Zadrži prenesene GPX datoteke';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Sprema dovršene datoteke ruta u privatnu pohranu aplikacije nakon prijenosa.';

  @override
  String get activityHistoryEmpty =>
      'Nema dovršenih aktivnosti spremljenih na ovom uređaju.';

  @override
  String get activityHistoryLoadFailed =>
      'Lokalne aktivnosti nije moguće učitati.';

  @override
  String get activityHistoryRefresh => 'Osvježi';

  @override
  String get activityHistoryLocalActivities => 'Lokalne aktivnosti';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Trajanje: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Udaljenost: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Prijenos: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Učitaj više';

  @override
  String get activityHistoryDetailsTitle => 'Pojedinosti aktivnosti';

  @override
  String get activityHistoryDetailsMissing =>
      'Ova lokalna aktivnost više nije dostupna.';

  @override
  String get activityHistorySummary => 'Sažetak';

  @override
  String get activityHistoryActions => 'Radnje';

  @override
  String get activityHistoryType => 'Vrsta';

  @override
  String get activityHistoryStartedAt => 'Početak';

  @override
  String get activityHistoryEndedAt => 'Završetak';

  @override
  String get activityHistoryDurationLabel => 'Trajanje';

  @override
  String get activityHistoryDistanceLabel => 'Udaljenost';

  @override
  String get activityHistoryAverageSpeed => 'Prosječna brzina';

  @override
  String get activityHistoryPointCount => 'GPS točke';

  @override
  String get activityHistoryUploadStatusLabel => 'Prijenos';

  @override
  String get activityHistoryGpxStatus => 'GPX datoteka';

  @override
  String get activityHistoryGpxAvailable => 'Spremljeno na ovom uređaju';

  @override
  String get activityHistoryGpxMissing => 'Nije dostupno na ovom uređaju';

  @override
  String get mapTab => 'Karta';

  @override
  String get myLocation => 'Moja lokacija';

  @override
  String get settingsTab => 'Postavke';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® je registrirani žig João Vitória Silve.';

  @override
  String get settingsScreen => 'Postavke';

  @override
  String get deviceAccessTitle => 'Pristup uređaju';

  @override
  String get deviceAccessSubtitle =>
      'Upravljanje lokacijom i pristupom zdravstvenim podacima';

  @override
  String get deviceAccessLocationSection => 'Lokacija';

  @override
  String get deviceAccessHealthSection => 'Zdravstveni podaci';

  @override
  String get deviceAccessLocationTitle => 'Pristup lokaciji';

  @override
  String get deviceAccessHealthTitle => 'Pristup zdravstvenim podacima';

  @override
  String get deviceAccessChecking => 'Provjera pristupa...';

  @override
  String get deviceAccessLocationServicesOff => 'Usluge lokacije su isključene';

  @override
  String get deviceAccessLocationAlways => 'Dopušteno cijelo vrijeme';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Dopušteno tijekom korištenja aplikacije';

  @override
  String get deviceAccessLocationBlocked => 'Blokirano u postavkama sustava';

  @override
  String get deviceAccessLocationNotAllowed => 'Nije dopušteno';

  @override
  String get deviceAccessHealthUnavailable => 'Nije dostupno na ovom uređaju';

  @override
  String get deviceAccessHealthRequired => 'Potrebno je Health Connect';

  @override
  String get deviceAccessHealthSetUp => 'Zdravstveni pristup postavljen';

  @override
  String get deviceAccessHealthNeedsAttention => 'Pristup zahtijeva pažnju';

  @override
  String get deviceAccessHealthNotConnected => 'Nije povezano';

  @override
  String get language => 'Jezik';

  @override
  String get languageSystemDefault => 'Zadano prema sustavu';

  @override
  String get serverSettings => 'Poslužitelj';

  @override
  String get signInConnectServer => 'Prijava';

  @override
  String get signInConnectServerSubtitle =>
      'Snimajte izvanmrežno sada i sinkronizirajte aktivnosti kasnije';

  @override
  String get serverSettingsTitle => 'Postavke poslužitelja';

  @override
  String connectedToServer(String server) {
    return 'Povezan na $server';
  }

  @override
  String get loggedIn => 'Prijavljeni';

  @override
  String get notConfigured => 'Nije konfigurirano';

  @override
  String get notLoggedIn => 'Niste prijavljeni';

  @override
  String get serverUrl => 'URL poslužitelja';

  @override
  String get serverProtocol => 'Protokol';

  @override
  String get serverUrlHint => 'https://primjer.com';

  @override
  String get warnHttpServerUrlTitle => 'Nesigurna veza';

  @override
  String get warnHttpServerUrlMessage =>
      'Ovaj URL poslužitelja koristi obični HTTP. Vaši podaci za prijavu i podaci prenosit će se bez enkripcije. Nastavite samo ako razumijete i prihvaćate rizik.';

  @override
  String get warnHttpServerUrlConfirm => 'Ipak nastavi';

  @override
  String get tileServerUrl => 'URL poslužitelja pločica karte';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle =>
      'Drugačiji host poslužitelja pločica';

  @override
  String get tileServerHostWarningMessage =>
      'Host poslužitelja pločica razlikuje se od hosta vašeg Endurain poslužitelja. Pločice će se učitati s poslužitelja treće strane. Želite li nastaviti?';

  @override
  String get savedSuccessfully => 'Postavke su uspješno spremljene';

  @override
  String get diagnostics => 'Dijagnostika';

  @override
  String get diagnosticsSubtitle => 'Lokalni kontekst rušenja';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Poveznicu nije moguće otvoriti';

  @override
  String get diagnosticsTitle => 'Dijagnostika';

  @override
  String get diagnosticsCollection => 'Prikupljanje';

  @override
  String get diagnosticsEnable => 'Prikupljaj dijagnostiku';

  @override
  String get diagnosticsEnableSubtitle =>
      'Pohrani nedavne događaje i pogreške aplikacije na ovom uređaju';

  @override
  String get diagnosticsDisabled =>
      'Prikupljanje dijagnostike je isključeno. Uključite ga da biste počeli bilježiti događaje i pogreške aplikacije na ovom uređaju.';

  @override
  String get diagnosticsEmpty => 'Još nije zabilježena nijedna dijagnostika.';

  @override
  String get diagnosticsCopy => 'Kopiraj';

  @override
  String get diagnosticsCopied => 'Dijagnostika kopirana';

  @override
  String get diagnosticsClear => 'Očisti';

  @override
  String get diagnosticsCleared => 'Dijagnostika očišćena';

  @override
  String get diagnosticsSummary => 'Sažetak';

  @override
  String get diagnosticsLastUpdated => 'Zadnje ažurirano';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Događaji: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Pogreške: $count';
  }

  @override
  String get diagnosticsEvents => 'Događaji';

  @override
  String get diagnosticsNoEvents => 'Nema zabilježenih događaja';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Događaj: $event';
  }

  @override
  String get diagnosticsErrors => 'Pogreške';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Pogreška: $type';
  }

  @override
  String get diagnosticsActions => 'Radnje';

  @override
  String get diagnosticsRawReport => 'Neobrađeno izvješće';

  @override
  String get healthSyncSettingsTitle => 'Sinkronizacija zdravlja';

  @override
  String get healthSyncSettingsSubtitle =>
      'Uvezite vježbe sa svoje zdravstvene platforme';

  @override
  String get healthSyncScreenTitle => 'Sinkronizacija zdravlja';

  @override
  String get healthAccessScreenTitle => 'Zdravstveni pristup';

  @override
  String get healthAccessRequestedData => 'Traženi podaci';

  @override
  String get healthAccessWorkouts => 'Vježbe';

  @override
  String get healthAccessWorkoutRoutes => 'Rute vježbanja';

  @override
  String get healthAccessHeartRate => 'Otkucaji srca';

  @override
  String get healthAccessWorkoutSummary =>
      'Udaljenost, kalorije i koraci vježbanja';

  @override
  String get healthAccessAllowed => 'Dopušteno';

  @override
  String get healthAccessNeedsAttention => 'Treba pozornost';

  @override
  String get healthAccessManagedBySystem => 'Upravlja se u postavkama sustava';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit ne otkriva koje podatke Endurain može čitati. Pregledajte pristup u aplikaciji Zdravlje.';

  @override
  String get healthAccessReview => 'Pregledajte zdravstveni pristup';

  @override
  String get healthAccessReviewIos => 'Kako pregledati pristup';

  @override
  String get healthAccessDisconnect => 'Prekini vezu sa zdravstvenim podacima';

  @override
  String get healthAccessDisconnectTitle =>
      'Prekinuti vezu sa zdravstvenim podacima?';

  @override
  String get healthAccessDisconnectMessage =>
      'Automatski uvoz i lokalna povijest uvoza za ovaj poslužitelj bit će poništeni. Postojeće aktivnosti ostaju u povijesti.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Otvorite aplikaciju Zdravlje, dodirnite svoju profilnu sliku, zatim Aplikacije i usluge. Odaberite Endurain i ažurirajte kategorije podataka.';

  @override
  String get healthSyncAuthorize => 'Povežite se sa zdravstvenim podacima';

  @override
  String get healthSyncInstallProvider => 'Instalirajte Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Za sinkronizaciju vježbi potreban je Health Connect. Instalirajte ga za nastavak.';

  @override
  String get healthSyncUnsupported =>
      'Sinkronizacija zdravlja nije dostupna na ovom uređaju.';

  @override
  String get healthSyncSelectAll => 'Odaberite sve';

  @override
  String get healthSyncClearSelection => 'čisto';

  @override
  String healthSyncImportSelected(int count) {
    return 'Uvezi odabrano ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Uvezeno $count vježbanja.';
  }

  @override
  String get healthSyncNoRouteLabel => 'Nema GPS rute';

  @override
  String get healthSyncEmptyState =>
      'Nije pronađen nijedan trening u odabranom razdoblju.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Neki su treninzi preskočeni jer pristup ruti vježbanja nije dopušten. Otvorite Health Connect → Dozvole i dopustite rute vježbanja za Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Neki su treninzi preskočeni jer Endurain nije mogao pročitati njihove GPS rute. U aplikaciji Health otvorite svoj profil, zatim Apps and Services, odaberite Endurain i dopustite Workout Routes.';

  @override
  String get healthSyncReviewAccess => 'Pregledajte pristup';

  @override
  String get healthSyncAutoSyncTitle =>
      'Automatska sinkronizacija pri nastavku';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Automatski uvezite nove treninge kada se aplikacija otvori.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Ove vježbe ne uključuju GPS rutu, pa se ne mogu uvesti. Neke aplikacije (kao što je Garmin Connect) bilježe aktivnosti u Apple Health bez dijeljenja rute. Vježbe snimljene Apple Watchom uključuju rute i mogu se uvesti.';

  @override
  String get healthSyncBadgeNonImportable => 'Neuvozna';

  @override
  String get healthSyncViewAvailable => 'Dostupno';

  @override
  String get healthSyncViewImported => 'Uvezeno';

  @override
  String get healthSyncDateRange => 'Razdoblje vježbanja';

  @override
  String get healthSyncRange30Days => 'Zadnjih 30 dana';

  @override
  String get healthSyncRange3Months => 'Zadnja 3 mjeseca';

  @override
  String get healthSyncRange6Months => 'Zadnjih 6 mjeseci';

  @override
  String get healthSyncRangeYear => 'Zadnja godina';

  @override
  String get healthSyncRangeAll => 'Cijela povijest';

  @override
  String get healthSyncRangeCustom => 'Prilagođeno razdoblje';

  @override
  String get healthSyncImportedEmpty => 'Nema uvezenih vježbanja za ovu vezu.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Uvezeno: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Vrati';

  @override
  String get sensorsTitle => 'Senzori';

  @override
  String get sensorsSettingsSubtitle => 'Mjerači pulsa i drugi vanjski senzori';

  @override
  String get sensorsHeartRateSection => 'Puls';

  @override
  String get sensorsHeartRateHelp =>
      'Upari Bluetooth mjerač pulsa da vidiš svoj puls uživo.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth je isključen. Uključi ga za povezivanje senzora.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Dopusti pristup Bluetoothu za povezivanje senzora.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Ovaj uređaj ne podržava Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Traži senzore';

  @override
  String get sensorsScanning => 'Traženje…';

  @override
  String get sensorsStopScan => 'Zaustavi';

  @override
  String get sensorsNoDevices => 'Još nema pronađenih senzora pulsa.';

  @override
  String get sensorsAvailableSection => 'Dostupni senzori';

  @override
  String get sensorsSavedSection => 'Spremljeni senzor';

  @override
  String get sensorsConnect => 'Poveži';

  @override
  String get sensorsConnecting => 'Povezivanje…';

  @override
  String get sensorsConnected => 'Povezano';

  @override
  String get sensorsDisconnect => 'Prekini vezu';

  @override
  String get sensorsForget => 'Zaboravi';

  @override
  String get sensorsConnectionFailed =>
      'Povezivanje nije uspjelo. Pokušaj ponovno.';

  @override
  String get sensorsPermissionRequired =>
      'Za pronalazak senzora potrebna je dozvola za Bluetooth.';

  @override
  String get sensorsUnknownDevice => 'Nepoznat senzor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Snaga';

  @override
  String get sensorsPowerHelp =>
      'Upari Bluetooth mjerač snage da vidiš svoju snagu uživo.';

  @override
  String get sensorsNoPowerDevices => 'Još nema pronađenih mjerača snage.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Kadenca';

  @override
  String get sensorsCadenceHelp =>
      'Upari Bluetooth senzor kadence da vidiš svoju kadencu uživo.';

  @override
  String get sensorsNoCadenceDevices => 'Još nema pronađenih senzora kadence.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Udaljeno prijavljivanje rušenja';

  @override
  String get diagnosticsRemoteEnable => 'Šalji izvješća o rušenju';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Šalji izvješća o rušenjima i pogreškama na dijagnostički poslužitelj. Neovisno je o lokalnoj dijagnostici — možeš uključiti oboje, jedno ili ništa.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Udaljeno prijavljivanje rušenja nije dostupno u ovoj verziji.';

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
  String get unitsTitle => 'Jedinice';

  @override
  String get unitsSubtitle => 'Jedinice udaljenosti, brzine i visine';

  @override
  String get unitsSystemDefault => 'Prati regiju uređaja';

  @override
  String get unitsMetric => 'Metričke (km)';

  @override
  String get unitsImperial => 'Imperijalne (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';
}
