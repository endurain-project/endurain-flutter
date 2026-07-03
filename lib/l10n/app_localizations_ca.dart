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
  String get errorPkceVerifierMissing =>
      'No s\'ha trobat el verificador d\'inici de sessió';

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
  String get ssoMissingSessionId =>
      'La resposta SSO no incloïa cap identificador de sessió';

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
  String get settingsScreen => 'Configuració';

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
  String get loggedIn => 'Sessió iniciada';

  @override
  String get notConfigured => 'No configurat';

  @override
  String get notLoggedIn => 'Sessió no iniciada';

  @override
  String get serverUrl => 'URL del servidor';

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
  String get diagnosticsTitle => 'Diagnòstics';

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
}
