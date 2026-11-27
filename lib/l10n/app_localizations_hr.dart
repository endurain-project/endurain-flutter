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
  String get errorActivityIngestionUnsupportedFormat =>
      'Format datoteke nije podržan';

  @override
  String get errorActivityIngestionInvalidFile =>
      'Datoteka je oštećena ili se nije mogla pročitati';

  @override
  String get errorActivityIngestionNoActivitiesFound =>
      'U datoteci nisu pronađene aktivnosti';

  @override
  String get errorActivityIngestionProcessingFailed =>
      'Nešto je pošlo po zlu prilikom uvoza aktivnosti. Pokušajte ponovno.';

  @override
  String get errorActivityIngestionProviderUnavailable =>
      'Pružatelj aktivnosti trenutačno nije dostupan. Pokušajte ponovno kasnije.';

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
      'Nije moguće pretvoriti trening u GPX';

  @override
  String get errorHealthImportFailed => 'Nije moguće uvesti trening';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Nije moguće uvesti trening: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Pristup zdravstvenim podacima je odbijen';

  @override
  String get errorHealthUnavailable =>
      'Zdravstveni podaci nisu dostupni na ovom uređaju';

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
  String get errorMfaSessionMissing =>
      'Vaša sesija prijave je izgubljena. Prijavite se ponovno.';

  @override
  String get errorSsoCallbackFailed =>
      'Jedinstvenu prijavu (SSO) nije bilo moguće dovršiti. Pokušajte ponovno.';

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
  String get legacyDataTitle => 'Aktivnosti od prije ažuriranja poslužitelja';

  @override
  String legacyDataMessageWithUsername(String username) {
    return 'Na ovom uređaju postoje aktivnosti spremljene za račun na ovom poslužitelju od prije njegova ažuriranja. Jesu li vaše, $username? Ako jesu, one koje još čekaju bit će prenesene na vaš račun.';
  }

  @override
  String get legacyDataMessage =>
      'Na ovom uređaju postoje aktivnosti spremljene za račun na ovom poslužitelju od prije njegova ažuriranja. Pripadaju li računu s kojim ste se upravo prijavili? Ako da, one koje još čekaju bit će prenesene na njega.';

  @override
  String get legacyDataConfirm => 'Moje su';

  @override
  String get legacyDataDecline => 'Nisu moje';

  @override
  String get errorActivityUploadLimit =>
      'Poslužitelj ima previše vaših prijenosa u tijeku. Aplikacija će pokušati ponovno kasnije.';

  @override
  String get errorPasswordChangeFailed => 'Lozinku nije moguće promijeniti';

  @override
  String errorPasswordChangeFailedWithDetails(String details) {
    return 'Lozinku nije moguće promijeniti: $details';
  }

  @override
  String get errorSignInStepUnsupported =>
      'Poslužitelj je zatražio korak prijave koji ova verzija aplikacije ne podržava. Ažurirajte aplikaciju i pokušajte ponovno.';

  @override
  String get errorSsoEmailMissing =>
      'Vaš pružatelj identiteta nije podijelio adresu e-pošte, koja je potrebna za izradu računa.';

  @override
  String get errorSsoEmailUnverified =>
      'Vaš pružatelj identiteta nije potvrdio vašu adresu e-pošte. Potvrdite je ondje i pokušajte ponovno.';

  @override
  String get errorSsoAutoCreateDisabled =>
      'Nijedan račun ne odgovara ovoj prijavi, a ovaj poslužitelj ne izrađuje račune automatski. Obratite se administratoru.';

  @override
  String get errorSsoLinkByEmailDisabled =>
      'Račun već koristi ovu adresu e-pošte, ali ovaj pružatelj se ne može prijaviti u njega. Prijavite se na drugi način ili se obratite administratoru.';

  @override
  String get errorSsoApprovalPending =>
      'Vaš račun čeka odobrenje administratora.';

  @override
  String get errorSsoAccountDisabled =>
      'Ovaj račun je onemogućen. Obratite se administratoru.';

  @override
  String get errorSsoRedirectNotAllowed =>
      'Ovaj poslužitelj ne dopušta jedinstvenu prijavu iz ove aplikacije. Zamolite administratora da doda com.endurain.endurain:/auth/sso/callback u ALLOWED_REDIRECT_URIS.';

  @override
  String get errorActivityMfaEnrolmentRequired =>
      'Vaš administrator zahtijeva provjeru u dva koraka. Postavite je u web-aplikaciji Endurain i pokušajte ponovno.';

  @override
  String get errorActivityFileTooLarge =>
      'Datoteka aktivnosti prevelika je za ovaj poslužitelj';

  @override
  String get errorActivityUnsupportedFileType =>
      'Ovaj poslužitelj ne prihvaća ovu vrstu datoteke aktivnosti';

  @override
  String get errorTooManyRequests =>
      'Previše pokušaja. Pričekajte trenutak i pokušajte ponovno.';

  @override
  String get passwordChangeTitle => 'Odaberite novu lozinku';

  @override
  String get passwordChangeMessage =>
      'Administrator vam je postavio lozinku. Odaberite novu da biste dovršili prijavu.';

  @override
  String get newPassword => 'Nova lozinka';

  @override
  String get confirmNewPassword => 'Potvrdite novu lozinku';

  @override
  String get passwordsDoNotMatch => 'Lozinke se ne podudaraju';

  @override
  String get changePassword => 'Promijeni lozinku';

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
  String get mfaBackupCode => 'Rezervni kôd';

  @override
  String get mfaBackupCodeHint =>
      'Unesite jedan od svojih rezervnih kôdova od 8 znakova';

  @override
  String get mfaUseBackupCode => 'Koristi rezervni kôd';

  @override
  String get mfaUseAuthenticatorCode =>
      'Koristi kôd iz aplikacije za autentifikaciju';

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
  String get activityUploadAwaitingSignIn =>
      'Spremljeno na ovom uređaju. Prenijet će se nakon prijave.';

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
  String get activityAutoPauseTitle => 'Automatska pauza';

  @override
  String get activityAutoPauseSubtitle =>
      'Automatski pauzira kada prestanete s kretanjem';

  @override
  String get activityAutoPauseToggleLabel => 'Automatski pauziraj';

  @override
  String get activityAutoPauseToggleDescription =>
      'Snimanje se automatski pauzira kada prestanete s kretanjem, a nastavlja se čim se ponovno počnete kretati.';

  @override
  String get activityAutoPauseDelayHelperText =>
      'Odaberite koliko dugo bez kretanja treba pričekati prije pauze.';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekundi',
      few: '$seconds sekunde',
      one: '$seconds sekunda',
    );
    return '$_temp0';
  }

  @override
  String get activityAutoPausedIndicator => 'Automatski pauzirano';

  @override
  String get startCountdownSettingsTitle => 'Odbrojavanje prije početka';

  @override
  String get startCountdownSettingsSubtitle =>
      'Odbrojavaj prije početka snimanja';

  @override
  String get startCountdownToggleLabel => 'Odbrojavaj prije početka';

  @override
  String get startCountdownToggleDescription =>
      'Daje vam vremena da spremite telefon prije nego što snimanje počne.';

  @override
  String get startCountdownDurationHelperText =>
      'Odaberite koliko dugo traje odbrojavanje.';

  @override
  String startCountdownDurationOptionLabel(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekundi',
      few: '$seconds sekunde',
      one: '$seconds sekunda',
    );
    return '$_temp0';
  }

  @override
  String get startCountdownVoiceLabel => 'Odbrojavaj naglas';

  @override
  String get startCountdownVoiceDescription =>
      'Naglas čita zadnje sekunde i javlja kada je snimanje počelo.';

  @override
  String get activityStartCountdownTitle => 'Snimanje počinje za';

  @override
  String activityStartCountdownRemaining(int seconds) {
    return 'Preostalo sekundi: $seconds';
  }

  @override
  String get activityStartCountdownStartNow => 'Počni odmah';

  @override
  String activityStartCountdownAddSeconds(int seconds) {
    return '+$seconds s';
  }

  @override
  String get audioAnnouncementsRecordingStarted => 'Snimanje je počelo';

  @override
  String get audioAnnouncementsAutoPaused => 'Snimanje pauzirano';

  @override
  String get audioAnnouncementsAutoResumed => 'Snimanje nastavljeno';

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
      'Endurain® je registrirani žig čiji je nositelj João Vitória Silva';

  @override
  String get settingsScreen => 'Postavke';

  @override
  String get settingsSectionAccount => 'Račun';

  @override
  String get settingsSectionGeneral => 'Općenito';

  @override
  String get settingsSectionRecording => 'Snimanje';

  @override
  String get settingsSectionDevices => 'Uređaji i integracije';

  @override
  String get settingsSectionData => 'Podaci';

  @override
  String get settingsSectionPrivacySupport => 'Privatnost i podrška';

  @override
  String get deviceAccessTitle => 'Pristup uređaju';

  @override
  String get deviceAccessSubtitle =>
      'Upravljanje pristupom lokaciji i zdravstvenim podacima';

  @override
  String get deviceAccessLocationSection => 'Lokacija';

  @override
  String get deviceAccessHealthSection => 'Zdravstveni podaci';

  @override
  String get deviceAccessLocationTitle => 'Pristup lokaciji';

  @override
  String get deviceAccessHealthTitle => 'Pristup zdravstvenim podacima';

  @override
  String get deviceAccessBluetoothSection => 'Bluetooth';

  @override
  String get deviceAccessBluetoothTitle => 'Pristup Bluetoothu';

  @override
  String get deviceAccessBluetoothAllowed => 'Dopušteno';

  @override
  String get deviceAccessBluetoothOff => 'Bluetooth je isključen';

  @override
  String get deviceAccessBluetoothBlocked => 'Blokirano u postavkama sustava';

  @override
  String get deviceAccessBluetoothNotAllowed => 'Nije dopušteno';

  @override
  String get deviceAccessBluetoothUnavailable =>
      'Nije dostupno na ovom uređaju';

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
  String get deviceAccessHealthRequired => 'Potreban je Health Connect';

  @override
  String get deviceAccessHealthSetUp =>
      'Pristup zdravstvenim podacima postavljen';

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
    return 'Povezano s poslužiteljem $server';
  }

  @override
  String get loggedIn => 'Prijavljeni';

  @override
  String get serverNotSecure => 'Nije sigurno (HTTP)';

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
  String get mapTilesSettingsTitle => 'Pločice karte';

  @override
  String get mapTilesSettingsSubtitle =>
      'Poslužitelj pločica za crtanje karata';

  @override
  String get mapTilesSettingsNote =>
      'Vrijedi dok ste povezani s ovim poslužiteljem. Ponovnom prijavom zamjenjuje se postavkom pločica vašeg poslužitelja, ako je ima.';

  @override
  String get mapTilesSettingsLoadFailed =>
      'Postavka pločica karte nije se mogla učitati.';

  @override
  String get tryAgain => 'Pokušaj ponovno';

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
  String get healthSyncSettingsTitle => 'Sinkronizacija zdravstvenih podataka';

  @override
  String get healthSyncSettingsSubtitle =>
      'Uvezite treninge sa svoje zdravstvene platforme';

  @override
  String get healthSyncScreenTitle => 'Sinkronizacija zdravstvenih podataka';

  @override
  String get healthAccessScreenTitle => 'Pristup zdravstvenim podacima';

  @override
  String get healthAccessRequestedData => 'Traženi podaci';

  @override
  String get healthAccessWorkouts => 'Treninzi';

  @override
  String get healthAccessWorkoutRoutes => 'Rute treninga';

  @override
  String get healthAccessHeartRate => 'Otkucaji srca';

  @override
  String get healthAccessAllowed => 'Dopušteno';

  @override
  String get healthAccessNeedsAttention => 'Zahtijeva pažnju';

  @override
  String get healthAccessManagedBySystem => 'Upravlja se u postavkama sustava';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit ne otkriva koje podatke Endurain može čitati. Pregledajte pristup u aplikaciji Zdravlje.';

  @override
  String get healthAccessReview => 'Pregledaj pristup zdravstvenim podacima';

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
  String get healthAccessBlockedTitle => 'Dopustite pristup u Health Connectu';

  @override
  String get healthAccessBlockedMessage =>
      'Health Connect prestaje pitati nakon što je pristup dvaput odbijen. Otvorite Health Connect kako biste dopustili Endurainu čitanje vaših treninga, ruta i srčane frekvencije.';

  @override
  String get healthAccessOpenHealthConnect => 'Otvori Health Connect';

  @override
  String get healthSyncAuthorize => 'Poveži zdravstvene podatke';

  @override
  String get healthSyncInstallProvider => 'Instaliraj Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Za sinkronizaciju treninga potreban je Health Connect. Instalirajte ga za nastavak.';

  @override
  String get healthSyncUnsupported =>
      'Sinkronizacija zdravstvenih podataka nije dostupna na ovom uređaju.';

  @override
  String get healthSyncSelectAll => 'Odaberi sve';

  @override
  String get healthSyncClearSelection => 'Poništi odabir';

  @override
  String healthSyncImportSelected(int count) {
    return 'Uvezi odabrane ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uvezeno je $count treninga.',
      few: 'Uvezena su $count treninga.',
      one: 'Uvezen je $count trening.',
    );
    return '$_temp0';
  }

  @override
  String get healthSyncNoRouteLabel => 'Bez GPS rute';

  @override
  String get healthSyncEmptyState =>
      'Nije pronađen nijedan trening u odabranom razdoblju.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Neki su treninzi preskočeni jer nije odobren pristup rutama vježbanja. Otvorite Health Connect → Dopuštenja i dopustite rute vježbanja za Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Neki su treninzi preskočeni jer Endurain nije mogao pročitati njihove GPS rute. U aplikaciji Zdravlje otvorite svoj profil, zatim Aplikacije i usluge, odaberite Endurain i dopustite Rute treninga.';

  @override
  String get healthSyncHistoryAccessGuidance =>
      'Stariji treninzi nisu prikazani jer u Health Connectu nije odobren pristup prošlim podacima. Dopustite „Pristup prošlim podacima” za Endurain u Health Connectu da biste ih uvezli.';

  @override
  String get healthSyncReviewAccess => 'Pregledaj pristup';

  @override
  String get healthSyncAutoSyncTitle =>
      'Automatska sinkronizacija pri otvaranju';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Automatski uvozi nove treninge kada se aplikacija otvori.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Ovi treninzi ne sadrže GPS rutu pa se ne mogu uvesti. Neke aplikacije (npr. Garmin Connect) bilježe aktivnosti u Apple Health bez dijeljenja rute. Treninzi snimljeni Apple Watchom sadrže rute i mogu se uvesti.';

  @override
  String get healthSyncBadgeNonImportable => 'Nije moguće uvesti';

  @override
  String get healthSyncViewAvailable => 'Dostupno';

  @override
  String get healthSyncViewImported => 'Uvezeno';

  @override
  String get healthSyncDateRange => 'Razdoblje treninga';

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
  String get healthSyncImportedEmpty => 'Nema uvezenih treninga za ovu vezu.';

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
      'Uparite Bluetooth mjerač pulsa da biste vidjeli svoj puls uživo.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth je isključen. Uključite ga za povezivanje senzora.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Dopustite pristup Bluetoothu za povezivanje senzora.';

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
      'Povezivanje nije uspjelo. Pokušajte ponovno.';

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
      'Uparite Bluetooth mjerač snage da biste vidjeli svoju snagu uživo.';

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
      'Uparite Bluetooth senzor kadence da biste vidjeli svoju kadencu uživo.';

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
      'Šalji izvješća o rušenjima i pogreškama na dijagnostički poslužitelj. Neovisno je o lokalnoj dijagnostici; možeš uključiti oboje, jedno ili ništa.';

  @override
  String get diagnosticsRemoteActive => 'Izvješća o rušenju se šalju';

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
      'Poslužitelj je pokušao preusmjeriti na nesigurnu vezu. Zahtjev je blokiran radi zaštite vaših vjerodajnica.';

  @override
  String get errorTooManyRedirects =>
      'Poslužitelj je preusmjeravao previše puta. Provjerite adresu poslužitelja.';

  @override
  String get audioAnnouncementsTitle => 'Govorne najave';

  @override
  String get audioAnnouncementsSubtitle =>
      'Govorne obavijesti o udaljenosti, vremenu, tempu ili brzini';

  @override
  String get audioAnnouncementsMasterSwitch => 'Najavi napredak aktivnosti';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Izgovara vašu udaljenost, vrijeme, tempo ili brzinu tijekom snimanja';

  @override
  String get audioAnnouncementsDuckSwitch => 'Utišaj drugi zvuk tijekom govora';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Privremeno smanjuje glasnoću drugog zvuka tijekom svake najave';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Interval najave prema aktivnosti';

  @override
  String get audioAnnouncementsByDistance => 'Udaljenost';

  @override
  String get audioAnnouncementsByTime => 'Vrijeme';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Svakih $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Svakih $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Smanji interval';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Povećaj interval';

  @override
  String get audioAnnouncementsPreview => 'Poslušaj primjer';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'Primjer najave nije dostupan na ovom uređaju';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Promjene se primjenjuju na sljedeće snimanje.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Udaljenost $distance. Vrijeme $duration. Krug: $lapMetric. Ukupno: $overallMetric.';
  }
}
