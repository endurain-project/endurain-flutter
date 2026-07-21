// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get error => 'Viga';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Tühista';

  @override
  String get save => 'Salvesta';

  @override
  String get back => 'Tagasi';

  @override
  String get requiredField => 'See väli on kohustuslik';

  @override
  String get invalidUrl => 'Sisestage kehtiv URL';

  @override
  String get errorActivityUploadFailed => 'Tegevust ei õnnestunud üles laadida';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Tegevust ei õnnestunud üles laadida: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Tegevuste üleslaadimine pole veel seadistatud';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Ajutist tegevusfaili ei õnnestunud kustutada';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Tegevuse üleslaadimisfaili ei õnnestunud ette valmistada';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Seda kohalikku tegevust ei leitud';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Kohalikku tegevust ei õnnestunud kustutada';

  @override
  String get errorActivityLocalGpxMissing => 'Kohalik GPX-fail pole saadaval';

  @override
  String get errorActivityLocalLoadFailed =>
      'Kohalikke tegevusi ei õnnestunud laadida';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Seda tegevust ei õnnestunud salvestada';

  @override
  String get errorActivityLocalSaveFailed =>
      'Tegevust ei õnnestunud kohapeal salvestada';

  @override
  String get errorFetchProvidersFailed =>
      'Sisselogimispakkujaid ei õnnestunud laadida';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Sisselogimispakkujaid ei õnnestunud laadida: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Serveri sätteid ei õnnestunud laadida';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Serveri sätteid ei õnnestunud laadida: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Treeningut ei saanud GPX-iks teisendada';

  @override
  String get errorHealthImportFailed => 'Treeningut ei saanud importida';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Treeningut ei saanud importida: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Juurdepääs terviseandmetele keelati';

  @override
  String get errorHealthReadFailed => 'Terviseandmeid ei õnnestunud lugeda';

  @override
  String get errorLoginError => 'Sisselogimine ebaõnnestus';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Sisselogimine ebaõnnestus: $details';
  }

  @override
  String get errorLoginFailed => 'Sisselogimine ebaõnnestus';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Sisselogimine ebaõnnestus: $details';
  }

  @override
  String get errorMfaVerificationError => 'MFA-koodi ei õnnestunud kinnitada';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'MFA-koodi ei õnnestunud kinnitada: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA kinnitamine ebaõnnestus';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA kinnitamine ebaõnnestus: $details';
  }

  @override
  String get errorNoSessionIdReceived => 'Serverilt ei saadud seansi ID-d';

  @override
  String get errorNotAuthenticated => 'Te pole sisse logitud';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Sisselogimise kinnitajat ei leitud. Alustage sisselogimist uuesti.';

  @override
  String get errorServerUrlNotConfigured => 'Serveri URL pole seadistatud';

  @override
  String get errorInsecureTransportNotAllowed =>
      'See server nõuab turvalist (HTTPS) ühendust';

  @override
  String get errorSessionExpired =>
      'Teie seanss on aegunud. Logige uuesti sisse.';

  @override
  String get errorSsoTokenExchangeError =>
      'SSO-sisselogimist ei õnnestunud lõpule viia';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'SSO-sisselogimist ei õnnestunud lõpule viia: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Lubade vahetus ebaõnnestus';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Lubade vahetus ebaõnnestus: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Päring aegus. Kontrollige ühendust ja proovige uuesti.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Turvamälust ei saa kustutada. Seadme mälu ei pruugi olla saadaval.';

  @override
  String get errorSecureStorageReadFailed =>
      'Turvamälust ei saa lugeda. Seadme mälu ei pruugi olla saadaval.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Turvamällu ei saa kirjutada. Seadme mälu ei pruugi olla saadaval.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Server tagastas ootamatu vastuse';

  @override
  String get errorUnsupportedHttpMethod => 'Toetamata HTTP-meetod';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Toetamata HTTP-meetod: $details';
  }

  @override
  String get loginTitle => 'Sisselogimine';

  @override
  String get login => 'Logi sisse';

  @override
  String get logout => 'Logi välja';

  @override
  String get logoutConfirmTitle => 'Logi välja';

  @override
  String get logoutConfirmMessage => 'Kas soovite kindlasti välja logida?';

  @override
  String get logoutServerFailedWarning =>
      'Serverist väljalogimine ebaõnnestus, kuid väljalogimine tehti kohapeal';

  @override
  String get ssoBrowserLaunchFailed =>
      'SSO-sisselogimist ei õnnestunud süsteemibrauseris avada';

  @override
  String ssoSignInWith(String provider) {
    return 'Logi sisse teenusega $provider';
  }

  @override
  String get ssoOrDivider => 'VÕI';

  @override
  String get next => 'Edasi';

  @override
  String get username => 'Kasutajanimi';

  @override
  String get usernameHint => 'Sisestage oma kasutajanimi';

  @override
  String get password => 'Parool';

  @override
  String get passwordHint => 'Sisestage oma parool';

  @override
  String get showPassword => 'Näita parooli';

  @override
  String get mfaTitle => 'Kaheastmeline autentimine';

  @override
  String get mfaCode => 'MFA-kood';

  @override
  String get mfaCodeHint => 'Sisestage 6-kohaline kood';

  @override
  String get mfaCodeRequired => 'Sisestage MFA-kood';

  @override
  String get verify => 'Kinnita';

  @override
  String get activityDiscard => 'Loobu';

  @override
  String get activityDiscardConfirmMessage =>
      'See kustutab selle tegevuse salvestatud punktid.';

  @override
  String get activityDiscardConfirmTitle => 'Loobuda tegevusest?';

  @override
  String get activityLocationPermissionDenied =>
      'Tegevuse salvestamiseks on vaja asukohaluba.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Asukohaluba on blokeeritud. Avage sätted, et lubada juurdepääs asukohale.';

  @override
  String get activityLocationServiceDisabled => 'Asukohateenused on keelatud.';

  @override
  String get activityLocationStreamFailed =>
      'Asukohavärskendused peatusid ootamatult.';

  @override
  String get activityGpxGenerationFailed =>
      'Tegevuse GPX-faili ei õnnestunud luua.';

  @override
  String get activityLocalSaveFailed =>
      'Seda tegevust ei õnnestunud sellesse seadmesse salvestada.';

  @override
  String get activityOpenSettings => 'Ava sätted';

  @override
  String get activityPause => 'Peata';

  @override
  String get activityRecordingEmpty => 'Ühtegi GPS-punkti ei salvestatud.';

  @override
  String get activityRecordingFailed => 'Salvestamine ebaõnnestus.';

  @override
  String get activityResume => 'Jätka';

  @override
  String get activityRetryUpload => 'Proovi üleslaadimist uuesti';

  @override
  String get activityDone => 'Valmis';

  @override
  String get activityViewHistory => 'Vaata ajalugu';

  @override
  String get activityDeleteLocal => 'Kustuta kohalik koopia';

  @override
  String get activityExportGpx => 'Jaga GPX-faili';

  @override
  String get activityExportGpxSubject => 'Enduraini tegevuse GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Kustutada kohalik tegevus?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'See eemaldab kohaliku tegevuse kirje ja GPX-faili sellest seadmest.';

  @override
  String get activityStart => 'Alusta';

  @override
  String get activityBackgroundPermissionTitle =>
      'Kas lubada jälgimine taustal?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain vajab, et taustaasukoht oleks seatud väärtusele Alati, et salvestamine jätkuks, kui rakendus on taustal, ekraan on lukus või vahetate rakendust.';

  @override
  String get activityBackgroundPermissionContinue => 'Jätka';

  @override
  String get activityBackgroundPermissionRequired =>
      'Jälgimine taustal iPhone\'is ja iPadis nõuab, et asukoht oleks seatud väärtusele Alati.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Jälgimine taustal on väljas';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Et salvestada usaldusväärselt taustal või lukustatud ekraaniga, avage Sätted ja seadke Asukoht väärtusele Alati Enduraini jaoks.';

  @override
  String get activityTrackingNotificationTitle => 'Tegevuse salvestamine';

  @override
  String get activityTrackingNotificationText =>
      'Endurain jälgib teie asukohta, et seda tegevust salvestada.';

  @override
  String get activityStatDistance => 'Vahemaa';

  @override
  String get activityStatDuration => 'Aeg';

  @override
  String get activityStatSpeed => 'Kiirus';

  @override
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Maks. kiirus';

  @override
  String get activityStatElevationGain => 'Tõus';

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
  String get activityStop => 'Peata';

  @override
  String get activityStopAndSave => 'Peata ja salvesta';

  @override
  String get activityStopConfirmMessage =>
      'Valige, kas soovite selle salvestuse säilitada või sellest loobuda.';

  @override
  String get activityStopConfirmTitle => 'Kas lõpetada tegevus?';

  @override
  String get activityStopping => 'Peatamine';

  @override
  String get activityTypeHike => 'Matk';

  @override
  String get activityTypeLabel => 'Tegevuse tüüp';

  @override
  String get activityTypeOther => 'Muu';

  @override
  String get activityTypeRide => 'Rattasõit';

  @override
  String get activityTypeRun => 'Jooks';

  @override
  String get activityTypeWalk => 'Kõnd';

  @override
  String get activityUploadFailed => 'Üleslaadimine ebaõnnestus';

  @override
  String get activityUploadCleanupFailed =>
      'Üles laaditud, kuid puhastamine ebaõnnestus';

  @override
  String get activityUploadReady => 'Üleslaadimiseks valmis';

  @override
  String get activityUploaded => 'Üles laaditud';

  @override
  String get activityUploading => 'Üleslaadimine';

  @override
  String get activityUploadStatusPending => 'Ootel';

  @override
  String get activityUploadStatusUploaded => 'Üles laaditud';

  @override
  String get activityUploadStatusFailed => 'Ebaõnnestus';

  @override
  String get activityHistoryTitle => 'Tegevuste ajalugu';

  @override
  String get activityHistorySettingsSubtitle =>
      'Sellesse seadmesse salvestatud lõpetatud tegevused';

  @override
  String get activityRetainUploadedGpx => 'Säilita üleslaaditud GPX-failid';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Salvestab lõpetatud marsruudifailid pärast üleslaadimist rakenduse privaatsesse mällu.';

  @override
  String get activityHistoryEmpty =>
      'Sellesse seadmesse pole salvestatud ühtegi lõpetatud tegevust.';

  @override
  String get activityHistoryLoadFailed =>
      'Kohalikke tegevusi ei õnnestunud laadida.';

  @override
  String get activityHistoryRefresh => 'Värskenda';

  @override
  String get activityHistoryLocalActivities => 'Kohalikud tegevused';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Kestus: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Vahemaa: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Üleslaadimine: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Laadi rohkem';

  @override
  String get activityHistoryDetailsTitle => 'Tegevuse üksikasjad';

  @override
  String get activityHistoryDetailsMissing =>
      'See kohalik tegevus pole enam saadaval.';

  @override
  String get activityHistorySummary => 'Kokkuvõte';

  @override
  String get activityHistoryActions => 'Toimingud';

  @override
  String get activityHistoryType => 'Tüüp';

  @override
  String get activityHistoryStartedAt => 'Alustatud';

  @override
  String get activityHistoryEndedAt => 'Lõpetatud';

  @override
  String get activityHistoryDurationLabel => 'Kestus';

  @override
  String get activityHistoryDistanceLabel => 'Vahemaa';

  @override
  String get activityHistoryAverageSpeed => 'Keskmine kiirus';

  @override
  String get activityHistoryPointCount => 'GPS-punktid';

  @override
  String get activityHistoryUploadStatusLabel => 'Üleslaadimine';

  @override
  String get activityHistoryGpxStatus => 'GPX-fail';

  @override
  String get activityHistoryGpxAvailable => 'Salvestatud sellesse seadmesse';

  @override
  String get activityHistoryGpxMissing => 'Selles seadmes pole saadaval';

  @override
  String get mapTab => 'Kaart';

  @override
  String get myLocation => 'Minu asukoht';

  @override
  String get settingsTab => 'Sätted';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® on João Vitória Silva registreeritud kaubamärk.';

  @override
  String get settingsScreen => 'Sätted';

  @override
  String get deviceAccessTitle => 'Seadme juurdepääs';

  @override
  String get deviceAccessSubtitle =>
      'Hallake juurdepääsu asukoha- ja terviseandmetele';

  @override
  String get deviceAccessLocationSection => 'Asukoht';

  @override
  String get deviceAccessHealthSection => 'Terviseandmed';

  @override
  String get deviceAccessLocationTitle => 'Juurdepääs asukohale';

  @override
  String get deviceAccessHealthTitle => 'Juurdepääs terviseandmetele';

  @override
  String get deviceAccessChecking => 'Juurdepääsu kontrollimine…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Asukohateenused on välja lülitatud';

  @override
  String get deviceAccessLocationAlways => 'Lubatud kogu aeg';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Rakenduse kasutamise ajal lubatud';

  @override
  String get deviceAccessLocationBlocked => 'Süsteemi seadetes blokeeritud';

  @override
  String get deviceAccessLocationNotAllowed => 'Pole lubatud';

  @override
  String get deviceAccessHealthUnavailable => 'Pole selles seadmes saadaval';

  @override
  String get deviceAccessHealthRequired => 'Nõutav on Health Connect';

  @override
  String get deviceAccessHealthSetUp => 'Tervise juurdepääs seadistatud';

  @override
  String get deviceAccessHealthNeedsAttention => 'Juurdepääs vajab tähelepanu';

  @override
  String get deviceAccessHealthNotConnected => 'Pole ühendatud';

  @override
  String get language => 'Keel';

  @override
  String get languageSystemDefault => 'Süsteemi vaikeväärtus';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Logi sisse';

  @override
  String get signInConnectServerSubtitle =>
      'Salvestage nüüd võrguühenduseta ja sünkroonige tegevused hiljem';

  @override
  String get serverSettingsTitle => 'Serveri sätted';

  @override
  String connectedToServer(String server) {
    return 'Ühendatud serveriga $server';
  }

  @override
  String get loggedIn => 'Sisse logitud';

  @override
  String get notConfigured => 'Pole seadistatud';

  @override
  String get notLoggedIn => 'Pole sisse logitud';

  @override
  String get serverUrl => 'Serveri URL';

  @override
  String get serverProtocol => 'Protokoll';

  @override
  String get serverUrlHint => 'https://naide.com';

  @override
  String get warnHttpServerUrlTitle => 'Ebaturvaline ühendus';

  @override
  String get warnHttpServerUrlMessage =>
      'See serveri URL kasutab tavalist HTTP-d. Teie sisselogimisandmed ja andmed edastatakse ilma krüptimiseta. Jätkake ainult siis, kui mõistate ja aktsepteerite riski.';

  @override
  String get warnHttpServerUrlConfirm => 'Jätka sellegipoolest';

  @override
  String get tileServerUrl => 'Kaardipaanide serveri URL';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Erinev paaniserveri host';

  @override
  String get tileServerHostWarningMessage =>
      'Paaniserveri host erineb teie Enduraini serveri hostist. Paanid laaditakse kolmanda osapoole serverist. Kas soovite jätkata?';

  @override
  String get savedSuccessfully => 'Sätted edukalt salvestatud';

  @override
  String get diagnostics => 'Diagnostika';

  @override
  String get diagnosticsSubtitle => 'Kohalik krahhikontekst';

  @override
  String get sourceCode => 'Lähtekood';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Lingi avamine ebaõnnestus';

  @override
  String get diagnosticsTitle => 'Diagnostika';

  @override
  String get diagnosticsCollection => 'Kogumine';

  @override
  String get diagnosticsEnable => 'Kogu diagnostikat';

  @override
  String get diagnosticsEnableSubtitle =>
      'Salvesta rakenduse hiljutised sündmused ja vead sellesse seadmesse';

  @override
  String get diagnosticsDisabled =>
      'Diagnostika kogumine on välja lülitatud. Lülita see sisse, et hakata salvestama rakenduse sündmusi ja vigu sellesse seadmesse.';

  @override
  String get diagnosticsEmpty => 'Diagnostikaandmeid pole veel jäädvustatud.';

  @override
  String get diagnosticsCopy => 'Kopeeri';

  @override
  String get diagnosticsCopied => 'Diagnostika kopeeritud';

  @override
  String get diagnosticsClear => 'Tühjenda';

  @override
  String get diagnosticsCleared => 'Diagnostika tühjendatud';

  @override
  String get diagnosticsSummary => 'Kokkuvõte';

  @override
  String get diagnosticsLastUpdated => 'Viimati uuendatud';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Sündmused: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Vead: $count';
  }

  @override
  String get diagnosticsEvents => 'Sündmused';

  @override
  String get diagnosticsNoEvents => 'Sündmusi pole jäädvustatud';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Sündmus: $event';
  }

  @override
  String get diagnosticsErrors => 'Vead';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Viga: $type';
  }

  @override
  String get diagnosticsActions => 'Toimingud';

  @override
  String get diagnosticsRawReport => 'Töötlemata aruanne';

  @override
  String get healthSyncSettingsTitle => 'Tervise sünkroonimine';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importige treeningud oma terviseplatvormilt';

  @override
  String get healthSyncScreenTitle => 'Tervise sünkroonimine';

  @override
  String get healthAccessScreenTitle => 'Juurdepääs tervisele';

  @override
  String get healthAccessRequestedData => 'Taotletud andmed';

  @override
  String get healthAccessWorkouts => 'Treeningud';

  @override
  String get healthAccessWorkoutRoutes => 'Treeningu marsruudid';

  @override
  String get healthAccessHeartRate => 'Südame löögisagedus';

  @override
  String get healthAccessWorkoutSummary =>
      'Treeningu vahemaa, kalorid ja sammud';

  @override
  String get healthAccessAllowed => 'Lubatud';

  @override
  String get healthAccessNeedsAttention => 'Vajab tähelepanu';

  @override
  String get healthAccessManagedBySystem => 'Hallatakse süsteemiseadetes';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit ei avalda, milliseid andmeid Endurain lugeda saab. Vaadake juurdepääs rakenduses Health üle.';

  @override
  String get healthAccessReview => 'Vaadake üle juurdepääs tervisele';

  @override
  String get healthAccessReviewIos => 'Kuidas juurdepääsu üle vaadata';

  @override
  String get healthAccessDisconnect => 'Katkesta terviseandmete ühendus';

  @override
  String get healthAccessDisconnectTitle =>
      'Kas katkestada terviseandmete ühendus?';

  @override
  String get healthAccessDisconnectMessage =>
      'Selle serveri automaatne import ja kohalik impordiajalugu lähtestatakse. Olemasolevad tegevused jäävad ajalukku.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Avage rakendus Health, puudutage oma profiilipilti ja seejärel valikut Rakendused ja teenused. Valige Endurain ja värskendage andmekategooriaid.';

  @override
  String get healthSyncAuthorize => 'Ühendage terviseandmetega';

  @override
  String get healthSyncInstallProvider => 'Installige Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Treeningu sünkroonimiseks on vaja Health Connecti. Jätkamiseks installige see.';

  @override
  String get healthSyncUnsupported =>
      'Tervise sünkroonimine pole selles seadmes saadaval.';

  @override
  String get healthSyncSelectAll => 'Valige kõik';

  @override
  String get healthSyncClearSelection => 'Selge';

  @override
  String healthSyncImportSelected(int count) {
    return 'Impordi valitud ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Imporditud $count treening(t).';
  }

  @override
  String get healthSyncNoRouteLabel => 'GPS-i marsruuti pole';

  @override
  String get healthSyncEmptyState =>
      'Valitud ajavahemikus ei leitud ühtegi treeningut.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Mõned treeningud jäeti vahele, kuna juurdepääsu harjutuste marsruudile ei antud. Avage Health Connect → Load ja lubage Enduraini treeningmarsruudid.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Mõned treeningud jäid vahele, kuna Endurain ei osanud nende GPS-i marsruute lugeda. Avage terviserakenduses oma profiil, seejärel Rakendused ja teenused, valige Endurain ja lubage treeningmarsruudid.';

  @override
  String get healthSyncReviewAccess => 'Vaadake juurdepääs';

  @override
  String get healthSyncAutoSyncTitle => 'Automaatne sünkroonimine jätkamisel';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importige uued treeningud rakenduse avanemisel automaatselt.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Need treeningud ei sisalda GPS-marsruuti, seega ei saa neid importida. Mõned rakendused (nt Garmin Connect) salvestavad tegevusi Apple Healthile ilma marsruuti jagamata. Apple Watchiga salvestatud treeningud sisaldavad marsruute ja neid saab importida.';

  @override
  String get healthSyncBadgeNonImportable => 'Mitteimporditav';

  @override
  String get healthSyncViewAvailable => 'Saadaval';

  @override
  String get healthSyncViewImported => 'Imporditud';

  @override
  String get healthSyncDateRange => 'Treeningute ajavahemik';

  @override
  String get healthSyncRange30Days => 'Viimased 30 päeva';

  @override
  String get healthSyncRange3Months => 'Viimased 3 kuud';

  @override
  String get healthSyncRange6Months => 'Viimased 6 kuud';

  @override
  String get healthSyncRangeYear => 'Viimane aasta';

  @override
  String get healthSyncRangeAll => 'Kogu ajalugu';

  @override
  String get healthSyncRangeCustom => 'Kohandatud ajavahemik';

  @override
  String get healthSyncImportedEmpty =>
      'Selle ühenduse jaoks pole imporditud treeninguid.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Imporditud: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Taasta';

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
}
