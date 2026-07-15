// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get error => 'Kļūda';

  @override
  String get ok => 'Labi';

  @override
  String get cancel => 'Atcelt';

  @override
  String get save => 'Saglabāt';

  @override
  String get back => 'Atpakaļ';

  @override
  String get requiredField => 'Šis lauks ir obligāts';

  @override
  String get invalidUrl => 'Ievadiet derīgu URL';

  @override
  String get errorActivityUploadFailed => 'Neizdevās augšupielādēt aktivitāti';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Neizdevās augšupielādēt aktivitāti: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Aktivitāšu augšupielāde vēl nav konfigurēta';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Neizdevās izdzēst pagaidu aktivitātes failu';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Neizdevās sagatavot aktivitātes augšupielādes failu';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Neizdevās atrast šo lokālo aktivitāti';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Neizdevās izdzēst lokālo aktivitāti';

  @override
  String get errorActivityLocalGpxMissing => 'Lokālais GPX fails nav pieejams';

  @override
  String get errorActivityLocalLoadFailed =>
      'Neizdevās ielādēt lokālās aktivitātes';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Neizdevās saglabāt šo aktivitāti';

  @override
  String get errorActivityLocalSaveFailed =>
      'Neizdevās saglabāt aktivitāti lokāli';

  @override
  String get errorFetchProvidersFailed =>
      'Neizdevās ielādēt pieteikšanās nodrošinātājus';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Neizdevās ielādēt pieteikšanās nodrošinātājus: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Neizdevās ielādēt servera iestatījumus';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Neizdevās ielādēt servera iestatījumus: $details';
  }

  @override
  String get errorHealthGpxBuildFailed => 'Nevarēja konvertēt treniņu uz GPX';

  @override
  String get errorHealthImportFailed => 'Nevarēja importēt treniņu';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Nevarēja importēt treniņu: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Piekļuve veselības datiem tika liegta';

  @override
  String get errorHealthReadFailed => 'Nevarēja nolasīt veselības datus';

  @override
  String get errorHealthUnavailable =>
      'Veselības sinhronizācija šajā ierīcē nav pieejama';

  @override
  String get errorLoginError => 'Neizdevās pieteikties';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Neizdevās pieteikties: $details';
  }

  @override
  String get errorLoginFailed => 'Pieteikšanās neizdevās';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Pieteikšanās neizdevās: $details';
  }

  @override
  String get errorMfaVerificationError => 'Neizdevās pārbaudīt MFA kodu';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Neizdevās pārbaudīt MFA kodu: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA pārbaude neizdevās';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA pārbaude neizdevās: $details';
  }

  @override
  String get errorNoSessionIdReceived => 'No servera netika saņemts sesijas ID';

  @override
  String get errorNotAuthenticated => 'Jūs neesat pieteicies';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Pieteikšanās verificētājs netika atrasts. Sāciet pieteikšanos no jauna.';

  @override
  String get errorServerUrlNotConfigured => 'Servera URL nav konfigurēts';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Šim serverim nepieciešams drošs (HTTPS) savienojums';

  @override
  String get errorSessionExpired =>
      'Jūsu sesija ir beigusies. Piesakieties vēlreiz.';

  @override
  String get errorSsoTokenExchangeError => 'Neizdevās pabeigt SSO pieteikšanos';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Neizdevās pabeigt SSO pieteikšanos: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Pilnvaru apmaiņa neizdevās';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Pilnvaru apmaiņa neizdevās: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Pieprasījuma noildze. Pārbaudiet savienojumu un mēģiniet vēlreiz.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Nevar izdzēst no drošās krātuves. Ierīces krātuve, iespējams, nav pieejama.';

  @override
  String get errorSecureStorageReadFailed =>
      'Nevar nolasīt no drošās krātuves. Ierīces krātuve, iespējams, nav pieejama.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Nevar ierakstīt drošajā krātuvē. Ierīces krātuve, iespējams, nav pieejama.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Serveris atgrieza negaidītu atbildi';

  @override
  String get errorUnsupportedHttpMethod => 'Neatbalstīta HTTP metode';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Neatbalstīta HTTP metode: $details';
  }

  @override
  String get loginTitle => 'Pieteikšanās';

  @override
  String get login => 'Pieteikties';

  @override
  String get logout => 'Atteikties';

  @override
  String get logoutConfirmTitle => 'Atteikties';

  @override
  String get logoutConfirmMessage => 'Vai tiešām vēlaties atteikties?';

  @override
  String get logoutServerFailedWarning =>
      'Neizdevās atteikties no servera, bet atteikšanās veikta lokāli';

  @override
  String get ssoBrowserLaunchFailed =>
      'Neizdevās atvērt SSO pieteikšanos sistēmas pārlūkā';

  @override
  String ssoSignInWith(String provider) {
    return 'Pieteikties ar $provider';
  }

  @override
  String get ssoOrDivider => 'VAI';

  @override
  String get next => 'Tālāk';

  @override
  String get username => 'Lietotājvārds';

  @override
  String get usernameHint => 'Ievadiet savu lietotājvārdu';

  @override
  String get password => 'Parole';

  @override
  String get passwordHint => 'Ievadiet savu paroli';

  @override
  String get showPassword => 'Rādīt paroli';

  @override
  String get mfaTitle => 'Divfaktoru autentifikācija';

  @override
  String get mfaCode => 'MFA kods';

  @override
  String get mfaCodeHint => 'Ievadiet 6 ciparu kodu';

  @override
  String get mfaCodeRequired => 'Ievadiet MFA kodu';

  @override
  String get verify => 'Pārbaudīt';

  @override
  String get activityDiscard => 'Atmest';

  @override
  String get activityDiscardConfirmMessage =>
      'Tādējādi tiks izdzēsti šīs aktivitātes ierakstītie punkti.';

  @override
  String get activityDiscardConfirmTitle => 'Atmest aktivitāti?';

  @override
  String get activityLocationPermissionDenied =>
      'Lai ierakstītu aktivitāti, nepieciešama atrašanās vietas atļauja.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Atrašanās vietas atļauja ir bloķēta. Atveriet iestatījumus, lai atļautu piekļuvi atrašanās vietai.';

  @override
  String get activityLocationServiceDisabled =>
      'Atrašanās vietas pakalpojumi ir atspējoti.';

  @override
  String get activityLocationStreamFailed =>
      'Atrašanās vietas atjauninājumi negaidīti apstājās.';

  @override
  String get activityGpxGenerationFailed =>
      'Neizdevās izveidot aktivitātes GPX failu.';

  @override
  String get activityLocalSaveFailed =>
      'Neizdevās saglabāt šo aktivitāti šajā ierīcē.';

  @override
  String get activityOpenSettings => 'Atvērt iestatījumus';

  @override
  String get activityPause => 'Pauze';

  @override
  String get activityRecordingEmpty => 'Netika ierakstīts neviens GPS punkts.';

  @override
  String get activityRecordingFailed => 'Ierakstīšana neizdevās.';

  @override
  String get activityResume => 'Turpināt';

  @override
  String get activityRetryUpload => 'Mēģināt augšupielādēt vēlreiz';

  @override
  String get activityDone => 'Gatavs';

  @override
  String get activityViewHistory => 'Skatīt vēsturi';

  @override
  String get activityDeleteLocal => 'Dzēst lokālo kopiju';

  @override
  String get activityExportGpx => 'Kopīgot GPX failu';

  @override
  String get activityExportGpxSubject => 'Endurain aktivitātes GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Dzēst lokālo aktivitāti?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Tādējādi no šīs ierīces tiek noņemts lokālās aktivitātes ieraksts un GPX fails.';

  @override
  String get activityStart => 'Sākt';

  @override
  String get activityBackgroundPermissionTitle => 'Atļaut izsekošanu fonā?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain nepieciešams, lai fona atrašanās vieta būtu iestatīta uz Vienmēr, lai ierakstīšana turpinātos, kad lietotne ir fonā, ekrāns ir bloķēts vai jūs pārslēdzat lietotnes.';

  @override
  String get activityBackgroundPermissionContinue => 'Turpināt';

  @override
  String get activityBackgroundPermissionRequired =>
      'Izsekošanai fonā iPhone un iPad ierīcēs atrašanās vietai jābūt iestatītai uz Vienmēr.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Izsekošana fonā ir izslēgta';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Lai droši ierakstītu fonā vai ar bloķētu ekrānu, atveriet Iestatījumus un iestatiet Atrašanās vietu uz Vienmēr Endurain lietotnei.';

  @override
  String get activityTrackingNotificationTitle =>
      'Notiek aktivitātes ierakstīšana';

  @override
  String get activityTrackingNotificationText =>
      'Endurain izseko jūsu atrašanās vietu, lai ierakstītu šo aktivitāti.';

  @override
  String get activityStatDistance => 'Attālums';

  @override
  String get activityStatDuration => 'Laiks';

  @override
  String get activityStatSpeed => 'Ātrums';

  @override
  String get activityStatPace => 'Temps';

  @override
  String get activityStatMaxSpeed => 'Maks. ātrums';

  @override
  String get activityStatElevationGain => 'Kāpums';

  @override
  String get activityStop => 'Apturēt';

  @override
  String get activityStopAndSave => 'Apturēt un saglabāt';

  @override
  String get activityStopConfirmMessage =>
      'Izvēlieties, vai saglabāt šo ierakstu vai to atmest.';

  @override
  String get activityStopConfirmTitle => 'Beigt aktivitāti?';

  @override
  String get activityStopping => 'Notiek apturēšana';

  @override
  String get activityTypeHike => 'Pārgājiens';

  @override
  String get activityTypeLabel => 'Aktivitātes veids';

  @override
  String get activityTypeOther => 'Cits';

  @override
  String get activityTypeRide => 'Riteņbraukšana';

  @override
  String get activityTypeRun => 'Skriešana';

  @override
  String get activityTypeWalk => 'Pastaiga';

  @override
  String get activityUploadFailed => 'Augšupielāde neizdevās';

  @override
  String get activityUploadCleanupFailed =>
      'Augšupielādēts, bet tīrīšana neizdevās';

  @override
  String get activityUploadReady => 'Gatavs augšupielādei';

  @override
  String get activityUploaded => 'Augšupielādēts';

  @override
  String get activityUploading => 'Notiek augšupielāde';

  @override
  String get activityUploadStatusPending => 'Gaida';

  @override
  String get activityUploadStatusUploaded => 'Augšupielādēts';

  @override
  String get activityUploadStatusFailed => 'Neizdevās';

  @override
  String get activityHistoryTitle => 'Aktivitāšu vēsture';

  @override
  String get activityHistorySettingsSubtitle =>
      'Šajā ierīcē saglabātās pabeigtās aktivitātes';

  @override
  String get activityRetainUploadedGpx => 'Saglabāt augšupielādētos GPX failus';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Pēc augšupielādes saglabā pabeigtos maršrutu failus lietotnes privātajā krātuvē.';

  @override
  String get activityHistoryEmpty =>
      'Šajā ierīcē nav saglabātu pabeigtu aktivitāšu.';

  @override
  String get activityHistoryLoadFailed =>
      'Neizdevās ielādēt lokālās aktivitātes.';

  @override
  String get activityHistoryRefresh => 'Atsvaidzināt';

  @override
  String get activityHistoryLocalActivities => 'Lokālās aktivitātes';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Ilgums: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Attālums: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Augšupielāde: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Ielādēt vairāk';

  @override
  String get activityHistoryDetailsTitle => 'Aktivitātes informācija';

  @override
  String get activityHistoryDetailsMissing =>
      'Šī lokālā aktivitāte vairs nav pieejama.';

  @override
  String get activityHistorySummary => 'Kopsavilkums';

  @override
  String get activityHistoryActions => 'Darbības';

  @override
  String get activityHistoryType => 'Veids';

  @override
  String get activityHistoryStartedAt => 'Sākts';

  @override
  String get activityHistoryEndedAt => 'Beidzies';

  @override
  String get activityHistoryDurationLabel => 'Ilgums';

  @override
  String get activityHistoryDistanceLabel => 'Attālums';

  @override
  String get activityHistoryAverageSpeed => 'Vidējais ātrums';

  @override
  String get activityHistoryPointCount => 'GPS punkti';

  @override
  String get activityHistoryUploadStatusLabel => 'Augšupielāde';

  @override
  String get activityHistoryGpxStatus => 'GPX fails';

  @override
  String get activityHistoryGpxAvailable => 'Saglabāts šajā ierīcē';

  @override
  String get activityHistoryGpxMissing => 'Nav pieejams šajā ierīcē';

  @override
  String get mapTab => 'Karte';

  @override
  String get myLocation => 'Mana atrašanās vieta';

  @override
  String get settingsTab => 'Iestatījumi';

  @override
  String get endurainTrademarkNotice =>
      'Endurain® ir João Vitória Silva reģistrēta preču zīme.';

  @override
  String get settingsScreen => 'Iestatījumi';

  @override
  String get deviceAccessTitle => 'Ierīces piekļuve';

  @override
  String get deviceAccessSubtitle =>
      'Pārvaldiet piekļuvi atrašanās vietas un veselības datiem';

  @override
  String get deviceAccessLocationSection => 'Atrašanās vieta';

  @override
  String get deviceAccessHealthSection => 'Veselības dati';

  @override
  String get deviceAccessLocationTitle => 'Piekļuve atrašanās vietai';

  @override
  String get deviceAccessHealthTitle => 'Piekļuve veselības datiem';

  @override
  String get deviceAccessChecking => 'Notiek piekļuves pārbaude…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Atrašanās vietas pakalpojumi ir izslēgti';

  @override
  String get deviceAccessLocationAlways => 'Atļauts visu laiku';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Atļauts lietotnes lietošanas laikā';

  @override
  String get deviceAccessLocationBlocked => 'Bloķēts sistēmas iestatījumos';

  @override
  String get deviceAccessLocationNotAllowed => 'Nav atļauts';

  @override
  String get deviceAccessHealthUnavailable => 'Nav pieejams šajā ierīcē';

  @override
  String get deviceAccessHealthRequired => 'Nepieciešams Health Connect';

  @override
  String get deviceAccessHealthSetUp =>
      'Ir izveidota piekļuve veselības aprūpei';

  @override
  String get deviceAccessHealthNeedsAttention => 'Piekļuvei jāpievērš uzmanība';

  @override
  String get deviceAccessHealthNotConnected => 'Nav savienots';

  @override
  String get language => 'Valoda';

  @override
  String get languageSystemDefault => 'Sistēmas noklusējums';

  @override
  String get serverSettings => 'Serveris';

  @override
  String get signInConnectServer => 'Pieteikties';

  @override
  String get signInConnectServerSubtitle =>
      'Ierakstiet bezsaistē tagad un sinhronizējiet aktivitātes vēlāk';

  @override
  String get serverSettingsTitle => 'Servera iestatījumi';

  @override
  String connectedToServer(String server) {
    return 'Izveidots savienojums ar $server';
  }

  @override
  String get loggedIn => 'Pieteicies';

  @override
  String get notConfigured => 'Nav konfigurēts';

  @override
  String get notLoggedIn => 'Neesat pieteicies';

  @override
  String get serverUrl => 'Servera URL';

  @override
  String get serverProtocol => 'Protokols';

  @override
  String get serverUrlHint => 'https://piemers.com';

  @override
  String get warnHttpServerUrlTitle => 'Nedrošs savienojums';

  @override
  String get warnHttpServerUrlMessage =>
      'Šis servera URL izmanto vienkāršu HTTP. Jūsu pieteikšanās akreditācijas dati un dati tiks pārsūtīti bez šifrēšanas. Turpiniet tikai tad, ja saprotat un pieņemat risku.';

  @override
  String get warnHttpServerUrlConfirm => 'Tomēr turpināt';

  @override
  String get tileServerUrl => 'Kartes elementu servera URL';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Cits elementu servera resursdators';

  @override
  String get tileServerHostWarningMessage =>
      'Elementu servera resursdators atšķiras no jūsu Endurain servera resursdatora. Elementi tiks ielādēti no trešās puses servera. Vai vēlaties turpināt?';

  @override
  String get savedSuccessfully => 'Iestatījumi veiksmīgi saglabāti';

  @override
  String get diagnostics => 'Diagnostika';

  @override
  String get diagnosticsSubtitle => 'Lokālais avāriju konteksts';

  @override
  String get sourceCode => 'Pirmkods';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Neizdevās atvērt saiti';

  @override
  String get diagnosticsTitle => 'Diagnostika';

  @override
  String get diagnosticsCollection => 'Vākšana';

  @override
  String get diagnosticsEnable => 'Vākt diagnostiku';

  @override
  String get diagnosticsEnableSubtitle =>
      'Saglabāt jaunākos lietotnes notikumus un kļūdas šajā ierīcē';

  @override
  String get diagnosticsDisabled =>
      'Diagnostikas vākšana ir izslēgta. Ieslēdziet to, lai sāktu reģistrēt lietotnes notikumus un kļūdas šajā ierīcē.';

  @override
  String get diagnosticsEmpty => 'Vēl nav tverti diagnostikas dati.';

  @override
  String get diagnosticsCopy => 'Kopēt';

  @override
  String get diagnosticsCopied => 'Diagnostika nokopēta';

  @override
  String get diagnosticsClear => 'Notīrīt';

  @override
  String get diagnosticsCleared => 'Diagnostika notīrīta';

  @override
  String get diagnosticsSummary => 'Kopsavilkums';

  @override
  String get diagnosticsLastUpdated => 'Pēdējoreiz atjaunināts';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Notikumi: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Kļūdas: $count';
  }

  @override
  String get diagnosticsEvents => 'Notikumi';

  @override
  String get diagnosticsNoEvents => 'Nav tvertu notikumu';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Notikums: $event';
  }

  @override
  String get diagnosticsErrors => 'Kļūdas';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Kļūda: $type';
  }

  @override
  String get diagnosticsActions => 'Darbības';

  @override
  String get diagnosticsRawReport => 'Neapstrādāts pārskats';

  @override
  String get healthSyncSettingsTitle => 'Veselības sinhronizācija';

  @override
  String get healthSyncSettingsSubtitle =>
      'Importējiet treniņus no savas veselības platformas';

  @override
  String get healthSyncScreenTitle => 'Veselības sinhronizācija';

  @override
  String get healthAccessScreenTitle => 'Veselības pieejamība';

  @override
  String get healthAccessRequestedData => 'Pieprasītie dati';

  @override
  String get healthAccessWorkouts => 'Treniņi';

  @override
  String get healthAccessWorkoutRoutes => 'Treniņu maršruti';

  @override
  String get healthAccessHeartRate => 'Sirdsdarbība';

  @override
  String get healthAccessWorkoutSummary =>
      'Treniņa distance, kalorijas un soļi';

  @override
  String get healthAccessAllowed => 'Atļauts';

  @override
  String get healthAccessNeedsAttention => 'Nepieciešama uzmanība';

  @override
  String get healthAccessManagedBySystem => 'Pārvalda sistēmas iestatījumos';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit neatklāj, kādus datus Endurain var nolasīt. Pārskatiet piekļuvi lietotnē Health.';

  @override
  String get healthAccessReview => 'Pārskatiet veselības pieejamību';

  @override
  String get healthAccessReviewIos => 'Kā pārskatīt piekļuvi';

  @override
  String get healthAccessDisconnect => 'Atvienot veselības datus';

  @override
  String get healthAccessDisconnectTitle => 'Atvienot veselības datus?';

  @override
  String get healthAccessDisconnectMessage =>
      'Šī servera automātiskā importēšana un lokālā importēšanas vēsture tiks atiestatīta. Esošās aktivitātes paliks vēsturē.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Atveriet lietotni Health, pieskarieties savam profila attēlam un pēc tam — Programmas un pakalpojumi. Atlasiet Endurain un atjauniniet datu kategorijas.';

  @override
  String get healthSyncAuthorize =>
      'Izveidojiet savienojumu ar veselības datiem';

  @override
  String get healthSyncInstallProvider => 'Instalējiet Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Lai sinhronizētu treniņus, ir nepieciešams Health Connect. Instalējiet to, lai turpinātu.';

  @override
  String get healthSyncUnsupported =>
      'Veselības sinhronizācija šajā ierīcē nav pieejama.';

  @override
  String get healthSyncSelectAll => 'Atlasiet visu';

  @override
  String get healthSyncClearSelection => 'Skaidrs';

  @override
  String healthSyncImportSelected(int count) {
    return 'Importēt atlasīto ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Importēts(-i) $count treniņš(-i).';
  }

  @override
  String get healthSyncNoRouteLabel => 'Nav GPS maršruta';

  @override
  String get healthSyncEmptyState =>
      'Atlasītajā periodā nav atrasts neviens treniņš.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Daži treniņi tika izlaisti, jo netika piešķirta piekļuve vingrinājumu maršrutam. Atveriet Health Connect → Atļaujas un atļaujiet Endurain vingrojumu maršrutus.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Daži treniņi tika izlaisti, jo Endurain nevarēja nolasīt savus GPS maršrutus. Lietotnē Health atveriet savu profilu, pēc tam Programmas un pakalpojumi, atlasiet Endurain un atļaujiet Workout Routes.';

  @override
  String get healthSyncReviewAccess => 'Pārskatiet piekļuvi';

  @override
  String get healthSyncAutoSyncTitle => 'Automātiskā sinhronizācija, atsākot';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Kad lietotne tiek atvērta, automātiski importējiet jaunus treniņus.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Šajos treniņos nav iekļauts GPS maršruts, tāpēc tos nevar importēt. Dažas lietotnes (piemēram, Garmin Connect) ieraksta darbības pakalpojumā Apple Health, nekoplietojot maršrutu. Ar Apple Watch ierakstītajos treniņos ir iekļauti maršruti, un tos var importēt.';

  @override
  String get healthSyncBadgeNonImportable => 'Neimportējams';

  @override
  String get healthSyncViewAvailable => 'Pieejami';

  @override
  String get healthSyncViewImported => 'Importēti';

  @override
  String get healthSyncDateRange => 'Treniņu periods';

  @override
  String get healthSyncRange30Days => 'Pēdējās 30 dienas';

  @override
  String get healthSyncRange3Months => 'Pēdējie 3 mēneši';

  @override
  String get healthSyncRange6Months => 'Pēdējie 6 mēneši';

  @override
  String get healthSyncRangeYear => 'Pēdējais gads';

  @override
  String get healthSyncRangeAll => 'Visa vēsture';

  @override
  String get healthSyncRangeCustom => 'Pielāgots periods';

  @override
  String get healthSyncImportedEmpty =>
      'Šim savienojumam nav importētu treniņu.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Importēts: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Atjaunot';
}
