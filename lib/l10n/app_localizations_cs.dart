// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get error => 'Chyba';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Zrušit';

  @override
  String get save => 'Uložit';

  @override
  String get back => 'Zpět';

  @override
  String get requiredField => 'Toto pole je povinné';

  @override
  String get invalidUrl => 'Zadejte platnou adresu URL';

  @override
  String get errorActivityUploadFailed => 'Aktivitu se nepodařilo nahrát';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Aktivitu se nepodařilo nahrát: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Nahrávání aktivit ještě není nastaveno';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Dočasný soubor aktivity se nepodařilo odstranit';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Soubor pro nahrání aktivity se nepodařilo připravit';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Tuto místní aktivitu se nepodařilo najít';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Místní aktivitu se nepodařilo odstranit';

  @override
  String get errorActivityLocalGpxMissing =>
      'Místní soubor GPX není k dispozici';

  @override
  String get errorActivityLocalLoadFailed =>
      'Místní aktivity se nepodařilo načíst';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Tuto aktivitu se nepodařilo uložit';

  @override
  String get errorActivityLocalSaveFailed =>
      'Aktivitu se nepodařilo uložit místně';

  @override
  String get errorFetchProvidersFailed =>
      'Poskytovatele přihlášení se nepodařilo načíst';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Poskytovatele přihlášení se nepodařilo načíst: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Nastavení serveru se nepodařilo načíst';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Nastavení serveru se nepodařilo načíst: $details';
  }

  @override
  String get errorLoginError => 'Nepodařilo se přihlásit';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Nepodařilo se přihlásit: $details';
  }

  @override
  String get errorLoginFailed => 'Přihlášení se nezdařilo';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Přihlášení se nezdařilo: $details';
  }

  @override
  String get errorMfaVerificationError => 'Kód MFA se nepodařilo ověřit';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Kód MFA se nepodařilo ověřit: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Ověření MFA se nezdařilo';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Ověření MFA se nezdařilo: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Ze serveru nebylo přijato žádné ID relace';

  @override
  String get errorNotAuthenticated => 'Nejste přihlášeni';

  @override
  String get errorPkceVerifierMissing => 'Ověřovač přihlášení nebyl nalezen';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Ověřovač přihlášení nebyl nalezen. Zahajte přihlášení znovu.';

  @override
  String get errorServerUrlNotConfigured => 'Adresa URL serveru není nastavena';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Tento server vyžaduje zabezpečené připojení (HTTPS)';

  @override
  String get errorSessionExpired =>
      'Platnost vaší relace vypršela. Přihlaste se znovu.';

  @override
  String get errorSsoTokenExchangeError =>
      'Přihlášení přes SSO se nepodařilo dokončit';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Přihlášení přes SSO se nepodařilo dokončit: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Výměna tokenů se nezdařila';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Výměna tokenů se nezdařila: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Vypršel časový limit požadavku. Zkontrolujte připojení a zkuste to znovu.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Ze zabezpečeného úložiště nelze odstranit. Úložiště zařízení nemusí být dostupné.';

  @override
  String get errorSecureStorageReadFailed =>
      'Ze zabezpečeného úložiště nelze číst. Úložiště zařízení nemusí být dostupné.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Do zabezpečeného úložiště nelze zapisovat. Úložiště zařízení nemusí být dostupné.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Server vrátil neočekávanou odpověď';

  @override
  String get errorUnsupportedHttpMethod => 'Nepodporovaná metoda HTTP';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nepodporovaná metoda HTTP: $details';
  }

  @override
  String get loginTitle => 'Přihlášení';

  @override
  String get login => 'Přihlásit se';

  @override
  String get logout => 'Odhlásit se';

  @override
  String get logoutConfirmTitle => 'Odhlásit se';

  @override
  String get logoutConfirmMessage => 'Opravdu se chcete odhlásit?';

  @override
  String get logoutServerFailedWarning =>
      'Odhlášení ze serveru se nezdařilo, ale odhlášení proběhlo místně';

  @override
  String get ssoBrowserLaunchFailed =>
      'Přihlášení přes SSO se nepodařilo otevřít v systémovém prohlížeči';

  @override
  String get ssoMissingSessionId => 'Odpověď SSO neobsahovala ID relace';

  @override
  String ssoSignInWith(String provider) {
    return 'Přihlásit se pomocí $provider';
  }

  @override
  String get ssoOrDivider => 'NEBO';

  @override
  String get next => 'Další';

  @override
  String get username => 'Uživatelské jméno';

  @override
  String get usernameHint => 'Zadejte své uživatelské jméno';

  @override
  String get password => 'Heslo';

  @override
  String get passwordHint => 'Zadejte své heslo';

  @override
  String get showPassword => 'Zobrazit heslo';

  @override
  String get mfaTitle => 'Dvoufaktorové ověření';

  @override
  String get mfaCode => 'Kód MFA';

  @override
  String get mfaCodeHint => 'Zadejte 6místný kód';

  @override
  String get mfaCodeRequired => 'Zadejte kód MFA';

  @override
  String get verify => 'Ověřit';

  @override
  String get activityDiscard => 'Zahodit';

  @override
  String get activityDiscardConfirmMessage =>
      'Tímto odstraníte zaznamenané body této aktivity.';

  @override
  String get activityDiscardConfirmTitle => 'Zahodit aktivitu?';

  @override
  String get activityLocationPermissionDenied =>
      'K zaznamenání aktivity je vyžadováno oprávnění k poloze.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Oprávnění k poloze je blokováno. Otevřete nastavení a povolte přístup k poloze.';

  @override
  String get activityLocationServiceDisabled =>
      'Služby určování polohy jsou vypnuté.';

  @override
  String get activityLocationStreamFailed =>
      'Aktualizace polohy se neočekávaně zastavily.';

  @override
  String get activityGpxGenerationFailed =>
      'Soubor GPX aktivity se nepodařilo vytvořit.';

  @override
  String get activityLocalSaveFailed =>
      'Tuto aktivitu se nepodařilo uložit do tohoto zařízení.';

  @override
  String get activityOpenSettings => 'Otevřít nastavení';

  @override
  String get activityPause => 'Pozastavit';

  @override
  String get activityRecordingEmpty => 'Nebyly zaznamenány žádné body GPS.';

  @override
  String get activityRecordingFailed => 'Záznam se nezdařil.';

  @override
  String get activityResume => 'Pokračovat';

  @override
  String get activityRetryUpload => 'Zkusit nahrát znovu';

  @override
  String get activityDone => 'Hotovo';

  @override
  String get activityViewHistory => 'Zobrazit historii';

  @override
  String get activityDeleteLocal => 'Odstranit místní kopii';

  @override
  String get activityExportGpx => 'Sdílet soubor GPX';

  @override
  String get activityExportGpxSubject => 'GPX aktivity Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Odstranit místní aktivitu?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Tímto z tohoto zařízení odeberete záznam místní aktivity a soubor GPX.';

  @override
  String get activityStart => 'Spustit';

  @override
  String get activityBackgroundPermissionTitle =>
      'Povolit sledování na pozadí?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain vyžaduje polohu na pozadí nastavenou na Vždy, aby záznam pokračoval, když je aplikace na pozadí, obrazovka je uzamčena nebo přepnete aplikaci.';

  @override
  String get activityBackgroundPermissionContinue => 'Pokračovat';

  @override
  String get activityBackgroundPermissionRequired =>
      'Sledování na pozadí na iPhonu a iPadu vyžaduje polohu nastavenou na Vždy.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Sledování na pozadí je vypnuté';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Chcete-li spolehlivě zaznamenávat na pozadí nebo při uzamčené obrazovce, otevřete Nastavení a nastavte Polohu na Vždy pro Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Zaznamenávání aktivity';

  @override
  String get activityTrackingNotificationText =>
      'Endurain sleduje vaši polohu, aby zaznamenal tuto aktivitu.';

  @override
  String get activityStatDistance => 'Vzdálenost';

  @override
  String get activityStatDuration => 'Čas';

  @override
  String get activityStatSpeed => 'Rychlost';

  @override
  String get activityStop => 'Zastavit';

  @override
  String get activityStopAndSave => 'Zastavit a uložit';

  @override
  String get activityStopConfirmMessage =>
      'Zvolte, zda chcete tento záznam ponechat, nebo zahodit.';

  @override
  String get activityStopConfirmTitle => 'Ukončit aktivitu?';

  @override
  String get activityStopping => 'Zastavování';

  @override
  String get activityTypeHike => 'Turistika';

  @override
  String get activityTypeLabel => 'Typ aktivity';

  @override
  String get activityTypeOther => 'Jiné';

  @override
  String get activityTypeRide => 'Cyklistika';

  @override
  String get activityTypeRun => 'Běh';

  @override
  String get activityTypeWalk => 'Chůze';

  @override
  String get activityUploadFailed => 'Nahrání se nezdařilo';

  @override
  String get activityUploadCleanupFailed =>
      'Nahráno, ale vyčištění se nezdařilo';

  @override
  String get activityUploadReady => 'Připraveno k nahrání';

  @override
  String get activityUploaded => 'Nahráno';

  @override
  String get activityUploading => 'Nahrávání';

  @override
  String get activityUploadStatusPending => 'Čeká';

  @override
  String get activityUploadStatusUploaded => 'Nahráno';

  @override
  String get activityUploadStatusFailed => 'Nezdařilo se';

  @override
  String get activityHistoryTitle => 'Historie aktivit';

  @override
  String get activityHistorySettingsSubtitle =>
      'Dokončené aktivity uložené v tomto zařízení';

  @override
  String get activityRetainUploadedGpx => 'Ponechat nahrané soubory GPX';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Po nahrání ukládá dokončené soubory tras do soukromého úložiště aplikace.';

  @override
  String get activityHistoryEmpty =>
      'V tomto zařízení nejsou uloženy žádné dokončené aktivity.';

  @override
  String get activityHistoryLoadFailed =>
      'Místní aktivity se nepodařilo načíst.';

  @override
  String get activityHistoryRefresh => 'Obnovit';

  @override
  String get activityHistoryLocalActivities => 'Místní aktivity';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Doba trvání: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Vzdálenost: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Nahrání: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Načíst více';

  @override
  String get activityHistoryDetailsTitle => 'Podrobnosti aktivity';

  @override
  String get activityHistoryDetailsMissing =>
      'Tato místní aktivita již není k dispozici.';

  @override
  String get activityHistorySummary => 'Souhrn';

  @override
  String get activityHistoryActions => 'Akce';

  @override
  String get activityHistoryType => 'Typ';

  @override
  String get activityHistoryStartedAt => 'Zahájeno';

  @override
  String get activityHistoryEndedAt => 'Ukončeno';

  @override
  String get activityHistoryDurationLabel => 'Doba trvání';

  @override
  String get activityHistoryDistanceLabel => 'Vzdálenost';

  @override
  String get activityHistoryAverageSpeed => 'Průměrná rychlost';

  @override
  String get activityHistoryPointCount => 'Body GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Nahrání';

  @override
  String get activityHistoryGpxStatus => 'Soubor GPX';

  @override
  String get activityHistoryGpxAvailable => 'Uloženo v tomto zařízení';

  @override
  String get activityHistoryGpxMissing => 'Není k dispozici v tomto zařízení';

  @override
  String get mapTab => 'Mapa';

  @override
  String get myLocation => 'Moje poloha';

  @override
  String get settingsTab => 'Nastavení';

  @override
  String get settingsScreen => 'Nastavení';

  @override
  String get language => 'Jazyk';

  @override
  String get languageSystemDefault => 'Výchozí podle systému';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Přihlásit se';

  @override
  String get signInConnectServerSubtitle =>
      'Zaznamenávejte offline nyní a aktivity synchronizujte později';

  @override
  String get serverSettingsTitle => 'Nastavení serveru';

  @override
  String get loggedIn => 'Přihlášeno';

  @override
  String get notConfigured => 'Nenastaveno';

  @override
  String get notLoggedIn => 'Nepřihlášeno';

  @override
  String get serverUrl => 'Adresa URL serveru';

  @override
  String get serverUrlHint => 'https://priklad.com';

  @override
  String get warnHttpServerUrlTitle => 'Nezabezpečené připojení';

  @override
  String get warnHttpServerUrlMessage =>
      'Tato adresa URL serveru používá nešifrované HTTP. Vaše přihlašovací údaje a data budou přenášeny bez šifrování. Pokračujte pouze v případě, že rozumíte riziku a přijímáte ho.';

  @override
  String get warnHttpServerUrlConfirm => 'Přesto pokračovat';

  @override
  String get tileServerUrl => 'Adresa URL serveru mapových dlaždic';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Jiný hostitel serveru dlaždic';

  @override
  String get tileServerHostWarningMessage =>
      'Hostitel serveru dlaždic se liší od hostitele vašeho serveru Endurain. Dlaždice budou načteny ze serveru třetí strany. Chcete pokračovat?';

  @override
  String get savedSuccessfully => 'Nastavení bylo úspěšně uloženo';

  @override
  String get diagnostics => 'Diagnostika';

  @override
  String get diagnosticsSubtitle => 'Místní kontext pádů';

  @override
  String get diagnosticsTitle => 'Diagnostika';

  @override
  String get diagnosticsEmpty => 'Zatím nebyla zachycena žádná diagnostika.';

  @override
  String get diagnosticsCopy => 'Kopírovat';

  @override
  String get diagnosticsCopied => 'Diagnostika zkopírována';

  @override
  String get diagnosticsClear => 'Vymazat';

  @override
  String get diagnosticsCleared => 'Diagnostika vymazána';

  @override
  String get diagnosticsSummary => 'Souhrn';

  @override
  String get diagnosticsLastUpdated => 'Naposledy aktualizováno';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Události: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Chyby: $count';
  }

  @override
  String get diagnosticsEvents => 'Události';

  @override
  String get diagnosticsNoEvents => 'Nezachyceny žádné události';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Událost: $event';
  }

  @override
  String get diagnosticsErrors => 'Chyby';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Chyba: $type';
  }

  @override
  String get diagnosticsActions => 'Akce';

  @override
  String get diagnosticsRawReport => 'Nezpracovaná zpráva';
}
