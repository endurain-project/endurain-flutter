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
  String get errorHealthGpxBuildFailed =>
      'Није могуће конвертовати вежбање у ГПКС';

  @override
  String get errorHealthImportFailed => 'Није могуће увести тренинг';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Није могуће увести тренинг: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Приступ здравственим подацима је одбијен';

  @override
  String get errorHealthReadFailed =>
      'Није могуће прочитати здравствене податке';

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
  String get activityStatPace => 'Темпо';

  @override
  String get activityStatMaxSpeed => 'Макс. брзина';

  @override
  String get activityStatElevationGain => 'Успон';

  @override
  String get activityStatHeartRate => 'Пулс';

  @override
  String get activityStatAvgHeartRate => 'Прос. пулс';

  @override
  String get activityStatPower => 'Снага';

  @override
  String get activityStatAvgPower => 'Прос. снага';

  @override
  String get activityStatCadence => 'Каденца';

  @override
  String get activityStatAvgCadence => 'Прос. каденца';

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
  String get endurainTrademarkNotice =>
      'Endurain® је регистровани жиг João Vitória Silva';

  @override
  String get settingsScreen => 'Подешавања';

  @override
  String get deviceAccessTitle => 'Приступ уређају';

  @override
  String get deviceAccessSubtitle =>
      'Управљајте приступом локацији и здравственим подацима';

  @override
  String get deviceAccessLocationSection => 'Локација';

  @override
  String get deviceAccessHealthSection => 'Здравствени подаци';

  @override
  String get deviceAccessLocationTitle => 'Приступ локацији';

  @override
  String get deviceAccessHealthTitle => 'Приступ здравственим подацима';

  @override
  String get deviceAccessChecking => 'Провера приступа…';

  @override
  String get deviceAccessLocationServicesOff => 'Услуге локације су искључене';

  @override
  String get deviceAccessLocationAlways => 'Дозвољено све време';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Дозвољено док користите апликацију';

  @override
  String get deviceAccessLocationBlocked =>
      'Блокирано у системским подешавањима';

  @override
  String get deviceAccessLocationNotAllowed => 'Није дозвољено';

  @override
  String get deviceAccessHealthUnavailable => 'Није доступно на овом уређају';

  @override
  String get deviceAccessHealthRequired => 'Хеалтх Цоннецт је обавезан';

  @override
  String get deviceAccessHealthSetUp => 'Постављен здравствени приступ';

  @override
  String get deviceAccessHealthNeedsAttention => 'Приступ захтева пажњу';

  @override
  String get deviceAccessHealthNotConnected => 'Није повезан';

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
  String connectedToServer(String server) {
    return 'Повезано са $server';
  }

  @override
  String get loggedIn => 'Пријављени';

  @override
  String get notConfigured => 'Није подешено';

  @override
  String get notLoggedIn => 'Нисте пријављени';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverProtocol => 'Протокол';

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
  String get sourceCodeSubtitle =>
      'github.com/endurain-project';

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

  @override
  String get healthSyncSettingsTitle => 'Здравствена синхронизација';

  @override
  String get healthSyncSettingsSubtitle =>
      'Увезите вежбе са своје здравствене платформе';

  @override
  String get healthSyncScreenTitle => 'Здравствена синхронизација';

  @override
  String get healthAccessScreenTitle => 'Приступ здрављу';

  @override
  String get healthAccessRequestedData => 'Тражени подаци';

  @override
  String get healthAccessWorkouts => 'Вежбе';

  @override
  String get healthAccessWorkoutRoutes => 'Руте за вежбање';

  @override
  String get healthAccessHeartRate => 'Откуцаји срца';

  @override
  String get healthAccessWorkoutSummary =>
      'Раздаљина, калорије и кораци вежбања';

  @override
  String get healthAccessAllowed => 'Дозвољено';

  @override
  String get healthAccessNeedsAttention => 'Потребна је пажња';

  @override
  String get healthAccessManagedBySystem =>
      'Управља се у системским подешавањима';

  @override
  String get healthAccessSystemManagedNotice =>
      'ХеалтхКит не открива које податке Ендураин може да чита. Прегледајте приступ у апликацији Здравље.';

  @override
  String get healthAccessReview => 'Прегледајте здравствени приступ';

  @override
  String get healthAccessReviewIos => 'Како прегледати приступ';

  @override
  String get healthAccessDisconnect => 'Прекини везу са здравственим подацима';

  @override
  String get healthAccessDisconnectTitle =>
      'Прекинути везу са здравственим подацима?';

  @override
  String get healthAccessDisconnectMessage =>
      'Аутоматски увоз и локална историја увоза за овај сервер биће ресетовани. Постојеће активности остају у историји.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Отворите апликацију Здравље, додирните своју слику профила, затим Апликације и услуге. Изаберите Ендураин и ажурирајте категорије података.';

  @override
  String get healthSyncAuthorize => 'Повежите се са здравственим подацима';

  @override
  String get healthSyncInstallProvider => 'Инсталирајте Хеалтх Цоннецт';

  @override
  String get healthSyncInstallProviderDescription =>
      'Хеалтх Цоннецт је неопходан за синхронизацију тренинга. Инсталирајте га да бисте наставили.';

  @override
  String get healthSyncUnsupported =>
      'Синхронизација здравља није доступна на овом уређају.';

  @override
  String get healthSyncSelectAll => 'Изаберите све';

  @override
  String get healthSyncClearSelection => 'Јасно';

  @override
  String healthSyncImportSelected(int count) {
    return 'Изабран увоз ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Увезено вежби: $count.';
  }

  @override
  String get healthSyncNoRouteLabel => 'Нема ГПС руте';

  @override
  String get healthSyncEmptyState =>
      'Није пронађен ниједан тренинг у изабраном периоду.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Неки тренинзи су прескочени јер приступ рути вежбања није одобрен. Отворите Хеалтх Цоннецт → Дозволе и дозволите руте вежбања за Ендураин.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Неки тренинзи су прескочени јер Ендураин није могао да прочита њихове ГПС руте. У апликацији Здравље отворите свој профил, затим Апликације и услуге, изаберите Ендураин и дозволите Руте за вежбање.';

  @override
  String get healthSyncReviewAccess => 'Прегледајте приступ';

  @override
  String get healthSyncAutoSyncTitle => 'Аутоматска синхронизација у наставку';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Аутоматски увозите нове вежбе када се апликација отвори.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Ове вежбе не укључују ГПС руту, тако да се не могу увести. Неке апликације (као што је Гармин Цоннецт) бележе активности у Аппле Хеалтх без дељења руте. Вежбе снимљене помоћу Аппле Ватцх-а укључују руте и могу се увести.';

  @override
  String get healthSyncBadgeNonImportable => 'Неувозно';

  @override
  String get healthSyncViewAvailable => 'Доступно';

  @override
  String get healthSyncViewImported => 'Увезено';

  @override
  String get healthSyncDateRange => 'Период вежбања';

  @override
  String get healthSyncRange30Days => 'Последњих 30 дана';

  @override
  String get healthSyncRange3Months => 'Последња 3 месеца';

  @override
  String get healthSyncRange6Months => 'Последњих 6 месеци';

  @override
  String get healthSyncRangeYear => 'Последња година';

  @override
  String get healthSyncRangeAll => 'Цела историја';

  @override
  String get healthSyncRangeCustom => 'Прилагођени период';

  @override
  String get healthSyncImportedEmpty => 'Нема увезених вежбања за ову везу.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Увезено: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Врати';

  @override
  String get sensorsTitle => 'Сензори';

  @override
  String get sensorsSettingsSubtitle => 'Мерачи пулса и други спољни сензори';

  @override
  String get sensorsHeartRateSection => 'Пулс';

  @override
  String get sensorsHeartRateHelp =>
      'Упари Bluetooth мерач пулса да видиш свој пулс уживо.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth је искључен. Укључи га да повежеш сензор.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Дозволи приступ Bluetooth-у да повежеш сензор.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Овај уређај не подржава Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Тражи сензоре';

  @override
  String get sensorsScanning => 'Тражење…';

  @override
  String get sensorsStopScan => 'Заустави';

  @override
  String get sensorsNoDevices => 'Још нема пронађених сензора пулса.';

  @override
  String get sensorsAvailableSection => 'Доступни сензори';

  @override
  String get sensorsSavedSection => 'Сачувани сензор';

  @override
  String get sensorsConnect => 'Повежи';

  @override
  String get sensorsConnecting => 'Повезивање…';

  @override
  String get sensorsConnected => 'Повезано';

  @override
  String get sensorsDisconnect => 'Прекини везу';

  @override
  String get sensorsForget => 'Заборави';

  @override
  String get sensorsConnectionFailed =>
      'Повезивање није успело. Покушај поново.';

  @override
  String get sensorsPermissionRequired =>
      'За проналажење сензора потребна је дозвола за Bluetooth.';

  @override
  String get sensorsUnknownDevice => 'Непознат сензор';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Снага';

  @override
  String get sensorsPowerHelp =>
      'Упари Bluetooth мерач снаге да видиш своју снагу уживо.';

  @override
  String get sensorsNoPowerDevices => 'Још нема пронађених мерача снаге.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Каденца';

  @override
  String get sensorsCadenceHelp =>
      'Упари Bluetooth сензор каденце да видиш своју каденцу уживо.';

  @override
  String get sensorsNoCadenceDevices => 'Још нема пронађених сензора каденце.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Удаљено пријављивање падова';

  @override
  String get diagnosticsRemoteEnable => 'Шаљи извештаје о падовима';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Шаљи извештаје о падовима и грешкама на дијагностички сервер. Независно је од локалне дијагностике — можеш укључити обоје, једно или ништа.';

  @override
  String get diagnosticsRemoteActive => 'Crash reports are being sent.';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Удаљено пријављивање падова није доступно у овој верзији.';

  @override
  String unitMeter(String value) {
    return '$value м';
  }

  @override
  String unitKilometer(String value) {
    return '$value км';
  }

  @override
  String unitFoot(String value) {
    return '$value ст';
  }

  @override
  String unitMile(String value) {
    return '$value ми';
  }

  @override
  String unitKilometersPerHour(String value) {
    return '$value км/ч';
  }

  @override
  String unitMilesPerHour(String value) {
    return '$value ми/ч';
  }

  @override
  String unitMinutesPerKilometer(String value) {
    return '$value мин/км';
  }

  @override
  String unitMinutesPerMile(String value) {
    return '$value мин/ми';
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
  String get unitsTitle => 'Јединице';

  @override
  String get unitsSubtitle =>
      'Јединице за раздаљину, брзину и надморску висину';

  @override
  String get unitsSystemDefault => 'Према региону уређаја';

  @override
  String get unitsMetric => 'Метричке (км)';

  @override
  String get unitsImperial => 'Империјалне (ми)';

  @override
  String get errorInsecureRedirectRejected =>
      'The server tried to redirect to an insecure connection. The request was blocked to protect your credentials.';

  @override
  String get errorTooManyRedirects =>
      'The server redirected too many times. Check the server address.';
}
