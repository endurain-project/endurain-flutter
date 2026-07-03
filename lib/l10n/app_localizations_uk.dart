// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get error => 'Помилка';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Скасувати';

  @override
  String get save => 'Зберегти';

  @override
  String get back => 'Назад';

  @override
  String get requiredField => 'Це поле обов\'язкове';

  @override
  String get invalidUrl => 'Введіть дійсний URL';

  @override
  String get errorActivityUploadFailed => 'Не вдалося завантажити активність';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Не вдалося завантажити активність: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Завантаження активностей ще не налаштовано';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Не вдалося видалити тимчасовий файл активності';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Не вдалося підготувати файл для завантаження активності';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Не вдалося знайти цю локальну активність';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Не вдалося видалити локальну активність';

  @override
  String get errorActivityLocalGpxMissing => 'Локальний файл GPX недоступний';

  @override
  String get errorActivityLocalLoadFailed =>
      'Не вдалося завантажити локальні активності';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Не вдалося зберегти цю активність';

  @override
  String get errorActivityLocalSaveFailed =>
      'Не вдалося зберегти активність локально';

  @override
  String get errorFetchProvidersFailed =>
      'Не вдалося завантажити постачальників входу';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Не вдалося завантажити постачальників входу: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Не вдалося завантажити налаштування сервера';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Не вдалося завантажити налаштування сервера: $details';
  }

  @override
  String get errorLoginError => 'Не вдалося увійти';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Не вдалося увійти: $details';
  }

  @override
  String get errorLoginFailed => 'Помилка входу';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Помилка входу: $details';
  }

  @override
  String get errorMfaVerificationError => 'Не вдалося перевірити код MFA';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Не вдалося перевірити код MFA: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Помилка перевірки MFA';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Помилка перевірки MFA: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Сервер не повернув ідентифікатор сеансу';

  @override
  String get errorNotAuthenticated => 'Ви не ввійшли';

  @override
  String get errorPkceVerifierMissing => 'Верифікатор входу не знайдено';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Верифікатор входу не знайдено. Почніть вхід знову.';

  @override
  String get errorServerUrlNotConfigured => 'URL сервера не налаштовано';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Цей сервер потребує безпечного (HTTPS) з\'єднання';

  @override
  String get errorSessionExpired => 'Ваш сеанс завершився. Увійдіть знову.';

  @override
  String get errorSsoTokenExchangeError =>
      'Не вдалося завершити вхід через SSO';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Не вдалося завершити вхід через SSO: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Помилка обміну токенів';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Помилка обміну токенів: $details';
  }

  @override
  String get errorRequestTimeout =>
      'Час очікування запиту вичерпано. Перевірте з\'єднання й повторіть спробу.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Не вдалося видалити з безпечного сховища. Сховище пристрою може бути недоступним.';

  @override
  String get errorSecureStorageReadFailed =>
      'Не вдалося прочитати з безпечного сховища. Сховище пристрою може бути недоступним.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Не вдалося записати в безпечне сховище. Сховище пристрою може бути недоступним.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Сервер повернув неочікувану відповідь';

  @override
  String get errorUnsupportedHttpMethod => 'Непідтримуваний метод HTTP';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Непідтримуваний метод HTTP: $details';
  }

  @override
  String get loginTitle => 'Вхід';

  @override
  String get login => 'Увійти';

  @override
  String get logout => 'Вийти';

  @override
  String get logoutConfirmTitle => 'Вийти';

  @override
  String get logoutConfirmMessage => 'Ви впевнені, що хочете вийти?';

  @override
  String get logoutServerFailedWarning =>
      'Не вдалося вийти із сервера, але вихід виконано локально';

  @override
  String get ssoBrowserLaunchFailed =>
      'Не вдалося відкрити вхід через SSO у системному браузері';

  @override
  String get ssoMissingSessionId =>
      'Відповідь SSO не містила ідентифікатора сеансу';

  @override
  String ssoSignInWith(String provider) {
    return 'Увійти через $provider';
  }

  @override
  String get ssoOrDivider => 'АБО';

  @override
  String get next => 'Далі';

  @override
  String get username => 'Ім\'я користувача';

  @override
  String get usernameHint => 'Введіть своє ім\'я користувача';

  @override
  String get password => 'Пароль';

  @override
  String get passwordHint => 'Введіть свій пароль';

  @override
  String get showPassword => 'Показати пароль';

  @override
  String get mfaTitle => 'Двофакторна автентифікація';

  @override
  String get mfaCode => 'Код MFA';

  @override
  String get mfaCodeHint => 'Введіть 6-значний код';

  @override
  String get mfaCodeRequired => 'Введіть код MFA';

  @override
  String get verify => 'Перевірити';

  @override
  String get activityDiscard => 'Відхилити';

  @override
  String get activityDiscardConfirmMessage =>
      'Це видалить записані точки цієї активності.';

  @override
  String get activityDiscardConfirmTitle => 'Відхилити активність?';

  @override
  String get activityLocationPermissionDenied =>
      'Для запису активності потрібен дозвіл на доступ до геопозиції.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Дозвіл на геопозицію заблоковано. Відкрийте налаштування, щоб дозволити доступ до геопозиції.';

  @override
  String get activityLocationServiceDisabled => 'Служби геопозиції вимкнено.';

  @override
  String get activityLocationStreamFailed =>
      'Оновлення геопозиції несподівано припинилися.';

  @override
  String get activityGpxGenerationFailed =>
      'Не вдалося створити файл GPX активності.';

  @override
  String get activityLocalSaveFailed =>
      'Не вдалося зберегти цю активність на цьому пристрої.';

  @override
  String get activityOpenSettings => 'Відкрити налаштування';

  @override
  String get activityPause => 'Пауза';

  @override
  String get activityRecordingEmpty => 'Жодної точки GPS не записано.';

  @override
  String get activityRecordingFailed => 'Помилка запису.';

  @override
  String get activityResume => 'Продовжити';

  @override
  String get activityRetryUpload => 'Повторити завантаження';

  @override
  String get activityDone => 'Готово';

  @override
  String get activityViewHistory => 'Переглянути історію';

  @override
  String get activityDeleteLocal => 'Видалити локальну копію';

  @override
  String get activityExportGpx => 'Поділитися файлом GPX';

  @override
  String get activityExportGpxSubject => 'GPX активності Endurain';

  @override
  String get activityDeleteLocalConfirmTitle => 'Видалити локальну активність?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Це видалить запис локальної активності та файл GPX із цього пристрою.';

  @override
  String get activityStart => 'Почати';

  @override
  String get activityBackgroundPermissionTitle =>
      'Дозволити відстеження у фоновому режимі?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain потребує, щоб фонова геопозиція була встановлена на «Завжди», щоб запис тривав, коли застосунок у фоні, екран заблоковано або ви перемикаєте застосунки.';

  @override
  String get activityBackgroundPermissionContinue => 'Продовжити';

  @override
  String get activityBackgroundPermissionRequired =>
      'Відстеження у фоновому режимі на iPhone та iPad потребує геопозиції, встановленої на «Завжди».';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Фонове відстеження вимкнено';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Щоб надійно записувати у фоновому режимі або із заблокованим екраном, відкрийте Налаштування та встановіть Геопозицію на «Завжди» для Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Запис активності';

  @override
  String get activityTrackingNotificationText =>
      'Endurain відстежує вашу геопозицію, щоб записати цю активність.';

  @override
  String get activityStatDistance => 'Відстань';

  @override
  String get activityStatDuration => 'Час';

  @override
  String get activityStatSpeed => 'Швидкість';

  @override
  String get activityStop => 'Зупинити';

  @override
  String get activityStopAndSave => 'Зупинити та зберегти';

  @override
  String get activityStopConfirmMessage =>
      'Виберіть, чи зберегти цей запис, чи відхилити його.';

  @override
  String get activityStopConfirmTitle => 'Завершити активність?';

  @override
  String get activityStopping => 'Зупинка';

  @override
  String get activityTypeHike => 'Похід';

  @override
  String get activityTypeLabel => 'Тип активності';

  @override
  String get activityTypeOther => 'Інше';

  @override
  String get activityTypeRide => 'Велосипед';

  @override
  String get activityTypeRun => 'Біг';

  @override
  String get activityTypeWalk => 'Ходьба';

  @override
  String get activityUploadFailed => 'Помилка завантаження';

  @override
  String get activityUploadCleanupFailed =>
      'Завантажено, але не вдалося очистити';

  @override
  String get activityUploadReady => 'Готово до завантаження';

  @override
  String get activityUploaded => 'Завантажено';

  @override
  String get activityUploading => 'Завантаження';

  @override
  String get activityUploadStatusPending => 'Очікує';

  @override
  String get activityUploadStatusUploaded => 'Завантажено';

  @override
  String get activityUploadStatusFailed => 'Не вдалося';

  @override
  String get activityHistoryTitle => 'Історія активностей';

  @override
  String get activityHistorySettingsSubtitle =>
      'Завершені активності, збережені на цьому пристрої';

  @override
  String get activityRetainUploadedGpx => 'Зберігати завантажені файли GPX';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Зберігає завершені файли маршрутів у приватному сховищі застосунку після завантаження.';

  @override
  String get activityHistoryEmpty =>
      'На цьому пристрої немає збережених завершених активностей.';

  @override
  String get activityHistoryLoadFailed =>
      'Не вдалося завантажити локальні активності.';

  @override
  String get activityHistoryRefresh => 'Оновити';

  @override
  String get activityHistoryLocalActivities => 'Локальні активності';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Тривалість: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Відстань: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Завантаження: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Завантажити ще';

  @override
  String get activityHistoryDetailsTitle => 'Деталі активності';

  @override
  String get activityHistoryDetailsMissing =>
      'Ця локальна активність більше недоступна.';

  @override
  String get activityHistorySummary => 'Підсумок';

  @override
  String get activityHistoryActions => 'Дії';

  @override
  String get activityHistoryType => 'Тип';

  @override
  String get activityHistoryStartedAt => 'Початок';

  @override
  String get activityHistoryEndedAt => 'Завершення';

  @override
  String get activityHistoryDurationLabel => 'Тривалість';

  @override
  String get activityHistoryDistanceLabel => 'Відстань';

  @override
  String get activityHistoryAverageSpeed => 'Середня швидкість';

  @override
  String get activityHistoryPointCount => 'Точки GPS';

  @override
  String get activityHistoryUploadStatusLabel => 'Завантаження';

  @override
  String get activityHistoryGpxStatus => 'Файл GPX';

  @override
  String get activityHistoryGpxAvailable => 'Збережено на цьому пристрої';

  @override
  String get activityHistoryGpxMissing => 'Недоступно на цьому пристрої';

  @override
  String get mapTab => 'Мапа';

  @override
  String get myLocation => 'Моє місцеположення';

  @override
  String get settingsTab => 'Налаштування';

  @override
  String get settingsScreen => 'Налаштування';

  @override
  String get language => 'Мова';

  @override
  String get languageSystemDefault => 'Системна за замовчуванням';

  @override
  String get serverSettings => 'Сервер';

  @override
  String get signInConnectServer => 'Увійти';

  @override
  String get signInConnectServerSubtitle =>
      'Записуйте офлайн зараз і синхронізуйте активності пізніше';

  @override
  String get serverSettingsTitle => 'Налаштування сервера';

  @override
  String get loggedIn => 'Ви ввійшли';

  @override
  String get notConfigured => 'Не налаштовано';

  @override
  String get notLoggedIn => 'Ви не ввійшли';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverUrlHint => 'https://example.com';

  @override
  String get warnHttpServerUrlTitle => 'Незахищене з\'єднання';

  @override
  String get warnHttpServerUrlMessage =>
      'Цей URL сервера використовує звичайний HTTP. Ваші облікові дані та дані передаватимуться без шифрування. Продовжуйте, лише якщо ви розумієте й приймаєте ризик.';

  @override
  String get warnHttpServerUrlConfirm => 'Усе одно продовжити';

  @override
  String get tileServerUrl => 'URL сервера картографічних плиток';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Інший хост сервера плиток';

  @override
  String get tileServerHostWarningMessage =>
      'Хост сервера плиток відрізняється від хоста вашого сервера Endurain. Плитки завантажуватимуться зі стороннього сервера. Продовжити?';

  @override
  String get savedSuccessfully => 'Налаштування успішно збережено';

  @override
  String get diagnostics => 'Діагностика';

  @override
  String get diagnosticsSubtitle => 'Локальний контекст збоїв';

  @override
  String get diagnosticsTitle => 'Діагностика';

  @override
  String get diagnosticsEmpty => 'Ще не зібрано жодних діагностичних даних.';

  @override
  String get diagnosticsCopy => 'Копіювати';

  @override
  String get diagnosticsCopied => 'Діагностику скопійовано';

  @override
  String get diagnosticsClear => 'Очистити';

  @override
  String get diagnosticsCleared => 'Діагностику очищено';

  @override
  String get diagnosticsSummary => 'Підсумок';

  @override
  String get diagnosticsLastUpdated => 'Останнє оновлення';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Події: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Помилки: $count';
  }

  @override
  String get diagnosticsEvents => 'Події';

  @override
  String get diagnosticsNoEvents => 'Подій не зафіксовано';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Подія: $event';
  }

  @override
  String get diagnosticsErrors => 'Помилки';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Помилка: $type';
  }

  @override
  String get diagnosticsActions => 'Дії';

  @override
  String get diagnosticsRawReport => 'Необроблений звіт';
}
