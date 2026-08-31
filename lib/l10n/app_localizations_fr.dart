// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get error => 'Erreur';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get back => 'Retour';

  @override
  String get requiredField => 'Ce champ est obligatoire';

  @override
  String get invalidUrl => 'Veuillez saisir une URL valide';

  @override
  String get errorActivityUploadFailed => 'Impossible d\'envoyer l\'activité';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Impossible d\'envoyer l\'activité : $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'L\'envoi d\'activités n\'est pas encore configuré';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Impossible de supprimer le fichier temporaire de l\'activité';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Impossible de préparer le fichier d\'envoi de l\'activité';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Impossible de trouver cette activité locale';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Impossible de supprimer l\'activité locale';

  @override
  String get errorActivityLocalGpxMissing =>
      'Le fichier GPX local n\'est pas disponible';

  @override
  String get errorActivityLocalLoadFailed =>
      'Impossible de charger les activités locales';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Impossible d\'enregistrer cette activité';

  @override
  String get errorActivityLocalSaveFailed =>
      'Impossible d\'enregistrer l\'activité localement';

  @override
  String get errorFetchProvidersFailed =>
      'Impossible de charger les fournisseurs de connexion';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Impossible de charger les fournisseurs de connexion : $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Impossible de charger les paramètres du serveur';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Impossible de charger les paramètres du serveur : $details';
  }

  @override
  String get errorHealthGpxBuildFailed =>
      'Impossible de convertir l\'entraînement en GPX';

  @override
  String get errorHealthImportFailed =>
      'Impossible d\'importer l\'entraînement';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Impossible d\'importer l\'entraînement : $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'L\'accès aux données de santé a été refusé';

  @override
  String get errorHealthReadFailed => 'Impossible de lire les données de santé';

  @override
  String get errorLoginError => 'Impossible de se connecter';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Impossible de se connecter : $details';
  }

  @override
  String get errorLoginFailed => 'Échec de la connexion';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Échec de la connexion : $details';
  }

  @override
  String get errorMfaVerificationError => 'Impossible de vérifier le code MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Impossible de vérifier le code MFA : $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Échec de la vérification MFA';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Échec de la vérification MFA : $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Aucun identifiant de session n\'a été reçu du serveur';

  @override
  String get errorNotAuthenticated => 'Vous n\'êtes pas connecté';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Le vérificateur de connexion est introuvable. Veuillez recommencer la connexion.';

  @override
  String get errorServerUrlNotConfigured =>
      'L\'URL du serveur n\'est pas configurée';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Ce serveur nécessite une connexion sécurisée (HTTPS)';

  @override
  String get errorSessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get errorSsoTokenExchangeError =>
      'Impossible de terminer la connexion SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Impossible de terminer la connexion SSO : $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Échec de l\'échange de jetons';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Échec de l\'échange de jetons : $details';
  }

  @override
  String get errorRequestTimeout =>
      'La requête a expiré. Vérifiez votre connexion et réessayez.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Impossible de supprimer du stockage sécurisé. Le stockage de l\'appareil est peut-être indisponible.';

  @override
  String get errorSecureStorageReadFailed =>
      'Impossible de lire depuis le stockage sécurisé. Le stockage de l\'appareil est peut-être indisponible.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Impossible d\'écrire dans le stockage sécurisé. Le stockage de l\'appareil est peut-être indisponible.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Le serveur a renvoyé une réponse inattendue';

  @override
  String get errorUnsupportedHttpMethod => 'Méthode HTTP non prise en charge';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Méthode HTTP non prise en charge : $details';
  }

  @override
  String get loginTitle => 'Connexion';

  @override
  String get login => 'Se connecter';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirmTitle => 'Se déconnecter';

  @override
  String get logoutConfirmMessage => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get logoutServerFailedWarning =>
      'Impossible de se déconnecter du serveur, mais déconnexion locale effectuée';

  @override
  String get ssoBrowserLaunchFailed =>
      'Impossible d\'ouvrir la connexion SSO dans le navigateur système';

  @override
  String ssoSignInWith(String provider) {
    return 'Se connecter avec $provider';
  }

  @override
  String get ssoOrDivider => 'OU';

  @override
  String get next => 'Suivant';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get usernameHint => 'Saisissez votre nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHint => 'Saisissez votre mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get mfaTitle => 'Authentification à deux facteurs';

  @override
  String get mfaCode => 'Code MFA';

  @override
  String get mfaCodeHint => 'Saisissez le code à 6 chiffres';

  @override
  String get mfaCodeRequired => 'Veuillez saisir le code MFA';

  @override
  String get verify => 'Vérifier';

  @override
  String get activityDiscard => 'Ignorer';

  @override
  String get activityDiscardConfirmMessage =>
      'Cela supprimera les points enregistrés de cette activité.';

  @override
  String get activityDiscardConfirmTitle => 'Ignorer l\'activité ?';

  @override
  String get activityLocationPermissionDenied =>
      'L\'autorisation de localisation est requise pour enregistrer une activité.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'L\'autorisation de localisation est bloquée. Ouvrez les réglages pour autoriser l\'accès à la localisation.';

  @override
  String get activityLocationServiceDisabled =>
      'Les services de localisation sont désactivés.';

  @override
  String get activityLocationStreamFailed =>
      'Les mises à jour de localisation se sont arrêtées de façon inattendue.';

  @override
  String get activityGpxGenerationFailed =>
      'Impossible de créer le fichier GPX de l\'activité.';

  @override
  String get activityLocalSaveFailed =>
      'Impossible d\'enregistrer cette activité sur cet appareil.';

  @override
  String get activityOpenSettings => 'Ouvrir les réglages';

  @override
  String get activityPause => 'Pause';

  @override
  String get activityRecordingEmpty => 'Aucun point GPS n\'a été enregistré.';

  @override
  String get activityRecordingFailed => 'Échec de l\'enregistrement.';

  @override
  String get activityResume => 'Reprendre';

  @override
  String get activityRetryUpload => 'Réessayer l\'envoi';

  @override
  String get activityDone => 'Terminé';

  @override
  String get activityViewHistory => 'Voir l\'historique';

  @override
  String get activityDeleteLocal => 'Supprimer la copie locale';

  @override
  String get activityExportGpx => 'Partager le fichier GPX';

  @override
  String get activityExportGpxSubject => 'GPX d\'activité Endurain';

  @override
  String get activityDeleteLocalConfirmTitle =>
      'Supprimer l\'activité locale ?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Cela supprime l\'enregistrement de l\'activité locale et le fichier GPX de cet appareil.';

  @override
  String get activityStart => 'Démarrer';

  @override
  String get activityBackgroundPermissionTitle =>
      'Autoriser le suivi en arrière-plan ?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain a besoin de la localisation en arrière-plan réglée sur Toujours pour que l\'enregistrement continue lorsque l\'application est en arrière-plan, que l\'écran est verrouillé ou que vous changez d\'application.';

  @override
  String get activityBackgroundPermissionContinue => 'Continuer';

  @override
  String get activityBackgroundPermissionRequired =>
      'Le suivi en arrière-plan sur iPhone et iPad nécessite la localisation réglée sur Toujours.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Le suivi en arrière-plan est désactivé';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Pour enregistrer de façon fiable en arrière-plan ou écran verrouillé, ouvrez les Réglages et réglez la Localisation sur Toujours pour Endurain.';

  @override
  String get activityTrackingNotificationTitle =>
      'Enregistrement de l\'activité';

  @override
  String get activityTrackingNotificationText =>
      'Endurain suit votre position pour enregistrer cette activité.';

  @override
  String get activityStatDistance => 'Distance';

  @override
  String get activityStatDuration => 'Temps';

  @override
  String get activityStatSpeed => 'Vitesse';

  @override
  String get activityStatPace => 'Allure';

  @override
  String get activityStatMaxSpeed => 'Vitesse max.';

  @override
  String get activityStatElevationGain => 'Dénivelé positif';

  @override
  String get activityStatHeartRate => 'Fréquence cardiaque';

  @override
  String get activityStatAvgHeartRate => 'Fréquence cardiaque moy.';

  @override
  String get activityStatPower => 'Puissance';

  @override
  String get activityStatAvgPower => 'Puissance moy.';

  @override
  String get activityStatCadence => 'Cadence';

  @override
  String get activityStatAvgCadence => 'Cadence moy.';

  @override
  String get activityStop => 'Arrêter';

  @override
  String get activityStopAndSave => 'Arrêter et enregistrer';

  @override
  String get activityStopConfirmMessage =>
      'Choisissez de conserver cet enregistrement ou de l\'ignorer.';

  @override
  String get activityStopConfirmTitle => 'Terminer l\'activité ?';

  @override
  String get activityStopping => 'Arrêt en cours';

  @override
  String get activityTypeHike => 'Randonnée';

  @override
  String get activityTypeLabel => 'Type d\'activité';

  @override
  String get activityTypeOther => 'Autre';

  @override
  String get activityTypeRide => 'Vélo';

  @override
  String get activityTypeRun => 'Course';

  @override
  String get activityTypeWalk => 'Marche';

  @override
  String get activityUploadFailed => 'Échec de l\'envoi';

  @override
  String get activityUploadCleanupFailed =>
      'Envoyé, mais le nettoyage a échoué';

  @override
  String get activityUploadReady => 'Prêt à envoyer';

  @override
  String get activityUploaded => 'Envoyé';

  @override
  String get activityUploading => 'Envoi en cours';

  @override
  String get activityUploadStatusPending => 'En attente';

  @override
  String get activityUploadStatusUploaded => 'Envoyé';

  @override
  String get activityUploadStatusFailed => 'Échec';

  @override
  String get activityHistoryTitle => 'Historique des activités';

  @override
  String get activityHistorySettingsSubtitle =>
      'Activités terminées enregistrées sur cet appareil';

  @override
  String get activityRetainUploadedGpx => 'Conserver les fichiers GPX envoyés';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Enregistre les fichiers d\'itinéraire terminés dans le stockage privé de l\'application après l\'envoi.';

  @override
  String get activityHistoryEmpty =>
      'Aucune activité terminée enregistrée sur cet appareil.';

  @override
  String get activityHistoryLoadFailed =>
      'Impossible de charger les activités locales.';

  @override
  String get activityHistoryRefresh => 'Actualiser';

  @override
  String get activityHistoryLocalActivities => 'Activités locales';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Durée : $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Distance : $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Envoi : $status';
  }

  @override
  String get activityHistoryLoadMore => 'Charger plus';

  @override
  String get activityHistoryDetailsTitle => 'Détails de l\'activité';

  @override
  String get activityHistoryDetailsMissing =>
      'Cette activité locale n\'est plus disponible.';

  @override
  String get activityHistorySummary => 'Résumé';

  @override
  String get activityHistoryActions => 'Actions';

  @override
  String get activityHistoryType => 'Type';

  @override
  String get activityHistoryStartedAt => 'Début';

  @override
  String get activityHistoryEndedAt => 'Fin';

  @override
  String get activityHistoryDurationLabel => 'Durée';

  @override
  String get activityHistoryDistanceLabel => 'Distance';

  @override
  String get activityHistoryAverageSpeed => 'Vitesse moyenne';

  @override
  String get activityHistoryPointCount => 'Points GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Envoi';

  @override
  String get activityHistoryGpxStatus => 'Fichier GPX';

  @override
  String get activityHistoryGpxAvailable => 'Enregistré sur cet appareil';

  @override
  String get activityHistoryGpxMissing => 'Non disponible sur cet appareil';

  @override
  String get mapTab => 'Carte';

  @override
  String get myLocation => 'Ma position';

  @override
  String get settingsTab => 'Réglages';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® est une marque déposée de João Vitória Silva';

  @override
  String get settingsScreen => 'Réglages';

  @override
  String get deviceAccessTitle => 'Accès aux appareils';

  @override
  String get deviceAccessSubtitle =>
      'Gérer l\'accès aux données de localisation et de santé';

  @override
  String get deviceAccessLocationSection => 'Emplacement';

  @override
  String get deviceAccessHealthSection => 'Données de santé';

  @override
  String get deviceAccessLocationTitle => 'Accès à la localisation';

  @override
  String get deviceAccessHealthTitle => 'Accès aux données de santé';

  @override
  String get deviceAccessChecking => 'Vérification de l\'accès…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Les services de localisation sont désactivés';

  @override
  String get deviceAccessLocationAlways => 'Autorisé tout le temps';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Autorisé lors de l\'utilisation de l\'application';

  @override
  String get deviceAccessLocationBlocked =>
      'Bloqué dans les paramètres système';

  @override
  String get deviceAccessLocationNotAllowed => 'Non autorisé';

  @override
  String get deviceAccessHealthUnavailable => 'Non disponible sur cet appareil';

  @override
  String get deviceAccessHealthRequired => 'Connexion Santé est requis';

  @override
  String get deviceAccessHealthSetUp => 'Accès à la santé mis en place';

  @override
  String get deviceAccessHealthNeedsAttention =>
      'L’accès nécessite une attention particulière';

  @override
  String get deviceAccessHealthNotConnected => 'Non connecté';

  @override
  String get language => 'Langue';

  @override
  String get languageSystemDefault => 'Réglage du système';

  @override
  String get serverSettings => 'Serveur';

  @override
  String get signInConnectServer => 'Se connecter';

  @override
  String get signInConnectServerSubtitle =>
      'Enregistrez hors ligne maintenant et synchronisez vos activités plus tard';

  @override
  String get serverSettingsTitle => 'Paramètres du serveur';

  @override
  String connectedToServer(String server) {
    return 'Connecté à $server';
  }

  @override
  String get loggedIn => 'Connecté';

  @override
  String get notConfigured => 'Non configuré';

  @override
  String get notLoggedIn => 'Non connecté';

  @override
  String get serverUrl => 'URL du serveur';

  @override
  String get serverProtocol => 'Protocole';

  @override
  String get serverUrlHint => 'https://exemple.com';

  @override
  String get warnHttpServerUrlTitle => 'Connexion non sécurisée';

  @override
  String get warnHttpServerUrlMessage =>
      'Cette URL de serveur utilise du HTTP non chiffré. Vos identifiants et données seront transmis sans chiffrement. Continuez seulement si vous comprenez et acceptez le risque.';

  @override
  String get warnHttpServerUrlConfirm => 'Continuer quand même';

  @override
  String get tileServerUrl => 'URL du serveur de tuiles de la carte';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle =>
      'Hôte de serveur de tuiles différent';

  @override
  String get tileServerHostWarningMessage =>
      'L\'hôte du serveur de tuiles est différent de celui de votre serveur Endurain. Les tuiles seront chargées depuis un serveur tiers. Voulez-vous continuer ?';

  @override
  String get savedSuccessfully => 'Paramètres enregistrés avec succès';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get diagnosticsSubtitle => 'Contexte local des plantages';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Impossible d\'ouvrir le lien';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsCollection => 'Collecte';

  @override
  String get diagnosticsEnable => 'Collecter les diagnostics';

  @override
  String get diagnosticsEnableSubtitle =>
      'Stocker les événements et erreurs récents de l\'application sur cet appareil';

  @override
  String get diagnosticsDisabled =>
      'La collecte des diagnostics est désactivée. Activez-la pour commencer à capturer les événements et erreurs de l\'application sur cet appareil.';

  @override
  String get diagnosticsEmpty => 'Aucun diagnostic n\'a encore été capturé.';

  @override
  String get diagnosticsCopy => 'Copier';

  @override
  String get diagnosticsCopied => 'Diagnostics copiés';

  @override
  String get diagnosticsClear => 'Effacer';

  @override
  String get diagnosticsCleared => 'Diagnostics effacés';

  @override
  String get diagnosticsSummary => 'Résumé';

  @override
  String get diagnosticsLastUpdated => 'Dernière mise à jour';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Événements : $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Erreurs : $count';
  }

  @override
  String get diagnosticsEvents => 'Événements';

  @override
  String get diagnosticsNoEvents => 'Aucun événement capturé';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Événement : $event';
  }

  @override
  String get diagnosticsErrors => 'Erreurs';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Erreur : $type';
  }

  @override
  String get diagnosticsActions => 'Actions';

  @override
  String get diagnosticsRawReport => 'Rapport brut';

  @override
  String get healthSyncSettingsTitle => 'Synchronisation de la santé';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importez des entraînements depuis votre plateforme de santé';

  @override
  String get healthSyncScreenTitle => 'Synchronisation de la santé';

  @override
  String get healthAccessScreenTitle => 'Accès à la santé';

  @override
  String get healthAccessRequestedData => 'Données demandées';

  @override
  String get healthAccessWorkouts => 'Entraînements';

  @override
  String get healthAccessWorkoutRoutes => 'Itinéraires d\'entraînement';

  @override
  String get healthAccessHeartRate => 'Fréquence cardiaque';

  @override
  String get healthAccessWorkoutSummary =>
      'Distance, calories et pas de l’entraînement';

  @override
  String get healthAccessAllowed => 'Autorisé';

  @override
  String get healthAccessNeedsAttention => 'A besoin d\'attention';

  @override
  String get healthAccessManagedBySystem => 'Géré dans les paramètres système';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit ne divulgue pas quelles données Endurain peut lire. Vérifiez l’accès dans l’application Santé.';

  @override
  String get healthAccessReview => 'Revoir l’accès à la santé';

  @override
  String get healthAccessReviewIos => 'Comment vérifier l\'accès';

  @override
  String get healthAccessDisconnect => 'Déconnecter les données de santé';

  @override
  String get healthAccessDisconnectTitle =>
      'Déconnecter les données de santé ?';

  @override
  String get healthAccessDisconnectMessage =>
      'L\'importation automatique et l\'historique local des importations de ce serveur seront réinitialisés. Les activités existantes restent dans l\'historique.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Ouvrez l\'application Santé, appuyez sur votre photo de profil, puis sur Applications et services. Sélectionnez Endurain et mettez à jour les catégories de données.';

  @override
  String get healthSyncAuthorize => 'Connectez-vous aux données de santé';

  @override
  String get healthSyncInstallProvider => 'Installer Connexion Santé';

  @override
  String get healthSyncInstallProviderDescription =>
      'Health Connect est requis pour synchroniser les entraînements. Installez-le pour continuer.';

  @override
  String get healthSyncUnsupported =>
      'La synchronisation de l\'état de santé n\'est pas disponible sur cet appareil.';

  @override
  String get healthSyncSelectAll => 'Tout sélectionner';

  @override
  String get healthSyncClearSelection => 'Effacer';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importer la sélection ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '$count entraînement(s) importé(s).';
  }

  @override
  String get healthSyncNoRouteLabel => 'Pas d\'itinéraire GPS';

  @override
  String get healthSyncEmptyState =>
      'Aucune séance d\'entraînement trouvée pour la période sélectionnée.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Certains entraînements ont été ignorés car l’accès au parcours d’exercices n’était pas accordé. Ouvrez Health Connect → Autorisations et autorisez les itinéraires d\'exercice pour Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Certains entraînements ont été ignorés car Endurain ne pouvait pas lire ses itinéraires GPS. Dans l\'application Santé, ouvrez votre profil, puis Applications et services, sélectionnez Endurain et autorisez les itinéraires d\'entraînement.';

  @override
  String get healthSyncReviewAccess => 'Accès aux avis';

  @override
  String get healthSyncAutoSyncTitle =>
      'Synchronisation automatique à la reprise';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Importez automatiquement de nouveaux entraînements à l\'ouverture de l\'application.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Ces entraînements n\'incluent pas d\'itinéraire GPS et ne peuvent donc pas être importés. Certaines applications (comme Garmin Connect) enregistrent les activités sur Apple Health sans partager l\'itinéraire. Les entraînements enregistrés avec Apple Watch incluent des itinéraires et peuvent être importés.';

  @override
  String get healthSyncBadgeNonImportable => 'Non importable';

  @override
  String get healthSyncViewAvailable => 'Disponibles';

  @override
  String get healthSyncViewImported => 'Importés';

  @override
  String get healthSyncDateRange => 'Période des entraînements';

  @override
  String get healthSyncRange30Days => '30 derniers jours';

  @override
  String get healthSyncRange3Months => '3 derniers mois';

  @override
  String get healthSyncRange6Months => '6 derniers mois';

  @override
  String get healthSyncRangeYear => 'Dernière année';

  @override
  String get healthSyncRangeAll => 'Tout l\'historique';

  @override
  String get healthSyncRangeCustom => 'Période personnalisée';

  @override
  String get healthSyncImportedEmpty =>
      'Aucun entraînement importé pour cette connexion.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importé : $dateTime';
  }

  @override
  String get healthSyncRestore => 'Restaurer';

  @override
  String get sensorsTitle => 'Capteurs';

  @override
  String get sensorsSettingsSubtitle =>
      'Cardiofréquencemètres et autres capteurs externes';

  @override
  String get sensorsHeartRateSection => 'Fréquence cardiaque';

  @override
  String get sensorsHeartRateHelp =>
      'Associez un cardiofréquencemètre Bluetooth pour voir votre fréquence cardiaque en direct.';

  @override
  String get sensorsBluetoothOff =>
      'Le Bluetooth est désactivé. Activez-le pour connecter un capteur.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Autorisez l\'accès au Bluetooth pour connecter un capteur.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Cet appareil ne prend pas en charge le Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Rechercher des capteurs';

  @override
  String get sensorsScanning => 'Recherche…';

  @override
  String get sensorsStopScan => 'Arrêter';

  @override
  String get sensorsNoDevices =>
      'Aucun capteur de fréquence cardiaque trouvé pour l\'instant.';

  @override
  String get sensorsAvailableSection => 'Capteurs disponibles';

  @override
  String get sensorsSavedSection => 'Capteur enregistré';

  @override
  String get sensorsConnect => 'Connecter';

  @override
  String get sensorsConnecting => 'Connexion…';

  @override
  String get sensorsConnected => 'Connecté';

  @override
  String get sensorsDisconnect => 'Déconnecter';

  @override
  String get sensorsForget => 'Oublier';

  @override
  String get sensorsConnectionFailed => 'Échec de la connexion. Réessayez.';

  @override
  String get sensorsPermissionRequired =>
      'L\'autorisation Bluetooth est requise pour trouver des capteurs.';

  @override
  String get sensorsUnknownDevice => 'Capteur inconnu';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Puissance';

  @override
  String get sensorsPowerHelp =>
      'Associez un capteur de puissance Bluetooth pour voir votre puissance en direct.';

  @override
  String get sensorsNoPowerDevices =>
      'Aucun capteur de puissance trouvé pour l\'instant.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadence';

  @override
  String get sensorsCadenceHelp =>
      'Associez un capteur de cadence Bluetooth pour voir votre cadence en direct.';

  @override
  String get sensorsNoCadenceDevices =>
      'Aucun capteur de cadence trouvé pour l\'instant.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Rapports de plantage à distance';

  @override
  String get diagnosticsRemoteEnable => 'Envoyer les rapports de plantage';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Envoyer les rapports de plantage et d\'erreur à un serveur de diagnostic. C\'est indépendant des diagnostics locaux; vous pouvez activer les deux, l\'un ou aucun.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Les rapports de plantage à distance ne sont pas disponibles dans cette version.';

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
  String get unitsTitle => 'Unités';

  @override
  String get unitsSubtitle => 'Unités de distance, de vitesse et d\'altitude';

  @override
  String get unitsSystemDefault => 'Suivre la région de l\'appareil';

  @override
  String get unitsMetric => 'Métrique (km)';

  @override
  String get unitsImperial => 'Impérial (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'Le serveur a tenté une redirection vers une connexion non sécurisée. La requête a été bloquée pour protéger vos identifiants.';

  @override
  String get errorTooManyRedirects =>
      'Le serveur a redirigé trop de fois. Vérifiez l\'adresse du serveur.';

  @override
  String get audioAnnouncementsTitle => 'Annonces vocales';

  @override
  String get audioAnnouncementsSubtitle =>
      'Mises à jour vocales sur la distance, le temps, l\'allure ou la vitesse';

  @override
  String get audioAnnouncementsMasterSwitch =>
      'Annoncer la progression de l\'activité';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Annonce à voix haute votre distance, votre temps, votre allure ou votre vitesse pendant un enregistrement';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Baisser les autres sons pendant l\'annonce';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Réduit temporairement le volume des autres sons pendant chaque annonce';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Intervalle d\'annonce par activité';

  @override
  String get audioAnnouncementsByDistance => 'Distance';

  @override
  String get audioAnnouncementsByTime => 'Temps';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Toutes les $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Toutes les $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Réduire l\'intervalle';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Augmenter l\'intervalle';

  @override
  String get audioAnnouncementsPreview => 'Écouter un exemple';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'L\'aperçu des annonces n\'est pas disponible sur cet appareil';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Les modifications s\'appliquent à votre prochain enregistrement.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Distance $distance. Temps $duration. Tour : $lapMetric. Global : $overallMetric.';
  }
}
