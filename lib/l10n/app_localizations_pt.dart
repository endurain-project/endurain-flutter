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
  String get errorPkceVerifierMissing =>
      'O verificador de login não foi encontrado';

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
  String get loginTitle => 'Login';

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
  String get ssoMissingSessionId =>
      'O retorno do SSO não incluiu um ID de sessão';

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
  String get settingsScreen => 'Configurações';

  @override
  String get serverSettings => 'Servidor';

  @override
  String get serverSettingsTitle => 'Definições do servidor';

  @override
  String get loggedIn => 'Autenticado';

  @override
  String get notConfigured => 'Não configurado';

  @override
  String get notLoggedIn => 'Sem sessão iniciada';

  @override
  String get serverUrl => 'URL do servidor';

  @override
  String get serverUrlHint => 'https://example.com';

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
  String get diagnosticsTitle => 'Diagnóstico';

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
}
