// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get error => 'Error';

  @override
  String get ok => 'D\'acord';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get save => 'Desa';

  @override
  String get back => 'Enrere';

  @override
  String get requiredField => 'Aquest camp és obligatori';

  @override
  String get invalidUrl => 'Introduïu un URL vàlid';

  @override
  String get errorActivityUploadFailed => 'No s\'ha pogut penjar l\'activitat';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'No s\'ha pogut penjar l\'activitat: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'La pujada d\'activitats encara no està configurada';

  @override
  String get errorActivityGpxCleanupFailed =>
      'No s\'ha pogut suprimir el fitxer temporal de l\'activitat';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'No s\'ha pogut preparar el fitxer per penjar l\'activitat';

  @override
  String get errorActivityLocalActivityNotFound =>
      'No s\'ha pogut trobar aquesta activitat local';

  @override
  String get errorActivityLocalDeleteFailed =>
      'No s\'ha pogut suprimir l\'activitat local';

  @override
  String get errorActivityLocalGpxMissing =>
      'El fitxer GPX local no està disponible';

  @override
  String get errorActivityLocalLoadFailed =>
      'No s\'han pogut carregar les activitats locals';

  @override
  String get errorActivityLocalRecordInvalid =>
      'No s\'ha pogut desar aquesta activitat';

  @override
  String get errorActivityLocalSaveFailed =>
      'No s\'ha pogut desar l\'activitat localment';

  @override
  String get errorFetchProvidersFailed =>
      'No s\'han pogut carregar els proveïdors d\'inici de sessió';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'No s\'han pogut carregar els proveïdors d\'inici de sessió: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'No s\'ha pogut carregar la configuració del servidor';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'No s\'ha pogut carregar la configuració del servidor: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'No s\'ha pogut convertir l\'entrenament a GPX';

  @override
  String get errorHealthImportFailed =>
      'No s\'ha pogut importar l\'entrenament';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'No s\'ha pogut importar l\'entrenament: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'S\'ha denegat l\'accés a les dades de salut';

  @override
  String get errorHealthReadFailed =>
      'No s\'han pogut llegir les dades de salut';

  @override
  String get errorLoginError => 'No s\'ha pogut iniciar la sessió';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'No s\'ha pogut iniciar la sessió: $details';
  }

  @override
  String get errorLoginFailed => 'Ha fallat l\'inici de sessió';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Ha fallat l\'inici de sessió: $details';
  }

  @override
  String get errorMfaVerificationError =>
      'No s\'ha pogut verificar el codi MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'No s\'ha pogut verificar el codi MFA: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Ha fallat la verificació MFA';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Ha fallat la verificació MFA: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'El servidor no ha retornat cap identificador de sessió';

  @override
  String get errorNotAuthenticated => 'No heu iniciat la sessió';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'No s\'ha trobat el verificador d\'inici de sessió. Torneu a començar l\'inici de sessió.';

  @override
  String get errorServerUrlNotConfigured =>
      'L\'URL del servidor no està configurat';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Aquest servidor requereix una connexió segura (HTTPS)';

  @override
  String get errorSessionExpired =>
      'La sessió ha caducat. Torneu a iniciar la sessió.';

  @override
  String get errorSsoTokenExchangeError =>
      'No s\'ha pogut completar l\'inici de sessió SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'No s\'ha pogut completar l\'inici de sessió SSO: $details';
  }

  @override
  String get errorTokenExchangeFailed =>
      'Ha fallat l\'intercanvi de testimonis';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Ha fallat l\'intercanvi de testimonis: $details';
  }

  @override
  String get errorRequestTimeout =>
      'La sol·licitud ha esgotat el temps d\'espera. Comproveu la connexió i torneu-ho a provar.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'No es pot suprimir de l\'emmagatzematge segur. És possible que l\'emmagatzematge del dispositiu no estigui disponible.';

  @override
  String get errorSecureStorageReadFailed =>
      'No es pot llegir de l\'emmagatzematge segur. És possible que l\'emmagatzematge del dispositiu no estigui disponible.';

  @override
  String get errorSecureStorageWriteFailed =>
      'No es pot escriure a l\'emmagatzematge segur. És possible que l\'emmagatzematge del dispositiu no estigui disponible.';

  @override
  String get errorUnexpectedResponseFormat =>
      'El servidor ha retornat una resposta inesperada';

  @override
  String get errorUnsupportedHttpMethod => 'Mètode HTTP no admès';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Mètode HTTP no admès: $details';
  }

  @override
  String get loginTitle => 'Inici de sessió';

  @override
  String get login => 'Inicia la sessió';

  @override
  String get logout => 'Tanca la sessió';

  @override
  String get logoutConfirmTitle => 'Tanca la sessió';

  @override
  String get logoutConfirmMessage => 'Segur que voleu tancar la sessió?';

  @override
  String get logoutServerFailedWarning =>
      'No s\'ha pogut tancar la sessió al servidor, però s\'ha tancat localment';

  @override
  String get ssoBrowserLaunchFailed =>
      'No s\'ha pogut obrir l\'inici de sessió SSO al navegador del sistema';

  @override
  String ssoSignInWith(String provider) {
    return 'Inicia la sessió amb $provider';
  }

  @override
  String get ssoOrDivider => 'O';

  @override
  String get next => 'Següent';

  @override
  String get username => 'Nom d\'usuari';

  @override
  String get usernameHint => 'Introduïu el vostre nom d\'usuari';

  @override
  String get password => 'Contrasenya';

  @override
  String get passwordHint => 'Introduïu la vostra contrasenya';

  @override
  String get showPassword => 'Mostra la contrasenya';

  @override
  String get mfaTitle => 'Autenticació de dos factors';

  @override
  String get mfaCode => 'Codi MFA';

  @override
  String get mfaCodeHint => 'Introduïu el codi de 6 dígits';

  @override
  String get mfaCodeRequired => 'Introduïu el codi MFA';

  @override
  String get verify => 'Verifica';

  @override
  String get activityDiscard => 'Descarta';

  @override
  String get activityDiscardConfirmMessage =>
      'Això suprimirà els punts enregistrats d\'aquesta activitat.';

  @override
  String get activityDiscardConfirmTitle => 'Voleu descartar l\'activitat?';

  @override
  String get activityLocationPermissionDenied =>
      'Cal permís d\'ubicació per enregistrar una activitat.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'El permís d\'ubicació està bloquejat. Obriu la configuració per permetre l\'accés a la ubicació.';

  @override
  String get activityLocationServiceDisabled =>
      'Els serveis d\'ubicació estan desactivats.';

  @override
  String get activityLocationStreamFailed =>
      'Les actualitzacions d\'ubicació s\'han aturat inesperadament.';

  @override
  String get activityGpxGenerationFailed =>
      'No s\'ha pogut crear el fitxer GPX de l\'activitat.';

  @override
  String get activityLocalSaveFailed =>
      'No s\'ha pogut desar aquesta activitat en aquest dispositiu.';

  @override
  String get activityOpenSettings => 'Obre la configuració';

  @override
  String get activityPause => 'Pausa';

  @override
  String get activityRecordingEmpty => 'No s\'ha enregistrat cap punt GPS.';

  @override
  String get activityRecordingFailed => 'L\'enregistrament ha fallat.';

  @override
  String get activityResume => 'Reprèn';

  @override
  String get activityRetryUpload => 'Torna a provar la pujada';

  @override
  String get activityDone => 'Fet';

  @override
  String get activityViewHistory => 'Mostra l\'historial';

  @override
  String get activityDeleteLocal => 'Suprimeix la còpia local';

  @override
  String get activityExportGpx => 'Comparteix el fitxer GPX';

  @override
  String get activityExportGpxSubject => 'GPX d\'activitat d\'Endurain';

  @override
  String get activityDeleteLocalConfirmTitle =>
      'Voleu suprimir l\'activitat local?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Això elimina el registre de l\'activitat local i el fitxer GPX d\'aquest dispositiu.';

  @override
  String get activityStart => 'Inicia';

  @override
  String get activityBackgroundPermissionTitle =>
      'Voleu permetre el seguiment en segon pla?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain necessita la ubicació en segon pla configurada com a Sempre perquè l\'enregistrament continuï quan l\'aplicació estigui en segon pla, la pantalla estigui bloquejada o canvieu d\'aplicació.';

  @override
  String get activityBackgroundPermissionContinue => 'Continua';

  @override
  String get activityBackgroundPermissionRequired =>
      'El seguiment en segon pla a l\'iPhone i l\'iPad requereix la ubicació configurada com a Sempre.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'El seguiment en segon pla està desactivat';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Per enregistrar de manera fiable en segon pla o amb la pantalla bloquejada, obriu la Configuració i establiu la Ubicació com a Sempre per a Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Enregistrant activitat';

  @override
  String get activityTrackingNotificationText =>
      'Endurain està fent el seguiment de la vostra ubicació per enregistrar aquesta activitat.';

  @override
  String get activityStatDistance => 'Distància';

  @override
  String get activityStatDuration => 'Temps';

  @override
  String get activityStatSpeed => 'Velocitat';

  @override
  String get activityStatPace => 'Ritme';

  @override
  String get activityStatMaxSpeed => 'Velocitat màxima';

  @override
  String get activityStatElevationGain => 'Desnivell positiu';

  @override
  String get activityStatHeartRate => 'Freqüència cardíaca';

  @override
  String get activityStatAvgHeartRate => 'Freqüència cardíaca mitjana';

  @override
  String get activityStatPower => 'Potència';

  @override
  String get activityStatAvgPower => 'Potència mitjana';

  @override
  String get activityStatCadence => 'Cadència';

  @override
  String get activityStatAvgCadence => 'Cadència mitjana';

  @override
  String get activityStop => 'Atura';

  @override
  String get activityStopAndSave => 'Atura i desa';

  @override
  String get activityStopConfirmMessage =>
      'Trieu si voleu conservar aquest enregistrament o descartar-lo.';

  @override
  String get activityStopConfirmTitle => 'Voleu finalitzar l\'activitat?';

  @override
  String get activityStopping => 'Aturant';

  @override
  String get activityTypeHike => 'Excursió';

  @override
  String get activityTypeLabel => 'Tipus d\'activitat';

  @override
  String get activityTypeOther => 'Altres';

  @override
  String get activityTypeRide => 'Ciclisme';

  @override
  String get activityTypeRun => 'Cursa';

  @override
  String get activityTypeWalk => 'Caminada';

  @override
  String get activityUploadFailed => 'Ha fallat la pujada';

  @override
  String get activityUploadCleanupFailed => 'Penjada, però ha fallat la neteja';

  @override
  String get activityUploadReady => 'A punt per penjar';

  @override
  String get activityUploaded => 'Penjada';

  @override
  String get activityUploading => 'Penjant';

  @override
  String get activityUploadStatusPending => 'Pendent';

  @override
  String get activityUploadStatusUploaded => 'Penjada';

  @override
  String get activityUploadStatusFailed => 'Ha fallat';

  @override
  String get activityHistoryTitle => 'Historial d\'activitats';

  @override
  String get activityHistorySettingsSubtitle =>
      'Activitats completades desades en aquest dispositiu';

  @override
  String get activityRetainUploadedGpx => 'Conserva els fitxers GPX penjats';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Desa els fitxers de ruta completats a l\'emmagatzematge privat de l\'aplicació després de penjar-los.';

  @override
  String get activityHistoryEmpty =>
      'No hi ha activitats completades desades en aquest dispositiu.';

  @override
  String get activityHistoryLoadFailed =>
      'No s\'han pogut carregar les activitats locals.';

  @override
  String get activityHistoryRefresh => 'Actualitza';

  @override
  String get activityHistoryLocalActivities => 'Activitats locals';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Durada: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distància: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Pujada: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Carrega\'n més';

  @override
  String get activityHistoryDetailsTitle => 'Detalls de l\'activitat';

  @override
  String get activityHistoryDetailsMissing =>
      'Aquesta activitat local ja no està disponible.';

  @override
  String get activityHistorySummary => 'Resum';

  @override
  String get activityHistoryActions => 'Accions';

  @override
  String get activityHistoryType => 'Tipus';

  @override
  String get activityHistoryStartedAt => 'Inici';

  @override
  String get activityHistoryEndedAt => 'Fi';

  @override
  String get activityHistoryDurationLabel => 'Durada';

  @override
  String get activityHistoryDistanceLabel => 'Distància';

  @override
  String get activityHistoryAverageSpeed => 'Velocitat mitjana';

  @override
  String get activityHistoryPointCount => 'Punts GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Pujada';

  @override
  String get activityHistoryGpxStatus => 'Fitxer GPX';

  @override
  String get activityHistoryGpxAvailable => 'Desat en aquest dispositiu';

  @override
  String get activityHistoryGpxMissing => 'No disponible en aquest dispositiu';

  @override
  String get mapTab => 'Mapa';

  @override
  String get myLocation => 'La meva ubicació';

  @override
  String get settingsTab => 'Configuració';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® és una marca registrada de João Vitória Silva';

  @override
  String get settingsScreen => 'Configuració';

  @override
  String get deviceAccessTitle => 'Accés al dispositiu';

  @override
  String get deviceAccessSubtitle =>
      'Gestioneu la ubicació i l\'accés a les dades de salut';

  @override
  String get deviceAccessLocationSection => 'Ubicació';

  @override
  String get deviceAccessHealthSection => 'Dades de salut';

  @override
  String get deviceAccessLocationTitle => 'Accés a la ubicació';

  @override
  String get deviceAccessHealthTitle => 'Accés a les dades de salut';

  @override
  String get deviceAccessChecking => 'S\'està comprovant l\'accés...';

  @override
  String get deviceAccessLocationServicesOff =>
      'Els serveis d\'ubicació estan desactivats';

  @override
  String get deviceAccessLocationAlways => 'Permès tot el temps';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Permès mentre s\'utilitza l\'aplicació';

  @override
  String get deviceAccessLocationBlocked =>
      'Bloquejat a la configuració del sistema';

  @override
  String get deviceAccessLocationNotAllowed => 'No es permet';

  @override
  String get deviceAccessHealthUnavailable =>
      'No disponible en aquest dispositiu';

  @override
  String get deviceAccessHealthRequired => 'Es requereix Health Connect';

  @override
  String get deviceAccessHealthSetUp => 'Configuració d\'accés a la salut';

  @override
  String get deviceAccessHealthNeedsAttention => 'L\'accés requereix atenció';

  @override
  String get deviceAccessHealthNotConnected => 'No connectat';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminat del sistema';

  @override
  String get serverSettings => 'Servidor';

  @override
  String get signInConnectServer => 'Inicia la sessió';

  @override
  String get signInConnectServerSubtitle =>
      'Enregistreu sense connexió ara i sincronitzeu les activitats més tard';

  @override
  String get serverSettingsTitle => 'Configuració del servidor';

  @override
  String connectedToServer(String server) {
    return 'Connectat a $server';
  }

  @override
  String get loggedIn => 'Sessió iniciada';

  @override
  String get notConfigured => 'No configurat';

  @override
  String get notLoggedIn => 'Sessió no iniciada';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get serverProtocol => 'Protocol del servidor';

  @override
  String get serverUrlHint => 'https://exemple.com';

  @override
  String get warnHttpServerUrlTitle => 'Connexió insegura';

  @override
  String get warnHttpServerUrlMessage =>
      'Aquest URL del servidor utilitza HTTP sense xifrar. Les vostres credencials i dades es transmetran sense xifratge. Continueu només si enteneu i accepteu el risc.';

  @override
  String get warnHttpServerUrlConfirm => 'Continua igualment';

  @override
  String get tileServerUrl => 'URL del servidor de tessel·les del mapa';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Servidor de tessel·les diferent';

  @override
  String get tileServerHostWarningMessage =>
      'L\'amfitrió del servidor de tessel·les és diferent del del vostre servidor Endurain. Les tessel·les es carregaran des d\'un servidor de tercers. Voleu continuar?';

  @override
  String get savedSuccessfully => 'La configuració s\'ha desat correctament';

  @override
  String get diagnostics => 'Diagnòstics';

  @override
  String get diagnosticsSubtitle => 'Context local de fallades';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'No s\'ha pogut obrir l\'enllaç';

  @override
  String get diagnosticsTitle => 'Diagnòstics';

  @override
  String get diagnosticsCollection => 'Recopilació';

  @override
  String get diagnosticsEnable => 'Recopila diagnòstics';

  @override
  String get diagnosticsEnableSubtitle =>
      'Desa els esdeveniments i errors recents de l\'aplicació en aquest dispositiu';

  @override
  String get diagnosticsDisabled =>
      'La recopilació de diagnòstics està desactivada. Activa-la per començar a capturar esdeveniments i errors de l\'aplicació en aquest dispositiu.';

  @override
  String get diagnosticsEmpty => 'Encara no s\'ha capturat cap diagnòstic.';

  @override
  String get diagnosticsCopy => 'Copia';

  @override
  String get diagnosticsCopied => 'Diagnòstics copiats';

  @override
  String get diagnosticsClear => 'Esborra';

  @override
  String get diagnosticsCleared => 'Diagnòstics esborrats';

  @override
  String get diagnosticsSummary => 'Resum';

  @override
  String get diagnosticsLastUpdated => 'Darrera actualització';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Esdeveniments: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Errors: $count';
  }

  @override
  String get diagnosticsEvents => 'Esdeveniments';

  @override
  String get diagnosticsNoEvents => 'No s\'ha capturat cap esdeveniment';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Esdeveniment: $event';
  }

  @override
  String get diagnosticsErrors => 'Errors';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Error: $type';
  }

  @override
  String get diagnosticsActions => 'Accions';

  @override
  String get diagnosticsRawReport => 'Informe en brut';

  @override
  String get healthSyncSettingsTitle => 'Sincronització de la salut';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importa entrenaments des de la teva plataforma de salut';

  @override
  String get healthSyncScreenTitle => 'Sincronització de la salut';

  @override
  String get healthAccessScreenTitle => 'Accés a la salut';

  @override
  String get healthAccessRequestedData => 'Dades sol·licitades';

  @override
  String get healthAccessWorkouts => 'Entrenaments';

  @override
  String get healthAccessWorkoutRoutes => 'Rutes d\'entrenament';

  @override
  String get healthAccessHeartRate => 'Freqüència cardíaca';

  @override
  String get healthAccessWorkoutSummary =>
      'Distància, calories i passos dels entrenaments';

  @override
  String get healthAccessAllowed => 'Permès';

  @override
  String get healthAccessNeedsAttention => 'Necessita atenció';

  @override
  String get healthAccessManagedBySystem =>
      'Gestionat a la configuració del sistema';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit no revela quines dades pot llegir Endurain. Revisa l\'accés a l\'aplicació Salut.';

  @override
  String get healthAccessReview => 'Revisar l\'accés a la salut';

  @override
  String get healthAccessReviewIos => 'Com revisar l\'accés';

  @override
  String get healthAccessDisconnect => 'Desconnecta les dades de salut';

  @override
  String get healthAccessDisconnectTitle =>
      'Voleu desconnectar les dades de salut?';

  @override
  String get healthAccessDisconnectMessage =>
      'Es restabliran la importació automàtica i l\'historial local d\'importacions d\'aquest servidor. Les activitats existents es mantindran a l\'historial.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Obriu l\'aplicació Salut, toqueu la vostra foto de perfil i, a continuació, Aplicacions i serveis. Seleccioneu Endurain i actualitzeu les categories de dades.';

  @override
  String get healthSyncAuthorize => 'Connecteu-vos a dades de salut';

  @override
  String get healthSyncInstallProvider => 'Instal·leu Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Es requereix Health Connect per sincronitzar els entrenaments. Instal·leu-lo per continuar.';

  @override
  String get healthSyncUnsupported =>
      'La sincronització de salut no està disponible en aquest dispositiu.';

  @override
  String get healthSyncSelectAll => 'Seleccioneu-ho tot';

  @override
  String get healthSyncClearSelection => 'Clar';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importació seleccionada ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'S\'han importat $count entrenaments.';
  }

  @override
  String get healthSyncNoRouteLabel => 'No hi ha ruta GPS';

  @override
  String get healthSyncEmptyState =>
      'No s\'ha trobat cap entrenament en el període seleccionat.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Alguns entrenaments es van saltar perquè no es va concedir l\'accés a la ruta d\'exercici. Obriu Health Connect → Permisos i permeteu rutes d\'exercici per a Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Alguns entrenaments es van saltar perquè Endurain no podia llegir les seves rutes GPS. A l\'aplicació Salut, obriu el vostre perfil, després Aplicacions i serveis, seleccioneu Endurain i permeteu les rutes d\'entrenament.';

  @override
  String get healthSyncReviewAccess => 'Revisió d\'accés';

  @override
  String get healthSyncAutoSyncTitle =>
      'Sincronització automàtica al currículum';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importa nous entrenaments automàticament quan s\'obre l\'aplicació.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Aquests entrenaments no inclouen una ruta GPS, de manera que no es poden importar. Algunes aplicacions (com Garmin Connect) registren activitats a Apple Health sense compartir la ruta. Els entrenaments gravats amb Apple Watch inclouen rutes i es poden importar.';

  @override
  String get healthSyncBadgeNonImportable => 'No importables';

  @override
  String get healthSyncViewAvailable => 'Disponibles';

  @override
  String get healthSyncViewImported => 'Importats';

  @override
  String get healthSyncDateRange => 'Interval dels entrenaments';

  @override
  String get healthSyncRange30Days => 'Últims 30 dies';

  @override
  String get healthSyncRange3Months => 'Últims 3 mesos';

  @override
  String get healthSyncRange6Months => 'Últims 6 mesos';

  @override
  String get healthSyncRangeYear => 'Últim any';

  @override
  String get healthSyncRangeAll => 'Tot l\'historial';

  @override
  String get healthSyncRangeCustom => 'Interval personalitzat';

  @override
  String get healthSyncImportedEmpty =>
      'No hi ha entrenaments importats per a aquesta connexió.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importat: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Restaura';

  @override
  String get sensorsTitle => 'Sensors';

  @override
  String get sensorsSettingsSubtitle =>
      'Monitors de freqüència cardíaca i altres sensors externs';

  @override
  String get sensorsHeartRateSection => 'Freqüència cardíaca';

  @override
  String get sensorsHeartRateHelp =>
      'Vincula un monitor de freqüència cardíaca Bluetooth per veure la teva freqüència cardíaca en directe.';

  @override
  String get sensorsBluetoothOff =>
      'El Bluetooth està desactivat. Activa\'l per connectar un sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Permet l\'accés al Bluetooth per connectar un sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Aquest dispositiu no admet Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Cerca sensors';

  @override
  String get sensorsScanning => 'S\'està cercant…';

  @override
  String get sensorsStopScan => 'Atura';

  @override
  String get sensorsNoDevices =>
      'Encara no s\'ha trobat cap sensor de freqüència cardíaca.';

  @override
  String get sensorsAvailableSection => 'Sensors disponibles';

  @override
  String get sensorsSavedSection => 'Sensor desat';

  @override
  String get sensorsConnect => 'Connecta';

  @override
  String get sensorsConnecting => 'S\'està connectant…';

  @override
  String get sensorsConnected => 'Connectat';

  @override
  String get sensorsDisconnect => 'Desconnecta';

  @override
  String get sensorsForget => 'Oblida';

  @override
  String get sensorsConnectionFailed =>
      'No s\'ha pogut connectar. Torna-ho a provar.';

  @override
  String get sensorsPermissionRequired =>
      'Cal el permís de Bluetooth per trobar sensors.';

  @override
  String get sensorsUnknownDevice => 'Sensor desconegut';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Potència';

  @override
  String get sensorsPowerHelp =>
      'Vincula un mesurador de potència Bluetooth per veure la teva potència en directe.';

  @override
  String get sensorsNoPowerDevices =>
      'Encara no s\'ha trobat cap mesurador de potència.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadència';

  @override
  String get sensorsCadenceHelp =>
      'Vincula un sensor de cadència Bluetooth per veure la teva cadència en directe.';

  @override
  String get sensorsNoCadenceDevices =>
      'Encara no s\'ha trobat cap sensor de cadència.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Informes de fallada remots';

  @override
  String get diagnosticsRemoteEnable => 'Envia informes de fallada';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Envia informes de fallada i d\'error a un servidor de diagnòstic. Això és independent dels diagnòstics locals: pots activar-ne tots dos, un o cap.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Els informes de fallada remots no estan disponibles en aquesta versió.';

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
  String get unitsTitle => 'Unitats';

  @override
  String get unitsSubtitle => 'Unitats de distància, velocitat i altitud';

  @override
  String get unitsSystemDefault => 'Segueix la regió del dispositiu';

  @override
  String get unitsMetric => 'Mètric (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';

  @override
  String get audioAnnouncementsTitle => 'Anuncis de veu';

  @override
  String get audioAnnouncementsSubtitle =>
      'Actualitzacions de veu sobre distància, temps, ritme o velocitat';

  @override
  String get audioAnnouncementsMasterSwitch =>
      'Anuncia el progrés de l\'activitat';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Diu en veu alta la distància, el temps, el ritme o la velocitat durant un enregistrament';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Redueix altres àudios mentre parla';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Redueix temporalment el volum d\'altres àudios durant cada anunci';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Interval d\'anunci per activitat';

  @override
  String get audioAnnouncementsByDistance => 'Distància';

  @override
  String get audioAnnouncementsByTime => 'Temps';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Cada $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Cada $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Redueix l\'interval';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Augmenta l\'interval';

  @override
  String get audioAnnouncementsPreview => 'Escoltar exemple';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'L\'escolta prèvia dels anuncis no està disponible en aquest dispositiu';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Els canvis s\'apliquen al vostre proper enregistrament.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Distància $distance. Temps $duration. Volta: $lapMetric. Global: $overallMetric.';
  }
}
