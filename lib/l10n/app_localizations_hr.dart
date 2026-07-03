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
  String get errorPkceVerifierMissing => 'Verifikator prijave nije pronađen';

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
  String get ssoMissingSessionId => 'Odgovor SSO-a nije sadržavao ID sesije';

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
  String get settingsScreen => 'Postavke';

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
  String get loggedIn => 'Prijavljeni';

  @override
  String get notConfigured => 'Nije konfigurirano';

  @override
  String get notLoggedIn => 'Niste prijavljeni';

  @override
  String get serverUrl => 'URL poslužitelja';

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
  String get sourceCode => 'Izvorni kôd';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Poveznicu nije moguće otvoriti';

  @override
  String get diagnosticsTitle => 'Dijagnostika';

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
}
