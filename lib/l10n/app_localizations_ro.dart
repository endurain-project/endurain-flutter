// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get error => 'Eroare';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Anulează';

  @override
  String get save => 'Salvează';

  @override
  String get back => 'Înapoi';

  @override
  String get requiredField => 'Acest câmp este obligatoriu';

  @override
  String get invalidUrl => 'Introduceți un URL valid';

  @override
  String get errorActivityUploadFailed => 'Nu s-a putut încărca activitatea';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Nu s-a putut încărca activitatea: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Încărcarea activităților nu este încă configurată';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Nu s-a putut șterge fișierul temporar al activității';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Nu s-a putut pregăti fișierul pentru încărcarea activității';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Această activitate locală nu a putut fi găsită';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Activitatea locală nu a putut fi ștearsă';

  @override
  String get errorActivityLocalGpxMissing =>
      'Fișierul GPX local nu este disponibil';

  @override
  String get errorActivityLocalLoadFailed =>
      'Activitățile locale nu au putut fi încărcate';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Această activitate nu a putut fi salvată';

  @override
  String get errorActivityLocalSaveFailed =>
      'Activitatea nu a putut fi salvată local';

  @override
  String get errorFetchProvidersFailed =>
      'Furnizorii de autentificare nu au putut fi încărcați';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Furnizorii de autentificare nu au putut fi încărcați: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Setările serverului nu au putut fi încărcate';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Setările serverului nu au putut fi încărcate: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Nu s-a putut converti antrenamentul în GPX';

  @override
  String get errorHealthImportFailed => 'Nu s-a putut importa antrenamentul';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Nu s-a putut importa antrenamentul: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Accesul la datele de sănătate a fost interzis';

  @override
  String get errorHealthReadFailed => 'Nu s-au putut citi datele de sănătate';

  @override
  String get errorLoginError => 'Autentificarea nu a reușit';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Autentificarea nu a reușit: $details';
  }

  @override
  String get errorLoginFailed => 'Autentificare eșuată';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Autentificare eșuată: $details';
  }

  @override
  String get errorMfaVerificationError => 'Codul MFA nu a putut fi verificat';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Codul MFA nu a putut fi verificat: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Verificarea MFA a eșuat';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Verificarea MFA a eșuat: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Nu s-a primit niciun ID de sesiune de la server';

  @override
  String get errorNotAuthenticated => 'Nu sunteți autentificat';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Verificatorul de autentificare nu a fost găsit. Reîncepeți autentificarea.';

  @override
  String get errorServerUrlNotConfigured =>
      'URL-ul serverului nu este configurat';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Acest server necesită o conexiune securizată (HTTPS)';

  @override
  String get errorSessionExpired =>
      'Sesiunea dvs. a expirat. Autentificați-vă din nou.';

  @override
  String get errorSsoTokenExchangeError =>
      'Autentificarea SSO nu a putut fi finalizată';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Autentificarea SSO nu a putut fi finalizată: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Schimbul de token-uri a eșuat';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Schimbul de token-uri a eșuat: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Cererea a expirat. Verificați conexiunea și încercați din nou.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Nu se poate șterge din stocarea securizată. Este posibil ca stocarea dispozitivului să nu fie disponibilă.';

  @override
  String get errorSecureStorageReadFailed =>
      'Nu se poate citi din stocarea securizată. Este posibil ca stocarea dispozitivului să nu fie disponibilă.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Nu se poate scrie în stocarea securizată. Este posibil ca stocarea dispozitivului să nu fie disponibilă.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Serverul a returnat un răspuns neahteptat';

  @override
  String get errorUnsupportedHttpMethod => 'Metodă HTTP neacceptată';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Metodă HTTP neacceptată: $details';
  }

  @override
  String get loginTitle => 'Autentificare';

  @override
  String get login => 'Autentificare';

  @override
  String get logout => 'Deconectare';

  @override
  String get logoutConfirmTitle => 'Deconectare';

  @override
  String get logoutConfirmMessage => 'Sigur doriți să vă deconectați?';

  @override
  String get logoutServerFailedWarning =>
      'Deconectarea de la server nu a reușit, dar v-ați deconectat local';

  @override
  String get ssoBrowserLaunchFailed =>
      'Autentificarea SSO nu a putut fi deschisă în browserul de sistem';

  @override
  String ssoSignInWith(String provider) {
    return 'Autentificare cu $provider';
  }

  @override
  String get ssoOrDivider => 'SAU';

  @override
  String get next => 'Înainte';

  @override
  String get username => 'Nume de utilizator';

  @override
  String get usernameHint => 'Introduceți numele de utilizator';

  @override
  String get password => 'Parolă';

  @override
  String get passwordHint => 'Introduceți parola';

  @override
  String get showPassword => 'Afișează parola';

  @override
  String get mfaTitle => 'Autentificare cu doi factori';

  @override
  String get mfaCode => 'Cod MFA';

  @override
  String get mfaCodeHint => 'Introduceți codul din 6 cifre';

  @override
  String get mfaCodeRequired => 'Introduceți codul MFA';

  @override
  String get verify => 'Verifică';

  @override
  String get activityDiscard => 'Renunță';

  @override
  String get activityDiscardConfirmMessage =>
      'Aceasta va șterge punctele înregistrate ale acestei activități.';

  @override
  String get activityDiscardConfirmTitle => 'Renunțați la activitate?';

  @override
  String get activityLocationPermissionDenied =>
      'Permisiunea de localizare este necesară pentru a înregistra o activitate.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Permisiunea de localizare este blocată. Deschideți setările pentru a permite accesul la locație.';

  @override
  String get activityLocationServiceDisabled =>
      'Serviciile de localizare sunt dezactivate.';

  @override
  String get activityLocationStreamFailed =>
      'Actualizările de locație s-au oprit neașteptat.';

  @override
  String get activityGpxGenerationFailed =>
      'Nu s-a putut crea fișierul GPX al activității.';

  @override
  String get activityLocalSaveFailed =>
      'Această activitate nu a putut fi salvată pe acest dispozitiv.';

  @override
  String get activityOpenSettings => 'Deschide setările';

  @override
  String get activityPause => 'Pauză';

  @override
  String get activityRecordingEmpty =>
      'Nu a fost înregistrat niciun punct GPS.';

  @override
  String get activityRecordingFailed => 'Înregistrarea a eșuat.';

  @override
  String get activityResume => 'Reia';

  @override
  String get activityRetryUpload => 'Reîncearcă încărcarea';

  @override
  String get activityDone => 'Gata';

  @override
  String get activityViewHistory => 'Vezi istoricul';

  @override
  String get activityDeleteLocal => 'Șterge copia locală';

  @override
  String get activityExportGpx => 'Partajează fișierul GPX';

  @override
  String get activityExportGpxSubject => 'GPX activitate Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Ștergeți activitatea locală?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Aceasta elimină înregistrarea activității locale și fișierul GPX de pe acest dispozitiv.';

  @override
  String get activityStart => 'Începe';

  @override
  String get activityBackgroundPermissionTitle =>
      'Permiteți urmărirea în fundal?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain necesită locația în fundal setată la Întotdeauna, pentru ca înregistrarea să continue când aplicația este în fundal, ecranul este blocat sau schimbați aplicația.';

  @override
  String get activityBackgroundPermissionContinue => 'Continuă';

  @override
  String get activityBackgroundPermissionRequired =>
      'Urmărirea în fundal pe iPhone și iPad necesită locația setată la Întotdeauna.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Urmărirea în fundal este dezactivată';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Pentru a înregistra fiabil în fundal sau cu ecranul blocat, deschideți Setările și setați Locația la Întotdeauna pentru Endurain.';

  @override
  String get activityTrackingNotificationTitle =>
      'Se înregistrează activitatea';

  @override
  String get activityTrackingNotificationText =>
      'Endurain vă urmărește locația pentru a înregistra această activitate.';

  @override
  String get activityStatDistance => 'Distanță';

  @override
  String get activityStatDuration => 'Timp';

  @override
  String get activityStatSpeed => 'Viteză';

  @override
  String get activityStatPace => 'Ritm';

  @override
  String get activityStatMaxSpeed => 'Viteză maximă';

  @override
  String get activityStatElevationGain => 'Urcare';

  @override
  String get activityStatHeartRate => 'Ritm cardiac';

  @override
  String get activityStatAvgHeartRate => 'Ritm cardiac mediu';

  @override
  String get activityStatPower => 'Putere';

  @override
  String get activityStatAvgPower => 'Putere medie';

  @override
  String get activityStatCadence => 'Cadență';

  @override
  String get activityStatAvgCadence => 'Cadență medie';

  @override
  String get activityStop => 'Oprește';

  @override
  String get activityStopAndSave => 'Oprește și salvează';

  @override
  String get activityStopConfirmMessage =>
      'Alegeți dacă doriți să păstrați această înregistrare sau să renunțați la ea.';

  @override
  String get activityStopConfirmTitle => 'Încheiați activitatea?';

  @override
  String get activityStopping => 'Se oprește';

  @override
  String get activityTypeHike => 'Drumeție';

  @override
  String get activityTypeLabel => 'Tip de activitate';

  @override
  String get activityTypeOther => 'Altele';

  @override
  String get activityTypeRide => 'Ciclism';

  @override
  String get activityTypeRun => 'Alergare';

  @override
  String get activityTypeWalk => 'Mers pe jos';

  @override
  String get activityUploadFailed => 'Încărcarea a eșuat';

  @override
  String get activityUploadCleanupFailed => 'Încărcat, dar curățarea a eșuat';

  @override
  String get activityUploadReady => 'Gata de încărcare';

  @override
  String get activityUploaded => 'Încărcat';

  @override
  String get activityUploading => 'Se încarcă';

  @override
  String get activityUploadStatusPending => 'În așteptare';

  @override
  String get activityUploadStatusUploaded => 'Încărcat';

  @override
  String get activityUploadStatusFailed => 'Eșuat';

  @override
  String get activityHistoryTitle => 'Istoricul activităților';

  @override
  String get activityHistorySettingsSubtitle =>
      'Activități finalizate salvate pe acest dispozitiv';

  @override
  String get activityRetainUploadedGpx => 'Păstrează fișierele GPX încărcate';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Salvează fișierele de traseu finalizate în stocarea privată a aplicației după încărcare.';

  @override
  String get activityAutoPauseTitle => 'Pauză automată';

  @override
  String get activityAutoPauseSubtitle =>
      'Pune automat pauză când te oprești din mișcare';

  @override
  String get activityAutoPauseToggleLabel => 'Pauză automată';

  @override
  String get activityAutoPauseToggleDescription =>
      'Înregistrarea este pusă automat pe pauză când te oprești din mișcare și reia imediat ce te miști din nou.';

  @override
  String get activityAutoPauseDelayHelperText =>
      'Alege cât timp fără mișcare se așteaptă înainte de pauză.';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    return '$seconds secunde';
  }

  @override
  String get activityAutoPausedIndicator => 'În pauză automată';

  @override
  String get activityHistoryEmpty =>
      'Nicio activitate finalizată salvată pe acest dispozitiv.';

  @override
  String get activityHistoryLoadFailed =>
      'Activitățile locale nu au putut fi încărcate.';

  @override
  String get activityHistoryRefresh => 'Reîmprospătează';

  @override
  String get activityHistoryLocalActivities => 'Activități locale';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Durată: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distanță: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Încărcare: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Încarcă mai multe';

  @override
  String get activityHistoryDetailsTitle => 'Detalii activitate';

  @override
  String get activityHistoryDetailsMissing =>
      'Această activitate locală nu mai este disponibilă.';

  @override
  String get activityHistorySummary => 'Rezumat';

  @override
  String get activityHistoryActions => 'Acțiuni';

  @override
  String get activityHistoryType => 'Tip';

  @override
  String get activityHistoryStartedAt => 'Început';

  @override
  String get activityHistoryEndedAt => 'Încheiat';

  @override
  String get activityHistoryDurationLabel => 'Durată';

  @override
  String get activityHistoryDistanceLabel => 'Distanță';

  @override
  String get activityHistoryAverageSpeed => 'Viteză medie';

  @override
  String get activityHistoryPointCount => 'Puncte GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Încărcare';

  @override
  String get activityHistoryGpxStatus => 'Fișier GPX';

  @override
  String get activityHistoryGpxAvailable => 'Salvat pe acest dispozitiv';

  @override
  String get activityHistoryGpxMissing => 'Indisponibil pe acest dispozitiv';

  @override
  String get mapTab => 'Hartă';

  @override
  String get myLocation => 'Locația mea';

  @override
  String get settingsTab => 'Setări';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® este o marcă înregistrată a lui João Vitória Silva';

  @override
  String get settingsScreen => 'Setări';

  @override
  String get deviceAccessTitle => 'Acces la dispozitiv';

  @override
  String get deviceAccessSubtitle =>
      'Gestionați locația și accesul la datele de sănătate';

  @override
  String get deviceAccessLocationSection => 'Locație';

  @override
  String get deviceAccessHealthSection => 'Date de sănătate';

  @override
  String get deviceAccessLocationTitle => 'Acces la locație';

  @override
  String get deviceAccessHealthTitle => 'Accesul la datele de sănătate';

  @override
  String get deviceAccessChecking => 'Se verifică accesul...';

  @override
  String get deviceAccessLocationServicesOff =>
      'Serviciile de localizare sunt dezactivate';

  @override
  String get deviceAccessLocationAlways => 'Permis tot timpul';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Permis în timpul utilizării aplicației';

  @override
  String get deviceAccessLocationBlocked => 'Blocat în setările sistemului';

  @override
  String get deviceAccessLocationNotAllowed => 'Nu este permis';

  @override
  String get deviceAccessHealthUnavailable =>
      'Nu este disponibil pe acest dispozitiv';

  @override
  String get deviceAccessHealthRequired => 'Health Connect este necesar';

  @override
  String get deviceAccessHealthSetUp => 'Accesul la sănătate configurat';

  @override
  String get deviceAccessHealthNeedsAttention => 'Accesul necesită atenție';

  @override
  String get deviceAccessHealthNotConnected => 'Nu este conectat';

  @override
  String get language => 'Limbă';

  @override
  String get languageSystemDefault => 'Implicit de sistem';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Autentificare';

  @override
  String get signInConnectServerSubtitle =>
      'Înregistrați offline acum și sincronizați activitățile mai târziu';

  @override
  String get serverSettingsTitle => 'Setările serverului';

  @override
  String connectedToServer(String server) {
    return 'Conectat la $server';
  }

  @override
  String get loggedIn => 'Autentificat';

  @override
  String get notConfigured => 'Neconfigurat';

  @override
  String get notLoggedIn => 'Neautentificat';

  @override
  String get serverUrl => 'URL server';

  @override
  String get serverProtocol => 'Protocol de server';

  @override
  String get serverUrlHint => 'https://exemplu.com';

  @override
  String get warnHttpServerUrlTitle => 'Conexiune nesecurizată';

  @override
  String get warnHttpServerUrlMessage =>
      'Acest URL de server folosește HTTP necriptat. Datele dvs. de autentificare și datele vor fi transmise fără criptare. Continuați doar dacă înțelegeți și acceptați riscul.';

  @override
  String get warnHttpServerUrlConfirm => 'Continuă oricum';

  @override
  String get tileServerUrl => 'URL server de dale pentru hartă';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle =>
      'Gazdă diferită a serverului de dale';

  @override
  String get tileServerHostWarningMessage =>
      'Gazda serverului de dale este diferită de gazda serverului dvs. Endurain. Dalele vor fi încărcate de la un server terț. Doriți să continuați?';

  @override
  String get savedSuccessfully => 'Setările au fost salvate cu succes';

  @override
  String get diagnostics => 'Diagnosticare';

  @override
  String get diagnosticsSubtitle => 'Context local de blocare';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Linkul nu a putut fi deschis';

  @override
  String get diagnosticsTitle => 'Diagnosticare';

  @override
  String get diagnosticsCollection => 'Colectare';

  @override
  String get diagnosticsEnable => 'Colectează diagnostice';

  @override
  String get diagnosticsEnableSubtitle =>
      'Stochează evenimentele și erorile recente ale aplicației pe acest dispozitiv';

  @override
  String get diagnosticsDisabled =>
      'Colectarea diagnosticelor este dezactivată. Activează-o pentru a începe să înregistrezi evenimentele și erorile aplicației pe acest dispozitiv.';

  @override
  String get diagnosticsEmpty =>
      'Nu au fost capturate încă date de diagnosticare.';

  @override
  String get diagnosticsCopy => 'Copiază';

  @override
  String get diagnosticsCopied => 'Diagnosticare copiată';

  @override
  String get diagnosticsClear => 'Șterge';

  @override
  String get diagnosticsCleared => 'Diagnosticare ștearsă';

  @override
  String get diagnosticsSummary => 'Rezumat';

  @override
  String get diagnosticsLastUpdated => 'Ultima actualizare';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Evenimente: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Erori: $count';
  }

  @override
  String get diagnosticsEvents => 'Evenimente';

  @override
  String get diagnosticsNoEvents => 'Niciun eveniment capturat';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Eveniment: $event';
  }

  @override
  String get diagnosticsErrors => 'Erori';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Eroare: $type';
  }

  @override
  String get diagnosticsActions => 'Acțiuni';

  @override
  String get diagnosticsRawReport => 'Raport brut';

  @override
  String get healthSyncSettingsTitle => 'Sincronizarea sănătății';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importați antrenamente de pe platforma dvs. de sănătate';

  @override
  String get healthSyncScreenTitle => 'Sincronizarea sănătății';

  @override
  String get healthAccessScreenTitle => 'Acces la sănătate';

  @override
  String get healthAccessRequestedData => 'Date solicitate';

  @override
  String get healthAccessWorkouts => 'Antrenamente';

  @override
  String get healthAccessWorkoutRoutes => 'Trasee de antrenament';

  @override
  String get healthAccessHeartRate => 'Ritmul cardiac';

  @override
  String get healthAccessWorkoutSummary =>
      'Distanță, calorii și pași din antrenament';

  @override
  String get healthAccessAllowed => 'Permis';

  @override
  String get healthAccessNeedsAttention => 'Necesită atenție';

  @override
  String get healthAccessManagedBySystem => 'Gestionat în setările sistemului';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit nu dezvăluie ce date poate citi Endurain. Examinați accesul în aplicația Sănătate.';

  @override
  String get healthAccessReview => 'Examinați accesul la sănătate';

  @override
  String get healthAccessReviewIos => 'Cum să revizuiți accesul';

  @override
  String get healthAccessDisconnect => 'Deconectează datele de sănătate';

  @override
  String get healthAccessDisconnectTitle => 'Deconectați datele de sănătate?';

  @override
  String get healthAccessDisconnectMessage =>
      'Importul automat și istoricul local al importurilor pentru acest server vor fi resetate. Activitățile existente rămân în istoric.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Deschideți aplicația Sănătate, atingeți fotografia de profil, apoi Aplicații și servicii. Selectați Endurain și actualizați categoriile de date.';

  @override
  String get healthSyncAuthorize => 'Conectați-vă la datele de sănătate';

  @override
  String get healthSyncInstallProvider => 'Instalați Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Health Connect este necesar pentru a sincroniza antrenamentele. Instalați-l pentru a continua.';

  @override
  String get healthSyncUnsupported =>
      'Sincronizarea sănătății nu este disponibilă pe acest dispozitiv.';

  @override
  String get healthSyncSelectAll => 'Selectați toate';

  @override
  String get healthSyncClearSelection => 'Clar';

  @override
  String healthSyncImportSelected(int count) {
    return 'Import selectat ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Au importat $count antrenament(e).';
  }

  @override
  String get healthSyncNoRouteLabel => 'Fără traseu GPS';

  @override
  String get healthSyncEmptyState =>
      'Nu s-au găsit antrenamente în perioada selectată.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Unele antrenamente au fost omise, deoarece accesul la traseul exercițiului nu a fost acordat. Deschideți Health Connect → Permisiuni și permiteți rute de exerciții pentru Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Unele antrenamente au fost omise, deoarece Endurain nu a putut citi traseele GPS. În aplicația Sănătate, deschideți profilul, apoi Aplicații și servicii, selectați Endurain și permiteți Rute de antrenament.';

  @override
  String get healthSyncReviewAccess => 'Examinați accesul';

  @override
  String get healthSyncAutoSyncTitle => 'Sincronizare automată la reluare';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importați automat antrenamente noi când se deschide aplicația.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Aceste antrenamente nu includ o rută GPS, așa că nu pot fi importate. Unele aplicații (cum ar fi Garmin Connect) înregistrează activități în Apple Health fără a partaja traseul. Antrenamentele înregistrate cu Apple Watch includ rute și pot fi importate.';

  @override
  String get healthSyncBadgeNonImportable => 'Neimportabil';

  @override
  String get healthSyncViewAvailable => 'Disponibile';

  @override
  String get healthSyncViewImported => 'Importate';

  @override
  String get healthSyncDateRange => 'Perioada antrenamentelor';

  @override
  String get healthSyncRange30Days => 'Ultimele 30 de zile';

  @override
  String get healthSyncRange3Months => 'Ultimele 3 luni';

  @override
  String get healthSyncRange6Months => 'Ultimele 6 luni';

  @override
  String get healthSyncRangeYear => 'Ultimul an';

  @override
  String get healthSyncRangeAll => 'Tot istoricul';

  @override
  String get healthSyncRangeCustom => 'Perioadă personalizată';

  @override
  String get healthSyncImportedEmpty =>
      'Nu există antrenamente importate pentru această conexiune.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importat: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Restaurează';

  @override
  String get sensorsTitle => 'Senzori';

  @override
  String get sensorsSettingsSubtitle =>
      'Monitoare de ritm cardiac și alți senzori externi';

  @override
  String get sensorsHeartRateSection => 'Ritm cardiac';

  @override
  String get sensorsHeartRateHelp =>
      'Asociază un monitor de ritm cardiac Bluetooth pentru a-ți vedea ritmul cardiac în timp real.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth este dezactivat. Activează-l pentru a conecta un senzor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Permite accesul la Bluetooth pentru a conecta un senzor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Acest dispozitiv nu acceptă Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Caută senzori';

  @override
  String get sensorsScanning => 'Se caută…';

  @override
  String get sensorsStopScan => 'Oprește';

  @override
  String get sensorsNoDevices => 'Nu s-au găsit încă senzori de ritm cardiac.';

  @override
  String get sensorsAvailableSection => 'Senzori disponibili';

  @override
  String get sensorsSavedSection => 'Senzor salvat';

  @override
  String get sensorsConnect => 'Conectează';

  @override
  String get sensorsConnecting => 'Se conectează…';

  @override
  String get sensorsConnected => 'Conectat';

  @override
  String get sensorsDisconnect => 'Deconectează';

  @override
  String get sensorsForget => 'Uită';

  @override
  String get sensorsConnectionFailed => 'Conectarea a eșuat. Încearcă din nou.';

  @override
  String get sensorsPermissionRequired =>
      'Este necesară permisiunea Bluetooth pentru a găsi senzori.';

  @override
  String get sensorsUnknownDevice => 'Senzor necunoscut';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Putere';

  @override
  String get sensorsPowerHelp =>
      'Asociază un senzor de putere Bluetooth pentru a-ți vedea puterea în timp real.';

  @override
  String get sensorsNoPowerDevices => 'Nu s-au găsit încă senzori de putere.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadență';

  @override
  String get sensorsCadenceHelp =>
      'Asociază un senzor de cadență Bluetooth pentru a-ți vedea cadența în timp real.';

  @override
  String get sensorsNoCadenceDevices =>
      'Nu s-au găsit încă senzori de cadență.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Raportare de la distanță a blocărilor';

  @override
  String get diagnosticsRemoteEnable => 'Trimite rapoarte de blocare';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Trimite rapoarte de blocare și de eroare către un server de diagnosticare. Este independent de diagnosticarea locală; poți activa ambele, una sau niciuna.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Raportarea de la distanță a blocărilor nu este disponibilă în această versiune.';

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
  String get unitsTitle => 'Unități';

  @override
  String get unitsSubtitle => 'Unități de distanță, viteză și altitudine';

  @override
  String get unitsSystemDefault => 'Urmează regiunea dispozitivului';

  @override
  String get unitsMetric => 'Metric (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';

  @override
  String get audioAnnouncementsTitle => 'Anunțuri vocale';

  @override
  String get audioAnnouncementsSubtitle =>
      'Actualizări vocale despre distanță, timp, ritm sau viteză';

  @override
  String get audioAnnouncementsMasterSwitch => 'Anunță progresul activității';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Rostește distanța, timpul, ritmul sau viteza în timpul unei înregistrări';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Reduce alte sunete în timpul vorbirii';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Reduce temporar volumul altor sunete în timpul fiecărui anunț';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Interval de anunț în funcție de activitate';

  @override
  String get audioAnnouncementsByDistance => 'Distanță';

  @override
  String get audioAnnouncementsByTime => 'Timp';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'La fiecare $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'La fiecare $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Micșorează intervalul';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Mărește intervalul';

  @override
  String get audioAnnouncementsPreview => 'Ascultă un exemplu';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'Previzualizarea anunțului nu este disponibilă pe acest dispozitiv';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Modificările se aplică la următoarea înregistrare.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Distanță $distance. Timp $duration. Tură: $lapMetric. Total: $overallMetric.';
  }
}
