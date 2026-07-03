// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get error => 'Errore';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get back => 'Indietro';

  @override
  String get requiredField => 'Questo campo è obbligatorio';

  @override
  String get invalidUrl => 'Inserisci un URL valido';

  @override
  String get errorActivityUploadFailed => 'Impossibile caricare l\'attività';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Impossibile caricare l\'attività: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Il caricamento delle attività non è ancora configurato';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Impossibile eliminare il file temporaneo dell\'attività';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Impossibile preparare il file di caricamento dell\'attività';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Impossibile trovare questa attività locale';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Impossibile eliminare l\'attività locale';

  @override
  String get errorActivityLocalGpxMissing =>
      'Il file GPX locale non è disponibile';

  @override
  String get errorActivityLocalLoadFailed =>
      'Impossibile caricare le attività locali';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Impossibile salvare questa attività';

  @override
  String get errorActivityLocalSaveFailed =>
      'Impossibile salvare l\'attività localmente';

  @override
  String get errorFetchProvidersFailed =>
      'Impossibile caricare i provider di accesso';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Impossibile caricare i provider di accesso: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Impossibile caricare le impostazioni del server';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Impossibile caricare le impostazioni del server: $details';
  }

  @override
  String get errorLoginError => 'Impossibile accedere';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Impossibile accedere: $details';
  }

  @override
  String get errorLoginFailed => 'Accesso non riuscito';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Accesso non riuscito: $details';
  }

  @override
  String get errorMfaVerificationError =>
      'Impossibile verificare il codice MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Impossibile verificare il codice MFA: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Verifica MFA non riuscita';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Verifica MFA non riuscita: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Nessun ID di sessione ricevuto dal server';

  @override
  String get errorNotAuthenticated => 'Non hai effettuato l\'accesso';

  @override
  String get errorPkceVerifierMissing => 'Verificatore di accesso non trovato';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Verificatore di accesso non trovato. Riavvia l\'accesso.';

  @override
  String get errorServerUrlNotConfigured =>
      'L\'URL del server non è configurato';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Questo server richiede una connessione sicura (HTTPS)';

  @override
  String get errorSessionExpired =>
      'La tua sessione è scaduta. Effettua di nuovo l\'accesso.';

  @override
  String get errorSsoTokenExchangeError =>
      'Impossibile completare l\'accesso SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Impossibile completare l\'accesso SSO: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Scambio di token non riuscito';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Scambio di token non riuscito: $details';
  }

  @override
  String get errorRequestTimeout =>
      'La richiesta è scaduta. Controlla la connessione e riprova.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Impossibile eliminare dall\'archivio sicuro. L\'archivio del dispositivo potrebbe non essere disponibile.';

  @override
  String get errorSecureStorageReadFailed =>
      'Impossibile leggere dall\'archivio sicuro. L\'archivio del dispositivo potrebbe non essere disponibile.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Impossibile scrivere nell\'archivio sicuro. L\'archivio del dispositivo potrebbe non essere disponibile.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Il server ha restituito una risposta imprevista';

  @override
  String get errorUnsupportedHttpMethod => 'Metodo HTTP non supportato';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Metodo HTTP non supportato: $details';
  }

  @override
  String get loginTitle => 'Accesso';

  @override
  String get login => 'Accedi';

  @override
  String get logout => 'Esci';

  @override
  String get logoutConfirmTitle => 'Esci';

  @override
  String get logoutConfirmMessage => 'Vuoi davvero uscire?';

  @override
  String get logoutServerFailedWarning =>
      'Impossibile uscire dal server, ma disconnessione locale effettuata';

  @override
  String get ssoBrowserLaunchFailed =>
      'Impossibile aprire l\'accesso SSO nel browser di sistema';

  @override
  String get ssoMissingSessionId =>
      'La risposta SSO non conteneva un ID di sessione';

  @override
  String ssoSignInWith(String provider) {
    return 'Accedi con $provider';
  }

  @override
  String get ssoOrDivider => 'OPPURE';

  @override
  String get next => 'Avanti';

  @override
  String get username => 'Nome utente';

  @override
  String get usernameHint => 'Inserisci il tuo nome utente';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Inserisci la tua password';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get mfaTitle => 'Autenticazione a due fattori';

  @override
  String get mfaCode => 'Codice MFA';

  @override
  String get mfaCodeHint => 'Inserisci il codice a 6 cifre';

  @override
  String get mfaCodeRequired => 'Inserisci il codice MFA';

  @override
  String get verify => 'Verifica';

  @override
  String get activityDiscard => 'Elimina';

  @override
  String get activityDiscardConfirmMessage =>
      'Questo eliminerà i punti registrati di questa attività.';

  @override
  String get activityDiscardConfirmTitle => 'Eliminare l\'attività?';

  @override
  String get activityLocationPermissionDenied =>
      'L\'autorizzazione alla posizione è necessaria per registrare un\'attività.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'L\'autorizzazione alla posizione è bloccata. Apri le impostazioni per consentire l\'accesso alla posizione.';

  @override
  String get activityLocationServiceDisabled =>
      'I servizi di localizzazione sono disattivati.';

  @override
  String get activityLocationStreamFailed =>
      'Gli aggiornamenti della posizione si sono interrotti in modo imprevisto.';

  @override
  String get activityGpxGenerationFailed =>
      'Impossibile creare il file GPX dell\'attività.';

  @override
  String get activityLocalSaveFailed =>
      'Impossibile salvare questa attività su questo dispositivo.';

  @override
  String get activityOpenSettings => 'Apri impostazioni';

  @override
  String get activityPause => 'Pausa';

  @override
  String get activityRecordingEmpty => 'Nessun punto GPS registrato.';

  @override
  String get activityRecordingFailed => 'Registrazione non riuscita.';

  @override
  String get activityResume => 'Riprendi';

  @override
  String get activityRetryUpload => 'Riprova caricamento';

  @override
  String get activityDone => 'Fatto';

  @override
  String get activityViewHistory => 'Visualizza cronologia';

  @override
  String get activityDeleteLocal => 'Elimina copia locale';

  @override
  String get activityExportGpx => 'Condividi file GPX';

  @override
  String get activityExportGpxSubject => 'GPX attività Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Eliminare l\'attività locale?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Questo rimuove il record dell\'attività locale e il file GPX da questo dispositivo.';

  @override
  String get activityStart => 'Avvia';

  @override
  String get activityBackgroundPermissionTitle =>
      'Consentire il tracciamento in background?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain necessita della posizione in background impostata su Sempre affinché la registrazione continui quando l\'app è in background, lo schermo è bloccato o cambi app.';

  @override
  String get activityBackgroundPermissionContinue => 'Continua';

  @override
  String get activityBackgroundPermissionRequired =>
      'Il tracciamento in background su iPhone e iPad richiede la posizione impostata su Sempre.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Il tracciamento in background è disattivato';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Per registrare in modo affidabile in background o con lo schermo bloccato, apri Impostazioni e imposta la Posizione su Sempre per Endurain.';

  @override
  String get activityTrackingNotificationTitle =>
      'Registrazione dell\'attività';

  @override
  String get activityTrackingNotificationText =>
      'Endurain sta tracciando la tua posizione per registrare questa attività.';

  @override
  String get activityStatDistance => 'Distanza';

  @override
  String get activityStatDuration => 'Tempo';

  @override
  String get activityStatSpeed => 'Velocità';

  @override
  String get activityStop => 'Ferma';

  @override
  String get activityStopAndSave => 'Ferma e salva';

  @override
  String get activityStopConfirmMessage =>
      'Scegli se conservare questa registrazione o eliminarla.';

  @override
  String get activityStopConfirmTitle => 'Terminare l\'attività?';

  @override
  String get activityStopping => 'Arresto in corso';

  @override
  String get activityTypeHike => 'Escursione';

  @override
  String get activityTypeLabel => 'Tipo di attività';

  @override
  String get activityTypeOther => 'Altro';

  @override
  String get activityTypeRide => 'Bici';

  @override
  String get activityTypeRun => 'Corsa';

  @override
  String get activityTypeWalk => 'Camminata';

  @override
  String get activityUploadFailed => 'Caricamento non riuscito';

  @override
  String get activityUploadCleanupFailed => 'Caricato, ma pulizia non riuscita';

  @override
  String get activityUploadReady => 'Pronto per il caricamento';

  @override
  String get activityUploaded => 'Caricato';

  @override
  String get activityUploading => 'Caricamento in corso';

  @override
  String get activityUploadStatusPending => 'In attesa';

  @override
  String get activityUploadStatusUploaded => 'Caricato';

  @override
  String get activityUploadStatusFailed => 'Non riuscito';

  @override
  String get activityHistoryTitle => 'Cronologia attività';

  @override
  String get activityHistorySettingsSubtitle =>
      'Attività completate salvate su questo dispositivo';

  @override
  String get activityRetainUploadedGpx => 'Conserva i file GPX caricati';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Salva i file di percorso completati nell\'archivio privato dell\'app dopo il caricamento.';

  @override
  String get activityHistoryEmpty =>
      'Nessuna attività completata salvata su questo dispositivo.';

  @override
  String get activityHistoryLoadFailed =>
      'Impossibile caricare le attività locali.';

  @override
  String get activityHistoryRefresh => 'Aggiorna';

  @override
  String get activityHistoryLocalActivities => 'Attività locali';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Durata: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distanza: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Caricamento: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Carica altro';

  @override
  String get activityHistoryDetailsTitle => 'Dettagli attività';

  @override
  String get activityHistoryDetailsMissing =>
      'Questa attività locale non è più disponibile.';

  @override
  String get activityHistorySummary => 'Riepilogo';

  @override
  String get activityHistoryActions => 'Azioni';

  @override
  String get activityHistoryType => 'Tipo';

  @override
  String get activityHistoryStartedAt => 'Inizio';

  @override
  String get activityHistoryEndedAt => 'Fine';

  @override
  String get activityHistoryDurationLabel => 'Durata';

  @override
  String get activityHistoryDistanceLabel => 'Distanza';

  @override
  String get activityHistoryAverageSpeed => 'Velocità media';

  @override
  String get activityHistoryPointCount => 'Punti GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Caricamento';

  @override
  String get activityHistoryGpxStatus => 'File GPX';

  @override
  String get activityHistoryGpxAvailable => 'Salvato su questo dispositivo';

  @override
  String get activityHistoryGpxMissing =>
      'Non disponibile su questo dispositivo';

  @override
  String get mapTab => 'Mappa';

  @override
  String get myLocation => 'La mia posizione';

  @override
  String get settingsTab => 'Impostazioni';

  @override
  String get settingsScreen => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystemDefault => 'Predefinita del sistema';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Accedi';

  @override
  String get signInConnectServerSubtitle =>
      'Registra offline ora e sincronizza le tue attività più tardi';

  @override
  String get serverSettingsTitle => 'Impostazioni del server';

  @override
  String get loggedIn => 'Connesso';

  @override
  String get notConfigured => 'Non configurato';

  @override
  String get notLoggedIn => 'Non connesso';

  @override
  String get serverUrl => 'URL del server';

  @override
  String get serverUrlHint => 'https://esempio.com';

  @override
  String get warnHttpServerUrlTitle => 'Connessione non sicura';

  @override
  String get warnHttpServerUrlMessage =>
      'Questo URL del server usa HTTP non cifrato. Le tue credenziali e i tuoi dati saranno trasmessi senza crittografia. Continua solo se comprendi e accetti il rischio.';

  @override
  String get warnHttpServerUrlConfirm => 'Continua comunque';

  @override
  String get tileServerUrl => 'URL del server dei tasselli della mappa';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle =>
      'Host del server dei tasselli diverso';

  @override
  String get tileServerHostWarningMessage =>
      'L\'host del server dei tasselli è diverso dall\'host del tuo server Endurain. I tasselli saranno caricati da un server di terze parti. Vuoi continuare?';

  @override
  String get savedSuccessfully => 'Impostazioni salvate correttamente';

  @override
  String get diagnostics => 'Diagnostica';

  @override
  String get diagnosticsSubtitle => 'Contesto locale degli arresti anomali';

  @override
  String get sourceCode => 'Codice sorgente';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Impossibile aprire il collegamento';

  @override
  String get diagnosticsTitle => 'Diagnostica';

  @override
  String get diagnosticsCollection => 'Raccolta';

  @override
  String get diagnosticsEnable => 'Raccogli diagnostica';

  @override
  String get diagnosticsEnableSubtitle =>
      'Memorizza gli eventi e gli errori recenti dell\'app su questo dispositivo';

  @override
  String get diagnosticsDisabled =>
      'La raccolta della diagnostica è disattivata. Attivala per iniziare a registrare eventi ed errori dell\'app su questo dispositivo.';

  @override
  String get diagnosticsEmpty => 'Nessun dato diagnostico ancora acquisito.';

  @override
  String get diagnosticsCopy => 'Copia';

  @override
  String get diagnosticsCopied => 'Diagnostica copiata';

  @override
  String get diagnosticsClear => 'Cancella';

  @override
  String get diagnosticsCleared => 'Diagnostica cancellata';

  @override
  String get diagnosticsSummary => 'Riepilogo';

  @override
  String get diagnosticsLastUpdated => 'Ultimo aggiornamento';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Eventi: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Errori: $count';
  }

  @override
  String get diagnosticsEvents => 'Eventi';

  @override
  String get diagnosticsNoEvents => 'Nessun evento acquisito';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Evento: $event';
  }

  @override
  String get diagnosticsErrors => 'Errori';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Errore: $type';
  }

  @override
  String get diagnosticsActions => 'Azioni';

  @override
  String get diagnosticsRawReport => 'Report non elaborato';
}
