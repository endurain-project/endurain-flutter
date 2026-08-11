// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Galician (`gl`).
class AppLocalizationsGl extends AppLocalizations {
  AppLocalizationsGl([String locale = 'gl']) : super(locale);

  @override
  String get error => 'Erro';

  @override
  String get ok => 'Aceptar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Gardar';

  @override
  String get back => 'Atrás';

  @override
  String get requiredField => 'Este campo é obrigatorio';

  @override
  String get invalidUrl => 'Introduce un URL válido';

  @override
  String get errorActivityUploadFailed => 'Non se puido subir a actividade';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Non se puido subir a actividade: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'A subida de actividades aínda non está configurada';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Non se puido eliminar o ficheiro temporal da actividade';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Non se puido preparar o ficheiro para subir a actividade';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Non se puido atopar esta actividade local';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Non se puido eliminar a actividade local';

  @override
  String get errorActivityLocalGpxMissing =>
      'O ficheiro GPX local non está dispoñible';

  @override
  String get errorActivityLocalLoadFailed =>
      'Non se puideron cargar as actividades locais';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Non se puido gardar esta actividade';

  @override
  String get errorActivityLocalSaveFailed =>
      'Non se puido gardar a actividade localmente';

  @override
  String get errorFetchProvidersFailed =>
      'Non se puideron cargar os provedores de inicio de sesión';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Non se puideron cargar os provedores de inicio de sesión: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Non se puido cargar a configuración do servidor';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Non se puido cargar a configuración do servidor: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Non se puido converter o adestramento a GPX';

  @override
  String get errorHealthImportFailed => 'Non se puido importar o adestramento';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Non se puido importar o adestramento: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Denegóuselle o acceso aos datos de saúde';

  @override
  String get errorHealthReadFailed => 'Non se puideron ler os datos de saúde';

