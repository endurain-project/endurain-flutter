// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get error => 'Грешка';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Откажи';

  @override
  String get save => 'Сачувај';

  @override
  String get back => 'Назад';

  @override
  String get requiredField => 'Ово поље је обавезно';

  @override
  String get invalidUrl => 'Унесите важећи URL';

  @override
  String get errorActivityUploadFailed => 'Није могуће отпремити активност';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Није могуће отпремити активност: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Отпремање активности још није подешено';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Није могуће избрисати привремену датотеку активности';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Није могуће припремити датотеку за отпремање активности';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Ову локалну активност није могуће пронаћи';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Није могуће избрисати локалну активност';

  @override
  String get errorActivityLocalGpxMissing =>
      'Локална GPX датотека није доступна';

  @override
  String get errorActivityLocalLoadFailed =>
      'Није могуће учитати локалне активности';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Ову активност није могуће сачувати';

  @override
  String get errorActivityLocalSaveFailed =>
      'Није могуће локално сачувати активност';

  @override
  String get errorFetchProvidersFailed =>
      'Није могуће учитати добављаче пријаве';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Није могуће учитати добављаче пријаве: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Није могуће учитати подешавања сервера';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Није могуће учитати подешавања сервера: $details';
  }

  @override
  String get errorLoginError => 'Пријава није успела';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Пријава није успела: $details';
  }

  @override
  String get errorLoginFailed => 'Неуспела пријава';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Неуспела пријава: $details';
  }

  @override
  String get errorMfaVerificationError => 'Није могуће верификовати MFA кôд';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Није могуће верификовати MFA кôд: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Верификација MFA није успела';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Верификација MFA није успела: $details';
  }

  @override
  String get errorNoSessionIdReceived => 'Са сервера није примљен ИД сесије';

  @override
  String get errorNotAuthenticated => 'Нисте пријављени';

  @override
  String get errorPkceVerifierMissing => 'Верификатор пријаве није пронађен';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Верификатор пријаве није пронађен. Поново започните пријаву.';

  @override
  String get errorServerUrlNotConfigured => 'URL сервера није подешен';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Овај сервер захтева безбедну (HTTPS) везу';

  @override
  String get errorSessionExpired =>
      'Ваша сесија је истекла. Пријавите се поново.';

  @override
  String get errorSsoTokenExchangeError => 'Није могуће завршити SSO пријаву';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Није могуће завршити SSO пријаву: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Размена токена није успела';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Размена токена није успела: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Захтев је истекао. Проверите везу и покушајте поново.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Није могуће брисати из безбедног складишта. Складиште уређаја можда није доступно.';

  @override
  String get errorSecureStorageReadFailed =>
      'Није могуће читати из безбедног складишта. Складиште уређаја можда није доступно.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Није могуће уписивати у безбедно складиште. Складиште уређаја можда није доступно.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Сервер је вратио неочекивани одговор';

  @override
  String get errorUnsupportedHttpMethod => 'Неподржана HTTP метода';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Неподржана HTTP метода: $details';
  }

  @override
  String get loginTitle => 'Пријава';

  @override
  String get login => 'Пријава';

  @override
  String get logout => 'Одјава';

  @override
  String get logoutConfirmTitle => 'Одјава';

  @override
  String get logoutConfirmMessage =>
      'Да ли сте сигурни да желите да се одјавите?';

  @override
  String get logoutServerFailedWarning =>
      'Одјава са сервера није успела, али сте одјављени локално';

  @override
  String get ssoBrowserLaunchFailed =>
      'Није могуће отворити SSO пријаву у системском прегледачу';

  @override
  String get ssoMissingSessionId => 'SSO одговор није садржао ИД сесије';

  @override
  String ssoSignInWith(String provider) {
    return 'Пријава преко $provider';
  }

  @override
  String get ssoOrDivider => 'ИЛИ';

  @override
  String get next => 'Даље';

  @override
  String get username => 'Корисничко име';

  @override
  String get usernameHint => 'Унесите своје корисничко име';

  @override
  String get password => 'Лозинка';

  @override
  String get passwordHint => 'Унесите своју лозинку';

  @override
  String get showPassword => 'Прикажи лозинку';

  @override
  String get mfaTitle => 'Двофакторска аутентификација';

  @override
  String get mfaCode => 'MFA кôд';

  @override
  String get mfaCodeHint => 'Унесите шестоцифрени кôд';

  @override
  String get mfaCodeRequired => 'Унесите MFA кôд';

  @override
  String get verify => 'Верификуј';

  @override
  String get activityDiscard => 'Одбаци';

  @override
  String get activityDiscardConfirmMessage =>
      'Ово ће избрисати забележене тачке ове активности.';

  @override
  String get activityDiscardConfirmTitle => 'Одбацити активност?';

  @override
  String get activityLocationPermissionDenied =>
      'За снимање активности потребна је дозвола за локацију.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Дозвола за локацију је блокирана. Отворите подешавања да бисте дозволили приступ локацији.';

  @override
  String get activityLocationServiceDisabled =>
      'Услуге локације су онемогућене.';

  @override
  String get activityLocationStreamFailed =>
      'Ажурирања локације су се неочекивано зауставила.';

  @override
  String get activityGpxGenerationFailed =>
      'Није могуће креирати GPX датотеку активности.';

  @override
  String get activityLocalSaveFailed =>
      'Није могуће сачувати ову активност на овом уређају.';

  @override
  String get activityOpenSettings => 'Отвори подешавања';

  @override
  String get activityPause => 'Паузирај';

  @override
  String get activityRecordingEmpty => 'Није забележена ниједна GPS тачка.';

  @override
  String get activityRecordingFailed => 'Снимање није успело.';

  @override
  String get activityResume => 'Настави';

  @override
  String get activityRetryUpload => 'Покушај отпремање поново';

  @override
  String get activityDone => 'Готово';

  @override
  String get activityViewHistory => 'Прикажи историју';

  @override
  String get activityDeleteLocal => 'Избриши локалну копију';

  @override
  String get activityExportGpx => 'Дели GPX датотеку';

  @override
  String get activityExportGpxSubject => 'GPX активности Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Избрисати локалну активност?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Ово уклања запис локалне активности и GPX датотеку са овог уређаја.';

  @override
  String get activityStart => 'Започни';

  @override
  String get activityBackgroundPermissionTitle =>
      'Дозволити праћење у позадини?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain захтева да локација у позадини буде подешена на Увек, како би се снимање наставило када је апликација у позадини, екран је закључан или промените апликацију.';

  @override
  String get activityBackgroundPermissionContinue => 'Настави';

  @override
  String get activityBackgroundPermissionRequired =>
      'Праћење у позадини на iPhone-у и iPad-у захтева да локација буде подешена на Увек.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Праћење у позадини је искључено';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'За поуздано снимање у позадини или са закључаним екраном, отворите Подешавања и подесите Локацију на Увек за Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Снимање активности';

  @override
  String get activityTrackingNotificationText =>
      'Endurain прати вашу локацију да би снимио ову активност.';

  @override
  String get activityStatDistance => 'Раздаљина';

  @override
  String get activityStatDuration => 'Време';

  @override
  String get activityStatSpeed => 'Брзина';

  @override
  String get activityStop => 'Заустави';

  @override
  String get activityStopAndSave => 'Заустави и сачувај';

  @override
  String get activityStopConfirmMessage =>
      'Изаберите да ли желите да задржите ово снимање или да га одбаците.';

  @override
  String get activityStopConfirmTitle => 'Завршити активност?';

  @override
  String get activityStopping => 'Заустављање';

  @override
  String get activityTypeHike => 'Планинарење';

  @override
  String get activityTypeLabel => 'Тип активности';

  @override
  String get activityTypeOther => 'Друго';

  @override
  String get activityTypeRide => 'Бициклизам';

  @override
  String get activityTypeRun => 'Трчање';

  @override
  String get activityTypeWalk => 'Ходање';

  @override
  String get activityUploadFailed => 'Отпремање није успело';

  @override
  String get activityUploadCleanupFailed =>
      'Отпремљено, али чишћење није успело';

  @override
  String get activityUploadReady => 'Спремно за отпремање';

  @override
  String get activityUploaded => 'Отпремљено';

  @override
  String get activityUploading => 'Отпремање';

  @override
  String get activityUploadStatusPending => 'На чекању';

  @override
  String get activityUploadStatusUploaded => 'Отпремљено';

  @override
  String get activityUploadStatusFailed => 'Неуспело';

  @override
  String get activityHistoryTitle => 'Историја активности';

  @override
  String get activityHistorySettingsSubtitle =>
      'Завршене активности сачуване на овом уређају';

  @override
  String get activityRetainUploadedGpx => 'Задржи отпремљене GPX датотеке';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Чува завршене датотеке рута у приватном складишту апликације након отпремања.';

  @override
  String get activityHistoryEmpty =>
      'Нема завршених активности сачуваних на овом уређају.';

  @override
  String get activityHistoryLoadFailed =>
      'Није могуће учитати локалне активности.';

  @override
  String get activityHistoryRefresh => 'Освежи';

  @override
  String get activityHistoryLocalActivities => 'Локалне активности';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Трајање: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Раздаљина: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Отпремање: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Учитај још';

  @override
  String get activityHistoryDetailsTitle => 'Детаљи активности';

  @override
  String get activityHistoryDetailsMissing =>
      'Ова локална активност више није доступна.';

  @override
  String get activityHistorySummary => 'Резиме';

  @override
  String get activityHistoryActions => 'Радње';

  @override
  String get activityHistoryType => 'Тип';

  @override
  String get activityHistoryStartedAt => 'Почетак';

  @override
  String get activityHistoryEndedAt => 'Крај';

  @override
  String get activityHistoryDurationLabel => 'Трајање';

  @override
  String get activityHistoryDistanceLabel => 'Раздаљина';

  @override
  String get activityHistoryAverageSpeed => 'Просечна брзина';

  @override
  String get activityHistoryPointCount => 'GPS тачке';

  @override
  String get activityHistoryUploadStatusLabel => 'Отпремање';

  @override
  String get activityHistoryGpxStatus => 'GPX датотека';

  @override
  String get activityHistoryGpxAvailable => 'Сачувано на овом уређају';

  @override
  String get activityHistoryGpxMissing => 'Није доступно на овом уређају';

  @override
  String get mapTab => 'Мапа';

  @override
  String get myLocation => 'Моја локација';

  @override
  String get settingsTab => 'Подешавања';

  @override
  String get settingsScreen => 'Подешавања';

  @override
  String get language => 'Језик';

  @override
  String get languageSystemDefault => 'Подразумевано за систем';

  @override
  String get serverSettings => 'Сервер';

  @override
  String get signInConnectServer => 'Пријава';

  @override
  String get signInConnectServerSubtitle =>
      'Снимајте офлајн сада и синхронизујте активности касније';

  @override
  String get serverSettingsTitle => 'Подешавања сервера';

  @override
  String get loggedIn => 'Пријављени';

  @override
  String get notConfigured => 'Није подешено';

  @override
  String get notLoggedIn => 'Нисте пријављени';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverUrlHint => 'https://primer.com';

  @override
  String get warnHttpServerUrlTitle => 'Небезбедна веза';

  @override
  String get warnHttpServerUrlMessage =>
      'Овај URL сервера користи обичан HTTP. Ваши подаци за пријаву и подаци биће пренети без шифровања. Наставите само ако разумете и прихватате ризик.';

  @override
  String get warnHttpServerUrlConfirm => 'Ипак настави';

  @override
  String get tileServerUrl => 'URL сервера плочица мапе';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Другачији хост сервера плочица';

  @override
  String get tileServerHostWarningMessage =>
      'Хост сервера плочица разликује се од хоста вашег Endurain сервера. Плочице ће се учитати са сервера треће стране. Желите ли да наставите?';

  @override
  String get savedSuccessfully => 'Подешавања су успешно сачувана';

  @override
  String get diagnostics => 'Дијагностика';

  @override
  String get diagnosticsSubtitle => 'Локални контекст падова';

  @override
  String get sourceCode => 'Изворни код';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Није могуће отворити везу';

  @override
  String get diagnosticsTitle => 'Дијагностика';

  @override
  String get diagnosticsCollection => 'Прикупљање';

  @override
  String get diagnosticsEnable => 'Прикупљај дијагностику';

  @override
  String get diagnosticsEnableSubtitle =>
      'Чувај недавне догађаје и грешке апликације на овом уређају';

  @override
  String get diagnosticsDisabled =>
      'Прикупљање дијагностике је искључено. Укључите га да бисте почели да бележите догађаје и грешке апликације на овом уређају.';

  @override
  String get diagnosticsEmpty =>
      'Још увек нису прикупљени дијагностички подаци.';

  @override
  String get diagnosticsCopy => 'Копирај';

  @override
  String get diagnosticsCopied => 'Дијагностика је копирана';

  @override
  String get diagnosticsClear => 'Обриши';

  @override
  String get diagnosticsCleared => 'Дијагностика је обрисана';

  @override
  String get diagnosticsSummary => 'Резиме';

  @override
  String get diagnosticsLastUpdated => 'Последње ажурирање';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Догађаји: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Грешке: $count';
  }

  @override
  String get diagnosticsEvents => 'Догађаји';

  @override
  String get diagnosticsNoEvents => 'Нема забележених догађаја';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Догађај: $event';
  }

  @override
  String get diagnosticsErrors => 'Грешке';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Грешка: $type';
  }

  @override
  String get diagnosticsActions => 'Радње';

  @override
  String get diagnosticsRawReport => 'Необрађени извештај';
}
