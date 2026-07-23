// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get error => 'Napaka';

  @override
  String get ok => 'V redu';

  @override
  String get cancel => 'Prekliči';

  @override
  String get save => 'Shrani';

  @override
  String get back => 'Nazaj';

  @override
  String get requiredField => 'To polje je obvezno';

  @override
  String get invalidUrl => 'Vnesite veljaven URL';

  @override
  String get errorActivityUploadFailed => 'Aktivnosti ni bilo mogoče naložiti';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Aktivnosti ni bilo mogoče naložiti: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Nalaganje aktivnosti še ni nastavljeno';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Začasne datoteke aktivnosti ni bilo mogoče izbrisati';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Datoteke za nalaganje aktivnosti ni bilo mogoče pripraviti';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Te lokalne aktivnosti ni bilo mogoče najti';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Lokalne aktivnosti ni bilo mogoče izbrisati';

  @override
  String get errorActivityLocalGpxMissing => 'Lokalna datoteka GPX ni na voljo';

  @override
  String get errorActivityLocalLoadFailed =>
      'Lokalnih aktivnosti ni bilo mogoče naložiti';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Te aktivnosti ni bilo mogoče shraniti';

  @override
  String get errorActivityLocalSaveFailed =>
      'Aktivnosti ni bilo mogoče shraniti lokalno';

  @override
  String get errorFetchProvidersFailed =>
      'Ponudnikov prijave ni bilo mogoče naložiti';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Ponudnikov prijave ni bilo mogoče naložiti: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Nastavitev strežnika ni bilo mogoče naložiti';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Nastavitev strežnika ni bilo mogoče naložiti: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Vadbe ni bilo mogoče pretvoriti v GPX';

  @override
  String get errorHealthImportFailed => 'Vadbe ni bilo mogoče uvoziti';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Ni bilo mogoče uvoziti vadbe: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Dostop do zdravstvenih podatkov je bil zavrnjen';

  @override
  String get errorHealthReadFailed =>
      'Ni bilo mogoče prebrati zdravstvenih podatkov';

  @override
  String get errorLoginError => 'Prijava ni mogoča';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Prijava ni mogoča: $details';
  }

  @override
  String get errorLoginFailed => 'Prijava ni uspela';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Prijava ni uspela: $details';
  }

  @override
  String get errorMfaVerificationError => 'Kode MFA ni bilo mogoče preveriti';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Kode MFA ni bilo mogoče preveriti: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Preverjanje MFA ni uspelo';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Preverjanje MFA ni uspelo: $details';
  }

  @override
  String get errorNoSessionIdReceived => 'Strežnik ni vrnil ID-ja seje';

  @override
  String get errorNotAuthenticated => 'Niste prijavljeni';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Preverjevalnika prijave ni bilo mogoče najti. Znova začnite prijavo.';

  @override
  String get errorServerUrlNotConfigured => 'URL strežnika ni nastavljen';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Ta strežnik zahteva varno povezavo (HTTPS)';

  @override
  String get errorSessionExpired => 'Vaša seja je potekla. Znova se prijavite.';

  @override
  String get errorSsoTokenExchangeError =>
      'Prijave SSO ni bilo mogoče dokončati';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Prijave SSO ni bilo mogoče dokončati: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Izmenjava žetonov ni uspela';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Izmenjava žetonov ni uspela: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Zahteva je potekla. Preverite povezavo in poskusite znova.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Iz varne shrambe ni mogoče izbrisati. Shramba naprave morda ni na voljo.';

  @override
  String get errorSecureStorageReadFailed =>
      'Iz varne shrambe ni mogoče brati. Shramba naprave morda ni na voljo.';

  @override
  String get errorSecureStorageWriteFailed =>
      'V varno shrambo ni mogoče pisati. Shramba naprave morda ni na voljo.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Strežnik je vrnil nepričakovan odgovor';

  @override
  String get errorUnsupportedHttpMethod => 'Nepodprta metoda HTTP';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nepodprta metoda HTTP: $details';
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
  String get logoutConfirmMessage => 'Ali se res želite odjaviti?';

  @override
  String get logoutServerFailedWarning =>
      'Odjava s strežnika ni uspela, vendar ste odjavljeni lokalno';

  @override
  String get ssoBrowserLaunchFailed =>
      'Prijave SSO ni bilo mogoče odpreti v sistemskem brskalniku';

  @override
  String ssoSignInWith(String provider) {
    return 'Prijava z $provider';
  }

  @override
  String get ssoOrDivider => 'ALI';

  @override
  String get next => 'Naprej';

  @override
  String get username => 'Uporabniško ime';

  @override
  String get usernameHint => 'Vnesite svoje uporabniško ime';

  @override
  String get password => 'Geslo';

  @override
  String get passwordHint => 'Vnesite svoje geslo';

  @override
  String get showPassword => 'Pokaži geslo';

  @override
  String get mfaTitle => 'Dvostopenjsko preverjanje pristnosti';

  @override
  String get mfaCode => 'Koda MFA';

  @override
  String get mfaCodeHint => 'Vnesite 6-mestno kodo';

  @override
  String get mfaCodeRequired => 'Vnesite kodo MFA';

  @override
  String get verify => 'Preveri';

  @override
  String get activityDiscard => 'Zavrzi';

  @override
  String get activityDiscardConfirmMessage =>
      'S tem boste izbrisali zabeležene točke te aktivnosti.';

  @override
  String get activityDiscardConfirmTitle => 'Želite zavreči aktivnost?';

  @override
  String get activityLocationPermissionDenied =>
      'Za snemanje aktivnosti je potrebno dovoljenje za lokacijo.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Dovoljenje za lokacijo je blokirano. Odprite nastavitve, da omogočite dostop do lokacije.';

  @override
  String get activityLocationServiceDisabled =>
      'Lokacijske storitve so onemogočene.';

  @override
  String get activityLocationStreamFailed =>
      'Posodobitve lokacije so se nepričakovano ustavile.';

  @override
  String get activityGpxGenerationFailed =>
      'Datoteke GPX aktivnosti ni bilo mogoče ustvariti.';

  @override
  String get activityLocalSaveFailed =>
      'Te aktivnosti ni bilo mogoče shraniti v to napravo.';

  @override
  String get activityOpenSettings => 'Odpri nastavitve';

  @override
  String get activityPause => 'Premor';

  @override
  String get activityRecordingEmpty => 'Zabeležena ni bila nobena točka GPS.';

  @override
  String get activityRecordingFailed => 'Snemanje ni uspelo.';

  @override
  String get activityResume => 'Nadaljuj';

  @override
  String get activityRetryUpload => 'Znova poskusi naložiti';

  @override
  String get activityDone => 'Končano';

  @override
  String get activityViewHistory => 'Prikaži zgodovino';

  @override
  String get activityDeleteLocal => 'Izbriši lokalno kopijo';

  @override
  String get activityExportGpx => 'Deli datoteko GPX';

  @override
  String get activityExportGpxSubject => 'GPX aktivnosti Endurain';

  @override
  String get activityDeleteLocalConfirmTitle =>
      'Želite izbrisati lokalno aktivnost?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'S tem boste iz te naprave odstranili zapis lokalne aktivnosti in datoteko GPX.';

  @override
  String get activityStart => 'Začni';

  @override
  String get activityBackgroundPermissionTitle => 'Dovolite sledenje v ozadju?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain potrebuje lokacijo v ozadju nastavljeno na Vedno, da se snemanje nadaljuje, ko je aplikacija v ozadju, je zaslon zaklenjen ali preklopite aplikacijo.';

  @override
  String get activityBackgroundPermissionContinue => 'Nadaljuj';

  @override
  String get activityBackgroundPermissionRequired =>
      'Sledenje v ozadju na iPhonu in iPadu zahteva lokacijo, nastavljeno na Vedno.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Sledenje v ozadju je izklopljeno';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Za zanesljivo snemanje v ozadju ali ob zaklenjenem zaslonu odprite Nastavitve in nastavite Lokacijo na Vedno za Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Snemanje aktivnosti';

  @override
  String get activityTrackingNotificationText =>
      'Endurain sledi vaši lokaciji za snemanje te aktivnosti.';

  @override
  String get activityStatDistance => 'Razdalja';

  @override
  String get activityStatDuration => 'Čas';

  @override
  String get activityStatSpeed => 'Hitrost';

  @override
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Najv. hitrost';

  @override
  String get activityStatElevationGain => 'Vzpon';

  @override
  String get activityStatHeartRate => 'Srčni utrip';

  @override
  String get activityStatAvgHeartRate => 'Povpr. srčni utrip';

  @override
  String get activityStatPower => 'Moč';

  @override
  String get activityStatAvgPower => 'Povpr. moč';

  @override
  String get activityStatCadence => 'Kadenca';

  @override
  String get activityStatAvgCadence => 'Povpr. kadenca';

  @override
  String get activityStop => 'Ustavi';

  @override
  String get activityStopAndSave => 'Ustavi in shrani';

  @override
  String get activityStopConfirmMessage =>
      'Izberite, ali želite ta posnetek obdržati ali zavreči.';

  @override
  String get activityStopConfirmTitle => 'Želite končati aktivnost?';

  @override
  String get activityStopping => 'Ustavljanje';

  @override
  String get activityTypeHike => 'Pohod';

  @override
  String get activityTypeLabel => 'Vrsta aktivnosti';

  @override
  String get activityTypeOther => 'Drugo';

  @override
  String get activityTypeRide => 'Kolesarjenje';

  @override
  String get activityTypeRun => 'Tek';

  @override
  String get activityTypeWalk => 'Hoja';

  @override
  String get activityUploadFailed => 'Nalaganje ni uspelo';

  @override
  String get activityUploadCleanupFailed =>
      'Naloženo, vendar čiščenje ni uspelo';

  @override
  String get activityUploadReady => 'Pripravljeno za nalaganje';

  @override
  String get activityUploaded => 'Naloženo';

  @override
  String get activityUploading => 'Nalaganje';

  @override
  String get activityUploadStatusPending => 'V čakanju';

  @override
  String get activityUploadStatusUploaded => 'Naloženo';

  @override
  String get activityUploadStatusFailed => 'Ni uspelo';

  @override
  String get activityHistoryTitle => 'Zgodovina aktivnosti';

  @override
  String get activityHistorySettingsSubtitle =>
      'Dokončane aktivnosti, shranjene v tej napravi';

  @override
  String get activityRetainUploadedGpx => 'Obdrži naložene datoteke GPX';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Po nalaganju shrani dokončane datoteke poti v zasebno shrambo aplikacije.';

  @override
  String get activityHistoryEmpty =>
      'V tej napravi ni shranjenih dokončanih aktivnosti.';

  @override
  String get activityHistoryLoadFailed =>
      'Lokalnih aktivnosti ni bilo mogoče naložiti.';

  @override
  String get activityHistoryRefresh => 'Osveži';

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
    return 'Razdalja: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Nalaganje: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Naloži več';

  @override
  String get activityHistoryDetailsTitle => 'Podrobnosti aktivnosti';

  @override
  String get activityHistoryDetailsMissing =>
      'Ta lokalna aktivnost ni več na voljo.';

  @override
  String get activityHistorySummary => 'Povzetek';

  @override
  String get activityHistoryActions => 'Dejanja';

  @override
  String get activityHistoryType => 'Vrsta';

  @override
  String get activityHistoryStartedAt => 'Začeto';

  @override
  String get activityHistoryEndedAt => 'Končano';

  @override
  String get activityHistoryDurationLabel => 'Trajanje';

  @override
  String get activityHistoryDistanceLabel => 'Razdalja';

  @override
  String get activityHistoryAverageSpeed => 'Povprečna hitrost';

  @override
  String get activityHistoryPointCount => 'Točke GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Nalaganje';

  @override
  String get activityHistoryGpxStatus => 'Datoteka GPX';

  @override
  String get activityHistoryGpxAvailable => 'Shranjeno v tej napravi';

  @override
  String get activityHistoryGpxMissing => 'Ni na voljo v tej napravi';

  @override
  String get mapTab => 'Zemljevid';

  @override
  String get myLocation => 'Moja lokacija';

  @override
  String get settingsTab => 'Nastavitve';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® je registrirana blagovna znamka João Vitória Silva';

  @override
  String get settingsScreen => 'Nastavitve';

  @override
  String get deviceAccessTitle => 'Dostop do naprave';

  @override
  String get deviceAccessSubtitle =>
      'Upravljajte lokacijo in dostop do zdravstvenih podatkov';

  @override
  String get deviceAccessLocationSection => 'Lokacija';

  @override
  String get deviceAccessHealthSection => 'Zdravstveni podatki';

  @override
  String get deviceAccessLocationTitle => 'Dostop do lokacije';

  @override
  String get deviceAccessHealthTitle => 'Dostop do zdravstvenih podatkov';

  @override
  String get deviceAccessChecking => 'Preverjanje dostopa ...';

  @override
  String get deviceAccessLocationServicesOff =>
      'Lokacijske storitve so izklopljene';

  @override
  String get deviceAccessLocationAlways => 'Dovoljeno ves čas';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Dovoljeno med uporabo aplikacije';

  @override
  String get deviceAccessLocationBlocked =>
      'Blokirano v sistemskih nastavitvah';

  @override
  String get deviceAccessLocationNotAllowed => 'Ni dovoljeno';

  @override
  String get deviceAccessHealthUnavailable => 'Ni na voljo v tej napravi';

  @override
  String get deviceAccessHealthRequired => 'Potreben je Health Connect';

  @override
  String get deviceAccessHealthSetUp => 'Vzpostavljen zdravstveni dostop';

  @override
  String get deviceAccessHealthNeedsAttention => 'Dostop zahteva pozornost';

  @override
  String get deviceAccessHealthNotConnected => 'Ni povezano';

  @override
  String get language => 'Jezik';

  @override
  String get languageSystemDefault => 'Privzeto za sistem';

  @override
  String get serverSettings => 'Strežnik';

  @override
  String get signInConnectServer => 'Prijava';

  @override
  String get signInConnectServerSubtitle =>
      'Snemajte brez povezave zdaj in sinhronizirajte aktivnosti pozneje';

  @override
  String get serverSettingsTitle => 'Nastavitve strežnika';

  @override
  String connectedToServer(String server) {
    return 'Povezan s $server';
  }

  @override
  String get loggedIn => 'Prijavljeni';

  @override
  String get notConfigured => 'Ni nastavljeno';

  @override
  String get notLoggedIn => 'Niste prijavljeni';

  @override
  String get serverUrl => 'URL strežnika';

  @override
  String get serverProtocol => 'Protokol';

  @override
  String get serverUrlHint => 'https://primer.com';

  @override
  String get warnHttpServerUrlTitle => 'Nezaščitena povezava';

  @override
  String get warnHttpServerUrlMessage =>
      'Ta URL strežnika uporablja navadni HTTP. Vaši podatki za prijavo in podatki bodo posredovani brez šifriranja. Nadaljujte le, če razumete in sprejemate tveganje.';

  @override
  String get warnHttpServerUrlConfirm => 'Vseeno nadaljuj';

  @override
  String get tileServerUrl => 'URL strežnika ploščic zemljevida';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Drug gostitelj strežnika ploščic';

  @override
  String get tileServerHostWarningMessage =>
      'Gostitelj strežnika ploščic se razlikuje od gostitelja vašega strežnika Endurain. Ploščice bodo naložene s strežnika tretje osebe. Želite nadaljevati?';

  @override
  String get savedSuccessfully => 'Nastavitve so uspešno shranjene';

  @override
  String get diagnostics => 'Diagnostika';

  @override
  String get diagnosticsSubtitle => 'Lokalni kontekst sesutij';

  @override
  String get sourceCode => 'Izvorna koda';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Povezave ni mogoče odpreti';

  @override
  String get diagnosticsTitle => 'Diagnostika';

  @override
  String get diagnosticsCollection => 'Zbiranje';

  @override
  String get diagnosticsEnable => 'Zbiraj diagnostiko';

  @override
  String get diagnosticsEnableSubtitle =>
      'Shrani nedavne dogodke in napake aplikacije v tej napravi';

  @override
  String get diagnosticsDisabled =>
      'Zbiranje diagnostike je izklopljeno. Vklopite ga, da začnete beležiti dogodke in napake aplikacije v tej napravi.';

  @override
  String get diagnosticsEmpty => 'Zajet ni bil še noben diagnostični podatek.';

  @override
  String get diagnosticsCopy => 'Kopiraj';

  @override
  String get diagnosticsCopied => 'Diagnostika kopirana';

  @override
  String get diagnosticsClear => 'Počisti';

  @override
  String get diagnosticsCleared => 'Diagnostika počiščena';

  @override
  String get diagnosticsSummary => 'Povzetek';

  @override
  String get diagnosticsLastUpdated => 'Nazadnje posodobljeno';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Dogodki: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Napake: $count';
  }

  @override
  String get diagnosticsEvents => 'Dogodki';

  @override
  String get diagnosticsNoEvents => 'Zajetih ni nobenih dogodkov';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Dogodek: $event';
  }

  @override
  String get diagnosticsErrors => 'Napake';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Napaka: $type';
  }

  @override
  String get diagnosticsActions => 'Dejanja';

  @override
  String get diagnosticsRawReport => 'Neobdelano poročilo';

  @override
  String get healthSyncSettingsTitle => 'Sinhronizacija zdravja';

  @override
  String get healthSyncSettingsSubtitle =>
      'Uvozite vadbe iz svoje zdravstvene platforme';

  @override
  String get healthSyncScreenTitle => 'Sinhronizacija zdravja';

  @override
  String get healthAccessScreenTitle => 'Zdravstveni dostop';

  @override
  String get healthAccessRequestedData => 'Zahtevani podatki';

  @override
  String get healthAccessWorkouts => 'Vadbe';

  @override
  String get healthAccessWorkoutRoutes => 'Vadbene poti';

  @override
  String get healthAccessHeartRate => 'Srčni utrip';

  @override
  String get healthAccessWorkoutSummary => 'Razdalja, kalorije in koraki vadbe';

  @override
  String get healthAccessAllowed => 'Dovoljeno';

  @override
  String get healthAccessNeedsAttention => 'Potrebuje pozornost';

  @override
  String get healthAccessManagedBySystem =>
      'Upravlja se v sistemskih nastavitvah';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit ne razkriva, katere podatke lahko Endurain bere. Pregled dostopa v aplikaciji Health.';

  @override
  String get healthAccessReview => 'Pregled zdravstvenega dostopa';

  @override
  String get healthAccessReviewIos => 'Kako pregledati dostop';

  @override
  String get healthAccessDisconnect =>
      'Prekini povezavo z zdravstvenimi podatki';

  @override
  String get healthAccessDisconnectTitle =>
      'Prekiniti povezavo z zdravstvenimi podatki?';

  @override
  String get healthAccessDisconnectMessage =>
      'Samodejni uvoz in lokalna zgodovina uvozov za ta strežnik bosta ponastavljena. Obstoječe dejavnosti ostanejo v zgodovini.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Odprite aplikacijo Zdravje, tapnite svojo profilno sliko in nato Aplikacije in storitve. Izberite Endurain in posodobite kategorije podatkov.';

  @override
  String get healthSyncAuthorize => 'Povežite se z zdravstvenimi podatki';

  @override
  String get healthSyncInstallProvider => 'Namestite Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Za sinhronizacijo vadb je potreben Health Connect. Namestite ga za nadaljevanje.';

  @override
  String get healthSyncUnsupported =>
      'Sinhronizacija zdravja ni na voljo v tej napravi.';

  @override
  String get healthSyncSelectAll => 'Izberite vse';

  @override
  String get healthSyncClearSelection => 'jasno';

  @override
  String healthSyncImportSelected(int count) {
    return 'Uvoz izbranih ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Uvoženih $count vadb.';
  }

  @override
  String get healthSyncNoRouteLabel => 'Ni GPS poti';

  @override
  String get healthSyncEmptyState =>
      'V izbranem obdobju ni bilo najdenih vadb.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Nekatere vadbe so bile preskočene, ker dostop do vadbene poti ni bil odobren. Odprite Health Connect → Dovoljenja in dovolite vadbene poti za Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Nekatere vadbe so bile preskočene, ker Endurain ni mogel brati njihovih poti GPS. V aplikaciji Health odprite svoj profil, nato Apps and Services, izberite Endurain in dovolite Workout Routes.';

  @override
  String get healthSyncReviewAccess => 'Pregled dostopa';

  @override
  String get healthSyncAutoSyncTitle =>
      'Samodejna sinhronizacija ob nadaljevanju';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Samodejno uvozite nove vadbe, ko se aplikacija odpre.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Te vadbe ne vključujejo poti GPS, zato jih ni mogoče uvoziti. Nekatere aplikacije (kot je Garmin Connect) beležijo dejavnosti v Apple Health, ne da bi delile pot. Vadbe, posnete z Apple Watch, vključujejo poti in jih je mogoče uvoziti.';

  @override
  String get healthSyncBadgeNonImportable => 'Neuvozno';

  @override
  String get healthSyncViewAvailable => 'Na voljo';

  @override
  String get healthSyncViewImported => 'Uvoženo';

  @override
  String get healthSyncDateRange => 'Obdobje vadb';

  @override
  String get healthSyncRange30Days => 'Zadnjih 30 dni';

  @override
  String get healthSyncRange3Months => 'Zadnji 3 meseci';

  @override
  String get healthSyncRange6Months => 'Zadnjih 6 mesecev';

  @override
  String get healthSyncRangeYear => 'Zadnje leto';

  @override
  String get healthSyncRangeAll => 'Celotna zgodovina';

  @override
  String get healthSyncRangeCustom => 'Obdobje po meri';

  @override
  String get healthSyncImportedEmpty => 'Za to povezavo ni uvoženih vadb.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Uvoženo: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Obnovi';

  @override
  String get sensorsTitle => 'Senzorji';

  @override
  String get sensorsSettingsSubtitle =>
      'Merilniki srčnega utripa in drugi zunanji senzorji';

  @override
  String get sensorsHeartRateSection => 'Srčni utrip';

  @override
  String get sensorsHeartRateHelp =>
      'Poveži merilnik srčnega utripa Bluetooth za ogled srčnega utripa v živo.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth je izklopljen. Vklopi ga za povezavo senzorja.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Dovoli dostop do Bluetootha za povezavo senzorja.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Ta naprava ne podpira Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Poišči senzorje';

  @override
  String get sensorsScanning => 'Iskanje…';

  @override
  String get sensorsStopScan => 'Ustavi';

  @override
  String get sensorsNoDevices =>
      'Zaenkrat ni najdenih senzorjev srčnega utripa.';

  @override
  String get sensorsAvailableSection => 'Razpoložljivi senzorji';

  @override
  String get sensorsSavedSection => 'Shranjen senzor';

  @override
  String get sensorsConnect => 'Poveži';

  @override
  String get sensorsConnecting => 'Povezovanje…';

  @override
  String get sensorsConnected => 'Povezano';

  @override
  String get sensorsDisconnect => 'Prekini povezavo';

  @override
  String get sensorsForget => 'Pozabi';

  @override
  String get sensorsConnectionFailed => 'Povezava ni uspela. Poskusi znova.';

  @override
  String get sensorsPermissionRequired =>
      'Za iskanje senzorjev je potrebno dovoljenje za Bluetooth.';

  @override
  String get sensorsUnknownDevice => 'Neznan senzor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Moč';

  @override
  String get sensorsPowerHelp =>
      'Poveži merilnik moči Bluetooth za ogled moči v živo.';

  @override
  String get sensorsNoPowerDevices => 'Zaenkrat ni najdenih merilnikov moči.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Kadenca';

  @override
  String get sensorsCadenceHelp =>
      'Poveži senzor kadence Bluetooth za ogled kadence v živo.';

  @override
  String get sensorsNoCadenceDevices =>
      'Zaenkrat ni najdenih senzorjev kadence.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Oddaljeno poročanje o zrušitvah';

  @override
  String get diagnosticsRemoteEnable => 'Pošiljaj poročila o zrušitvah';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Pošiljaj poročila o zrušitvah in napakah na diagnostični strežnik. To je ločeno od lokalne diagnostike — omogočiš lahko oboje, eno ali nič.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Oddaljeno poročanje o zrušitvah v tej različici ni na voljo.';
}