  @override
  String get errorLoginError => 'Non se puido iniciar sesión';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Non se puido iniciar sesión: $details';
  }

  @override
  String get errorLoginFailed => 'Produciuse un erro ao iniciar sesión';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Produciuse un erro ao iniciar sesión: $details';
  }

  @override
  String get errorMfaVerificationError => 'Non se puido verificar o código MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Non se puido verificar o código MFA: $details';
  }

  @override
  String get errorMfaVerificationFailed =>
      'Produciuse un erro na verificación MFA';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Produciuse un erro na verificación MFA: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'O servidor non devolveu ningún identificador de sesión';

  @override
  String get errorNotAuthenticated => 'Non iniciaches sesión';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Non se atopou o verificador de inicio de sesión. Volve iniciar sesión.';

  @override
  String get errorServerUrlNotConfigured =>
      'O URL do servidor non está configurado';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Este servidor require unha conexión segura (HTTPS)';

  @override
  String get errorSessionExpired =>
      'A túa sesión caducou. Inicia sesión de novo.';

  @override
  String get errorSsoTokenExchangeError =>
      'Non se puido completar o inicio de sesión SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Non se puido completar o inicio de sesión SSO: $details';
  }

  @override
  String get errorTokenExchangeFailed =>
      'Produciuse un erro no intercambio de tokens';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Produciuse un erro no intercambio de tokens: $details';
  }

  @override
  String get errorRequestTimeout =>
      'A solicitude esgotou o tempo de espera. Comproba a túa conexión e téntao de novo.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Non se pode eliminar do almacenamento seguro. É posible que o almacenamento do dispositivo non estea dispoñible.';

  @override
  String get errorSecureStorageReadFailed =>
      'Non se pode ler do almacenamento seguro. É posible que o almacenamento do dispositivo non estea dispoñible.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Non se pode escribir no almacenamento seguro. É posible que o almacenamento do dispositivo non estea dispoñible.';

  @override
  String get errorUnexpectedResponseFormat =>
      'O servidor devolveu unha resposta inesperada';

  @override
  String get errorUnsupportedHttpMethod => 'Método HTTP non admitido';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Método HTTP non admitido: $details';
  }

  @override
  String get loginTitle => 'Inicio de sesión';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Pechar sesión';

  @override
  String get logoutConfirmTitle => 'Pechar sesión';

  @override
  String get logoutConfirmMessage => 'Seguro que queres pechar a sesión?';

  @override
  String get logoutServerFailedWarning =>
      'Non se puido pechar a sesión no servidor, pero pechouse localmente';

  @override
  String get ssoBrowserLaunchFailed =>
      'Non se puido abrir o inicio de sesión SSO no navegador do sistema';

  @override
  String ssoSignInWith(String provider) {
    return 'Iniciar sesión con $provider';
  }

  @override
  String get ssoOrDivider => 'OU';

  @override
  String get next => 'Seguinte';

  @override
  String get username => 'Nome de usuario';

  @override
  String get usernameHint => 'Introduce o teu nome de usuario';

  @override
  String get password => 'Contrasinal';

  @override
  String get passwordHint => 'Introduce o teu contrasinal';

  @override
  String get showPassword => 'Mostrar o contrasinal';

  @override
  String get mfaTitle => 'Autenticación de dous factores';

  @override
  String get mfaCode => 'Código MFA';

  @override
  String get mfaCodeHint => 'Introduce o código de 6 díxitos';

  @override
  String get mfaCodeRequired => 'Introduce o código MFA';

  @override
  String get verify => 'Verificar';

  @override
  String get activityDiscard => 'Descartar';

  @override
  String get activityDiscardConfirmMessage =>
      'Isto eliminará os puntos rexistrados desta actividade.';

  @override
  String get activityDiscardConfirmTitle => 'Descartar a actividade?';

  @override
  String get activityLocationPermissionDenied =>
      'Necesítase o permiso de localización para rexistrar unha actividade.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'O permiso de localización está bloqueado. Abre a configuración para permitir o acceso á localización.';

  @override
  String get activityLocationServiceDisabled =>
      'Os servizos de localización están desactivados.';

  @override
  String get activityLocationStreamFailed =>
      'As actualizacións de localización detivéronse inesperadamente.';

  @override
  String get activityGpxGenerationFailed =>
      'Non se puido crear o ficheiro GPX da actividade.';

  @override
  String get activityLocalSaveFailed =>
      'Non se puido gardar esta actividade neste dispositivo.';

  @override
  String get activityOpenSettings => 'Abrir a configuración';

  @override
  String get activityPause => 'Pausar';

  @override
  String get activityRecordingEmpty => 'Non se rexistrou ningún punto GPS.';

  @override
  String get activityRecordingFailed => 'Produciuse un erro na gravación.';

  @override
  String get activityResume => 'Retomar';

  @override
  String get activityRetryUpload => 'Tentar subir de novo';

  @override
  String get activityDone => 'Feito';

  @override
  String get activityViewHistory => 'Ver o historial';

  @override
  String get activityDeleteLocal => 'Eliminar a copia local';

  @override
  String get activityExportGpx => 'Compartir o ficheiro GPX';

  @override
  String get activityExportGpxSubject => 'GPX de actividade de Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Eliminar a actividade local?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Isto elimina o rexistro da actividade local e o ficheiro GPX deste dispositivo.';

  @override
  String get activityStart => 'Iniciar';

  @override
  String get activityBackgroundPermissionTitle =>
      'Permitir o seguimento en segundo plano?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain necesita a localización en segundo plano configurada como Sempre para que a gravación continúe cando a aplicación estea en segundo plano, a pantalla estea bloqueada ou cambies de aplicación.';

  @override
  String get activityBackgroundPermissionContinue => 'Continuar';

  @override
  String get activityBackgroundPermissionRequired =>
      'O seguimento en segundo plano no iPhone e no iPad require a localización configurada como Sempre.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'O seguimento en segundo plano está desactivado';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Para gravar de forma fiable en segundo plano ou coa pantalla bloqueada, abre a Configuración e establece a Localización como Sempre para Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Gravando a actividade';

  @override
  String get activityTrackingNotificationText =>
      'Endurain está a seguir a túa localización para rexistrar esta actividade.';

  @override
  String get activityStatDistance => 'Distancia';

  @override
  String get activityStatDuration => 'Tempo';

  @override
  String get activityStatSpeed => 'Velocidade';

  @override
  String get activityStatPace => 'Ritmo';

  @override
  String get activityStatMaxSpeed => 'Velocidade máxima';

  @override
  String get activityStatElevationGain => 'Desnivel positivo';

  @override
  String get activityStatHeartRate => 'Frecuencia cardíaca';

  @override
  String get activityStatAvgHeartRate => 'Frecuencia cardíaca media';

  @override
  String get activityStatPower => 'Potencia';

  @override
  String get activityStatAvgPower => 'Potencia media';

  @override
  String get activityStatCadence => 'Cadencia';

  @override
  String get activityStatAvgCadence => 'Cadencia media';

  @override
  String get activityStop => 'Deter';

  @override
  String get activityStopAndSave => 'Deter e gardar';

  @override
  String get activityStopConfirmMessage =>
      'Escolle se queres conservar esta gravación ou descartala.';

  @override
  String get activityStopConfirmTitle => 'Rematar a actividade?';

  @override
  String get activityStopping => 'Detendo';

  @override
  String get activityTypeHike => 'Sendeirismo';

  @override
  String get activityTypeLabel => 'Tipo de actividade';

  @override
  String get activityTypeOther => 'Outro';

  @override
  String get activityTypeRide => 'Ciclismo';

  @override
  String get activityTypeRun => 'Carreira';

  @override
  String get activityTypeWalk => 'Camiñada';

  @override
  String get activityUploadFailed => 'Produciuse un erro na subida';

  @override
  String get activityUploadCleanupFailed => 'Subida, pero fallou a limpeza';

  @override
  String get activityUploadReady => 'Lista para subir';

  @override
  String get activityUploaded => 'Subida';

  @override
  String get activityUploading => 'Subindo';

  @override
  String get activityUploadStatusPending => 'Pendente';

  @override
  String get activityUploadStatusUploaded => 'Subida';

  @override
  String get activityUploadStatusFailed => 'Fallida';

  @override
  String get activityHistoryTitle => 'Historial de actividades';

  @override
  String get activityHistorySettingsSubtitle =>
      'Actividades completadas gardadas neste dispositivo';

  @override
  String get activityRetainUploadedGpx => 'Conservar os ficheiros GPX subidos';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Garda os ficheiros de ruta completados no almacenamento privado da aplicación despois de subilos.';

  @override
  String get activityHistoryEmpty =>
      'Non hai actividades completadas gardadas neste dispositivo.';

  @override
  String get activityHistoryLoadFailed =>
      'Non se puideron cargar as actividades locais.';

  @override
  String get activityHistoryRefresh => 'Actualizar';

  @override
  String get activityHistoryLocalActivities => 'Actividades locais';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Duración: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distancia: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Subida: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Cargar máis';

  @override
  String get activityHistoryDetailsTitle => 'Detalles da actividade';

  @override
  String get activityHistoryDetailsMissing =>
      'Esta actividade local xa non está dispoñible.';

  @override
  String get activityHistorySummary => 'Resumo';

  @override
  String get activityHistoryActions => 'Accións';

  @override
  String get activityHistoryType => 'Tipo';

  @override
  String get activityHistoryStartedAt => 'Inicio';

  @override
  String get activityHistoryEndedAt => 'Fin';

  @override
  String get activityHistoryDurationLabel => 'Duración';

  @override
  String get activityHistoryDistanceLabel => 'Distancia';

  @override
  String get activityHistoryAverageSpeed => 'Velocidade media';

  @override
  String get activityHistoryPointCount => 'Puntos GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Subida';

  @override
  String get activityHistoryGpxStatus => 'Ficheiro GPX';

  @override
  String get activityHistoryGpxAvailable => 'Gardado neste dispositivo';

  @override
  String get activityHistoryGpxMissing => 'Non dispoñible neste dispositivo';

  @override
  String get mapTab => 'Mapa';

  @override
  String get myLocation => 'A miña localización';

  @override
  String get settingsTab => 'Configuración';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® é unha marca rexistrada de João Vitória Silva';

  @override
  String get settingsScreen => 'Configuración';

  @override
  String get deviceAccessTitle => 'Acceso ao dispositivo';

  @override
  String get deviceAccessSubtitle =>
      'Xestiona localización e acceso aos datos de saúde';

  @override
  String get deviceAccessLocationSection => 'Localización';

  @override
  String get deviceAccessHealthSection => 'Datos de saúde';

  @override
  String get deviceAccessLocationTitle => 'Acceso á localización';

  @override
  String get deviceAccessHealthTitle => 'Acceso a datos de saúde';

  @override
  String get deviceAccessChecking => 'Comprobando o acceso...';

  @override
  String get deviceAccessLocationServicesOff =>
      'Os servizos de localización están desactivados';

  @override
  String get deviceAccessLocationAlways => 'Permitido todo o tempo';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Permitido mentres se usa a aplicación';

  @override
  String get deviceAccessLocationBlocked =>
      'Bloqueado na configuración do sistema';

  @override
  String get deviceAccessLocationNotAllowed => 'Non permitido';

  @override
  String get deviceAccessHealthUnavailable =>
      'Non dispoñible neste dispositivo';

  @override
  String get deviceAccessHealthRequired => 'Requírese Health Connect';

  @override
  String get deviceAccessHealthSetUp => 'Acceso sanitario configurado';

  @override
  String get deviceAccessHealthNeedsAttention => 'O acceso precisa atención';

  @override
  String get deviceAccessHealthNotConnected => 'Non conectado';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminado do sistema';

  @override
  String get serverSettings => 'Servidor';

  @override
  String get signInConnectServer => 'Iniciar sesión';

  @override
  String get signInConnectServerSubtitle =>
      'Grava sen conexión agora e sincroniza as túas actividades máis tarde';

  @override
  String get serverSettingsTitle => 'Configuración do servidor';

  @override
  String connectedToServer(String server) {
    return 'Conectado a $server';
  }

  @override
  String get loggedIn => 'Sesión iniciada';

  @override
  String get notConfigured => 'Non configurado';

  @override
  String get notLoggedIn => 'Sen iniciar sesión';

  @override
  String get serverUrl => 'URL do servidor';

  @override
  String get serverProtocol => 'Protocolo';

  @override
  String get serverUrlHint => 'https://exemplo.com';

  @override
  String get warnHttpServerUrlTitle => 'Conexión insegura';

  @override
  String get warnHttpServerUrlMessage =>
      'Este URL do servidor usa HTTP sen cifrar. As túas credenciais e datos transmitiranse sen cifrado. Continúa só se entendes e aceptas o risco.';

  @override
  String get warnHttpServerUrlConfirm => 'Continuar de todos os xeitos';

  @override
  String get tileServerUrl => 'URL do servidor de teselas do mapa';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Servidor de teselas diferente';

  @override
  String get tileServerHostWarningMessage =>
      'O host do servidor de teselas é diferente do host do teu servidor Endurain. As teselas cargaranse desde un servidor de terceiros. Queres continuar?';

  @override
  String get savedSuccessfully => 'Configuración gardada correctamente';

  @override
  String get diagnostics => 'Diagnósticos';

  @override
  String get diagnosticsSubtitle => 'Contexto local de fallos';

  @override
  String get sourceCode => 'Código fonte';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Non foi posible abrir a ligazón';

  @override
  String get diagnosticsTitle => 'Diagnósticos';

  @override
  String get diagnosticsCollection => 'Recompilación';

  @override
  String get diagnosticsEnable => 'Recompilar diagnósticos';

  @override
  String get diagnosticsEnableSubtitle =>
      'Garda os eventos e erros recentes da aplicación neste dispositivo';

  @override
  String get diagnosticsDisabled =>
      'A recompilación de diagnósticos está desactivada. Activa esta opción para comezar a capturar eventos e erros da aplicación neste dispositivo.';

  @override
  String get diagnosticsEmpty => 'Aínda non se capturou ningún diagnóstico.';

  @override
  String get diagnosticsCopy => 'Copiar';

  @override
  String get diagnosticsCopied => 'Diagnósticos copiados';

  @override
  String get diagnosticsClear => 'Borrar';

  @override
  String get diagnosticsCleared => 'Diagnósticos borrados';

  @override
  String get diagnosticsSummary => 'Resumo';

  @override
  String get diagnosticsLastUpdated => 'Última actualización';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Eventos: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Erros: $count';
  }

  @override
  String get diagnosticsEvents => 'Eventos';

  @override
  String get diagnosticsNoEvents => 'Non se capturou ningún evento';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Evento: $event';
  }

  @override
  String get diagnosticsErrors => 'Erros';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Erro: $type';
  }

  @override
  String get diagnosticsActions => 'Accións';

  @override
  String get diagnosticsRawReport => 'Informe en bruto';

  @override
  String get healthSyncSettingsTitle => 'Sincronización da saúde';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importa adestramentos da túa plataforma de saúde';

  @override
  String get healthSyncScreenTitle => 'Sincronización da saúde';

  @override
  String get healthAccessScreenTitle => 'Acceso sanitario';

  @override
  String get healthAccessRequestedData => 'Datos solicitados';

  @override
  String get healthAccessWorkouts => 'Adestramentos';

  @override
  String get healthAccessWorkoutRoutes => 'Rutas de adestramento';

  @override
  String get healthAccessHeartRate => 'Frecuencia cardíaca';

  @override
  String get healthAccessWorkoutSummary =>
      'Distancia, calorías e pasos do adestramento';

  @override
  String get healthAccessAllowed => 'Permitido';

  @override
  String get healthAccessNeedsAttention => 'Necesita atención';

  @override
  String get healthAccessManagedBySystem =>
      'Xestionado na configuración do sistema';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit non revela que datos pode ler Endurain. Revisa o acceso na aplicación Saúde.';

  @override
  String get healthAccessReview => 'Revisar o acceso á saúde';

  @override
  String get healthAccessReviewIos => 'Como revisar o acceso';

  @override
  String get healthAccessDisconnect => 'Desconectar os datos de saúde';

  @override
  String get healthAccessDisconnectTitle => 'Desconectar os datos de saúde?';

  @override
  String get healthAccessDisconnectMessage =>
      'Restableceranse a importación automática e o historial local de importacións deste servidor. As actividades existentes permanecerán no historial.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Abre a aplicación Saúde, toca a túa imaxe de perfil e despois Aplicacións e servizos. Seleccione Endurain e actualice as categorías de datos.';

  @override
  String get healthSyncAuthorize => 'Conectar aos datos de saúde';

  @override
  String get healthSyncInstallProvider => 'Instala Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Requírese Health Connect para sincronizar os adestramentos. Instálao para continuar.';

  @override
  String get healthSyncUnsupported =>
      'A sincronización de saúde non está dispoñible neste dispositivo.';

  @override
  String get healthSyncSelectAll => 'Selecciona todo';

  @override
  String get healthSyncClearSelection => 'Limpar';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importación seleccionada ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Importáronse $count adestramentos.';
  }

  @override
  String get healthSyncNoRouteLabel => 'Sen ruta GPS';

  @override
  String get healthSyncEmptyState =>
      'Non se atopou ningún adestramento no período seleccionado.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Omitiron algúns adestramentos porque non se concedeu o acceso á ruta do exercicio. Abre Health Connect → Permisos e permite rutas de exercicio para Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Saltáronse algúns adestramentos porque Endurain non podía ler as súas rutas GPS. Na aplicación Saúde, abre o teu perfil, despois Aplicacións e servizos, selecciona Endurain e permite Rutas de adestramento.';

  @override
  String get healthSyncReviewAccess => 'Revisar o acceso';

  @override
  String get healthSyncAutoSyncTitle =>
      'Sincronización automática no currículo';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importa novos adestramentos automaticamente cando se abre a aplicación.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Estes adestramentos non inclúen unha ruta GPS, polo que non se poden importar. Algunhas aplicacións (como Garmin Connect) rexistran actividades en Apple Health sen compartir a ruta. Os adestramentos gravados con Apple Watch inclúen rutas e pódense importar.';

  @override
  String get healthSyncBadgeNonImportable => 'Non importables';

  @override
  String get healthSyncViewAvailable => 'Dispoñibles';

  @override
  String get healthSyncViewImported => 'Importados';

  @override
  String get healthSyncDateRange => 'Período dos adestramentos';

  @override
  String get healthSyncRange30Days => 'Últimos 30 días';

  @override
  String get healthSyncRange3Months => 'Últimos 3 meses';

  @override
  String get healthSyncRange6Months => 'Últimos 6 meses';

  @override
  String get healthSyncRangeYear => 'Último ano';

  @override
  String get healthSyncRangeAll => 'Todo o historial';

  @override
  String get healthSyncRangeCustom => 'Período personalizado';

  @override
  String get healthSyncImportedEmpty =>
      'Non hai adestramentos importados para esta conexión.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importado: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Restaurar';

  @override
  String get sensorsTitle => 'Sensores';

  @override
  String get sensorsSettingsSubtitle =>
      'Monitores de frecuencia cardíaca e outros sensores externos';

  @override
  String get sensorsHeartRateSection => 'Frecuencia cardíaca';

  @override
  String get sensorsHeartRateHelp =>
      'Vincula un monitor de frecuencia cardíaca Bluetooth para ver a túa frecuencia cardíaca en directo.';

  @override
  String get sensorsBluetoothOff =>
      'O Bluetooth está desactivado. Actívao para conectar un sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Permite o acceso ao Bluetooth para conectar un sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Este dispositivo non admite Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Buscar sensores';

  @override
  String get sensorsScanning => 'Buscando…';

  @override
  String get sensorsStopScan => 'Deter';

  @override
  String get sensorsNoDevices =>
      'Aínda non se atoparon sensores de frecuencia cardíaca.';

  @override
  String get sensorsAvailableSection => 'Sensores dispoñibles';

  @override
  String get sensorsSavedSection => 'Sensor gardado';

  @override
  String get sensorsConnect => 'Conectar';

  @override
  String get sensorsConnecting => 'Conectando…';

  @override
  String get sensorsConnected => 'Conectado';

  @override
  String get sensorsDisconnect => 'Desconectar';

  @override
  String get sensorsForget => 'Esquecer';

  @override
  String get sensorsConnectionFailed =>
      'Non se puido conectar. Téntao de novo.';

  @override
  String get sensorsPermissionRequired =>
      'Necesítase permiso de Bluetooth para atopar sensores.';

  @override
  String get sensorsUnknownDevice => 'Sensor descoñecido';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Potencia';

  @override
  String get sensorsPowerHelp =>
      'Vincula un medidor de potencia Bluetooth para ver a túa potencia en directo.';

  @override
  String get sensorsNoPowerDevices =>
      'Aínda non se atoparon medidores de potencia.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadencia';

  @override
  String get sensorsCadenceHelp =>
      'Vincula un sensor de cadencia Bluetooth para ver a túa cadencia en directo.';

  @override
  String get sensorsNoCadenceDevices =>
      'Aínda non se atoparon sensores de cadencia.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Informes de fallos remotos';

  @override
  String get diagnosticsRemoteEnable => 'Enviar informes de fallos';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Envía informes de fallos e erros a un servidor de diagnóstico. Isto é independente dos diagnósticos locais: podes activar ambos, un ou ningún.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Os informes de fallos remotos non están dispoñibles nesta versión.';

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
  String get unitsTitle => 'Unidades';

  @override
  String get unitsSubtitle => 'Unidades de distancia, velocidade e altitude';

  @override
  String get unitsSystemDefault => 'Seguir a rexión do dispositivo';

  @override
  String get unitsMetric => 'Métrico (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';
}
