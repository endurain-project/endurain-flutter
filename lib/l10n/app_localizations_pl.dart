// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get error => 'Błąd';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get back => 'Wstecz';

  @override
  String get requiredField => 'To pole jest wymagane';

  @override
  String get invalidUrl => 'Wprowadź prawidłowy adres URL';

  @override
  String get errorActivityUploadFailed => 'Nie udało się przesłać aktywności';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Nie udało się przesłać aktywności: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Przesyłanie aktywności nie jest jeszcze skonfigurowane';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Nie udało się usunąć tymczasowego pliku aktywności';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Nie udało się przygotować pliku do przesłania aktywności';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Nie udało się znaleźć tej lokalnej aktywności';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Nie udało się usunąć lokalnej aktywności';

  @override
  String get errorActivityLocalGpxMissing =>
      'Lokalny plik GPX jest niedostępny';

  @override
  String get errorActivityLocalLoadFailed =>
      'Nie udało się wczytać lokalnych aktywności';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Nie udało się zapisać tej aktywności';

  @override
  String get errorActivityLocalSaveFailed =>
      'Nie udało się zapisać aktywności lokalnie';

  @override
  String get errorFetchProvidersFailed =>
      'Nie udało się wczytać dostawców logowania';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Nie udało się wczytać dostawców logowania: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Nie udało się wczytać ustawień serwera';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Nie udało się wczytać ustawień serwera: $details';
  }

  @override
  String get errorLoginError => 'Nie udało się zalogować';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Nie udało się zalogować: $details';
  }

  @override
  String get errorLoginFailed => 'Logowanie nie powiodło się';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Logowanie nie powiodło się: $details';
  }

  @override
  String get errorMfaVerificationError => 'Nie udało się zweryfikować kodu MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Nie udało się zweryfikować kodu MFA: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Weryfikacja MFA nie powiodła się';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Weryfikacja MFA nie powiodła się: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Serwer nie zwrócił identyfikatora sesji';

  @override
  String get errorNotAuthenticated => 'Nie jesteś zalogowany';

  @override
  String get errorPkceVerifierMissing =>
      'Nie znaleziono weryfikatora logowania';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Nie znaleziono weryfikatora logowania. Rozpocznij logowanie ponownie.';

  @override
  String get errorServerUrlNotConfigured =>
      'Adres URL serwera nie jest skonfigurowany';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Ten serwer wymaga bezpiecznego połączenia (HTTPS)';

  @override
  String get errorSessionExpired =>
      'Twoja sesja wygasła. Zaloguj się ponownie.';

  @override
  String get errorSsoTokenExchangeError =>
      'Nie udało się ukończyć logowania SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Nie udało się ukończyć logowania SSO: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Wymiana tokenów nie powiodła się';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Wymiana tokenów nie powiodła się: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Upłynął limit czasu żądania. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Nie można usunąć z bezpiecznego magazynu. Magazyn urządzenia może być niedostępny.';

  @override
  String get errorSecureStorageReadFailed =>
      'Nie można odczytać z bezpiecznego magazynu. Magazyn urządzenia może być niedostępny.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Nie można zapisać w bezpiecznym magazynie. Magazyn urządzenia może być niedostępny.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Serwer zwrócił nieoczekiwaną odpowiedź';

  @override
  String get errorUnsupportedHttpMethod => 'Nieobsługiwana metoda HTTP';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nieobsługiwana metoda HTTP: $details';
  }

  @override
  String get loginTitle => 'Logowanie';

  @override
  String get login => 'Zaloguj się';

  @override
  String get logout => 'Wyloguj się';

  @override
  String get logoutConfirmTitle => 'Wyloguj się';

  @override
  String get logoutConfirmMessage => 'Czy na pewno chcesz się wylogować?';

  @override
  String get logoutServerFailedWarning =>
      'Nie udało się wylogować z serwera, ale wylogowano lokalnie';

  @override
  String get ssoBrowserLaunchFailed =>
      'Nie udało się otworzyć logowania SSO w przeglądarce systemowej';

  @override
  String get ssoMissingSessionId =>
      'Odpowiedź SSO nie zawierała identyfikatora sesji';

  @override
  String ssoSignInWith(String provider) {
    return 'Zaloguj się przez $provider';
  }

  @override
  String get ssoOrDivider => 'LUB';

  @override
  String get next => 'Dalej';

  @override
  String get username => 'Nazwa użytkownika';

  @override
  String get usernameHint => 'Wprowadź nazwę użytkownika';

  @override
  String get password => 'Hasło';

  @override
  String get passwordHint => 'Wprowadź hasło';

  @override
  String get showPassword => 'Pokaż hasło';

  @override
  String get mfaTitle => 'Uwierzytelnianie dwuskładnikowe';

  @override
  String get mfaCode => 'Kod MFA';

  @override
  String get mfaCodeHint => 'Wprowadź 6-cyfrowy kod';

  @override
  String get mfaCodeRequired => 'Wprowadź kod MFA';

  @override
  String get verify => 'Zweryfikuj';

  @override
  String get activityDiscard => 'Odrzuć';

  @override
  String get activityDiscardConfirmMessage =>
      'Spowoduje to usunięcie zarejestrowanych punktów tej aktywności.';

  @override
  String get activityDiscardConfirmTitle => 'Odrzucić aktywność?';

  @override
  String get activityLocationPermissionDenied =>
      'Do zarejestrowania aktywności wymagane jest uprawnienie do lokalizacji.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Uprawnienie do lokalizacji jest zablokowane. Otwórz ustawienia, aby zezwolić na dostęp do lokalizacji.';

  @override
  String get activityLocationServiceDisabled =>
      'Usługi lokalizacji są wyłączone.';

  @override
  String get activityLocationStreamFailed =>
      'Aktualizacje lokalizacji nieoczekiwanie się zatrzymały.';

  @override
  String get activityGpxGenerationFailed =>
      'Nie udało się utworzyć pliku GPX aktywności.';

  @override
  String get activityLocalSaveFailed =>
      'Nie udało się zapisać tej aktywności na tym urządzeniu.';

  @override
  String get activityOpenSettings => 'Otwórz ustawienia';

  @override
  String get activityPause => 'Wstrzymaj';

  @override
  String get activityRecordingEmpty =>
      'Nie zarejestrowano żadnych punktów GPS.';

  @override
  String get activityRecordingFailed => 'Nagrywanie nie powiodło się.';

  @override
  String get activityResume => 'Wznów';

  @override
  String get activityRetryUpload => 'Ponów przesyłanie';

  @override
  String get activityDone => 'Gotowe';

  @override
  String get activityViewHistory => 'Wyświetl historię';

  @override
  String get activityDeleteLocal => 'Usuń lokalną kopię';

  @override
  String get activityExportGpx => 'Udostępnij plik GPX';

  @override
  String get activityExportGpxSubject => 'Plik GPX aktywności Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Usunąć lokalną aktywność?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Spowoduje to usunięcie lokalnego rekordu aktywności i pliku GPX z tego urządzenia.';

  @override
  String get activityStart => 'Rozpocznij';

  @override
  String get activityBackgroundPermissionTitle =>
      'Zezwolić na śledzenie w tle?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain wymaga lokalizacji w tle ustawionej na Zawsze, aby nagrywanie było kontynuowane, gdy aplikacja działa w tle, ekran jest zablokowany lub przełączasz aplikacje.';

  @override
  String get activityBackgroundPermissionContinue => 'Kontynuuj';

  @override
  String get activityBackgroundPermissionRequired =>
      'Śledzenie w tle na iPhonie i iPadzie wymaga lokalizacji ustawionej na Zawsze.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Śledzenie w tle jest wyłączone';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Aby niezawodnie nagrywać w tle lub przy zablokowanym ekranie, otwórz Ustawienia i ustaw Lokalizację na Zawsze dla Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Nagrywanie aktywności';

  @override
  String get activityTrackingNotificationText =>
      'Endurain śledzi Twoją lokalizację, aby zarejestrować tę aktywność.';

  @override
  String get activityStatDistance => 'Dystans';

  @override
  String get activityStatDuration => 'Czas';

  @override
  String get activityStatSpeed => 'Prędkość';

  @override
  String get activityStop => 'Zatrzymaj';

  @override
  String get activityStopAndSave => 'Zatrzymaj i zapisz';

  @override
  String get activityStopConfirmMessage =>
      'Wybierz, czy chcesz zachować to nagranie, czy je odrzucić.';

  @override
  String get activityStopConfirmTitle => 'Zakończyć aktywność?';

  @override
  String get activityStopping => 'Zatrzymywanie';

  @override
  String get activityTypeHike => 'Wędrówka';

  @override
  String get activityTypeLabel => 'Typ aktywności';

  @override
  String get activityTypeOther => 'Inne';

  @override
  String get activityTypeRide => 'Jazda na rowerze';

  @override
  String get activityTypeRun => 'Bieg';

  @override
  String get activityTypeWalk => 'Spacer';

  @override
  String get activityUploadFailed => 'Przesyłanie nie powiodło się';

  @override
  String get activityUploadCleanupFailed =>
      'Przesłano, ale czyszczenie nie powiodło się';

  @override
  String get activityUploadReady => 'Gotowe do przesłania';

  @override
  String get activityUploaded => 'Przesłano';

  @override
  String get activityUploading => 'Przesyłanie';

  @override
  String get activityUploadStatusPending => 'Oczekujące';

  @override
  String get activityUploadStatusUploaded => 'Przesłano';

  @override
  String get activityUploadStatusFailed => 'Niepowodzenie';

  @override
  String get activityHistoryTitle => 'Historia aktywności';

  @override
  String get activityHistorySettingsSubtitle =>
      'Ukończone aktywności zapisane na tym urządzeniu';

  @override
  String get activityRetainUploadedGpx => 'Zachowaj przesłane pliki GPX';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Zapisuje ukończone pliki tras w prywatnej pamięci aplikacji po przesłaniu.';

  @override
  String get activityHistoryEmpty =>
      'Brak ukończonych aktywności zapisanych na tym urządzeniu.';

  @override
  String get activityHistoryLoadFailed =>
      'Nie udało się wczytać lokalnych aktywności.';

  @override
  String get activityHistoryRefresh => 'Odśwież';

  @override
  String get activityHistoryLocalActivities => 'Lokalne aktywności';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Czas trwania: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Dystans: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Przesyłanie: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Wczytaj więcej';

  @override
  String get activityHistoryDetailsTitle => 'Szczegóły aktywności';

  @override
  String get activityHistoryDetailsMissing =>
      'Ta lokalna aktywność nie jest już dostępna.';

  @override
  String get activityHistorySummary => 'Podsumowanie';

  @override
  String get activityHistoryActions => 'Akcje';

  @override
  String get activityHistoryType => 'Typ';

  @override
  String get activityHistoryStartedAt => 'Rozpoczęto';

  @override
  String get activityHistoryEndedAt => 'Zakończono';

  @override
  String get activityHistoryDurationLabel => 'Czas trwania';

  @override
  String get activityHistoryDistanceLabel => 'Dystans';

  @override
  String get activityHistoryAverageSpeed => 'Średnia prędkość';

  @override
  String get activityHistoryPointCount => 'Punkty GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Przesyłanie';

  @override
  String get activityHistoryGpxStatus => 'Plik GPX';

  @override
  String get activityHistoryGpxAvailable => 'Zapisano na tym urządzeniu';

  @override
  String get activityHistoryGpxMissing => 'Niedostępne na tym urządzeniu';

  @override
  String get mapTab => 'Mapa';

  @override
  String get myLocation => 'Moja lokalizacja';

  @override
  String get settingsTab => 'Ustawienia';

  @override
  String get settingsScreen => 'Ustawienia';

  @override
  String get language => 'Język';

  @override
  String get languageSystemDefault => 'Domyślny systemowy';

  @override
  String get serverSettings => 'Serwer';

  @override
  String get signInConnectServer => 'Zaloguj się';

  @override
  String get signInConnectServerSubtitle =>
      'Nagrywaj offline teraz i zsynchronizuj aktywności później';

  @override
  String get serverSettingsTitle => 'Ustawienia serwera';

  @override
  String get loggedIn => 'Zalogowano';

  @override
  String get notConfigured => 'Nie skonfigurowano';

  @override
  String get notLoggedIn => 'Nie zalogowano';

  @override
  String get serverUrl => 'Adres URL serwera';

  @override
  String get serverUrlHint => 'https://przyklad.com';

  @override
  String get warnHttpServerUrlTitle => 'Niezabezpieczone połączenie';

  @override
  String get warnHttpServerUrlMessage =>
      'Ten adres URL serwera używa zwykłego HTTP. Twoje dane logowania i dane będą przesyłane bez szyfrowania. Kontynuuj tylko wtedy, gdy rozumiesz i akceptujesz ryzyko.';

  @override
  String get warnHttpServerUrlConfirm => 'Kontynuuj mimo to';

  @override
  String get tileServerUrl => 'Adres URL serwera kafelków mapy';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Inny host serwera kafelków';

  @override
  String get tileServerHostWarningMessage =>
      'Host serwera kafelków różni się od hosta Twojego serwera Endurain. Kafelki będą ładowane z serwera zewnętrznego. Czy chcesz kontynuować?';

  @override
  String get savedSuccessfully => 'Ustawienia zostały zapisane';

  @override
  String get diagnostics => 'Diagnostyka';

  @override
  String get diagnosticsSubtitle => 'Lokalny kontekst awarii';

  @override
  String get sourceCode => 'Kod źródłowy';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Nie można otworzyć linku';

  @override
  String get diagnosticsTitle => 'Diagnostyka';

  @override
  String get diagnosticsEmpty =>
      'Nie przechwycono jeszcze żadnych danych diagnostycznych.';

  @override
  String get diagnosticsCopy => 'Kopiuj';

  @override
  String get diagnosticsCopied => 'Skopiowano diagnostykę';

  @override
  String get diagnosticsClear => 'Wyczyść';

  @override
  String get diagnosticsCleared => 'Wyczyszczono diagnostykę';

  @override
  String get diagnosticsSummary => 'Podsumowanie';

  @override
  String get diagnosticsLastUpdated => 'Ostatnia aktualizacja';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Zdarzenia: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Błędy: $count';
  }

  @override
  String get diagnosticsEvents => 'Zdarzenia';

  @override
  String get diagnosticsNoEvents => 'Nie przechwycono żadnych zdarzeń';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Zdarzenie: $event';
  }

  @override
  String get diagnosticsErrors => 'Błędy';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Błąd: $type';
  }

  @override
  String get diagnosticsActions => 'Akcje';

  @override
  String get diagnosticsRawReport => 'Nieprzetworzony raport';
}
