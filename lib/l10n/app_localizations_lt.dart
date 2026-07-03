// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get error => 'Klaida';

  @override
  String get ok => 'Gerai';

  @override
  String get cancel => 'Atšaukti';

  @override
  String get save => 'Įrašyti';

  @override
  String get back => 'Atgal';

  @override
  String get requiredField => 'Šis laukas privalomas';

  @override
  String get invalidUrl => 'Įveskite galiojantį URL';

  @override
  String get errorActivityUploadFailed => 'Nepavyko įkelti veiklos';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Nepavyko įkelti veiklos: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Veiklų įkėlimas dar nesukonfigūruotas';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Nepavyko ištrinti laikinojo veiklos failo';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Nepavyko paruošti veiklos įkėlimo failo';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Nepavyko rasti šios vietinės veiklos';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Nepavyko ištrinti vietinės veiklos';

  @override
  String get errorActivityLocalGpxMissing =>
      'Vietinis GPX failas nepasiekiamas';

  @override
  String get errorActivityLocalLoadFailed => 'Nepavyko įkelti vietinių veiklų';

  @override
  String get errorActivityLocalRecordInvalid => 'Nepavyko įrašyti šios veiklos';

  @override
  String get errorActivityLocalSaveFailed => 'Nepavyko įrašyti veiklos vietoje';

  @override
  String get errorFetchProvidersFailed =>
      'Nepavyko įkelti prisijungimo tiekėjų';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Nepavyko įkelti prisijungimo tiekėjų: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Nepavyko įkelti serverio nustatymų';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Nepavyko įkelti serverio nustatymų: $details';
  }

  @override
  String get errorLoginError => 'Nepavyko prisijungti';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Nepavyko prisijungti: $details';
  }

  @override
  String get errorLoginFailed => 'Prisijungti nepavyko';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Prisijungti nepavyko: $details';
  }

  @override
  String get errorMfaVerificationError => 'Nepavyko patvirtinti MFA kodo';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Nepavyko patvirtinti MFA kodo: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA patvirtinimas nepavyko';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA patvirtinimas nepavyko: $details';
  }

  @override
  String get errorNoSessionIdReceived => 'Iš serverio negautas seanso ID';

  @override
  String get errorNotAuthenticated => 'Nesate prisijungę';

  @override
  String get errorPkceVerifierMissing => 'Prisijungimo tikrintuvas nerastas';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Prisijungimo tikrintuvas nerastas. Pradėkite prisijungimą iš naujo.';

  @override
  String get errorServerUrlNotConfigured => 'Serverio URL nesukonfigūruotas';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Šis serveris reikalauja saugaus (HTTPS) ryšio';

  @override
  String get errorSessionExpired =>
      'Jūsų seansas baigėsi. Prisijunkite iš naujo.';

  @override
  String get errorSsoTokenExchangeError => 'Nepavyko užbaigti SSO prisijungimo';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Nepavyko užbaigti SSO prisijungimo: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Prieigos raktų mainai nepavyko';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Prieigos raktų mainai nepavyko: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Baigėsi užklausos laikas. Patikrinkite ryšį ir bandykite dar kartą.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Nepavyksta ištrinti iš saugios saugyklos. Įrenginio saugykla gali būti nepasiekiama.';

  @override
  String get errorSecureStorageReadFailed =>
      'Nepavyksta nuskaityti iš saugios saugyklos. Įrenginio saugykla gali būti nepasiekiama.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Nepavyksta įrašyti į saugią saugyklą. Įrenginio saugykla gali būti nepasiekiama.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Serveris grąžino netikėtą atsakymą';

  @override
  String get errorUnsupportedHttpMethod => 'Nepalaikomas HTTP metodas';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nepalaikomas HTTP metodas: $details';
  }

  @override
  String get loginTitle => 'Prisijungimas';

  @override
  String get login => 'Prisijungti';

  @override
  String get logout => 'Atsijungti';

  @override
  String get logoutConfirmTitle => 'Atsijungti';

  @override
  String get logoutConfirmMessage => 'Ar tikrai norite atsijungti?';

  @override
  String get logoutServerFailedWarning =>
      'Nepavyko atsijungti nuo serverio, bet atsijungta vietoje';

  @override
  String get ssoBrowserLaunchFailed =>
      'Nepavyko atidaryti SSO prisijungimo sistemos naršyklėje';

  @override
  String get ssoMissingSessionId => 'SSO atsakyme nebuvo seanso ID';

  @override
  String ssoSignInWith(String provider) {
    return 'Prisijungti naudojant $provider';
  }

  @override
  String get ssoOrDivider => 'ARBA';

  @override
  String get next => 'Toliau';

  @override
  String get username => 'Naudotojo vardas';

  @override
  String get usernameHint => 'Įveskite naudotojo vardą';

  @override
  String get password => 'Slaptažodis';

  @override
  String get passwordHint => 'Įveskite slaptažodį';

  @override
  String get showPassword => 'Rodyti slaptažodį';

  @override
  String get mfaTitle => 'Dviejų veiksnių autentifikavimas';

  @override
  String get mfaCode => 'MFA kodas';

  @override
  String get mfaCodeHint => 'Įveskite 6 skaitmenų kodą';

  @override
  String get mfaCodeRequired => 'Įveskite MFA kodą';

  @override
  String get verify => 'Patvirtinti';

  @override
  String get activityDiscard => 'Atmesti';

  @override
  String get activityDiscardConfirmMessage =>
      'Bus ištrinti šios veiklos įrašyti taškai.';

  @override
  String get activityDiscardConfirmTitle => 'Atmesti veiklą?';

  @override
  String get activityLocationPermissionDenied =>
      'Norint įrašyti veiklą, reikia vietos nustatymo leidimo.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Vietos nustatymo leidimas užblokuotas. Atidarykite nustatymus, kad leistumėte prieigą prie vietos.';

  @override
  String get activityLocationServiceDisabled =>
      'Vietos nustatymo paslaugos išjungtos.';

  @override
  String get activityLocationStreamFailed =>
      'Vietos naujinimai netikėtai sustojo.';

  @override
  String get activityGpxGenerationFailed =>
      'Nepavyko sukurti veiklos GPX failo.';

  @override
  String get activityLocalSaveFailed =>
      'Nepavyko įrašyti šios veiklos šiame įrenginyje.';

  @override
  String get activityOpenSettings => 'Atidaryti nustatymus';

  @override
  String get activityPause => 'Pristabdyti';

  @override
  String get activityRecordingEmpty => 'Neįrašyta nė vieno GPS taško.';

  @override
  String get activityRecordingFailed => 'Įrašymas nepavyko.';

  @override
  String get activityResume => 'Tęsti';

  @override
  String get activityRetryUpload => 'Bandyti įkelti dar kartą';

  @override
  String get activityDone => 'Atlikta';

  @override
  String get activityViewHistory => 'Peržiūrėti istoriją';

  @override
  String get activityDeleteLocal => 'Ištrinti vietinę kopiją';

  @override
  String get activityExportGpx => 'Bendrinti GPX failą';

  @override
  String get activityExportGpxSubject => 'Endurain veiklos GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Ištrinti vietinę veiklą?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Iš šio įrenginio bus pašalintas vietinės veiklos įrašas ir GPX failas.';

  @override
  String get activityStart => 'Pradėti';

  @override
  String get activityBackgroundPermissionTitle => 'Leisti stebėjimą fone?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain reikia, kad vietos nustatymas fone būtų nustatytas į Visada, kad įrašymas tęstųsi, kai programa veikia fone, ekranas užrakintas arba perjungiate programas.';

  @override
  String get activityBackgroundPermissionContinue => 'Tęsti';

  @override
  String get activityBackgroundPermissionRequired =>
      'Stebėjimui fone „iPhone“ ir „iPad“ įrenginiuose vietos nustatymas turi būti nustatytas į Visada.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Stebėjimas fone išjungtas';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Kad įrašymas patikimai veiktų fone arba užrakintu ekranu, atidarykite Nustatymus ir nustatykite Vietą į Visada, skirta Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Įrašoma veikla';

  @override
  String get activityTrackingNotificationText =>
      'Endurain stebi jūsų vietą, kad įrašytų šią veiklą.';

  @override
  String get activityStatDistance => 'Atstumas';

  @override
  String get activityStatDuration => 'Laikas';

  @override
  String get activityStatSpeed => 'Greitis';

  @override
  String get activityStop => 'Sustabdyti';

  @override
  String get activityStopAndSave => 'Sustabdyti ir įrašyti';

  @override
  String get activityStopConfirmMessage =>
      'Pasirinkite, ar norite išsaugoti šį įrašą, ar jį atmesti.';

  @override
  String get activityStopConfirmTitle => 'Baigti veiklą?';

  @override
  String get activityStopping => 'Stabdoma';

  @override
  String get activityTypeHike => 'Žygis';

  @override
  String get activityTypeLabel => 'Veiklos tipas';

  @override
  String get activityTypeOther => 'Kita';

  @override
  String get activityTypeRide => 'Dviratis';

  @override
  String get activityTypeRun => 'Bėgimas';

  @override
  String get activityTypeWalk => 'Ėjimas';

  @override
  String get activityUploadFailed => 'Įkelti nepavyko';

  @override
  String get activityUploadCleanupFailed => 'Įkelta, bet valymas nepavyko';

  @override
  String get activityUploadReady => 'Paruošta įkelti';

  @override
  String get activityUploaded => 'Įkelta';

  @override
  String get activityUploading => 'Įkeliama';

  @override
  String get activityUploadStatusPending => 'Laukiama';

  @override
  String get activityUploadStatusUploaded => 'Įkelta';

  @override
  String get activityUploadStatusFailed => 'Nepavyko';

  @override
  String get activityHistoryTitle => 'Veiklos istorija';

  @override
  String get activityHistorySettingsSubtitle =>
      'Užbaigtos veiklos, įrašytos šiame įrenginyje';

  @override
  String get activityRetainUploadedGpx => 'Išsaugoti įkeltus GPX failus';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Po įkėlimo užbaigtus maršrutų failus saugo privačioje programos saugykloje.';

  @override
  String get activityHistoryEmpty =>
      'Šiame įrenginyje nėra įrašytų užbaigtų veiklų.';

  @override
  String get activityHistoryLoadFailed => 'Nepavyko įkelti vietinių veiklų.';

  @override
  String get activityHistoryRefresh => 'Atnaujinti';

  @override
  String get activityHistoryLocalActivities => 'Vietinės veiklos';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Trukmė: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Atstumas: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Įkėlimas: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Įkelti daugiau';

  @override
  String get activityHistoryDetailsTitle => 'Veiklos informacija';

  @override
  String get activityHistoryDetailsMissing =>
      'Ši vietinė veikla nebepasiekiama.';

  @override
  String get activityHistorySummary => 'Santrauka';

  @override
  String get activityHistoryActions => 'Veiksmai';

  @override
  String get activityHistoryType => 'Tipas';

  @override
  String get activityHistoryStartedAt => 'Pradėta';

  @override
  String get activityHistoryEndedAt => 'Baigta';

  @override
  String get activityHistoryDurationLabel => 'Trukmė';

  @override
  String get activityHistoryDistanceLabel => 'Atstumas';

  @override
  String get activityHistoryAverageSpeed => 'Vidutinis greitis';

  @override
  String get activityHistoryPointCount => 'GPS taškai';

  @override
  String get activityHistoryUploadStatusLabel => 'Įkėlimas';

  @override
  String get activityHistoryGpxStatus => 'GPX failas';

  @override
  String get activityHistoryGpxAvailable => 'Įrašyta šiame įrenginyje';

  @override
  String get activityHistoryGpxMissing => 'Nepasiekiama šiame įrenginyje';

  @override
  String get mapTab => 'Žemėlapis';

  @override
  String get myLocation => 'Mano vieta';

  @override
  String get settingsTab => 'Nustatymai';

  @override
  String get settingsScreen => 'Nustatymai';

  @override
  String get language => 'Kalba';

  @override
  String get languageSystemDefault => 'Sistemos numatytoji';

  @override
  String get serverSettings => 'Serveris';

  @override
  String get signInConnectServer => 'Prisijungti';

  @override
  String get signInConnectServerSubtitle =>
      'Įrašykite neprisijungę dabar ir sinchronizuokite veiklas vėliau';

  @override
  String get serverSettingsTitle => 'Serverio nustatymai';

  @override
  String get loggedIn => 'Prisijungta';

  @override
  String get notConfigured => 'Nesukonfigūruota';

  @override
  String get notLoggedIn => 'Neprisijungta';

  @override
  String get serverUrl => 'Serverio URL';

  @override
  String get serverUrlHint => 'https://pavyzdys.com';

  @override
  String get warnHttpServerUrlTitle => 'Nesaugus ryšys';

  @override
  String get warnHttpServerUrlMessage =>
      'Šis serverio URL naudoja paprastą HTTP. Jūsų prisijungimo duomenys ir duomenys bus perduodami be šifravimo. Tęskite tik jei suprantate ir sutinkate su rizika.';

  @override
  String get warnHttpServerUrlConfirm => 'Vis tiek tęsti';

  @override
  String get tileServerUrl => 'Žemėlapio išklotinės serverio URL';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle =>
      'Kitas išklotinės serverio prieglobis';

  @override
  String get tileServerHostWarningMessage =>
      'Išklotinės serverio prieglobis skiriasi nuo jūsų Endurain serverio prieglobio. Išklotinės bus įkeltos iš trečiosios šalies serverio. Ar norite tęsti?';

  @override
  String get savedSuccessfully => 'Nustatymai sėkmingai įrašyti';

  @override
  String get diagnostics => 'Diagnostika';

  @override
  String get diagnosticsSubtitle => 'Vietinis strigčių kontekstas';

  @override
  String get diagnosticsTitle => 'Diagnostika';

  @override
  String get diagnosticsEmpty => 'Diagnostikos duomenų dar neužfiksuota.';

  @override
  String get diagnosticsCopy => 'Kopijuoti';

  @override
  String get diagnosticsCopied => 'Diagnostika nukopijuota';

  @override
  String get diagnosticsClear => 'Išvalyti';

  @override
  String get diagnosticsCleared => 'Diagnostika išvalyta';

  @override
  String get diagnosticsSummary => 'Santrauka';

  @override
  String get diagnosticsLastUpdated => 'Paskutinį kartą atnaujinta';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Įvykiai: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Klaidos: $count';
  }

  @override
  String get diagnosticsEvents => 'Įvykiai';

  @override
  String get diagnosticsNoEvents => 'Įvykių neužfiksuota';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Įvykis: $event';
  }

  @override
  String get diagnosticsErrors => 'Klaidos';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Klaida: $type';
  }

  @override
  String get diagnosticsActions => 'Veiksmai';

  @override
  String get diagnosticsRawReport => 'Neapdorota ataskaita';
}
