// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get error => 'Chyba';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get save => 'Uložiť';

  @override
  String get back => 'Späť';

  @override
  String get requiredField => 'Toto pole je povinné';

  @override
  String get invalidUrl => 'Zadajte platnú adresu URL';

  @override
  String get errorActivityUploadFailed => 'Aktivitu sa nepodarilo nahrať';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Aktivitu sa nepodarilo nahrať: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Nahrávanie aktivít ešte nie je nastavené';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Dočasný súbor aktivity sa nepodarilo odstrániť';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Súbor na nahranie aktivity sa nepodarilo pripraviť';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Túto miestnu aktivitu sa nepodarilo nájsť';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Miestnu aktivitu sa nepodarilo odstrániť';

  @override
  String get errorActivityLocalGpxMissing =>
      'Miestny súbor GPX nie je k dispozícii';

  @override
  String get errorActivityLocalLoadFailed =>
      'Miestne aktivity sa nepodarilo načítať';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Túto aktivitu sa nepodarilo uložiť';

  @override
  String get errorActivityLocalSaveFailed =>
      'Aktivitu sa nepodarilo uložiť miestne';

  @override
  String get errorFetchProvidersFailed =>
      'Poskytovateľov prihlásenia sa nepodarilo načítať';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Poskytovateľov prihlásenia sa nepodarilo načítať: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Nastavenia servera sa nepodarilo načítať';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Nastavenia servera sa nepodarilo načítať: $details';
  }

  @override
  String get errorLoginError => 'Nepodarilo sa prihlásiť';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Nepodarilo sa prihlásiť: $details';
  }

  @override
  String get errorLoginFailed => 'Prihlásenie zlyhalo';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Prihlásenie zlyhalo: $details';
  }

  @override
  String get errorMfaVerificationError => 'Kód MFA sa nepodarilo overiť';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Kód MFA sa nepodarilo overiť: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Overenie MFA zlyhalo';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Overenie MFA zlyhalo: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Zo servera nebolo prijaté žiadne ID relácie';

  @override
  String get errorNotAuthenticated => 'Nie ste prihlásení';

  @override
  String get errorPkceVerifierMissing => 'Overovateľ prihlásenia sa nenašiel';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Overovateľ prihlásenia sa nenašiel. Začnite prihlásenie znova.';

  @override
  String get errorServerUrlNotConfigured =>
      'Adresa URL servera nie je nastavená';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Tento server vyžaduje zabezpečené pripojenie (HTTPS)';

  @override
  String get errorSessionExpired =>
      'Platnosť vašej relácie vypršala. Prihláste sa znova.';

  @override
  String get errorSsoTokenExchangeError =>
      'Prihlásenie cez SSO sa nepodarilo dokončiť';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Prihlásenie cez SSO sa nepodarilo dokončiť: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Výmena tokenov zlyhala';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Výmena tokenov zlyhala: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Vypršal časový limit požiadavky. Skontrolujte pripojenie a skúste to znova.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Zo zabezpečeného úložiska nie je možné odstrániť. Úložisko zariadenia nemusí byť dostupné.';

  @override
  String get errorSecureStorageReadFailed =>
      'Zo zabezpečeného úložiska nie je možné čítať. Úložisko zariadenia nemusí byť dostupné.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Do zabezpečeného úložiska nie je možné zapisovať. Úložisko zariadenia nemusí byť dostupné.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Server vrátil neočakávanú odpoveď';

  @override
  String get errorUnsupportedHttpMethod => 'Nepodporovaná metóda HTTP';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nepodporovaná metóda HTTP: $details';
  }

  @override
  String get loginTitle => 'Prihlásenie';

  @override
  String get login => 'Prihlásiť sa';

  @override
  String get logout => 'Odhlásiť sa';

  @override
  String get logoutConfirmTitle => 'Odhlásiť sa';

  @override
  String get logoutConfirmMessage => 'Naozaj sa chcete odhlásiť?';

  @override
  String get logoutServerFailedWarning =>
      'Odhlásenie zo servera zlyhalo, ale odhlásenie prebehlo miestne';

  @override
  String get ssoBrowserLaunchFailed =>
      'Prihlásenie cez SSO sa nepodarilo otvoriť v systémovom prehliadači';

  @override
  String get ssoMissingSessionId => 'Odpoveď SSO neobsahovala ID relácie';

  @override
  String ssoSignInWith(String provider) {
    return 'Prihlásiť sa cez $provider';
  }

  @override
  String get ssoOrDivider => 'ALEBO';

  @override
  String get next => 'Ďalej';

  @override
  String get username => 'Používateľské meno';

  @override
  String get usernameHint => 'Zadajte svoje používateľské meno';

  @override
  String get password => 'Heslo';

  @override
  String get passwordHint => 'Zadajte svoje heslo';

  @override
  String get showPassword => 'Zobraziť heslo';

  @override
  String get mfaTitle => 'Dvojfaktorové overenie';

  @override
  String get mfaCode => 'Kód MFA';

  @override
  String get mfaCodeHint => 'Zadajte 6-miestny kód';

  @override
  String get mfaCodeRequired => 'Zadajte kód MFA';

  @override
  String get verify => 'Overiť';

  @override
  String get activityDiscard => 'Zahodiť';

  @override
  String get activityDiscardConfirmMessage =>
      'Týmto sa odstránia zaznamenané body tejto aktivity.';

  @override
  String get activityDiscardConfirmTitle => 'Zahodiť aktivitu?';

  @override
  String get activityLocationPermissionDenied =>
      'Na zaznamenanie aktivity sa vyžaduje povolenie polohy.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Povolenie polohy je zablokované. Otvorte nastavenia a povoľte prístup k polohe.';

  @override
  String get activityLocationServiceDisabled =>
      'Služby určovania polohy sú vypnuté.';

  @override
  String get activityLocationStreamFailed =>
      'Aktualizácie polohy sa neočakávane zastavili.';

  @override
  String get activityGpxGenerationFailed =>
      'Súbor GPX aktivity sa nepodarilo vytvoriť.';

  @override
  String get activityLocalSaveFailed =>
      'Túto aktivitu sa nepodarilo uložiť do tohto zariadenia.';

  @override
  String get activityOpenSettings => 'Otvoriť nastavenia';

  @override
  String get activityPause => 'Pozastaviť';

  @override
  String get activityRecordingEmpty => 'Nezaznamenali sa žiadne body GPS.';

  @override
  String get activityRecordingFailed => 'Záznam zlyhal.';

  @override
  String get activityResume => 'Pokračovať';

  @override
  String get activityRetryUpload => 'Skúsiť nahrať znova';

  @override
  String get activityDone => 'Hotovo';

  @override
  String get activityViewHistory => 'Zobraziť históriu';

  @override
  String get activityDeleteLocal => 'Odstrániť miestnu kópiu';

  @override
  String get activityExportGpx => 'Zdieľať súbor GPX';

  @override
  String get activityExportGpxSubject => 'GPX aktivity Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Odstrániť miestnu aktivitu?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Týmto sa z tohto zariadenia odstráni záznam miestnej aktivity a súbor GPX.';

  @override
  String get activityStart => 'Spustiť';

  @override
  String get activityBackgroundPermissionTitle =>
      'Povoliť sledovanie na pozadí?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain vyžaduje polohu na pozadí nastavenú na Vždy, aby záznam pokračoval, keď je aplikácia na pozadí, obrazovka je uzamknutá alebo prepnete aplikáciu.';

  @override
  String get activityBackgroundPermissionContinue => 'Pokračovať';

  @override
  String get activityBackgroundPermissionRequired =>
      'Sledovanie na pozadí na iPhone a iPad vyžaduje polohu nastavenú na Vždy.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Sledovanie na pozadí je vypnuté';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Ak chcete spoľahlivo zaznamenávať na pozadí alebo pri uzamknutej obrazovke, otvorte Nastavenia a nastavte Polohu na Vždy pre Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Zaznamenávanie aktivity';

  @override
  String get activityTrackingNotificationText =>
      'Endurain sleduje vašu polohu, aby zaznamenal túto aktivitu.';

  @override
  String get activityStatDistance => 'Vzdialenosť';

  @override
  String get activityStatDuration => 'Čas';

  @override
  String get activityStatSpeed => 'Rýchlosť';

  @override
  String get activityStop => 'Zastaviť';

  @override
  String get activityStopAndSave => 'Zastaviť a uložiť';

  @override
  String get activityStopConfirmMessage =>
      'Vyberte, či chcete tento záznam ponechať, alebo zahodiť.';

  @override
  String get activityStopConfirmTitle => 'Ukončiť aktivitu?';

  @override
  String get activityStopping => 'Zastavovanie';

  @override
  String get activityTypeHike => 'Turistika';

  @override
  String get activityTypeLabel => 'Typ aktivity';

  @override
  String get activityTypeOther => 'Iné';

  @override
  String get activityTypeRide => 'Cyklistika';

  @override
  String get activityTypeRun => 'Beh';

  @override
  String get activityTypeWalk => 'Chôdza';

  @override
  String get activityUploadFailed => 'Nahrávanie zlyhalo';

  @override
  String get activityUploadCleanupFailed => 'Nahraté, ale čistenie zlyhalo';

  @override
  String get activityUploadReady => 'Pripravené na nahranie';

  @override
  String get activityUploaded => 'Nahraté';

  @override
  String get activityUploading => 'Nahrávanie';

  @override
  String get activityUploadStatusPending => 'Čaká';

  @override
  String get activityUploadStatusUploaded => 'Nahraté';

  @override
  String get activityUploadStatusFailed => 'Zlyhalo';

  @override
  String get activityHistoryTitle => 'História aktivít';

  @override
  String get activityHistorySettingsSubtitle =>
      'Dokončené aktivity uložené v tomto zariadení';

  @override
  String get activityRetainUploadedGpx => 'Ponechať nahraté súbory GPX';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Po nahraní ukladá dokončené súbory trás do súkromného úložiska aplikácie.';

  @override
  String get activityHistoryEmpty =>
      'V tomto zariadení nie sú uložené žiadne dokončené aktivity.';

  @override
  String get activityHistoryLoadFailed =>
      'Miestne aktivity sa nepodarilo načítať.';

  @override
  String get activityHistoryRefresh => 'Obnoviť';

  @override
  String get activityHistoryLocalActivities => 'Miestne aktivity';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Trvanie: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Vzdialenosť: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Nahranie: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Načítať viac';

  @override
  String get activityHistoryDetailsTitle => 'Podrobnosti aktivity';

  @override
  String get activityHistoryDetailsMissing =>
      'Táto miestna aktivita už nie je k dispozícii.';

  @override
  String get activityHistorySummary => 'Súhrn';

  @override
  String get activityHistoryActions => 'Akcie';

  @override
  String get activityHistoryType => 'Typ';

  @override
  String get activityHistoryStartedAt => 'Začaté';

  @override
  String get activityHistoryEndedAt => 'Ukončené';

  @override
  String get activityHistoryDurationLabel => 'Trvanie';

  @override
  String get activityHistoryDistanceLabel => 'Vzdialenosť';

  @override
  String get activityHistoryAverageSpeed => 'Priemerná rýchlosť';

  @override
  String get activityHistoryPointCount => 'Body GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Nahranie';

  @override
  String get activityHistoryGpxStatus => 'Súbor GPX';

  @override
  String get activityHistoryGpxAvailable => 'Uložené v tomto zariadení';

  @override
  String get activityHistoryGpxMissing =>
      'Nie je k dispozícii v tomto zariadení';

  @override
  String get mapTab => 'Mapa';

  @override
  String get myLocation => 'Moja poloha';

  @override
  String get settingsTab => 'Nastavenia';

  @override
  String get settingsScreen => 'Nastavenia';

  @override
  String get language => 'Jazyk';

  @override
  String get languageSystemDefault => 'Predvolené podľa systému';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Prihlásiť sa';

  @override
  String get signInConnectServerSubtitle =>
      'Zaznamenávajte offline teraz a aktivity synchronizujte neskôr';

  @override
  String get serverSettingsTitle => 'Nastavenia servera';

  @override
  String get loggedIn => 'Prihlásené';

  @override
  String get notConfigured => 'Nenastavené';

  @override
  String get notLoggedIn => 'Neprihlásené';

  @override
  String get serverUrl => 'Adresa URL servera';

  @override
  String get serverUrlHint => 'https://priklad.com';

  @override
  String get warnHttpServerUrlTitle => 'Nezabezpečené pripojenie';

  @override
  String get warnHttpServerUrlMessage =>
      'Táto adresa URL servera používa nešifrované HTTP. Vaše prihlasovacie údaje a údaje budú prenášané bez šifrovania. Pokračujte iba vtedy, ak rozumiete riziku a prijímate ho.';

  @override
  String get warnHttpServerUrlConfirm => 'Napriek tomu pokračovať';

  @override
  String get tileServerUrl => 'Adresa URL servera mapových dlaždíc';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Iný hostiteľ servera dlaždíc';

  @override
  String get tileServerHostWarningMessage =>
      'Hostiteľ servera dlaždíc sa líši od hostiteľa vášho servera Endurain. Dlaždice sa načítajú zo servera tretej strany. Chcete pokračovať?';

  @override
  String get savedSuccessfully => 'Nastavenia boli úspešne uložené';

  @override
  String get diagnostics => 'Diagnostika';

  @override
  String get diagnosticsSubtitle => 'Miestny kontext pádov';

  @override
  String get diagnosticsTitle => 'Diagnostika';

  @override
  String get diagnosticsEmpty =>
      'Zatiaľ neboli zachytené žiadne diagnostické údaje.';

  @override
  String get diagnosticsCopy => 'Kopírovať';

  @override
  String get diagnosticsCopied => 'Diagnostika skopírovaná';

  @override
  String get diagnosticsClear => 'Vymazať';

  @override
  String get diagnosticsCleared => 'Diagnostika vymazaná';

  @override
  String get diagnosticsSummary => 'Súhrn';

  @override
  String get diagnosticsLastUpdated => 'Naposledy aktualizované';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Udalosti: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Chyby: $count';
  }

  @override
  String get diagnosticsEvents => 'Udalosti';

  @override
  String get diagnosticsNoEvents => 'Nezachytené žiadne udalosti';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Udalosť: $event';
  }

  @override
  String get diagnosticsErrors => 'Chyby';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Chyba: $type';
  }

  @override
  String get diagnosticsActions => 'Akcie';

  @override
  String get diagnosticsRawReport => 'Nespracovaná správa';
}
