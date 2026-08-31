// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get error => 'Erro';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get back => 'Voltar';

  @override
  String get requiredField => 'Este campo é obrigatório';

  @override
  String get invalidUrl => 'Por favor, insira um URL válido';

  @override
  String get errorActivityUploadFailed => 'Não foi possível enviar a atividade';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Não foi possível enviar a atividade: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'O envio de atividades ainda não está configurado';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Não foi possível apagar o ficheiro temporário da atividade';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Não foi possível preparar o ficheiro de envio da atividade';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Não foi possível encontrar esta atividade local';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Não foi possível apagar a atividade local';

  @override
  String get errorActivityLocalGpxMissing =>
      'O ficheiro GPX local não está disponível';

  @override
  String get errorActivityLocalLoadFailed =>
      'Não foi possível carregar atividades locais';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Não foi possível guardar esta atividade';

  @override
  String get errorActivityLocalSaveFailed =>
      'Não foi possível guardar a atividade localmente';

  @override
  String get errorFetchProvidersFailed =>
      'Não foi possível carregar os provedores de login';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Não foi possível carregar os provedores de login: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Não foi possível carregar as definições do servidor';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Não foi possível carregar as definições do servidor: $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Não foi possível converter o treino para GPX';

  @override
  String get errorHealthImportFailed => 'Não foi possível importar o treino';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Não foi possível importar o treino: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'O acesso aos dados de saúde foi negado';

  @override
  String get errorHealthReadFailed => 'Não foi possível ler os dados de saúde';

  @override
  String get errorLoginError => 'Não foi possível iniciar sessão';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Não foi possível iniciar sessão: $details';
  }

  @override
  String get errorLoginFailed => 'Falha ao iniciar sessão';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Falha ao iniciar sessão: $details';
  }

  @override
  String get errorMfaVerificationError =>
      'Não foi possível verificar o código MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Não foi possível verificar o código MFA: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Falha na verificação MFA';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Falha na verificação MFA: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'O servidor não devolveu um ID de sessão';

  @override
  String get errorNotAuthenticated => 'Não tem sessão iniciada';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'O verificador de login não foi encontrado. Inicie sessão novamente.';

  @override
  String get errorServerUrlNotConfigured =>
      'O URL do servidor não está configurado';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Este servidor requer uma ligação segura (HTTPS)';

  @override
  String get errorSessionExpired =>
      'A sua sessão expirou. Inicie sessão novamente.';

  @override
  String get errorSsoTokenExchangeError =>
      'Não foi possível concluir o login SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Não foi possível concluir o login SSO: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Falha na troca de token';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Falha na troca de token: $details';
  }

  @override
  String get errorRequestTimeout =>
      'O pedido expirou. Verifique a sua ligação e tente novamente.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Não foi possível eliminar do armazenamento seguro. O armazenamento do seu dispositivo pode estar indisponível.';

  @override
  String get errorSecureStorageReadFailed =>
      'Não foi possível ler o armazenamento seguro. O armazenamento do seu dispositivo pode estar indisponível.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Não foi possível escrever no armazenamento seguro. O armazenamento do seu dispositivo pode estar indisponível.';

  @override
  String get errorUnexpectedResponseFormat =>
      'O servidor devolveu uma resposta inesperada';

  @override
  String get errorUnsupportedHttpMethod => 'Método HTTP não suportado';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Método HTTP não suportado: $details';
  }

  @override
  String get loginTitle => 'Iniciar sessão';

  @override
  String get login => 'Entrar';

  @override
  String get logout => 'Sair';

  @override
  String get logoutConfirmTitle => 'Sair';

  @override
  String get logoutConfirmMessage => 'Tem certeza que deseja sair?';

  @override
  String get logoutServerFailedWarning =>
      'Não foi possível sair do servidor, mas saiu localmente';

  @override
  String get ssoBrowserLaunchFailed =>
      'Não foi possível abrir o login SSO no navegador do sistema';

  @override
  String ssoSignInWith(String provider) {
    return 'Entrar com $provider';
  }

  @override
  String get ssoOrDivider => 'OU';

  @override
  String get next => 'Próximo';

  @override
  String get username => 'Nome de utilizador';

  @override
  String get usernameHint => 'Insira o seu nome de utilizador';

  @override
  String get password => 'Palavra-passe';

  @override
  String get passwordHint => 'Insira a sua palavra-passe';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get mfaTitle => 'Autenticação de Dois Fatores';

  @override
  String get mfaCode => 'Código MFA';

  @override
  String get mfaCodeHint => 'Insira o código de 6 dígitos';

  @override
  String get mfaCodeRequired => 'Por favor, insira o código MFA';

  @override
  String get verify => 'Verificar';

  @override
  String get activityDiscard => 'Descartar';

  @override
  String get activityDiscardConfirmMessage =>
      'Isto irá apagar os pontos gravados para esta atividade.';

  @override
  String get activityDiscardConfirmTitle => 'Descartar atividade?';

  @override
  String get activityLocationPermissionDenied =>
      'É necessária permissão de localização para gravar uma atividade.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'A permissão de localização está bloqueada. Abra as definições para permitir o acesso à localização.';

  @override
  String get activityLocationServiceDisabled =>
      'Os serviços de localização estão desativados.';

  @override
  String get activityLocationStreamFailed =>
      'As atualizações de localização pararam inesperadamente.';

  @override
  String get activityGpxGenerationFailed =>
      'Não foi possível criar o ficheiro GPX da atividade.';

  @override
  String get activityLocalSaveFailed =>
      'Não foi possível guardar esta atividade neste dispositivo.';

  @override
  String get activityOpenSettings => 'Abrir definições';

  @override
  String get activityPause => 'Pausar';

  @override
  String get activityRecordingEmpty => 'Não foram gravados pontos GPS.';

  @override
  String get activityRecordingFailed => 'A gravação falhou.';

  @override
  String get activityResume => 'Retomar';

  @override
  String get activityRetryUpload => 'Tentar envio novamente';

  @override
  String get activityDone => 'Concluído';

  @override
  String get activityViewHistory => 'Ver histórico';

  @override
  String get activityDeleteLocal => 'Apagar cópia local';

  @override
  String get activityExportGpx => 'Partilhar ficheiro GPX';

  @override
  String get activityExportGpxSubject => 'Atividade Endurain GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Apagar atividade local?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Isto remove o registo local da atividade e o ficheiro GPX deste dispositivo.';

  @override
  String get activityStart => 'Iniciar';

  @override
  String get activityBackgroundPermissionTitle =>
      'Permitir rastreamento em segundo plano?';

  @override
  String get activityBackgroundPermissionMessage =>
      'O Endurain precisa da localização em segundo plano definida como Sempre para continuar a gravar quando a app fica em segundo plano, o ecrã está bloqueado ou muda para outra app.';

  @override
  String get activityBackgroundPermissionContinue => 'Continuar';

  @override
  String get activityBackgroundPermissionRequired =>
      'O rastreamento em segundo plano no iPhone e iPad precisa de Localização definida como Sempre.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Rastreamento em segundo plano desativado';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Para gravar de forma fiável em segundo plano ou com o ecrã bloqueado, abra as Definições e defina a Localização como Sempre para o Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'A gravar atividade';

  @override
  String get activityTrackingNotificationText =>
      'O Endurain está a registar a sua localização para gravar esta atividade.';

  @override
  String get activityStatDistance => 'Distância';

  @override
  String get activityStatDuration => 'Tempo';

  @override
  String get activityStatSpeed => 'Velocidade';

  @override
  String get activityStatPace => 'Ritmo';

  @override
  String get activityStatMaxSpeed => 'Velocidade máxima';

  @override
  String get activityStatElevationGain => 'Ganho de elevação';

  @override
  String get activityStatHeartRate => 'Frequência cardíaca';

  @override
  String get activityStatAvgHeartRate => 'FC média';

  @override
  String get activityStatPower => 'Potência';

  @override
  String get activityStatAvgPower => 'Potência média';

  @override
  String get activityStatCadence => 'Cadência';

  @override
  String get activityStatAvgCadence => 'Cadência média';

  @override
  String get activityStop => 'Parar';

  @override
  String get activityStopAndSave => 'Parar e guardar';

  @override
  String get activityStopConfirmMessage =>
      'Escolha se pretende guardar esta gravação ou descartá-la.';

  @override
  String get activityStopConfirmTitle => 'Terminar atividade?';

  @override
  String get activityStopping => 'A parar';

  @override
  String get activityTypeHike => 'Caminhada';

  @override
  String get activityTypeLabel => 'Tipo de atividade';

  @override
  String get activityTypeOther => 'Outra';

  @override
  String get activityTypeRide => 'Ciclismo';

  @override
  String get activityTypeRun => 'Corrida';

  @override
  String get activityTypeWalk => 'Passeio';

  @override
  String get activityUploadFailed => 'Falha no envio';

  @override
  String get activityUploadCleanupFailed => 'Enviado, mas a limpeza falhou';

  @override
  String get activityUploadReady => 'Pronto para enviar';

  @override
  String get activityUploaded => 'Enviado';

  @override
  String get activityUploading => 'A enviar';

  @override
  String get activityUploadStatusPending => 'Pendente';

  @override
  String get activityUploadStatusUploaded => 'Enviado';

  @override
  String get activityUploadStatusFailed => 'Falhou';

  @override
  String get activityHistoryTitle => 'Histórico de atividades';

  @override
  String get activityHistorySettingsSubtitle =>
      'Atividades concluídas guardadas neste dispositivo';

  @override
  String get activityRetainUploadedGpx => 'Manter ficheiros GPX enviados';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Guarda ficheiros de percurso concluídos no armazenamento privado da app depois do envio.';

  @override
  String get activityHistoryEmpty =>
      'Não há atividades concluídas guardadas neste dispositivo.';

  @override
  String get activityHistoryLoadFailed =>
      'Não foi possível carregar atividades locais.';

  @override
  String get activityHistoryRefresh => 'Atualizar';

  @override
  String get activityHistoryLocalActivities => 'Atividades locais';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Duração: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distância: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Envio: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Carregar mais';

  @override
  String get activityHistoryDetailsTitle => 'Detalhes da atividade';

  @override
  String get activityHistoryDetailsMissing =>
      'Esta atividade local já não está disponível.';

  @override
  String get activityHistorySummary => 'Resumo';

  @override
  String get activityHistoryActions => 'Ações';

  @override
  String get activityHistoryType => 'Tipo';

  @override
  String get activityHistoryStartedAt => 'Início';

  @override
  String get activityHistoryEndedAt => 'Fim';

  @override
  String get activityHistoryDurationLabel => 'Duração';

  @override
  String get activityHistoryDistanceLabel => 'Distância';

  @override
  String get activityHistoryAverageSpeed => 'Velocidade média';

  @override
  String get activityHistoryPointCount => 'Pontos GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Envio';

  @override
  String get activityHistoryGpxStatus => 'Ficheiro GPX';

  @override
  String get activityHistoryGpxAvailable => 'Guardado neste dispositivo';

  @override
  String get activityHistoryGpxMissing => 'Não disponível neste dispositivo';

  @override
  String get mapTab => 'Mapa';

  @override
  String get myLocation => 'A minha localização';

  @override
  String get settingsTab => 'Configurações';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® é uma marca registada de João Vitória Silva';

  @override
  String get settingsScreen => 'Configurações';

  @override
  String get deviceAccessTitle => 'Acesso ao dispositivo';

  @override
  String get deviceAccessSubtitle =>
      'Gerencie o acesso à localização e aos dados de saúde';

  @override
  String get deviceAccessLocationSection => 'Localização';

  @override
  String get deviceAccessHealthSection => 'Dados de saúde';

  @override
  String get deviceAccessLocationTitle => 'Acesso à localização';

  @override
  String get deviceAccessHealthTitle => 'Acesso aos dados de saúde';

  @override
  String get deviceAccessChecking => 'Verificando o acesso…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Os serviços de localização estão desativados';

  @override
  String get deviceAccessLocationAlways => 'Permitido o tempo todo';

  @override
  String get deviceAccessLocationWhileUsing => 'Permitido ao usar o aplicativo';

  @override
  String get deviceAccessLocationBlocked =>
      'Bloqueado nas configurações do sistema';

  @override
  String get deviceAccessLocationNotAllowed => 'Não permitido';

  @override
  String get deviceAccessHealthUnavailable =>
      'Não disponível neste dispositivo';

  @override
  String get deviceAccessHealthRequired => 'O Health Connect é necessário';

  @override
  String get deviceAccessHealthSetUp => 'Acesso à saúde configurado';

  @override
  String get deviceAccessHealthNeedsAttention => 'O acesso precisa de atenção';

  @override
  String get deviceAccessHealthNotConnected => 'Não conectado';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystemDefault => 'Predefinição do sistema';

  @override
  String get serverSettings => 'Servidor';

  @override
  String get signInConnectServer => 'Iniciar sessão';

  @override
  String get signInConnectServerSubtitle =>
      'Registe offline agora e sincronize as suas atividades mais tarde';

  @override
  String get serverSettingsTitle => 'Definições do servidor';

  @override
  String connectedToServer(String server) {
    return 'Ligado a $server';
  }

  @override
  String get loggedIn => 'Autenticado';

  @override
  String get notConfigured => 'Não configurado';

  @override
  String get notLoggedIn => 'Sem sessão iniciada';

  @override
  String get serverUrl => 'URL do servidor';

  @override
  String get serverProtocol => 'Protocolo';

  @override
  String get serverUrlHint => 'exemplo.com';

  @override
  String get warnHttpServerUrlTitle => 'Ligação não segura';

  @override
  String get warnHttpServerUrlMessage =>
      'O URL do servidor utiliza HTTP simples. As suas credenciais e dados serão transmitidos sem encriptação. Continue apenas se compreender e aceitar o risco.';

  @override
  String get warnHttpServerUrlConfirm => 'Continuar mesmo assim';

  @override
  String get tileServerUrl => 'URL do servidor de mapas';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle =>
      'Host do servidor de tiles diferente';

  @override
  String get tileServerHostWarningMessage =>
      'O host do servidor de tiles é diferente do host do servidor Endurain. Os tiles serão carregados de um servidor externo. Deseja continuar?';

  @override
  String get savedSuccessfully => 'Definições guardadas com sucesso';

  @override
  String get diagnostics => 'Diagnóstico';

  @override
  String get diagnosticsSubtitle => 'Contexto local de falhas';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Não foi possível abrir a ligação';

  @override
  String get diagnosticsTitle => 'Diagnóstico';

  @override
  String get diagnosticsCollection => 'Recolha';

  @override
  String get diagnosticsEnable => 'Recolher diagnósticos';

  @override
  String get diagnosticsEnableSubtitle =>
      'Guardar os eventos e erros recentes da aplicação neste dispositivo';

  @override
  String get diagnosticsDisabled =>
      'A recolha de diagnósticos está desativada. Ative-a para começar a registar eventos e erros da aplicação neste dispositivo.';

  @override
  String get diagnosticsEmpty => 'Ainda não foi capturado nenhum diagnóstico.';

  @override
  String get diagnosticsCopy => 'Copiar';

  @override
  String get diagnosticsCopied => 'Diagnóstico copiado';

  @override
  String get diagnosticsClear => 'Limpar';

  @override
  String get diagnosticsCleared => 'Diagnóstico limpo';

  @override
  String get diagnosticsSummary => 'Resumo';

  @override
  String get diagnosticsLastUpdated => 'Última atualização';

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
  String get diagnosticsNoEvents => 'Nenhum evento capturado';

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
  String get diagnosticsActions => 'Ações';

  @override
  String get diagnosticsRawReport => 'Relatório bruto';

  @override
  String get healthSyncSettingsTitle => 'Sincronização de saúde';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importar treinos da plataforma de saúde';

  @override
  String get healthSyncScreenTitle => 'Sincronização de saúde';

  @override
  String get healthAccessScreenTitle => 'Acesso à saúde';

  @override
  String get healthAccessRequestedData => 'Dados solicitados';

  @override
  String get healthAccessWorkouts => 'Treinos';

  @override
  String get healthAccessWorkoutRoutes => 'Rotas de treino';

  @override
  String get healthAccessHeartRate => 'Frequência cardíaca';

  @override
  String get healthAccessWorkoutSummary =>
      'Distância, calorias e passos do treino';

  @override
  String get healthAccessAllowed => 'Permitido';

  @override
  String get healthAccessNeedsAttention => 'Requer atenção';

  @override
  String get healthAccessManagedBySystem => 'Gerido nas definições do sistema';

  @override
  String get healthAccessSystemManagedNotice =>
      'O HealthKit não revela que dados o Endurain pode ler. Reveja o acesso na app Saúde.';

  @override
  String get healthAccessReview => 'Rever acesso à saúde';

  @override
  String get healthAccessReviewIos => 'Como rever o acesso';

  @override
  String get healthAccessDisconnect => 'Desligar dados de saúde';

  @override
  String get healthAccessDisconnectTitle => 'Desligar os dados de saúde?';

  @override
  String get healthAccessDisconnectMessage =>
      'A importação automática e o histórico local de importações deste servidor serão repostos. As atividades existentes permanecem no histórico.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Abra a app Saúde, toque na sua fotografia de perfil e depois em Apps e Serviços. Selecione Endurain e atualize as categorias de dados.';

  @override
  String get healthSyncAuthorize => 'Ligar aos dados de saúde';

  @override
  String get healthSyncInstallProvider => 'Instalar Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'O Health Connect é necessário para sincronizar treinos. Instale-o para continuar.';

  @override
  String get healthSyncUnsupported =>
      'A sincronização de saúde não está disponível neste dispositivo.';

  @override
  String get healthSyncSelectAll => 'Selecionar tudo';

  @override
  String get healthSyncClearSelection => 'Limpar';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importar selecionados ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '$count treino(s) importado(s).';
  }

  @override
  String get healthSyncNoRouteLabel => 'Sem rota GPS';

  @override
  String get healthSyncEmptyState =>
      'Nenhum treino encontrado no período selecionado.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Alguns treinos foram ignorados porque o acesso às rotas de exercício não foi concedido. Abra o Health Connect → Permissões e autorize as rotas de exercício para o Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Alguns treinos foram ignorados porque o Endurain não conseguiu ler as respetivas rotas GPS. Na aplicação Saúde, abra o seu perfil, depois Apps e Serviços, selecione Endurain e autorize Rotas de treino.';

  @override
  String get healthSyncReviewAccess => 'Rever acessos';

  @override
  String get healthSyncAutoSyncTitle => 'Sincronizar ao abrir';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importar novos treinos automaticamente ao abrir a aplicação.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Estes treinos não incluem uma rota GPS, por isso não podem ser importados. Algumas aplicações (como o Garmin Connect) registam atividades no Apple Health sem partilhar a rota. Os treinos registados com o Apple Watch incluem rotas e podem ser importados.';

  @override
  String get healthSyncBadgeNonImportable => 'Não importável';

  @override
  String get healthSyncViewAvailable => 'Disponíveis';

  @override
  String get healthSyncViewImported => 'Importados';

  @override
  String get healthSyncDateRange => 'Período dos treinos';

  @override
  String get healthSyncRange30Days => 'Últimos 30 dias';

  @override
  String get healthSyncRange3Months => 'Últimos 3 meses';

  @override
  String get healthSyncRange6Months => 'Últimos 6 meses';

  @override
  String get healthSyncRangeYear => 'Último ano';

  @override
  String get healthSyncRangeAll => 'Todo o histórico';

  @override
  String get healthSyncRangeCustom => 'Período personalizado';

  @override
  String get healthSyncImportedEmpty =>
      'Nenhum treino importado para esta ligação.';

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
      'Monitores de frequência cardíaca e outros sensores externos';

  @override
  String get sensorsHeartRateSection => 'Frequência cardíaca';

  @override
  String get sensorsHeartRateHelp =>
      'Emparelhe um monitor de frequência cardíaca Bluetooth para ver a sua frequência cardíaca em tempo real.';

  @override
  String get sensorsBluetoothOff =>
      'O Bluetooth está desligado. Ligue-o para conectar um sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Permita o acesso ao Bluetooth para conectar um sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Este dispositivo não suporta Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Procurar sensores';

  @override
  String get sensorsScanning => 'A procurar…';

  @override
  String get sensorsStopScan => 'Parar';

  @override
  String get sensorsNoDevices =>
      'Ainda não foram encontrados sensores de frequência cardíaca.';

  @override
  String get sensorsAvailableSection => 'Sensores disponíveis';

  @override
  String get sensorsSavedSection => 'Sensor guardado';

  @override
  String get sensorsConnect => 'Conectar';

  @override
  String get sensorsConnecting => 'A conectar…';

  @override
  String get sensorsConnected => 'Conectado';

  @override
  String get sensorsDisconnect => 'Desconectar';

  @override
  String get sensorsForget => 'Esquecer';

  @override
  String get sensorsConnectionFailed =>
      'Não foi possível conectar. Tente novamente.';

  @override
  String get sensorsPermissionRequired =>
      'É necessária permissão de Bluetooth para encontrar sensores.';

  @override
  String get sensorsUnknownDevice => 'Sensor desconhecido';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Potência';

  @override
  String get sensorsPowerHelp =>
      'Emparelhe um medidor de potência Bluetooth para ver a sua potência em tempo real.';

  @override
  String get sensorsNoPowerDevices =>
      'Ainda não foram encontrados medidores de potência.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadência';

  @override
  String get sensorsCadenceHelp =>
      'Emparelhe um sensor de cadência Bluetooth para ver a sua cadência em tempo real.';

  @override
  String get sensorsNoCadenceDevices =>
      'Ainda não foram encontrados sensores de cadência.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Relatórios de falhas remotos';

  @override
  String get diagnosticsRemoteEnable => 'Enviar relatórios de falhas';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Enviar relatórios de falhas e de erros para um servidor de diagnóstico. É independente do diagnóstico local; pode ativar ambos, um ou nenhum.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'O relatório remoto de falhas não está disponível nesta versão.';

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
  String get unitsSubtitle => 'Unidades de distância, velocidade e altitude';

  @override
  String get unitsSystemDefault => 'Seguir região do dispositivo';

  @override
  String get unitsMetric => 'Métrico (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'O servidor tentou redirecionar para uma ligação insegura. O pedido foi bloqueado para proteger as suas credenciais.';

  @override
  String get errorTooManyRedirects =>
      'O servidor redirecionou demasiadas vezes. Verifique o endereço do servidor.';

  @override
  String get audioAnnouncementsTitle => 'Anúncios de voz';

  @override
  String get audioAnnouncementsSubtitle =>
      'Atualizações de voz sobre distância, tempo, ritmo ou velocidade';

  @override
  String get audioAnnouncementsMasterSwitch =>
      'Anunciar o progresso da atividade';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Diz em voz alta a sua distância, tempo, ritmo ou velocidade durante uma gravação';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Reduzir outro áudio durante a fala';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Reduz temporariamente o volume de outro áudio durante cada anúncio';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Intervalo de anúncio por atividade';

  @override
  String get audioAnnouncementsByDistance => 'Distância';

  @override
  String get audioAnnouncementsByTime => 'Tempo';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'A cada $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'A cada $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Diminuir intervalo';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Aumentar intervalo';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Distância $distance. Tempo $duration. Volta: $lapMetric. Total: $overallMetric.';
  }
}
