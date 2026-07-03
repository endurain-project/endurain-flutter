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
  String get errorPkceVerifierMissing => 'Sisselogimise kinnitajat ei leitud';

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
  String get ssoMissingSessionId => 'SSO vastus ei sisaldanud seansi ID-d';

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
  String get settingsScreen => 'Sätted';

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
  String get loggedIn => 'Sisse logitud';

  @override
  String get notConfigured => 'Pole seadistatud';

  @override
  String get notLoggedIn => 'Pole sisse logitud';

  @override
  String get serverUrl => 'Serveri URL';

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
}
