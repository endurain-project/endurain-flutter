// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get error => 'Грешка';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Отказ';

  @override
  String get save => 'Запиши';

  @override
  String get back => 'Назад';

  @override
  String get requiredField => 'Това поле е задължително';

  @override
  String get invalidUrl => 'Въведете валиден URL адрес';

  @override
  String get errorActivityUploadFailed => 'Дейността не можа да бъде качена';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Дейността не можа да бъде качена: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Качването на дейности още не е конфигурирано';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Временният файл на дейността не можа да бъде изтрит';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Файлът за качване на дейността не можа да бъде подготвен';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Тази локална дейност не можа да бъде намерена';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Локалната дейност не можа да бъде изтрита';

  @override
  String get errorActivityLocalGpxMissing => 'Локалният GPX файл не е наличен';

  @override
  String get errorActivityLocalLoadFailed =>
      'Локалните дейности не можаха да бъдат заредени';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Тази дейност не можа да бъде записана';

  @override
  String get errorActivityLocalSaveFailed =>
      'Дейността не можа да бъде записана локално';

  @override
  String get errorFetchProvidersFailed =>
      'Доставчиците за вход не можаха да бъдат заредени';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Доставчиците за вход не можаха да бъдат заредени: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Настройките на сървъра не можаха да бъдат заредени';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Настройките на сървъра не можаха да бъдат заредени: $details';
  }

  @override
  String get errorLoginError => 'Входът не бе успешен';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Входът не бе успешен: $details';
  }

  @override
  String get errorLoginFailed => 'Неуспешен вход';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Неуспешен вход: $details';
  }

  @override
  String get errorMfaVerificationError => 'MFA кодът не можа да бъде потвърден';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'MFA кодът не можа да бъде потвърден: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Неуспешно потвърждаване на MFA';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Неуспешно потвърждаване на MFA: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Не е получен идентификатор на сесия от сървъра';

  @override
  String get errorNotAuthenticated => 'Не сте влезли';

  @override
  String get errorPkceVerifierMissing => 'Верификаторът за вход не бе намерен';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Верификаторът за вход не бе намерен. Започнете входа отначало.';

  @override
  String get errorServerUrlNotConfigured =>
      'URL адресът на сървъра не е конфигуриран';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Този сървър изисква защитена (HTTPS) връзка';

  @override
  String get errorSessionExpired => 'Сесията ви изтече. Влезте отново.';

  @override
  String get errorSsoTokenExchangeError =>
      'Входът чрез SSO не можа да бъде завършен';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Входът чрез SSO не можа да бъде завършен: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Неуспешна размяна на токени';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Неуспешна размяна на токени: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Времето за заявката изтече. Проверете връзката си и опитайте отново.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Не може да се изтрие от защитеното хранилище. Хранилището на устройството може да не е налично.';

  @override
  String get errorSecureStorageReadFailed =>
      'Не може да се чете от защитеното хранилище. Хранилището на устройството може да не е налично.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Не може да се записва в защитеното хранилище. Хранилището на устройството може да не е налично.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Сървърът върна неочакван отговор';

  @override
  String get errorUnsupportedHttpMethod => 'Неподдържан HTTP метод';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Неподдържан HTTP метод: $details';
  }

  @override
  String get loginTitle => 'Вход';

  @override
  String get login => 'Вход';

  @override
  String get logout => 'Изход';

  @override
  String get logoutConfirmTitle => 'Изход';

  @override
  String get logoutConfirmMessage => 'Наистина ли искате да излезете?';

  @override
  String get logoutServerFailedWarning =>
      'Изходът от сървъра не бе успешен, но излязохте локално';

  @override
  String get ssoBrowserLaunchFailed =>
      'Входът чрез SSO не можа да бъде отворен в системния браузър';

  @override
  String get ssoMissingSessionId =>
      'Отговорът на SSO не съдържаше идентификатор на сесия';

  @override
  String ssoSignInWith(String provider) {
    return 'Вход чрез $provider';
  }

  @override
  String get ssoOrDivider => 'ИЛИ';

  @override
  String get next => 'Напред';

  @override
  String get username => 'Потребителско име';

  @override
  String get usernameHint => 'Въведете потребителското си име';

  @override
  String get password => 'Парола';

  @override
  String get passwordHint => 'Въведете паролата си';

  @override
  String get showPassword => 'Показване на паролата';

  @override
  String get mfaTitle => 'Двуфакторно удостоверяване';

  @override
  String get mfaCode => 'MFA код';

  @override
  String get mfaCodeHint => 'Въведете 6-цифрения код';

  @override
  String get mfaCodeRequired => 'Въведете MFA кода';

  @override
  String get verify => 'Потвърди';

  @override
  String get activityDiscard => 'Отхвърли';

  @override
  String get activityDiscardConfirmMessage =>
      'Това ще изтрие записаните точки на тази дейност.';

  @override
  String get activityDiscardConfirmTitle => 'Да се отхвърли ли дейността?';

  @override
  String get activityLocationPermissionDenied =>
      'За записване на дейност е необходимо разрешение за местоположение.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Разрешението за местоположение е блокирано. Отворете настройките, за да разрешите достъп до местоположението.';

  @override
  String get activityLocationServiceDisabled =>
      'Услугите за местоположение са изключени.';

  @override
  String get activityLocationStreamFailed =>
      'Актуализациите на местоположението спряха неочаквано.';

  @override
  String get activityGpxGenerationFailed =>
      'GPX файлът на дейността не можа да бъде създаден.';

  @override
  String get activityLocalSaveFailed =>
      'Тази дейност не можа да бъде записана на това устройство.';

  @override
  String get activityOpenSettings => 'Отвори настройките';

  @override
  String get activityPause => 'Пауза';

  @override
  String get activityRecordingEmpty => 'Не бяха записани GPS точки.';

  @override
  String get activityRecordingFailed => 'Записването не бе успешно.';

  @override
  String get activityResume => 'Продължи';

  @override
  String get activityRetryUpload => 'Опитай качването отново';

  @override
  String get activityDone => 'Готово';

  @override
  String get activityViewHistory => 'Преглед на историята';

  @override
  String get activityDeleteLocal => 'Изтрий локалното копие';

  @override
  String get activityExportGpx => 'Сподели GPX файла';

  @override
  String get activityExportGpxSubject => 'GPX на дейност от Endurain';

  @override
  String get activityDeleteLocalConfirmTitle =>
      'Да се изтрие ли локалната дейност?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Това премахва записа на локалната дейност и GPX файла от това устройство.';

  @override
  String get activityStart => 'Старт';

  @override
  String get activityBackgroundPermissionTitle =>
      'Да се разреши ли проследяване във фонов режим?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain изисква местоположението във фонов режим да е зададено на Винаги, за да продължи записването, когато приложението е във фонов режим, екранът е заключен или превключвате приложения.';

  @override
  String get activityBackgroundPermissionContinue => 'Продължи';

  @override
  String get activityBackgroundPermissionRequired =>
      'Проследяването във фонов режим на iPhone и iPad изисква местоположението да е зададено на Винаги.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Проследяването във фонов режим е изключено';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'За да записвате надеждно във фонов режим или при заключен екран, отворете Настройки и задайте Местоположение на Винаги за Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Записване на дейност';

  @override
  String get activityTrackingNotificationText =>
      'Endurain проследява местоположението ви, за да запише тази дейност.';

  @override
  String get activityStatDistance => 'Разстояние';

  @override
  String get activityStatDuration => 'Време';

  @override
  String get activityStatSpeed => 'Скорост';

  @override
  String get activityStop => 'Стоп';

  @override
  String get activityStopAndSave => 'Спри и запиши';

  @override
  String get activityStopConfirmMessage =>
      'Изберете дали да запазите този запис, или да го отхвърлите.';

  @override
  String get activityStopConfirmTitle => 'Да се приключи ли дейността?';

  @override
  String get activityStopping => 'Спиране';

  @override
  String get activityTypeHike => 'Планински преход';

  @override
  String get activityTypeLabel => 'Тип дейност';

  @override
  String get activityTypeOther => 'Друго';

  @override
  String get activityTypeRide => 'Колоездене';

  @override
  String get activityTypeRun => 'Бягане';

  @override
  String get activityTypeWalk => 'Ходене';

  @override
  String get activityUploadFailed => 'Качването не бе успешно';

  @override
  String get activityUploadCleanupFailed =>
      'Качено, но почистването не бе успешно';

  @override
  String get activityUploadReady => 'Готово за качване';

  @override
  String get activityUploaded => 'Качено';

  @override
  String get activityUploading => 'Качване';

  @override
  String get activityUploadStatusPending => 'Чакащо';

  @override
  String get activityUploadStatusUploaded => 'Качено';

  @override
  String get activityUploadStatusFailed => 'Неуспешно';

  @override
  String get activityHistoryTitle => 'История на дейностите';

  @override
  String get activityHistorySettingsSubtitle =>
      'Завършени дейности, записани на това устройство';

  @override
  String get activityRetainUploadedGpx => 'Запазвай качените GPX файлове';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Записва завършените файлове с маршрути в частното хранилище на приложението след качване.';

  @override
  String get activityHistoryEmpty =>
      'Няма завършени дейности, записани на това устройство.';

  @override
  String get activityHistoryLoadFailed =>
      'Локалните дейности не можаха да бъдат заредени.';

  @override
  String get activityHistoryRefresh => 'Опресни';

  @override
  String get activityHistoryLocalActivities => 'Локални дейности';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Продължителност: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Разстояние: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Качване: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Зареди още';

  @override
  String get activityHistoryDetailsTitle => 'Подробности за дейността';

  @override
  String get activityHistoryDetailsMissing =>
      'Тази локална дейност вече не е налична.';

  @override
  String get activityHistorySummary => 'Обобщение';

  @override
  String get activityHistoryActions => 'Действия';

  @override
  String get activityHistoryType => 'Тип';

  @override
  String get activityHistoryStartedAt => 'Начало';

  @override
  String get activityHistoryEndedAt => 'Край';

  @override
  String get activityHistoryDurationLabel => 'Продължителност';

  @override
  String get activityHistoryDistanceLabel => 'Разстояние';

  @override
  String get activityHistoryAverageSpeed => 'Средна скорост';

  @override
  String get activityHistoryPointCount => 'GPS точки';

  @override
  String get activityHistoryUploadStatusLabel => 'Качване';

  @override
  String get activityHistoryGpxStatus => 'GPX файл';

  @override
  String get activityHistoryGpxAvailable => 'Записано на това устройство';

  @override
  String get activityHistoryGpxMissing => 'Не е налично на това устройство';

  @override
  String get mapTab => 'Карта';

  @override
  String get myLocation => 'Моето местоположение';

  @override
  String get settingsTab => 'Настройки';

  @override
  String get settingsScreen => 'Настройки';

  @override
  String get language => 'Език';

  @override
  String get languageSystemDefault => 'Системна по подразбиране';

  @override
  String get serverSettings => 'Сървър';

  @override
  String get signInConnectServer => 'Вход';

  @override
  String get signInConnectServerSubtitle =>
      'Записвайте офлайн сега и синхронизирайте дейностите си по-късно';

  @override
  String get serverSettingsTitle => 'Настройки на сървъра';

  @override
  String get loggedIn => 'Влезли сте';

  @override
  String get notConfigured => 'Не е конфигурирано';

  @override
  String get notLoggedIn => 'Не сте влезли';

  @override
  String get serverUrl => 'URL адрес на сървъра';

  @override
  String get serverUrlHint => 'https://primer.com';

  @override
  String get warnHttpServerUrlTitle => 'Незащитена връзка';

  @override
  String get warnHttpServerUrlMessage =>
      'Този URL адрес на сървъра използва обикновен HTTP. Данните ви за вход и данните ви ще бъдат предадени без криптиране. Продължете само ако разбирате и приемате риска.';

  @override
  String get warnHttpServerUrlConfirm => 'Продължи въпреки това';

  @override
  String get tileServerUrl => 'URL адрес на сървъра за картови плочки';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Различен хост на сървъра за плочки';

  @override
  String get tileServerHostWarningMessage =>
      'Хостът на сървъра за плочки се различава от хоста на вашия сървър Endurain. Плочките ще се зареждат от сървър на трета страна. Искате ли да продължите?';

  @override
  String get savedSuccessfully => 'Настройките са записани успешно';

  @override
  String get diagnostics => 'Диагностика';

  @override
  String get diagnosticsSubtitle => 'Локален контекст на сривове';

  @override
  String get sourceCode => 'Изходен код';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Връзката не може да бъде отворена';

  @override
  String get diagnosticsTitle => 'Диагностика';

  @override
  String get diagnosticsCollection => 'Събиране';

  @override
  String get diagnosticsEnable => 'Събиране на диагностика';

  @override
  String get diagnosticsEnableSubtitle =>
      'Съхранявайте последните събития и грешки на приложението на това устройство';

  @override
  String get diagnosticsDisabled =>
      'Събирането на диагностика е изключено. Включете го, за да започнете да записвате събития и грешки на приложението на това устройство.';

  @override
  String get diagnosticsEmpty => 'Все още не са събрани диагностични данни.';

  @override
  String get diagnosticsCopy => 'Копирай';

  @override
  String get diagnosticsCopied => 'Диагностиката е копирана';

  @override
  String get diagnosticsClear => 'Изчисти';

  @override
  String get diagnosticsCleared => 'Диагностиката е изчистена';

  @override
  String get diagnosticsSummary => 'Обобщение';

  @override
  String get diagnosticsLastUpdated => 'Последно обновено';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Събития: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Грешки: $count';
  }

  @override
  String get diagnosticsEvents => 'Събития';

  @override
  String get diagnosticsNoEvents => 'Няма записани събития';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Събитие: $event';
  }

  @override
  String get diagnosticsErrors => 'Грешки';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Грешка: $type';
  }

  @override
  String get diagnosticsActions => 'Действия';

  @override
  String get diagnosticsRawReport => 'Необработен отчет';
}
