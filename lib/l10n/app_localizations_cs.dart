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
  String get errorActivityIngestionUnsupportedFormat =>
      'Formát souboru není podporován';

  @override
  String get errorActivityIngestionInvalidFile =>
      'Soubor je poškozený nebo ho nelze přečíst';

  @override
  String get errorActivityIngestionNoActivitiesFound =>
      'V souboru nebyly nalezeny žádné aktivity';

  @override
  String get errorActivityIngestionProcessingFailed =>
      'Při importu aktivity došlo k chybě. Zkuste to znovu.';

  @override
  String get errorActivityIngestionProviderUnavailable =>
      'Poskytovatel aktivit je momentálně nedostupný. Zkuste to později.';

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
  String get errorHealthGpxBuildFailed =>
      'Trénink se nepodařilo převést na GPX';

  @override
  String get errorHealthImportFailed => 'Trénink nelze importovat';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Trénink nelze importovat: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Přístup ke zdravotním údajům byl odepřen';

  @override
  String get errorHealthReadFailed => 'Nepodařilo se přečíst zdravotní údaje';

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
  String get errorMfaSessionMissing =>
      'Vaše přihlašovací relace byla ztracena. Přihlaste se prosím znovu.';

  @override
  String get errorSsoCallbackFailed =>
      'Jednotné přihlášení se nepodařilo dokončit. Zkuste to prosím znovu.';

  @override
  String get errorNotAuthenticated => 'Nejste přihlášeni';

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
  String get legacyDataTitle => 'Aktivity z doby před aktualizací serveru';

  @override
  String legacyDataMessageWithUsername(String username) {
    return 'V tomto zařízení jsou aktivity uložené pro účet na tomto serveru z doby před jeho aktualizací. Jsou vaše, $username? Pokud ano, ty, které ještě čekají, se nahrají do vašeho účtu.';
  }

  @override
  String get legacyDataMessage =>
      'V tomto zařízení jsou aktivity uložené pro účet na tomto serveru z doby před jeho aktualizací. Patří k účtu, ke kterému jste se právě přihlásili? Pokud ano, ty, které ještě čekají, se do něj nahrají.';

  @override
  String get legacyDataConfirm => 'Jsou moje';

  @override
  String get legacyDataDecline => 'Nejsou moje';

  @override
  String get errorActivityUploadLimit =>
      'Server má rozpracováno příliš mnoho vašich nahrávání. Aplikace to zkusí znovu později.';

  @override
  String get errorPasswordChangeFailed => 'Heslo se nepodařilo změnit';

  @override
  String errorPasswordChangeFailedWithDetails(String details) {
    return 'Heslo se nepodařilo změnit: $details';
  }

  @override
  String get errorSignInStepUnsupported =>
      'Server požádal o krok přihlášení, který tato verze aplikace nepodporuje. Aktualizujte aplikaci a zkuste to znovu.';

  @override
  String get errorSsoEmailMissing =>
      'Váš poskytovatel identity nesdílel e-mailovou adresu, která je potřeba k vytvoření účtu.';

  @override
  String get errorSsoEmailUnverified =>
      'Váš poskytovatel identity neověřil vaši e-mailovou adresu. Ověřte ji tam a zkuste to znovu.';

  @override
  String get errorSsoAutoCreateDisabled =>
      'Tomuto přihlášení neodpovídá žádný účet a tento server nevytváří účty automaticky. Obraťte se na správce.';

  @override
  String get errorSsoLinkByEmailDisabled =>
      'Tuto e-mailovou adresu už používá jiný účet, ale tento poskytovatel se k němu nemůže přihlásit. Přihlaste se jinak nebo se obraťte na správce.';

  @override
  String get errorSsoApprovalPending => 'Váš účet čeká na schválení správcem.';

  @override
  String get errorSsoAccountDisabled =>
      'Tento účet je zakázán. Obraťte se na správce.';

  @override
  String get errorSsoRedirectNotAllowed =>
      'Tento server nepovoluje jednotné přihlášení z této aplikace. Požádejte správce, aby přidal com.endurain.endurain:/auth/sso/callback do ALLOWED_REDIRECT_URIS.';

  @override
  String get errorActivityMfaEnrolmentRequired =>
      'Váš správce vyžaduje dvoufázové ověření. Nastavte ho ve webové aplikaci Endurain a zkuste to znovu.';

  @override
  String get errorActivityFileTooLarge =>
      'Soubor aktivity je pro tento server příliš velký';

  @override
  String get errorActivityUnsupportedFileType =>
      'Tento server tento druh souboru aktivity nepřijímá';

  @override
  String get errorTooManyRequests =>
      'Příliš mnoho pokusů. Chvíli počkejte a zkuste to znovu.';

  @override
  String get passwordChangeTitle => 'Zvolte nové heslo';

  @override
  String get passwordChangeMessage =>
      'Správce vám nastavil heslo. Pro dokončení přihlášení zvolte nové.';

  @override
  String get newPassword => 'Nové heslo';

  @override
  String get confirmNewPassword => 'Potvrďte nové heslo';

  @override
  String get passwordsDoNotMatch => 'Hesla se neshodují';

  @override
  String get changePassword => 'Změnit heslo';

  @override
  String get logoutServerFailedWarning =>
      'Odhlášení ze serveru se nezdařilo, ale odhlášení proběhlo místně';

  @override
  String get ssoBrowserLaunchFailed =>
      'Přihlášení přes SSO se nepodařilo otevřít v systémovém prohlížeči';

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
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Nejvyšší rychlost';

  @override
  String get activityStatElevationGain => 'Převýšení';

  @override
  String get activityStatHeartRate => 'Tep';

  @override
  String get activityStatAvgHeartRate => 'Prům. tep';

  @override
  String get activityStatPower => 'Výkon';

  @override
  String get activityStatAvgPower => 'Prům. výkon';

  @override
  String get activityStatCadence => 'Kadence';

  @override
  String get activityStatAvgCadence => 'Prům. kadence';

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
  String get activityAutoPauseTitle => 'Automatická pauza';

  @override
  String get activityAutoPauseSubtitle =>
      'Automaticky pozastaví, když se přestanete pohybovat';

  @override
  String get activityAutoPauseToggleLabel => 'Automaticky pozastavit';

  @override
  String get activityAutoPauseToggleDescription =>
      'Nahrávání se pozastaví, když se přestanete pohybovat, a obnoví se, jakmile se znovu začnete pohybovat.';

  @override
  String get activityAutoPauseDelayHelperText =>
      'Vyberte, jak dlouho čekat bez pohybu, než dojde k pozastavení.';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekund',
      many: '$seconds sekundy',
      few: '$seconds sekundy',
      one: '$seconds sekunda',
    );
    return '$_temp0';
  }

  @override
  String get activityAutoPausedIndicator => 'Automatická pauza';

  @override
  String get startCountdownSettingsTitle => 'Odpočet před startem';

  @override
  String get startCountdownSettingsSubtitle =>
      'Odpočítávat před zahájením nahrávání';

  @override
  String get startCountdownToggleLabel => 'Odpočítávat před startem';

  @override
  String get startCountdownToggleDescription =>
      'Dá vám čas schovat telefon, než začne nahrávání.';

  @override
  String get startCountdownDurationHelperText =>
      'Zvolte, jak dlouho odpočet trvá.';

  @override
  String startCountdownDurationOptionLabel(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekund',
      many: '$seconds sekundy',
      few: '$seconds sekundy',
      one: '$seconds sekunda',
    );
    return '$_temp0';
  }

  @override
  String get startCountdownVoiceLabel => 'Odpočet nahlas';

  @override
  String get startCountdownVoiceDescription =>
      'Přečte nahlas poslední sekundy a oznámí, kdy nahrávání začalo.';

  @override
  String get activityStartCountdownTitle => 'Nahrávání začne za';

  @override
  String activityStartCountdownRemaining(int seconds) {
    return 'Zbývá sekund: $seconds';
  }

  @override
  String get activityStartCountdownStartNow => 'Spustit hned';

  @override
  String activityStartCountdownAddSeconds(int seconds) {
    return '+$seconds s';
  }

  @override
  String get audioAnnouncementsRecordingStarted => 'Nahrávání zahájeno';

  @override
  String get audioAnnouncementsAutoPaused => 'Nahrávání pozastaveno';

  @override
  String get audioAnnouncementsAutoResumed => 'Nahrávání obnoveno';

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
  String get endurainTrademarkNotice =>
      'Endurain® je registrovaná ochranná známka João Vitória Silva';

  @override
  String get settingsScreen => 'Nastavení';

  @override
  String get settingsSectionAccount => 'Účet';

  @override
  String get settingsSectionGeneral => 'Obecné';

  @override
  String get settingsSectionRecording => 'Záznam';

  @override
  String get settingsSectionDevices => 'Zařízení a integrace';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionPrivacySupport => 'Soukromí a podpora';

  @override
  String get deviceAccessTitle => 'Přístup k zařízení';

  @override
  String get deviceAccessSubtitle =>
      'Spravujte přístup k údajům o poloze a zdraví';

  @override
  String get deviceAccessLocationSection => 'Poloha';

  @override
  String get deviceAccessHealthSection => 'Zdravotní údaje';

  @override
  String get deviceAccessLocationTitle => 'Přístup k poloze';

  @override
  String get deviceAccessHealthTitle => 'Přístup k údajům o zdraví';

  @override
  String get deviceAccessChecking => 'Kontrola přístupu…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Služby určování polohy jsou vypnuté';

  @override
  String get deviceAccessLocationAlways => 'Povoleno vždy';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Povoleno při používání aplikace';

  @override
  String get deviceAccessLocationBlocked => 'Blokováno v nastavení systému';

  @override
  String get deviceAccessLocationNotAllowed => 'Není povoleno';

  @override
  String get deviceAccessHealthUnavailable =>
      'Není k dispozici na tomto zařízení';

  @override
  String get deviceAccessHealthRequired => 'Vyžaduje se Health Connect';

  @override
  String get deviceAccessHealthSetUp => 'Přístup ke zdravotním údajům nastaven';

  @override
  String get deviceAccessHealthNeedsAttention => 'Přístup vyžaduje pozornost';

  @override
  String get deviceAccessHealthNotConnected => 'Nepřipojeno';

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
  String connectedToServer(String server) {
    return 'Připojeno k $server';
  }

  @override
  String get loggedIn => 'Přihlášeno';

  @override
  String get notConfigured => 'Nenastaveno';

  @override
  String get notLoggedIn => 'Nepřihlášeno';

  @override
  String get serverUrl => 'Adresa URL serveru';

  @override
  String get serverProtocol => 'Protokol';

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
  String get mapTilesSettingsTitle => 'Mapové dlaždice';

  @override
  String get mapTilesSettingsSubtitle => 'Server dlaždic pro vykreslování map';

  @override
  String get mapTilesSettingsNote =>
      'Platí, dokud jste připojeni k tomuto serveru. Po opětovném přihlášení se nahradí nastavením dlaždic vašeho serveru, pokud ho server má.';

  @override
  String get mapTilesSettingsLoadFailed =>
      'Nastavení mapových dlaždic se nepodařilo načíst.';

  @override
  String get tryAgain => 'Zkusit znovu';

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
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Odkaz se nepodařilo otevřít';

  @override
  String get diagnosticsTitle => 'Diagnostika';

  @override
  String get diagnosticsCollection => 'Shromažďování';

  @override
  String get diagnosticsEnable => 'Shromažďovat diagnostiku';

  @override
  String get diagnosticsEnableSubtitle =>
      'Ukládat nedávné události a chyby aplikace v tomto zařízení';

  @override
  String get diagnosticsDisabled =>
      'Shromažďování diagnostiky je vypnuto. Zapněte je, chcete-li začít zaznamenávat události a chyby aplikace v tomto zařízení.';

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

  @override
  String get healthSyncSettingsTitle => 'Synchronizace zdravotních dat';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importujte tréninky z vaší zdravotní platformy';

  @override
  String get healthSyncScreenTitle => 'Synchronizace zdravotních dat';

  @override
  String get healthAccessScreenTitle => 'Přístup ke zdravotním údajům';

  @override
  String get healthAccessRequestedData => 'Požadované údaje';

  @override
  String get healthAccessWorkouts => 'Tréninky';

  @override
  String get healthAccessWorkoutRoutes => 'Tréninkové trasy';

  @override
  String get healthAccessHeartRate => 'Srdeční frekvence';

  @override
  String get healthAccessAllowed => 'Povoleno';

  @override
  String get healthAccessNeedsAttention => 'Vyžaduje pozornost';

  @override
  String get healthAccessManagedBySystem => 'Spravováno v nastavení systému';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit nezveřejňuje, která data může Endurain číst. Zkontrolujte přístup v aplikaci Zdraví.';

  @override
  String get healthAccessReview => 'Zkontrolovat přístup ke zdravotním údajům';

  @override
  String get healthAccessReviewIos => 'Jak zkontrolovat přístup';

  @override
  String get healthAccessDisconnect => 'Odpojit zdravotní data';

  @override
  String get healthAccessDisconnectTitle => 'Odpojit zdravotní data?';

  @override
  String get healthAccessDisconnectMessage =>
      'Automatický import a místní historie importů pro tento server budou resetovány. Stávající aktivity zůstanou ve vaší historii.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Otevřete aplikaci Zdraví, klepněte na svůj profilový obrázek a poté na Aplikace a služby. Vyberte Endurain a aktualizujte kategorie dat.';

  @override
  String get healthSyncAuthorize => 'Připojit ke zdravotním datům';

  @override
  String get healthSyncInstallProvider => 'Nainstalovat Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Health Connect je vyžadován pro synchronizaci tréninků. Chcete-li pokračovat, nainstalujte jej.';

  @override
  String get healthSyncUnsupported =>
      'Synchronizace zdravotních dat není na tomto zařízení k dispozici.';

  @override
  String get healthSyncSelectAll => 'Vybrat vše';

  @override
  String get healthSyncClearSelection => 'Zrušit výběr';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importovat vybrané ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Importováno tréninků: $count.';
  }

  @override
  String get healthSyncNoRouteLabel => 'Bez trasy GPS';

  @override
  String get healthSyncEmptyState =>
      'Ve vybraném období nebyly nalezeny žádné tréninky.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Některé tréninky byly přeskočeny, protože nebyl udělen přístup k trasám cvičení. Otevřete Health Connect → Oprávnění a povolte pro Endurain trasy cvičení.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Některé tréninky byly vynechány, protože Endurain nedokázal přečíst jejich GPS trasy. V aplikaci Zdraví otevřete svůj profil, poté Aplikace a služby, vyberte Endurain a povolte trasy cvičení.';

  @override
  String get healthSyncHistoryAccessGuidance =>
      'Starší tréninky se nezobrazují, protože nebyl udělen přístup k minulým datům v Health Connect. Chcete-li je importovat, povolte pro Endurain v Health Connect „Přístup k minulým datům“.';

  @override
  String get healthSyncReviewAccess => 'Zkontrolovat přístup';

  @override
  String get healthSyncAutoSyncTitle =>
      'Automatická synchronizace při otevření';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Automaticky importovat nové tréninky po otevření aplikace.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Tyto tréninky neobsahují trasu GPS, takže je nelze importovat. Některé aplikace (např. Garmin Connect) zaznamenávají aktivity do Apple Health bez sdílení trasy. Tréninky zaznamenané pomocí Apple Watch trasy obsahují a lze je importovat.';

  @override
  String get healthSyncBadgeNonImportable => 'Nelze importovat';

  @override
  String get healthSyncViewAvailable => 'Dostupné';

  @override
  String get healthSyncViewImported => 'Importované';

  @override
  String get healthSyncDateRange => 'Období tréninků';

  @override
  String get healthSyncRange30Days => 'Posledních 30 dní';

  @override
  String get healthSyncRange3Months => 'Poslední 3 měsíce';

  @override
  String get healthSyncRange6Months => 'Posledních 6 měsíců';

  @override
  String get healthSyncRangeYear => 'Poslední rok';

  @override
  String get healthSyncRangeAll => 'Celá historie';

  @override
  String get healthSyncRangeCustom => 'Vlastní období';

  @override
  String get healthSyncImportedEmpty =>
      'Pro toto připojení nejsou importované tréninky.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importováno: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Obnovit';

  @override
  String get sensorsTitle => 'Senzory';

  @override
  String get sensorsSettingsSubtitle =>
      'Snímače tepové frekvence a další externí senzory';

  @override
  String get sensorsHeartRateSection => 'Tep';

  @override
  String get sensorsHeartRateHelp =>
      'Spárujte snímač tepové frekvence Bluetooth, abyste viděli svůj tep živě.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth je vypnuté. Zapněte ho pro připojení senzoru.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Povolte přístup k Bluetooth pro připojení senzoru.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Toto zařízení nepodporuje Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Hledat senzory';

  @override
  String get sensorsScanning => 'Hledání…';

  @override
  String get sensorsStopScan => 'Zastavit';

  @override
  String get sensorsNoDevices => 'Zatím nebyly nalezeny žádné snímače tepu.';

  @override
  String get sensorsAvailableSection => 'Dostupné senzory';

  @override
  String get sensorsSavedSection => 'Uložený senzor';

  @override
  String get sensorsConnect => 'Připojit';

  @override
  String get sensorsConnecting => 'Připojování…';

  @override
  String get sensorsConnected => 'Připojeno';

  @override
  String get sensorsDisconnect => 'Odpojit';

  @override
  String get sensorsForget => 'Zapomenout';

  @override
  String get sensorsConnectionFailed =>
      'Připojení se nezdařilo. Zkuste to znovu.';

  @override
  String get sensorsPermissionRequired =>
      'Pro hledání senzorů je vyžadováno oprávnění Bluetooth.';

  @override
  String get sensorsUnknownDevice => 'Neznámý senzor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Výkon';

  @override
  String get sensorsPowerHelp =>
      'Spárujte měřič výkonu Bluetooth, abyste viděli svůj výkon živě.';

  @override
  String get sensorsNoPowerDevices =>
      'Zatím nebyly nalezeny žádné měřiče výkonu.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Kadence';

  @override
  String get sensorsCadenceHelp =>
      'Spárujte snímač kadence Bluetooth, abyste viděli svou kadenci živě.';

  @override
  String get sensorsNoCadenceDevices =>
      'Zatím nebyly nalezeny žádné snímače kadence.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Vzdálené hlášení pádů';

  @override
  String get diagnosticsRemoteEnable => 'Odesílat hlášení o pádech';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Odesílejte hlášení o pádech a chybách na diagnostický server. Je to nezávislé na místní diagnostice; můžete zapnout obojí, jedno, nebo nic.';

  @override
  String get diagnosticsRemoteActive => 'Hlášení o pádech se odesílají';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Vzdálené hlášení pádů není v této verzi dostupné.';

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
  String get unitsTitle => 'Jednotky';

  @override
  String get unitsSubtitle => 'Jednotky vzdálenosti, rychlosti a převýšení';

  @override
  String get unitsSystemDefault => 'Podle regionu zařízení';

  @override
  String get unitsMetric => 'Metrické (km)';

  @override
  String get unitsImperial => 'Imperiální (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'Server se pokusil přesměrovat na nezabezpečené připojení. Požadavek byl zablokován na ochranu vašich přihlašovacích údajů.';

  @override
  String get errorTooManyRedirects =>
      'Server přesměroval příliš mnohokrát. Zkontrolujte adresu serveru.';

  @override
  String get audioAnnouncementsTitle => 'Hlasová oznámení';

  @override
  String get audioAnnouncementsSubtitle =>
      'Hlasové aktualizace vzdálenosti, času, tempa nebo rychlosti';

  @override
  String get audioAnnouncementsMasterSwitch => 'Oznamovat průběh aktivity';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Během nahrávání nahlas oznamuje vzdálenost, čas, tempo nebo rychlost';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Ztlumit ostatní zvuk během mluvení';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Dočasně sníží hlasitost ostatního zvuku během každého oznámení';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Interval oznámení podle typu aktivity';

  @override
  String get audioAnnouncementsByDistance => 'Vzdálenost';

  @override
  String get audioAnnouncementsByTime => 'Čas';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Každých $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Každých $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Zmenšit interval';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Zvětšit interval';

  @override
  String get audioAnnouncementsPreview => 'Přehrát ukázku';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'Ukázka hlášení není na tomto zařízení dostupná';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Změny se projeví při příštím záznamu.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Vzdálenost $distance. Čas $duration. Okruh: $lapMetric. Celkem: $overallMetric.';
  }
}
