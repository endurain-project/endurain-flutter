// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get error => 'Error';

  @override
  String get ok => 'Aceptar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get back => 'Atrás';

  @override
  String get requiredField => 'Este campo es obligatorio';

  @override
  String get invalidUrl => 'Introduce una URL válida';

  @override
  String get errorActivityUploadFailed => 'No se pudo subir la actividad';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'No se pudo subir la actividad: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'La subida de actividades aún no está configurada';

  @override
  String get errorActivityGpxCleanupFailed =>
      'No se pudo eliminar el archivo temporal de la actividad';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'No se pudo preparar el archivo para subir la actividad';

  @override
  String get errorActivityLocalActivityNotFound =>
      'No se pudo encontrar esta actividad local';

  @override
  String get errorActivityLocalDeleteFailed =>
      'No se pudo eliminar la actividad local';

  @override
  String get errorActivityLocalGpxMissing =>
      'El archivo GPX local no está disponible';

  @override
  String get errorActivityLocalLoadFailed =>
      'No se pudieron cargar las actividades locales';

  @override
  String get errorActivityLocalRecordInvalid =>
      'No se pudo guardar esta actividad';

  @override
  String get errorActivityLocalSaveFailed =>
      'No se pudo guardar la actividad localmente';

  @override
  String get errorFetchProvidersFailed =>
      'No se pudieron cargar los proveedores de inicio de sesión';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'No se pudieron cargar los proveedores de inicio de sesión: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'No se pudo cargar la configuración del servidor';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'No se pudo cargar la configuración del servidor: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'No se pudo convertir el entrenamiento a GPX';

  @override
  String get errorHealthImportFailed => 'No se pudo importar el entrenamiento';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'No se pudo importar el entrenamiento: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Se denegó el acceso a los datos de salud';

  @override
  String get errorHealthReadFailed => 'No se pudieron leer los datos de salud';

  @override
  String get errorLoginError => 'No se pudo iniciar sesión';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'No se pudo iniciar sesión: $details';
  }

  @override
  String get errorLoginFailed => 'Error al iniciar sesión';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Error al iniciar sesión: $details';
  }

  @override
  String get errorMfaVerificationError => 'No se pudo verificar el código MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'No se pudo verificar el código MFA: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Error en la verificación MFA';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Error en la verificación MFA: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'El servidor no devolvió ningún ID de sesión';

  @override
  String get errorNotAuthenticated => 'No has iniciado sesión';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'No se encontró el verificador de inicio de sesión. Vuelve a iniciar sesión.';

  @override
  String get errorServerUrlNotConfigured =>
      'La URL del servidor no está configurada';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Este servidor requiere una conexión segura (HTTPS)';

  @override
  String get errorSessionExpired =>
      'Tu sesión ha caducado. Inicia sesión de nuevo.';

  @override
  String get errorSsoTokenExchangeError =>
      'No se pudo completar el inicio de sesión SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'No se pudo completar el inicio de sesión SSO: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Error en el intercambio de tokens';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Error en el intercambio de tokens: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Se agotó el tiempo de espera de la solicitud. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'No se puede eliminar del almacenamiento seguro. Es posible que el almacenamiento del dispositivo no esté disponible.';

  @override
  String get errorSecureStorageReadFailed =>
      'No se puede leer del almacenamiento seguro. Es posible que el almacenamiento del dispositivo no esté disponible.';

  @override
  String get errorSecureStorageWriteFailed =>
      'No se puede escribir en el almacenamiento seguro. Es posible que el almacenamiento del dispositivo no esté disponible.';

  @override
  String get errorUnexpectedResponseFormat =>
      'El servidor devolvió una respuesta inesperada';

  @override
  String get errorUnsupportedHttpMethod => 'Método HTTP no admitido';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Método HTTP no admitido: $details';
  }

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutConfirmTitle => 'Cerrar sesión';

  @override
  String get logoutConfirmMessage => '¿Seguro que quieres cerrar sesión?';

  @override
  String get logoutServerFailedWarning =>
      'No se pudo cerrar sesión en el servidor, pero se cerró localmente';

  @override
  String get ssoBrowserLaunchFailed =>
      'No se pudo abrir el inicio de sesión SSO en el navegador del sistema';

  @override
  String ssoSignInWith(String provider) {
    return 'Iniciar sesión con $provider';
  }

  @override
  String get ssoOrDivider => 'O';

  @override
  String get next => 'Siguiente';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get usernameHint => 'Introduce tu nombre de usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordHint => 'Introduce tu contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get mfaTitle => 'Autenticación de dos factores';

  @override
  String get mfaCode => 'Código MFA';

  @override
  String get mfaCodeHint => 'Introduce el código de 6 dígitos';

  @override
  String get mfaCodeRequired => 'Introduce el código MFA';

  @override
  String get verify => 'Verificar';

  @override
  String get activityDiscard => 'Descartar';

  @override
  String get activityDiscardConfirmMessage =>
      'Esto eliminará los puntos registrados de esta actividad.';

  @override
  String get activityDiscardConfirmTitle => '¿Descartar la actividad?';

  @override
  String get activityLocationPermissionDenied =>
      'Se necesita permiso de ubicación para registrar una actividad.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'El permiso de ubicación está bloqueado. Abre la configuración para permitir el acceso a la ubicación.';

  @override
  String get activityLocationServiceDisabled =>
      'Los servicios de ubicación están desactivados.';

  @override
  String get activityLocationStreamFailed =>
      'Las actualizaciones de ubicación se detuvieron inesperadamente.';

  @override
  String get activityGpxGenerationFailed =>
      'No se pudo crear el archivo GPX de la actividad.';

  @override
  String get activityLocalSaveFailed =>
      'No se pudo guardar esta actividad en este dispositivo.';

  @override
  String get activityOpenSettings => 'Abrir configuración';

  @override
  String get activityPause => 'Pausar';

  @override
  String get activityRecordingEmpty => 'No se registró ningún punto GPS.';

  @override
  String get activityRecordingFailed => 'Error en la grabación.';

  @override
  String get activityResume => 'Reanudar';

  @override
  String get activityRetryUpload => 'Reintentar subida';

  @override
  String get activityDone => 'Listo';

  @override
  String get activityViewHistory => 'Ver historial';

  @override
  String get activityDeleteLocal => 'Eliminar copia local';

  @override
  String get activityExportGpx => 'Compartir archivo GPX';

  @override
  String get activityExportGpxSubject => 'GPX de actividad de Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => '¿Eliminar la actividad local?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Esto elimina el registro de la actividad local y el archivo GPX de este dispositivo.';

  @override
  String get activityStart => 'Iniciar';

  @override
  String get activityBackgroundPermissionTitle =>
      '¿Permitir el seguimiento en segundo plano?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain necesita la ubicación en segundo plano configurada como Siempre para que la grabación continúe cuando la app esté en segundo plano, la pantalla esté bloqueada o cambies de aplicación.';

  @override
  String get activityBackgroundPermissionContinue => 'Continuar';

  @override
  String get activityBackgroundPermissionRequired =>
      'El seguimiento en segundo plano en iPhone y iPad requiere la ubicación configurada como Siempre.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'El seguimiento en segundo plano está desactivado';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Para grabar de forma fiable en segundo plano o con la pantalla bloqueada, abre Configuración y establece la Ubicación como Siempre para Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Grabando actividad';

  @override
  String get activityTrackingNotificationText =>
      'Endurain está siguiendo tu ubicación para registrar esta actividad.';

  @override
  String get activityStatDistance => 'Distancia';

  @override
  String get activityStatDuration => 'Tiempo';

  @override
  String get activityStatSpeed => 'Velocidad';

  @override
  String get activityStatPace => 'Ritmo';

  @override
  String get activityStatMaxSpeed => 'Velocidad máxima';

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
  String get activityStop => 'Detener';

  @override
  String get activityStopAndSave => 'Detener y guardar';

  @override
  String get activityStopConfirmMessage =>
      'Elige si quieres conservar esta grabación o descartarla.';

  @override
  String get activityStopConfirmTitle => '¿Finalizar la actividad?';

  @override
  String get activityStopping => 'Deteniendo';

  @override
  String get activityTypeHike => 'Senderismo';

  @override
  String get activityTypeLabel => 'Tipo de actividad';

  @override
  String get activityTypeOther => 'Otro';

  @override
  String get activityTypeRide => 'Ciclismo';

  @override
  String get activityTypeRun => 'Carrera';

  @override
  String get activityTypeWalk => 'Caminata';

  @override
  String get activityUploadFailed => 'Error en la subida';

  @override
  String get activityUploadCleanupFailed =>
      'Subida completada, pero falló la limpieza';

  @override
  String get activityUploadReady => 'Lista para subir';

  @override
  String get activityUploaded => 'Subida';

  @override
  String get activityUploading => 'Subiendo';

  @override
  String get activityUploadStatusPending => 'Pendiente';

  @override
  String get activityUploadStatusUploaded => 'Subida';

  @override
  String get activityUploadStatusFailed => 'Fallida';

  @override
  String get activityHistoryTitle => 'Historial de actividades';

  @override
  String get activityHistorySettingsSubtitle =>
      'Actividades completadas guardadas en este dispositivo';

  @override
  String get activityRetainUploadedGpx => 'Conservar los archivos GPX subidos';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Guarda los archivos de ruta completados en el almacenamiento privado de la app después de subirlos.';

  @override
  String get activityHistoryEmpty =>
      'No hay actividades completadas guardadas en este dispositivo.';

  @override
  String get activityHistoryLoadFailed =>
      'No se pudieron cargar las actividades locales.';

  @override
  String get activityHistoryRefresh => 'Actualizar';

  @override
  String get activityHistoryLocalActivities => 'Actividades locales';

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
  String get activityHistoryLoadMore => 'Cargar más';

  @override
  String get activityHistoryDetailsTitle => 'Detalles de la actividad';

  @override
  String get activityHistoryDetailsMissing =>
      'Esta actividad local ya no está disponible.';

  @override
  String get activityHistorySummary => 'Resumen';

  @override
  String get activityHistoryActions => 'Acciones';

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
  String get activityHistoryAverageSpeed => 'Velocidad media';

  @override
  String get activityHistoryPointCount => 'Puntos GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Subida';

  @override
  String get activityHistoryGpxStatus => 'Archivo GPX';

  @override
  String get activityHistoryGpxAvailable => 'Guardado en este dispositivo';

  @override
  String get activityHistoryGpxMissing => 'No disponible en este dispositivo';

  @override
  String get mapTab => 'Mapa';

  @override
  String get myLocation => 'Mi ubicación';

  @override
  String get settingsTab => 'Configuración';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® es una marca registrada de João Vitória Silva';

  @override
  String get settingsScreen => 'Configuración';

  @override
  String get deviceAccessTitle => 'Acceso al dispositivo';

  @override
  String get deviceAccessSubtitle =>
      'Gestionar la ubicación y el acceso a los datos de salud';

  @override
  String get deviceAccessLocationSection => 'Ubicación';

  @override
  String get deviceAccessHealthSection => 'Datos de salud';

  @override
  String get deviceAccessLocationTitle => 'Acceso a la ubicación';

  @override
  String get deviceAccessHealthTitle => 'Acceso a datos de salud';

  @override
  String get deviceAccessChecking => 'Comprobando acceso…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Los servicios de ubicación están desactivados';

  @override
  String get deviceAccessLocationAlways => 'Permitido todo el tiempo';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Permitido mientras se usa la aplicación';

  @override
  String get deviceAccessLocationBlocked =>
      'Bloqueado en la configuración del sistema';

  @override
  String get deviceAccessLocationNotAllowed => 'No permitido';

  @override
  String get deviceAccessHealthUnavailable =>
      'No disponible en este dispositivo';

  @override
  String get deviceAccessHealthRequired => 'Se requiere Conexión de Salud';

  @override
  String get deviceAccessHealthSetUp => 'Configuración del acceso a la salud';

  @override
  String get deviceAccessHealthNeedsAttention => 'El acceso necesita atención';

  @override
  String get deviceAccessHealthNotConnected => 'No conectado';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get serverSettings => 'Servidor';

  @override
  String get signInConnectServer => 'Iniciar sesión';

  @override
  String get signInConnectServerSubtitle =>
      'Graba sin conexión ahora y sincroniza tus actividades más tarde';

  @override
  String get serverSettingsTitle => 'Configuración del servidor';

  @override
  String connectedToServer(String server) {
    return 'Conectado a $server';
  }

  @override
  String get loggedIn => 'Sesión iniciada';

  @override
  String get notConfigured => 'No configurado';

  @override
  String get notLoggedIn => 'Sin iniciar sesión';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get serverProtocol => 'Protocolo';

  @override
  String get serverUrlHint => 'https://ejemplo.com';

  @override
  String get warnHttpServerUrlTitle => 'Conexión insegura';

  @override
  String get warnHttpServerUrlMessage =>
      'Esta URL del servidor usa HTTP sin cifrar. Tus credenciales y datos se transmitirán sin cifrado. Continúa solo si entiendes y aceptas el riesgo.';

  @override
  String get warnHttpServerUrlConfirm => 'Continuar de todos modos';

  @override
  String get tileServerUrl => 'URL del servidor de teselas del mapa';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Servidor de teselas diferente';

  @override
  String get tileServerHostWarningMessage =>
      'El host del servidor de teselas es diferente del host de tu servidor Endurain. Las teselas se cargarán desde un servidor de terceros. ¿Quieres continuar?';

  @override
  String get savedSuccessfully => 'Configuración guardada correctamente';

  @override
  String get diagnostics => 'Diagnósticos';

  @override
  String get diagnosticsSubtitle => 'Contexto local de fallos';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'No se pudo abrir el enlace';

  @override
  String get diagnosticsTitle => 'Diagnósticos';

  @override
  String get diagnosticsCollection => 'Recopilación';

  @override
  String get diagnosticsEnable => 'Recopilar diagnósticos';

  @override
  String get diagnosticsEnableSubtitle =>
      'Guarda los eventos y errores recientes de la aplicación en este dispositivo';

  @override
  String get diagnosticsDisabled =>
      'La recopilación de diagnósticos está desactivada. Actívala para empezar a capturar eventos y errores de la aplicación en este dispositivo.';

  @override
  String get diagnosticsEmpty => 'Aún no se ha capturado ningún diagnóstico.';

  @override
  String get diagnosticsCopy => 'Copiar';

  @override
  String get diagnosticsCopied => 'Diagnósticos copiados';

  @override
  String get diagnosticsClear => 'Borrar';

  @override
  String get diagnosticsCleared => 'Diagnósticos borrados';

  @override
  String get diagnosticsSummary => 'Resumen';

  @override
  String get diagnosticsLastUpdated => 'Última actualización';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Eventos: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Errores: $count';
  }

  @override
  String get diagnosticsEvents => 'Eventos';

  @override
  String get diagnosticsNoEvents => 'No se capturaron eventos';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Evento: $event';
  }

  @override
  String get diagnosticsErrors => 'Errores';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Error: $type';
  }

  @override
  String get diagnosticsActions => 'Acciones';

  @override
  String get diagnosticsRawReport => 'Informe sin procesar';

  @override
  String get healthSyncSettingsTitle => 'Sincronización de salud';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importa entrenamientos desde tu plataforma de salud';

  @override
  String get healthSyncScreenTitle => 'Sincronización de salud';

  @override
  String get healthAccessScreenTitle => 'Acceso a la salud';

  @override
  String get healthAccessRequestedData => 'Datos solicitados';

  @override
  String get healthAccessWorkouts => 'Entrenamientos';

  @override
  String get healthAccessWorkoutRoutes => 'Rutas de entrenamiento';

  @override
  String get healthAccessHeartRate => 'frecuencia cardiaca';

  @override
  String get healthAccessWorkoutSummary =>
      'Distancia, calorías y pasos del entrenamiento';

  @override
  String get healthAccessAllowed => 'Permitido';

  @override
  String get healthAccessNeedsAttention => 'necesita atencion';

  @override
  String get healthAccessManagedBySystem =>
      'Gestionado en la configuración del sistema';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit no revela qué datos puede leer Endurain. Revisar el acceso en la aplicación Salud.';

  @override
  String get healthAccessReview => 'Revisar el acceso a la salud';

  @override
  String get healthAccessReviewIos => 'Cómo revisar el acceso';

  @override
  String get healthAccessDisconnect => 'Desconectar datos de salud';

  @override
  String get healthAccessDisconnectTitle => '¿Desconectar los datos de salud?';

  @override
  String get healthAccessDisconnectMessage =>
      'Se restablecerán la importación automática y el historial local de importaciones de este servidor. Las actividades existentes permanecerán en el historial.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Abra la aplicación Salud, toque su foto de perfil y luego Aplicaciones y servicios. Seleccione Endurain y actualice las categorías de datos.';

  @override
  String get healthSyncAuthorize => 'Conéctese a datos de salud';

  @override
  String get healthSyncInstallProvider => 'Instalar Conexión de salud';

  @override
  String get healthSyncInstallProviderDescription =>
      'Se requiere Health Connect para sincronizar los entrenamientos. Instálalo para continuar.';

  @override
  String get healthSyncUnsupported =>
      'La sincronización de salud no está disponible en este dispositivo.';

  @override
  String get healthSyncSelectAll => 'Seleccionar todo';

  @override
  String get healthSyncClearSelection => 'Borrar';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importar seleccionados ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '$count ejercicios importados.';
  }

  @override
  String get healthSyncNoRouteLabel => 'Sin ruta GPS';

  @override
  String get healthSyncEmptyState =>
      'No se encontraron entrenamientos en el periodo seleccionado.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Se omitieron algunos entrenamientos porque no se permitió el acceso a la ruta de ejercicio. Abra Health Connect → Permisos y permita rutas de ejercicio para Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Se omitieron algunos entrenamientos porque Endurain no pudo leer sus rutas GPS. En la aplicación Salud, abra su perfil, luego Aplicaciones y servicios, seleccione Endurain y permita Rutas de entrenamiento.';

  @override
  String get healthSyncReviewAccess => 'Acceso a reseñas';

  @override
  String get healthSyncAutoSyncTitle => 'Sincronización automática al reanudar';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importa nuevos entrenamientos automáticamente cuando se abre la aplicación.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Estos entrenamientos no incluyen ruta GPS, por lo que no se pueden importar. Algunas aplicaciones (como Garmin Connect) registran actividades en Apple Health sin compartir la ruta. Los entrenamientos grabados con Apple Watch incluyen rutas y se pueden importar.';

  @override
  String get healthSyncBadgeNonImportable => 'No importable';

  @override
  String get healthSyncViewAvailable => 'Disponibles';

  @override
  String get healthSyncViewImported => 'Importados';

  @override
  String get healthSyncDateRange => 'Periodo de entrenamientos';

  @override
  String get healthSyncRange30Days => 'Últimos 30 días';

  @override
  String get healthSyncRange3Months => 'Últimos 3 meses';

  @override
  String get healthSyncRange6Months => 'Últimos 6 meses';

  @override
  String get healthSyncRangeYear => 'Último año';

  @override
  String get healthSyncRangeAll => 'Todo el historial';

  @override
  String get healthSyncRangeCustom => 'Periodo personalizado';

  @override
  String get healthSyncImportedEmpty =>
      'No hay entrenamientos importados para esta conexión.';

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
      'Monitores de frecuencia cardíaca y otros sensores externos';

  @override
  String get sensorsHeartRateSection => 'Frecuencia cardíaca';

  @override
  String get sensorsHeartRateHelp =>
      'Vincula un monitor de frecuencia cardíaca Bluetooth para ver tu frecuencia cardíaca en directo.';

  @override
  String get sensorsBluetoothOff =>
      'El Bluetooth está desactivado. Actívalo para conectar un sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Permite el acceso al Bluetooth para conectar un sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Este dispositivo no admite Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Buscar sensores';

  @override
  String get sensorsScanning => 'Buscando…';

  @override
  String get sensorsStopScan => 'Detener';

  @override
  String get sensorsNoDevices =>
      'Aún no se han encontrado sensores de frecuencia cardíaca.';

  @override
  String get sensorsAvailableSection => 'Sensores disponibles';

  @override
  String get sensorsSavedSection => 'Sensor guardado';

  @override
  String get sensorsConnect => 'Conectar';

  @override
  String get sensorsConnecting => 'Conectando…';

  @override
  String get sensorsConnected => 'Conectado';

  @override
  String get sensorsDisconnect => 'Desconectar';

  @override
  String get sensorsForget => 'Olvidar';

  @override
  String get sensorsConnectionFailed =>
      'No se pudo conectar. Inténtalo de nuevo.';

  @override
  String get sensorsPermissionRequired =>
      'Se necesita permiso de Bluetooth para buscar sensores.';

  @override
  String get sensorsUnknownDevice => 'Sensor desconocido';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Potencia';

  @override
  String get sensorsPowerHelp =>
      'Vincula un medidor de potencia Bluetooth para ver tu potencia en directo.';

  @override
  String get sensorsNoPowerDevices =>
      'Aún no se han encontrado medidores de potencia.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadencia';

  @override
  String get sensorsCadenceHelp =>
      'Vincula un sensor de cadencia Bluetooth para ver tu cadencia en directo.';

  @override
  String get sensorsNoCadenceDevices =>
      'Aún no se han encontrado sensores de cadencia.';

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
      'Envía informes de fallos y errores a un servidor de diagnóstico. Esto es independiente de los diagnósticos locales: puedes activar ambos, uno o ninguno.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Los informes de fallos remotos no están disponibles en esta versión.';

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
  String get unitsSubtitle => 'Unidades de distancia, velocidad y altitud';

  @override
  String get unitsSystemDefault => 'Seguir la región del dispositivo';

  @override
  String get unitsMetric => 'Métrico (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'El servidor intentó redirigir a una conexión insegura. La solicitud se bloqueó para proteger tus credenciales.';

  @override
  String get errorTooManyRedirects =>
      'El servidor redirigió demasiadas veces. Comprueba la dirección del servidor.';

  @override
  String get audioAnnouncementsTitle => 'Anuncios de voz';

  @override
  String get audioAnnouncementsSubtitle =>
      'Actualizaciones de voz sobre distancia, tiempo, ritmo o velocidad';

  @override
  String get audioAnnouncementsMasterSwitch =>
      'Anunciar el progreso de la actividad';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Dice en voz alta tu distancia, tiempo, ritmo o velocidad durante una grabación';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Bajar el volumen de otro audio mientras habla';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Reduce temporalmente el volumen de otro audio durante cada anuncio';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Intervalo de anuncio por actividad';

  @override
  String get audioAnnouncementsByDistance => 'Distancia';

  @override
  String get audioAnnouncementsByTime => 'Tiempo';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Cada $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Cada $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Disminuir intervalo';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Aumentar intervalo';

  @override
  String get audioAnnouncementsPreview => 'Escuchar ejemplo';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'La muestra de anuncio no está disponible en este dispositivo';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Los cambios se aplican a tu próxima grabación.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Distancia $distance. Tiempo $duration. Vuelta: $lapMetric. Total: $overallMetric.';
  }
}
