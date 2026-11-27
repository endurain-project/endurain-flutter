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
  String get errorActivityIngestionUnsupportedFormat =>
      'Failivormingut ei toetata';

  @override
  String get errorActivityIngestionInvalidFile =>
      'Fail on rikutud või seda ei õnnestunud lugeda';

  @override
  String get errorActivityIngestionNoActivitiesFound =>
      'Failist ei leitud ühtegi tegevust';

  @override
  String get errorActivityIngestionProcessingFailed =>
      'Tegevuse importimisel läks midagi valesti. Proovi uuesti.';

  @override
  String get errorActivityIngestionProviderUnavailable =>
      'Tegevuste pakkuja ei ole praegu saadaval. Proovi hiljem uuesti.';

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
  String get errorHealthUnavailable =>
      'Terviseandmed pole selles seadmes saadaval';

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
  String get errorMfaSessionMissing =>
      'Teie sisselogimissessioon läks kaotsi. Palun logige uuesti sisse.';

  @override
  String get errorSsoCallbackFailed =>
      'Ühekordset sisselogimist (SSO) ei õnnestunud lõpetada. Proovige uuesti.';

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
  String get legacyDataTitle => 'Tegevused enne serveri uuendamist';

  @override
  String legacyDataMessageWithUsername(String username) {
    return 'Selles seadmes on tegevusi, mis on salvestatud selle serveri kontole enne serveri uuendamist. Kas need on teie omad, $username? Kui on, laaditakse veel ootel olevad teie kontole üles.';
  }

  @override
  String get legacyDataMessage =>
      'Selles seadmes on tegevusi, mis on salvestatud selle serveri kontole enne serveri uuendamist. Kas need kuuluvad kontole, millega just sisse logisite? Kui jah, laaditakse veel ootel olevad sinna üles.';

  @override
  String get legacyDataConfirm => 'Need on minu omad';

  @override
  String get legacyDataDecline => 'Pole minu omad';

  @override
  String get errorActivityUploadLimit =>
      'Serveris on liiga palju teie üleslaadimisi pooleli. Rakendus proovib hiljem uuesti.';

  @override
  String get errorPasswordChangeFailed => 'Parooli ei saanud muuta';

  @override
  String errorPasswordChangeFailedWithDetails(String details) {
    return 'Parooli ei saanud muuta: $details';
  }

  @override
  String get errorSignInStepUnsupported =>
      'Server küsis sisselogimise sammu, mida see rakenduse versioon ei toeta. Uuendage rakendust ja proovige uuesti.';

  @override
  String get errorSsoEmailMissing =>
      'Teie identiteedipakkuja ei jaganud e-posti aadressi, mis on konto loomiseks vajalik.';

  @override
  String get errorSsoEmailUnverified =>
      'Teie identiteedipakkuja pole teie e-posti aadressi kinnitanud. Kinnitage see seal ja proovige uuesti.';

  @override
  String get errorSsoAutoCreateDisabled =>
      'Ükski konto ei vasta sellele sisselogimisele ja see server ei loo kontosid automaatselt. Küsige oma administraatorilt.';

  @override
  String get errorSsoLinkByEmailDisabled =>
      'Seda e-posti aadressi kasutab juba üks konto, kuid see pakkuja ei saa sellesse sisse logida. Logige sisse muul viisil või küsige oma administraatorilt.';

  @override
  String get errorSsoApprovalPending =>
      'Teie konto ootab administraatori kinnitust.';

  @override
  String get errorSsoAccountDisabled =>
      'See konto on keelatud. Võtke ühendust oma administraatoriga.';

  @override
  String get errorSsoRedirectNotAllowed =>
      'See server ei luba sellest rakendusest ühekordset sisselogimist. Paluge administraatoril lisada com.endurain.endurain:/auth/sso/callback loendisse ALLOWED_REDIRECT_URIS.';

  @override
  String get errorActivityMfaEnrolmentRequired =>
      'Teie administraator nõuab kaheastmelist kinnitust. Seadistage see Enduraini veebirakenduses ja proovige uuesti.';

  @override
  String get errorActivityFileTooLarge =>
      'Tegevuse fail on sellele serverile liiga suur';

  @override
  String get errorActivityUnsupportedFileType =>
      'See server ei võta seda tüüpi tegevuse faili vastu';

  @override
  String get errorTooManyRequests =>
      'Liiga palju katseid. Oodake hetk ja proovige uuesti.';

  @override
  String get passwordChangeTitle => 'Valige uus parool';

  @override
  String get passwordChangeMessage =>
      'Administraator määras teie parooli. Sisselogimise lõpetamiseks valige uus.';

  @override
  String get newPassword => 'Uus parool';

  @override
  String get confirmNewPassword => 'Kinnitage uus parool';

  @override
  String get passwordsDoNotMatch => 'Paroolid ei ühti';

  @override
  String get changePassword => 'Muuda parooli';

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
  String get mfaBackupCode => 'Varukood';

  @override
  String get mfaBackupCodeHint =>
      'Sisestage üks oma 8-märgilistest varukoodidest';

  @override
  String get mfaUseBackupCode => 'Kasuta varukoodi';

  @override
  String get mfaUseAuthenticatorCode => 'Kasuta autentimisrakenduse koodi';

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
  String get activityStatHeartRate => 'Pulss';

  @override
  String get activityStatAvgHeartRate => 'Keskm. pulss';

  @override
  String get activityStatPower => 'Võimsus';

  @override
  String get activityStatAvgPower => 'Keskm. võimsus';

  @override
  String get activityStatCadence => 'Kadents';

  @override
  String get activityStatAvgCadence => 'Keskm. kadents';

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
  String get activityUploadAwaitingSignIn =>
      'Salvestatud sellesse seadmesse. See laaditakse üles pärast sisselogimist.';

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
  String get activityAutoPauseTitle => 'Automaatne paus';

  @override
  String get activityAutoPauseSubtitle =>
      'Peatab automaatselt, kui lõpetate liikumise';

  @override
  String get activityAutoPauseToggleLabel => 'Automaatne peatamine';

  @override
  String get activityAutoPauseToggleDescription =>
      'Salvestus peatub automaatselt, kui lõpetate liikumise, ja jätkub, kui hakkate uuesti liikuma.';

  @override
  String get activityAutoPauseDelayHelperText =>
      'Valige, kui kaua ilma liikumiseta enne peatamist oodata.';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    return '$seconds sekundit';
  }

  @override
  String get activityAutoPausedIndicator => 'Automaatselt peatatud';

  @override
  String get startCountdownSettingsTitle => 'Alguse loendus';

  @override
  String get startCountdownSettingsSubtitle =>
      'Loenda enne salvestamise algust';

  @override
  String get startCountdownToggleLabel => 'Loenda enne alustamist';

  @override
  String get startCountdownToggleDescription =>
      'Annab aega telefon ära panna enne, kui salvestamine algab.';

  @override
  String get startCountdownDurationHelperText =>
      'Vali, kui kaua loendus kestab.';

  @override
  String startCountdownDurationOptionLabel(int seconds) {
    return '$seconds sekundit';
  }

  @override
  String get startCountdownVoiceLabel => 'Loe loendus ette';

  @override
  String get startCountdownVoiceDescription =>
      'Loeb viimased sekundid ette ja teatab, kui salvestamine on alanud.';

  @override
  String get activityStartCountdownTitle => 'Salvestamise alguseni';

  @override
  String activityStartCountdownRemaining(int seconds) {
    return 'Sekundeid jäänud: $seconds';
  }

  @override
  String get activityStartCountdownStartNow => 'Alusta kohe';

  @override
  String activityStartCountdownAddSeconds(int seconds) {
    return '+$seconds s';
  }

  @override
  String get audioAnnouncementsRecordingStarted => 'Salvestamine alustatud';

  @override
  String get audioAnnouncementsAutoPaused => 'Salvestamine peatatud';

  @override
  String get audioAnnouncementsAutoResumed => 'Salvestamine jätkatud';

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
  String get settingsSectionAccount => 'Konto';

  @override
  String get settingsSectionGeneral => 'Üldine';

  @override
  String get settingsSectionRecording => 'Salvestamine';

  @override
  String get settingsSectionDevices => 'Seadmed ja integratsioonid';

  @override
  String get settingsSectionData => 'Andmed';

  @override
  String get settingsSectionPrivacySupport => 'Privaatsus ja tugi';

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
  String get deviceAccessBluetoothSection => 'Bluetooth';

  @override
  String get deviceAccessBluetoothTitle => 'Juurdepääs Bluetoothile';

  @override
  String get deviceAccessBluetoothAllowed => 'Lubatud';

  @override
  String get deviceAccessBluetoothOff => 'Bluetooth on välja lülitatud';

  @override
  String get deviceAccessBluetoothBlocked => 'Süsteemi seadetes blokeeritud';

  @override
  String get deviceAccessBluetoothNotAllowed => 'Pole lubatud';

  @override
  String get deviceAccessBluetoothUnavailable => 'Pole selles seadmes saadaval';

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
  String get deviceAccessHealthSetUp =>
      'Juurdepääs terviseandmetele seadistatud';

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
  String get serverNotSecure => 'Pole turvaline (HTTP)';

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
  String get mapTilesSettingsTitle => 'Kaardipaanid';

  @override
  String get mapTilesSettingsSubtitle =>
      'Paaniserver, millega kaarte joonistatakse';

  @override
  String get mapTilesSettingsNote =>
      'Kehtib, kuni olete selle serveriga ühendatud. Uuesti sisselogimisel asendatakse see teie serveri paaniseadega, kui serveril see on.';

  @override
  String get mapTilesSettingsLoadFailed =>
      'Kaardipaanide seadet ei õnnestunud laadida.';

  @override
  String get tryAgain => 'Proovi uuesti';

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
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

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
      'Treeningute importimine teie terviseplatvormilt';

  @override
  String get healthSyncScreenTitle => 'Tervise sünkroonimine';

  @override
  String get healthAccessScreenTitle => 'Juurdepääs terviseandmetele';

  @override
  String get healthAccessRequestedData => 'Taotletud andmed';

  @override
  String get healthAccessWorkouts => 'Treeningud';

  @override
  String get healthAccessWorkoutRoutes => 'Treeningmarsruudid';

  @override
  String get healthAccessHeartRate => 'Pulss';

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
  String get healthAccessReview => 'Vaata üle juurdepääs terviseandmetele';

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
  String get healthAccessBlockedTitle =>
      'Luba juurdepääs rakenduses Health Connect';

  @override
  String get healthAccessBlockedMessage =>
      'Health Connect lõpetab küsimise, kui juurdepääs on kaks korda keelatud. Ava Health Connect, et lubada Endurainil lugeda su treeninguid, marsruute ja pulssi.';

  @override
  String get healthAccessOpenHealthConnect => 'Ava Health Connect';

  @override
  String get healthSyncAuthorize => 'Ühenda terviseandmetega';

  @override
  String get healthSyncInstallProvider => 'Installi Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Treeningute sünkroonimiseks on vaja Health Connecti. Jätkamiseks installige see.';

  @override
  String get healthSyncUnsupported =>
      'Tervise sünkroonimine pole selles seadmes saadaval.';

  @override
  String get healthSyncSelectAll => 'Vali kõik';

  @override
  String get healthSyncClearSelection => 'Tühjenda valik';

  @override
  String healthSyncImportSelected(int count) {
    return 'Impordi valitud ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imporditud $count treeningut.',
      one: 'Imporditud $count treening.',
    );
    return '$_temp0';
  }

  @override
  String get healthSyncNoRouteLabel => 'GPS-i marsruuti pole';

  @override
  String get healthSyncEmptyState =>
      'Valitud ajavahemikus ei leitud ühtegi treeningut.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Mõned treeningud jäeti vahele, kuna juurdepääsu treeningmarsruutidele ei antud. Avage Health Connect → Load ja lubage Endurainile treeningmarsruudid.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Mõned treeningud jäeti vahele, kuna Endurain ei saanud nende GPS-marsruute lugeda. Avage rakenduses Health oma profiil, seejärel Rakendused ja teenused, valige Endurain ja lubage treeningmarsruudid.';

  @override
  String get healthSyncHistoryAccessGuidance =>
      'Vanemaid treeninguid ei kuvata, sest Health Connectis pole varasematele andmetele juurdepääsu antud. Nende importimiseks lubage Health Connectis Endurainile „Juurdepääs varasematele andmetele“.';

  @override
  String get healthSyncReviewAccess => 'Vaata juurdepääs üle';

  @override
  String get healthSyncAutoSyncTitle =>
      'Automaatne sünkroonimine rakenduse avamisel';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Impordib uued treeningud automaatselt, kui rakendus avatakse.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Need treeningud ei sisalda GPS-marsruuti, seega ei saa neid importida. Mõned rakendused (nt Garmin Connect) salvestavad tegevusi Apple Healthi ilma marsruuti jagamata. Apple Watchiga salvestatud treeningud sisaldavad marsruute ja neid saab importida.';

  @override
  String get healthSyncBadgeNonImportable => 'Pole imporditav';

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
  String get sensorsTitle => 'Andurid';

  @override
  String get sensorsSettingsSubtitle => 'Pulsimõõdikud ja muud välised andurid';

  @override
  String get sensorsHeartRateSection => 'Pulss';

  @override
  String get sensorsHeartRateHelp =>
      'Ühenda Bluetooth-pulsimõõdik, et näha oma pulssi reaalajas.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth on väljas. Lülita see sisse anduri ühendamiseks.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Lubage anduri ühendamiseks Bluetoothi juurdepääs.';

  @override
  String get sensorsBluetoothUnsupported =>
      'See seade ei toeta Bluetooth Low Energy\'t.';

  @override
  String get sensorsScan => 'Otsi andureid';

  @override
  String get sensorsScanning => 'Otsimine…';

  @override
  String get sensorsStopScan => 'Peata';

  @override
  String get sensorsNoDevices => 'Pulsiandureid pole veel leitud.';

  @override
  String get sensorsAvailableSection => 'Saadaolevad andurid';

  @override
  String get sensorsSavedSection => 'Salvestatud andur';

  @override
  String get sensorsConnect => 'Ühenda';

  @override
  String get sensorsConnecting => 'Ühendamine…';

  @override
  String get sensorsConnected => 'Ühendatud';

  @override
  String get sensorsDisconnect => 'Katkesta ühendus';

  @override
  String get sensorsForget => 'Unusta';

  @override
  String get sensorsConnectionFailed =>
      'Ühendamine ebaõnnestus. Proovi uuesti.';

  @override
  String get sensorsPermissionRequired =>
      'Andurite leidmiseks on vaja Bluetoothi luba.';

  @override
  String get sensorsUnknownDevice => 'Tundmatu andur';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Võimsus';

  @override
  String get sensorsPowerHelp =>
      'Ühenda Bluetooth-võimsusmõõdik, et näha oma võimsust reaalajas.';

  @override
  String get sensorsNoPowerDevices => 'Võimsusmõõdikuid pole veel leitud.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Kadents';

  @override
  String get sensorsCadenceHelp =>
      'Ühenda Bluetooth-kadentsiandur, et näha oma kadentsi reaalajas.';

  @override
  String get sensorsNoCadenceDevices => 'Kadentsiandureid pole veel leitud.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Kaug-krahhiraportid';

  @override
  String get diagnosticsRemoteEnable => 'Saada krahhiraporteid';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Saada krahhi- ja vearaporteid diagnostikaserverisse. See on eraldi kohalikust diagnostikast; võite lubada mõlemad, ühe või mitte kumbagi.';

  @override
  String get diagnosticsRemoteActive => 'Krahhiraporteid saadetakse';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Kaug-krahhiraportid pole selles versioonis saadaval.';

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
  String get unitsTitle => 'Ühikud';

  @override
  String get unitsSubtitle => 'Vahemaa, kiiruse ja kõrguse ühikud';

  @override
  String get unitsSystemDefault => 'Järgi seadme piirkonda';

  @override
  String get unitsMetric => 'Meetermõõdustik (km)';

  @override
  String get unitsImperial => 'Imperiaalne (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'Server püüdis suunata ümber ebaturvalisele ühendusele. Päring blokeeriti teie volituste kaitsmiseks.';

  @override
  String get errorTooManyRedirects =>
      'Server suunas liiga mitu korda ümber. Kontrollige serveri aadressi.';

  @override
  String get audioAnnouncementsTitle => 'Häälteated';

  @override
  String get audioAnnouncementsSubtitle =>
      'Häälteated vahemaa, aja, tempo või kiiruse kohta';

  @override
  String get audioAnnouncementsMasterSwitch => 'Teata tegevuse edenemisest';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Ütleb salvestamise ajal valjusti teie vahemaa, aja, tempo või kiiruse';

  @override
  String get audioAnnouncementsDuckSwitch => 'Vaigista muu heli teatamise ajal';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Vähendab ajutiselt muu heli valjust iga teate ajal';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Teate intervall tegevuse kaupa';

  @override
  String get audioAnnouncementsByDistance => 'Vahemaa';

  @override
  String get audioAnnouncementsByTime => 'Aeg';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Iga $value $unit järel';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Iga $minutes min järel';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Vähenda intervalli';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Suurenda intervalli';

  @override
  String get audioAnnouncementsPreview => 'Kuula näidet';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'Teate näidis ei ole selles seadmes saadaval';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Muudatused rakenduvad järgmisel salvestusel.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Vahemaa $distance. Aeg $duration. Ring: $lapMetric. Kokku: $overallMetric.';
  }
}
