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
  String get errorHealthGpxBuildFailed =>
      'Nie można przekonwertować treningu na GPX';

  @override
  String get errorHealthImportFailed => 'Nie można zaimportować treningu';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Nie można zaimportować treningu: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Odmówiono dostępu do danych zdrowotnych';

  @override
  String get errorHealthReadFailed =>
      'Nie udało się odczytać danych zdrowotnych';

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
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Maks. prędkość';

  @override
  String get activityStatElevationGain => 'Przewyższenie';

  @override
  String get activityStatHeartRate => 'Tętno';

  @override
  String get activityStatAvgHeartRate => 'Śr. tętno';

  @override
  String get activityStatPower => 'Moc';

  @override
  String get activityStatAvgPower => 'Śr. moc';

  @override
  String get activityStatCadence => 'Kadencja';

  @override
  String get activityStatAvgCadence => 'Śr. kadencja';

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
  String get endurainTrademarkNotice =>
      'Endurain® jest zarejestrowanym znakiem towarowym João Vitória Silva';

  @override
  String get settingsScreen => 'Ustawienia';

  @override
  String get deviceAccessTitle => 'Dostęp do urządzenia';

  @override
  String get deviceAccessSubtitle =>
      'Zarządzaj dostępem do danych o lokalizacji i stanie zdrowia';

  @override
  String get deviceAccessLocationSection => 'Lokalizacja';

  @override
  String get deviceAccessHealthSection => 'Dane dotyczące zdrowia';

  @override
  String get deviceAccessLocationTitle => 'Dostęp do lokalizacji';

  @override
  String get deviceAccessHealthTitle => 'Dostęp do danych zdrowotnych';

  @override
  String get deviceAccessChecking => 'Sprawdzam dostęp…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Usługi lokalizacyjne są wyłączone';

  @override
  String get deviceAccessLocationAlways => 'Dozwolone cały czas';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Dozwolone podczas korzystania z aplikacji';

  @override
  String get deviceAccessLocationBlocked =>
      'Zablokowane w ustawieniach systemu';

  @override
  String get deviceAccessLocationNotAllowed => 'Niedozwolone';

  @override
  String get deviceAccessHealthUnavailable => 'Niedostępne na tym urządzeniu';

  @override
  String get deviceAccessHealthRequired => 'Wymagane jest połączenie Zdrowie';

  @override
  String get deviceAccessHealthSetUp =>
      'Skonfigurowano dostęp do informacji zdrowotnych';

  @override
  String get deviceAccessHealthNeedsAttention => 'Dostęp wymaga uwagi';

  @override
  String get deviceAccessHealthNotConnected => 'Nie podłączony';

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
  String connectedToServer(String server) {
    return 'Połączono z $server';
  }

  @override
  String get loggedIn => 'Zalogowano';

  @override
  String get notConfigured => 'Nie skonfigurowano';

  @override
  String get notLoggedIn => 'Nie zalogowano';

  @override
  String get serverUrl => 'Adres URL serwera';

  @override
  String get serverProtocol => 'Protokół';

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
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Nie można otworzyć linku';

  @override
  String get diagnosticsTitle => 'Diagnostyka';

  @override
  String get diagnosticsCollection => 'Zbieranie';

  @override
  String get diagnosticsEnable => 'Zbieraj dane diagnostyczne';

  @override
  String get diagnosticsEnableSubtitle =>
      'Przechowuj ostatnie zdarzenia i błędy aplikacji na tym urządzeniu';

  @override
  String get diagnosticsDisabled =>
      'Zbieranie danych diagnostycznych jest wyłączone. Włącz je, aby rozpocząć rejestrowanie zdarzeń i błędów aplikacji na tym urządzeniu.';

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

  @override
  String get healthSyncSettingsTitle => 'Synchronizacja zdrowia';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importuj treningi ze swojej platformy zdrowotnej';

  @override
  String get healthSyncScreenTitle => 'Synchronizacja zdrowia';

  @override
  String get healthAccessScreenTitle => 'Dostęp do zdrowia';

  @override
  String get healthAccessRequestedData => 'Żądane dane';

  @override
  String get healthAccessWorkouts => 'Treningi';

  @override
  String get healthAccessWorkoutRoutes => 'Trasy treningowe';

  @override
  String get healthAccessHeartRate => 'Tętno';

  @override
  String get healthAccessWorkoutSummary => 'Dystans, kalorie i kroki treningu';

  @override
  String get healthAccessAllowed => 'Dozwolone';

  @override
  String get healthAccessNeedsAttention => 'Potrzebuje uwagi';

  @override
  String get healthAccessManagedBySystem => 'Zarządzane w ustawieniach systemu';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit nie ujawnia, jakie dane Endurain może odczytać. Sprawdź dostęp w aplikacji Zdrowie.';

  @override
  String get healthAccessReview => 'Przejrzyj dostęp do opieki zdrowotnej';

  @override
  String get healthAccessReviewIos => 'Jak sprawdzić dostęp';

  @override
  String get healthAccessDisconnect => 'Odłącz dane zdrowotne';

  @override
  String get healthAccessDisconnectTitle => 'Odłączyć dane zdrowotne?';

  @override
  String get healthAccessDisconnectMessage =>
      'Automatyczny import i lokalna historia importów dla tego serwera zostaną zresetowane. Istniejące aktywności pozostaną w historii.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Otwórz aplikację Zdrowie, dotknij swojego zdjęcia profilowego, a następnie Aplikacje i usługi. Wybierz Endurain i zaktualizuj kategorie danych.';

  @override
  String get healthSyncAuthorize => 'Połącz się z danymi o stanie zdrowia';

  @override
  String get healthSyncInstallProvider => 'Zainstaluj Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Do synchronizacji treningów wymagana jest aplikacja Health Connect. Zainstaluj, aby kontynuować.';

  @override
  String get healthSyncUnsupported =>
      'Synchronizacja stanu nie jest dostępna na tym urządzeniu.';

  @override
  String get healthSyncSelectAll => 'Zaznacz wszystko';

  @override
  String get healthSyncClearSelection => 'Jasne';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importuj wybrane ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Zaimportowano treningi ($count).';
  }

  @override
  String get healthSyncNoRouteLabel => 'Brak trasy GPS';

  @override
  String get healthSyncEmptyState =>
      'Nie znaleziono treningów w wybranym okresie.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Niektóre treningi zostały pominięte, ponieważ nie przyznano dostępu do trasy ćwiczeń. Otwórz Health Connect → Uprawnienia i zezwól na trasy ćwiczeń dla Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Niektóre treningi zostały pominięte, ponieważ Endurain nie mógł odczytać tras GPS. W aplikacji Zdrowie otwórz swój profil, wybierz Aplikacje i usługi, wybierz Endurain i zezwól na trasy treningowe.';

  @override
  String get healthSyncReviewAccess => 'Sprawdź dostęp';

  @override
  String get healthSyncAutoSyncTitle =>
      'Automatyczna synchronizacja po wznowieniu';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importuj nowe treningi automatycznie po otwarciu aplikacji.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Te treningi nie zawierają trasy GPS, więc nie można ich zaimportować. Niektóre aplikacje (np. Garmin Connect) rejestrują aktywność w Apple Health bez udostępniania trasy. Treningi zarejestrowane za pomocą Apple Watch obejmują trasy i można je importować.';

  @override
  String get healthSyncBadgeNonImportable => 'Niemożliwy do importu';

  @override
  String get healthSyncViewAvailable => 'Dostępne';

  @override
  String get healthSyncViewImported => 'Zaimportowane';

  @override
  String get healthSyncDateRange => 'Okres treningów';

  @override
  String get healthSyncRange30Days => 'Ostatnie 30 dni';

  @override
  String get healthSyncRange3Months => 'Ostatnie 3 miesiące';

  @override
  String get healthSyncRange6Months => 'Ostatnie 6 miesięcy';

  @override
  String get healthSyncRangeYear => 'Ostatni rok';

  @override
  String get healthSyncRangeAll => 'Cała historia';

  @override
  String get healthSyncRangeCustom => 'Własny okres';

  @override
  String get healthSyncImportedEmpty =>
      'Brak zaimportowanych treningów dla tego połączenia.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Zaimportowano: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Przywróć';

  @override
  String get sensorsTitle => 'Czujniki';

  @override
  String get sensorsSettingsSubtitle =>
      'Monitory tętna i inne czujniki zewnętrzne';

  @override
  String get sensorsHeartRateSection => 'Tętno';

  @override
  String get sensorsHeartRateHelp =>
      'Sparuj monitor tętna Bluetooth, aby widzieć swoje tętno na żywo.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth jest wyłączony. Włącz go, aby połączyć czujnik.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Zezwól na dostęp do Bluetooth, aby połączyć czujnik.';

  @override
  String get sensorsBluetoothUnsupported =>
      'To urządzenie nie obsługuje Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Szukaj czujników';

  @override
  String get sensorsScanning => 'Szukanie…';

  @override
  String get sensorsStopScan => 'Zatrzymaj';

  @override
  String get sensorsNoDevices =>
      'Nie znaleziono jeszcze żadnych czujników tętna.';

  @override
  String get sensorsAvailableSection => 'Dostępne czujniki';

  @override
  String get sensorsSavedSection => 'Zapisany czujnik';

  @override
  String get sensorsConnect => 'Połącz';

  @override
  String get sensorsConnecting => 'Łączenie…';

  @override
  String get sensorsConnected => 'Połączono';

  @override
  String get sensorsDisconnect => 'Rozłącz';

  @override
  String get sensorsForget => 'Zapomnij';

  @override
  String get sensorsConnectionFailed =>
      'Nie udało się połączyć. Spróbuj ponownie.';

  @override
  String get sensorsPermissionRequired =>
      'Do znalezienia czujników wymagane jest uprawnienie Bluetooth.';

  @override
  String get sensorsUnknownDevice => 'Nieznany czujnik';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Moc';

  @override
  String get sensorsPowerHelp =>
      'Sparuj miernik mocy Bluetooth, aby widzieć swoją moc na żywo.';

  @override
  String get sensorsNoPowerDevices =>
      'Nie znaleziono jeszcze żadnych mierników mocy.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Kadencja';

  @override
  String get sensorsCadenceHelp =>
      'Sparuj czujnik kadencji Bluetooth, aby widzieć swoją kadencję na żywo.';

  @override
  String get sensorsNoCadenceDevices =>
      'Nie znaleziono jeszcze żadnych czujników kadencji.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Zdalne raportowanie awarii';

  @override
  String get diagnosticsRemoteEnable => 'Wysyłaj raporty o awariach';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Wysyłaj raporty o awariach i błędach na serwer diagnostyczny. Jest to niezależne od lokalnej diagnostyki; możesz włączyć oba, jedno lub żadne.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Zdalne raportowanie awarii nie jest dostępne w tej wersji.';

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
  String get unitsTitle => 'Jednostki';

  @override
  String get unitsSubtitle => 'Jednostki odległości, prędkości i wysokości';

  @override
  String get unitsSystemDefault => 'Zgodnie z regionem urządzenia';

  @override
  String get unitsMetric => 'Metryczne (km)';

  @override
  String get unitsImperial => 'Imperialne (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';

  @override
  String get audioAnnouncementsTitle => 'Komunikaty głosowe';

  @override
  String get audioAnnouncementsSubtitle =>
      'Głosowe aktualizacje dystansu, czasu i tempa';

  @override
  String get audioAnnouncementsMasterSwitch => 'Ogłaszaj postęp aktywności';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Odczytuje na głos dystans, czas i tempo podczas nagrywania';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Przycisz inne dźwięki podczas mówienia';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Tymczasowo zmniejsza głośność innych dźwięków podczas każdego komunikatu';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Interwał komunikatów według aktywności';

  @override
  String get audioAnnouncementsByDistance => 'Dystans';

  @override
  String get audioAnnouncementsByTime => 'Czas';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Co $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Co $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Zmniejsz interwał';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Zwiększ interwał';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String pace,
  ) {
    return 'Dystans $distance. Czas $duration. Tempo $pace.';
  }
}
