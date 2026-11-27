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
  String get errorActivityIngestionUnsupportedFormat =>
      'Формат файлу не підтримується';

  @override
  String get errorActivityIngestionInvalidFile =>
      'Файл пошкоджено або його не вдалося прочитати';

  @override
  String get errorActivityIngestionNoActivitiesFound =>
      'У файлі не знайдено активностей';

  @override
  String get errorActivityIngestionProcessingFailed =>
      'Під час імпорту активності сталася помилка. Спробуйте ще раз.';

  @override
  String get errorActivityIngestionProviderUnavailable =>
      'Постачальник активностей зараз недоступний. Спробуйте пізніше.';

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
  String get errorHealthGpxBuildFailed =>
      'Не вдалося конвертувати тренування в GPX';

  @override
  String get errorHealthImportFailed => 'Не вдалося імпортувати тренування';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Не вдалося імпортувати тренування: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'У доступі до даних про здоров’я відмовлено';

  @override
  String get errorHealthUnavailable =>
      'Дані про здоров’я недоступні на цьому пристрої';

  @override
  String get errorHealthReadFailed =>
      'Не вдалося прочитати дані про стан здоров\'я';

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
  String get errorMfaSessionMissing => 'Сеанс входу втрачено. Увійдіть знову.';

  @override
  String get errorSsoCallbackFailed =>
      'Не вдалося завершити єдиний вхід (SSO). Спробуйте ще раз.';

  @override
  String get errorNotAuthenticated => 'Ви не ввійшли';

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
  String get legacyDataTitle => 'Активності до оновлення сервера';

  @override
  String legacyDataMessageWithUsername(String username) {
    return 'На цьому пристрої є активності, збережені для облікового запису на цьому сервері ще до його оновлення. Вони ваші, $username? Якщо так, ті, що ще очікують, буде завантажено до вашого облікового запису.';
  }

  @override
  String get legacyDataMessage =>
      'На цьому пристрої є активності, збережені для облікового запису на цьому сервері ще до його оновлення. Вони належать обліковому запису, у який ви щойно увійшли? Якщо так, ті, що ще очікують, буде завантажено до нього.';

  @override
  String get legacyDataConfirm => 'Вони мої';

  @override
  String get legacyDataDecline => 'Не мої';

  @override
  String get errorActivityUploadLimit =>
      'На сервері виконується забагато ваших завантажень. Застосунок спробує знову пізніше.';

  @override
  String get errorPasswordChangeFailed => 'Не вдалося змінити пароль';

  @override
  String errorPasswordChangeFailedWithDetails(String details) {
    return 'Не вдалося змінити пароль: $details';
  }

  @override
  String get errorSignInStepUnsupported =>
      'Сервер запросив крок входу, який ця версія застосунку не підтримує. Оновіть застосунок і спробуйте знову.';

  @override
  String get errorSsoEmailMissing =>
      'Ваш постачальник ідентичності не надав адресу електронної пошти, потрібну для створення облікового запису.';

  @override
  String get errorSsoEmailUnverified =>
      'Ваш постачальник ідентичності не підтвердив вашу адресу електронної пошти. Підтвердьте її там і спробуйте знову.';

  @override
  String get errorSsoAutoCreateDisabled =>
      'Жоден обліковий запис не відповідає цьому входу, а цей сервер не створює облікові записи автоматично. Зверніться до адміністратора.';

  @override
  String get errorSsoLinkByEmailDisabled =>
      'Цю адресу електронної пошти вже використовує обліковий запис, але цей постачальник не може в нього увійти. Увійдіть іншим способом або зверніться до адміністратора.';

  @override
  String get errorSsoApprovalPending =>
      'Ваш обліковий запис очікує схвалення адміністратора.';

  @override
  String get errorSsoAccountDisabled =>
      'Цей обліковий запис вимкнено. Зверніться до адміністратора.';

  @override
  String get errorSsoRedirectNotAllowed =>
      'Цей сервер не дозволяє єдиний вхід із цього застосунку. Попросіть адміністратора додати com.endurain.endurain:/auth/sso/callback до ALLOWED_REDIRECT_URIS.';

  @override
  String get errorActivityMfaEnrolmentRequired =>
      'Ваш адміністратор вимагає двоетапної перевірки. Налаштуйте її у вебзастосунку Endurain і спробуйте знову.';

  @override
  String get errorActivityFileTooLarge =>
      'Файл активності завеликий для цього сервера';

  @override
  String get errorActivityUnsupportedFileType =>
      'Цей сервер не приймає такий тип файлу активності';

  @override
  String get errorTooManyRequests =>
      'Забагато спроб. Зачекайте трохи й спробуйте знову.';

  @override
  String get passwordChangeTitle => 'Виберіть новий пароль';

  @override
  String get passwordChangeMessage =>
      'Адміністратор установив ваш пароль. Виберіть новий, щоб завершити вхід.';

  @override
  String get newPassword => 'Новий пароль';

  @override
  String get confirmNewPassword => 'Підтвердьте новий пароль';

  @override
  String get passwordsDoNotMatch => 'Паролі не збігаються';

  @override
  String get changePassword => 'Змінити пароль';

  @override
  String get logoutServerFailedWarning =>
      'Не вдалося вийти із сервера, але вихід виконано локально';

  @override
  String get ssoBrowserLaunchFailed =>
      'Не вдалося відкрити вхід через SSO у системному браузері';

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
  String get mfaBackupCode => 'Резервний код';

  @override
  String get mfaBackupCodeHint =>
      'Введіть один зі своїх 8-символьних резервних кодів';

  @override
  String get mfaUseBackupCode => 'Використати резервний код';

  @override
  String get mfaUseAuthenticatorCode =>
      'Використати код із застосунку автентифікації';

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
  String get activityStatPace => 'Темп';

  @override
  String get activityStatMaxSpeed => 'Макс. швидкість';

  @override
  String get activityStatElevationGain => 'Набір висоти';

  @override
  String get activityStatHeartRate => 'Пульс';

  @override
  String get activityStatAvgHeartRate => 'Сер. пульс';

  @override
  String get activityStatPower => 'Потужність';

  @override
  String get activityStatAvgPower => 'Сер. потужність';

  @override
  String get activityStatCadence => 'Каденс';

  @override
  String get activityStatAvgCadence => 'Сер. каденс';

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
  String get activityUploadAwaitingSignIn =>
      'Збережено на цьому пристрої. Буде вивантажено після входу.';

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
  String get activityAutoPauseTitle => 'Автоматична пауза';

  @override
  String get activityAutoPauseSubtitle =>
      'Автоматично призупиняє, коли ви припиняєте рух';

  @override
  String get activityAutoPauseToggleLabel => 'Автоматично призупиняти';

  @override
  String get activityAutoPauseToggleDescription =>
      'Запис автоматично призупиняється, коли ви припиняєте рух, і відновлюється, щойно ви знову починаєте рухатися.';

  @override
  String get activityAutoPauseDelayHelperText =>
      'Виберіть, скільки часу без руху чекати перед призупиненням.';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    return '$seconds с';
  }

  @override
  String get activityAutoPausedIndicator => 'Автоматично призупинено';

  @override
  String get activityPausedIndicator => 'Призупинено';

  @override
  String get startCountdownSettingsTitle => 'Зворотний відлік перед стартом';

  @override
  String get startCountdownSettingsSubtitle => 'Відлік перед початком запису';

  @override
  String get startCountdownToggleLabel => 'Відлік перед стартом';

  @override
  String get startCountdownToggleDescription =>
      'Дає час сховати телефон, перш ніж почнеться запис.';

  @override
  String get startCountdownDurationHelperText =>
      'Виберіть, скільки триває зворотний відлік.';

  @override
  String startCountdownDurationOptionLabel(int seconds) {
    return '$seconds с';
  }

  @override
  String get startCountdownVoiceLabel => 'Озвучувати відлік';

  @override
  String get startCountdownVoiceDescription =>
      'Озвучує останні секунди й повідомляє, коли запис почався.';

  @override
  String get activityStartCountdownTitle => 'Запис почнеться через';

  @override
  String activityStartCountdownRemaining(int seconds) {
    return 'Залишилося секунд: $seconds';
  }

  @override
  String get activityStartCountdownStartNow => 'Почати зараз';

  @override
  String activityStartCountdownAddSeconds(int seconds) {
    return '+$seconds с';
  }

  @override
  String get audioAnnouncementsRecordingStarted => 'Запис розпочато';

  @override
  String get audioAnnouncementsAutoPaused => 'Запис призупинено';

  @override
  String get audioAnnouncementsAutoResumed => 'Запис відновлено';

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
  String get endurainTrademarkNotice =>
      'Endurain® є зареєстрованою торговельною маркою João Vitória Silva';

  @override
  String get settingsScreen => 'Налаштування';

  @override
  String get settingsSectionAccount => 'Обліковий запис';

  @override
  String get settingsSectionGeneral => 'Загальні';

  @override
  String get settingsSectionRecording => 'Запис';

  @override
  String get settingsSectionDevices => 'Пристрої та інтеграції';

  @override
  String get settingsSectionData => 'Дані';

  @override
  String get settingsSectionPrivacySupport => 'Конфіденційність і підтримка';

  @override
  String get deviceAccessTitle => 'Доступ до пристрою';

  @override
  String get deviceAccessSubtitle =>
      'Керуйте доступом до геопозиції та даних про здоров’я';

  @override
  String get deviceAccessLocationSection => 'Геопозиція';

  @override
  String get deviceAccessHealthSection => 'Дані про здоров\'я';

  @override
  String get deviceAccessLocationTitle => 'Доступ до геопозиції';

  @override
  String get deviceAccessHealthTitle => 'Доступ до даних про здоров\'я';

  @override
  String get deviceAccessBluetoothSection => 'Bluetooth';

  @override
  String get deviceAccessBluetoothTitle => 'Доступ до Bluetooth';

  @override
  String get deviceAccessBluetoothAllowed => 'Дозволено';

  @override
  String get deviceAccessBluetoothOff => 'Bluetooth вимкнено';

  @override
  String get deviceAccessBluetoothBlocked =>
      'Заблоковано в системних налаштуваннях';

  @override
  String get deviceAccessBluetoothNotAllowed => 'Не дозволено';

  @override
  String get deviceAccessBluetoothUnavailable => 'Недоступно на цьому пристрої';

  @override
  String get deviceAccessChecking => 'Перевірка доступу…';

  @override
  String get deviceAccessLocationServicesOff => 'Служби геопозиції вимкнено';

  @override
  String get deviceAccessLocationAlways => 'Завжди дозволено';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Дозволено під час використання застосунку';

  @override
  String get deviceAccessLocationBlocked =>
      'Заблоковано в системних налаштуваннях';

  @override
  String get deviceAccessLocationNotAllowed => 'Не дозволено';

  @override
  String get deviceAccessHealthUnavailable => 'Недоступно на цьому пристрої';

  @override
  String get deviceAccessHealthRequired => 'Потрібен Health Connect';

  @override
  String get deviceAccessHealthSetUp =>
      'Доступ до даних про здоров’я налаштовано';

  @override
  String get deviceAccessHealthNeedsAttention => 'Доступ потребує уваги';

  @override
  String get deviceAccessHealthNotConnected => 'Не підключено';

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
  String connectedToServer(String server) {
    return 'Підключено до $server';
  }

  @override
  String get loggedIn => 'Ви ввійшли';

  @override
  String get serverNotSecure => 'Незахищено (HTTP)';

  @override
  String get notConfigured => 'Не налаштовано';

  @override
  String get notLoggedIn => 'Ви не ввійшли';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverProtocol => 'Протокол';

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
  String get mapTilesSettingsTitle => 'Картографічні плитки';

  @override
  String get mapTilesSettingsSubtitle => 'Сервер плиток для відображення карт';

  @override
  String get mapTilesSettingsNote =>
      'Діє, поки ви підключені до цього сервера. Після повторного входу замінюється налаштуванням плиток вашого сервера, якщо воно є.';

  @override
  String get mapTilesSettingsLoadFailed =>
      'Не вдалося завантажити налаштування картографічних плиток.';

  @override
  String get tryAgain => 'Спробувати ще раз';

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
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Не вдалося відкрити посилання';

  @override
  String get diagnosticsTitle => 'Діагностика';

  @override
  String get diagnosticsCollection => 'Збір';

  @override
  String get diagnosticsEnable => 'Збирати діагностику';

  @override
  String get diagnosticsEnableSubtitle =>
      'Зберігати останні події та помилки застосунку на цьому пристрої';

  @override
  String get diagnosticsDisabled =>
      'Збір діагностики вимкнено. Увімкніть його, щоб почати фіксувати події та помилки застосунку на цьому пристрої.';

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

  @override
  String get healthSyncSettingsTitle => 'Синхронізація даних про здоров’я';

  @override
  String get healthSyncSettingsSubtitle =>
      'Імпортуйте тренування зі своєї платформи здоров’я';

  @override
  String get healthSyncScreenTitle => 'Синхронізація даних про здоров’я';

  @override
  String get healthAccessScreenTitle => 'Доступ до даних про здоров’я';

  @override
  String get healthAccessRequestedData => 'Запитувані дані';

  @override
  String get healthAccessWorkouts => 'Тренування';

  @override
  String get healthAccessWorkoutRoutes => 'Маршрути тренувань';

  @override
  String get healthAccessHeartRate => 'Пульс';

  @override
  String get healthAccessAllowed => 'Дозволено';

  @override
  String get healthAccessNeedsAttention => 'Потребує уваги';

  @override
  String get healthAccessManagedBySystem => 'Керується в налаштуваннях системи';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit не повідомляє, які дані може читати Endurain. Перевірте доступ у програмі «Здоровʼя».';

  @override
  String get healthAccessReview => 'Перевірити доступ до даних про здоров’я';

  @override
  String get healthAccessReviewIos => 'Як перевірити доступ';

  @override
  String get healthAccessDisconnect => 'Від’єднати дані про здоров’я';

  @override
  String get healthAccessDisconnectTitle => 'Від’єднати дані про здоров’я?';

  @override
  String get healthAccessDisconnectMessage =>
      'Автоматичний імпорт і локальну історію імпорту для цього сервера буде скинуто. Наявні активності залишаться в історії.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Відкрийте програму «Здоровʼя», торкніться свого зображення профілю, а потім «Програми та служби». Виберіть Endurain і оновіть категорії даних.';

  @override
  String get healthAccessBlockedTitle => 'Дозвольте доступ у Health Connect';

  @override
  String get healthAccessBlockedMessage =>
      'Health Connect перестає запитувати після двох відмов у доступі. Відкрийте Health Connect, щоб дозволити Endurain читати ваші тренування, маршрути та пульс.';

  @override
  String get healthAccessOpenHealthConnect => 'Відкрити Health Connect';

  @override
  String get healthSyncAuthorize => 'Підключитися до даних про здоров’я';

  @override
  String get healthSyncInstallProvider => 'Встановити Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      'Для синхронізації тренувань потрібен Health Connect. Встановіть його, щоб продовжити.';

  @override
  String get healthSyncUnsupported =>
      'Синхронізація даних про здоров’я недоступна на цьому пристрої.';

  @override
  String get healthSyncSelectAll => 'Вибрати все';

  @override
  String get healthSyncClearSelection => 'Очистити';

  @override
  String healthSyncImportSelected(int count) {
    return 'Імпортувати вибрані ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return 'Імпортовано тренувань: $count.';
  }

  @override
  String get healthSyncNoRouteLabel => 'Немає маршруту GPS';

  @override
  String get healthSyncEmptyState =>
      'Не знайдено тренувань за вибраний період.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Деякі тренування пропущено, оскільки не надано доступ до маршрутів тренувань. Відкрийте Health Connect → Дозволи та дозвольте Endurain доступ до маршрутів тренувань.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Деякі тренування пропущено, оскільки Endurain не зміг прочитати їхні маршрути GPS. У програмі «Здоровʼя» відкрийте свій профіль, потім «Програми та служби», виберіть Endurain і дозвольте «Маршрути тренувань».';

  @override
  String get healthSyncHistoryAccessGuidance =>
      'Старіші тренування не показано, оскільки в Health Connect не надано доступ до попередніх даних. Щоб імпортувати їх, дозвольте Endurain «Доступ до попередніх даних» у Health Connect.';

  @override
  String get healthSyncReviewAccess => 'Перевірити доступ';

  @override
  String get healthSyncAutoSyncTitle => 'Імпортувати автоматично';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Нові тренування під час відкриття застосунку та, якщо дозволено, у фоновому режимі.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Ці тренування не містять GPS-маршруту, тому їх не можна імпортувати. Деякі застосунки (наприклад, Garmin Connect) записують активності в Apple Health, не передаючи маршрут. Тренування, записані за допомогою Apple Watch, містять маршрути й можуть бути імпортовані.';

  @override
  String get healthSyncBadgeNonImportable => 'Не імпортується';

  @override
  String get healthSyncViewAvailable => 'Доступні';

  @override
  String get healthSyncViewImported => 'Імпортовані';

  @override
  String get healthSyncDateRange => 'Період тренувань';

  @override
  String get healthSyncRange30Days => 'Останні 30 днів';

  @override
  String get healthSyncRange3Months => 'Останні 3 місяці';

  @override
  String get healthSyncRange6Months => 'Останні 6 місяців';

  @override
  String get healthSyncRangeYear => 'Останній рік';

  @override
  String get healthSyncRangeAll => 'Уся історія';

  @override
  String get healthSyncRangeCustom => 'Власний період';

  @override
  String get healthSyncImportedEmpty =>
      'Немає імпортованих тренувань для цього підключення.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Імпортовано: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Відновити';

  @override
  String get sensorsTitle => 'Датчики';

  @override
  String get sensorsSettingsSubtitle =>
      'Монітори пульсу та інші зовнішні датчики';

  @override
  String get sensorsHeartRateSection => 'Пульс';

  @override
  String get sensorsHeartRateHelp =>
      'Підключіть Bluetooth-монітор пульсу, щоб бачити свій пульс у реальному часі.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth вимкнено. Увімкніть його, щоб підключити датчик.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Дозвольте доступ до Bluetooth, щоб підключити датчик.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Цей пристрій не підтримує Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Шукати датчики';

  @override
  String get sensorsScanning => 'Пошук…';

  @override
  String get sensorsStopScan => 'Зупинити';

  @override
  String get sensorsNoDevices => 'Датчиків пульсу ще не знайдено.';

  @override
  String get sensorsAvailableSection => 'Доступні датчики';

  @override
  String get sensorsSavedSection => 'Збережений датчик';

  @override
  String get sensorsConnect => 'Підключити';

  @override
  String get sensorsConnecting => 'Підключення…';

  @override
  String get sensorsConnected => 'Підключено';

  @override
  String get sensorsDisconnect => 'Відключити';

  @override
  String get sensorsForget => 'Забути';

  @override
  String get sensorsConnectionFailed =>
      'Не вдалося підключитися. Спробуйте ще раз.';

  @override
  String get sensorsPermissionRequired =>
      'Для пошуку датчиків потрібен дозвіл на Bluetooth.';

  @override
  String get sensorsUnknownDevice => 'Невідомий датчик';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Потужність';

  @override
  String get sensorsPowerHelp =>
      'Підключіть Bluetooth-вимірювач потужності, щоб бачити свою потужність у реальному часі.';

  @override
  String get sensorsNoPowerDevices => 'Вимірювачів потужності ще не знайдено.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Каденс';

  @override
  String get sensorsCadenceHelp =>
      'Підключіть Bluetooth-датчик каденсу, щоб бачити свій каденс у реальному часі.';

  @override
  String get sensorsNoCadenceDevices => 'Датчиків каденсу ще не знайдено.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Віддалене звітування про збої';

  @override
  String get diagnosticsRemoteEnable => 'Надсилати звіти про збої';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Надсилайте звіти про збої та помилки на діагностичний сервер. Це незалежно від локальної діагностики; можна ввімкнути обидва, одне або жодного.';

  @override
  String get diagnosticsRemoteActive => 'Звіти про збої надсилаються';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Віддалене звітування про збої недоступне в цій версії.';

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
    return '$value фут';
  }

  @override
  String unitMile(String value) {
    return '$value ми';
  }

  @override
  String unitKilometersPerHour(String value) {
    return '$value км/год';
  }

  @override
  String unitMilesPerHour(String value) {
    return '$value ми/год';
  }

  @override
  String unitMinutesPerKilometer(String value) {
    return '$value хв/км';
  }

  @override
  String unitMinutesPerMile(String value) {
    return '$value хв/ми';
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
  String get unitsTitle => 'Одиниці виміру';

  @override
  String get unitsSubtitle => 'Одиниці відстані, швидкості та висоти';

  @override
  String get unitsSystemDefault => 'За регіоном пристрою';

  @override
  String get unitsMetric => 'Метричні (км)';

  @override
  String get unitsImperial => 'Імперські (ми)';

  @override
  String get errorInsecureRedirectRejected =>
      'Сервер спробував перенаправити на незахищене з\'єднання. Запит заблоковано для захисту ваших облікових даних.';

  @override
  String get errorTooManyRedirects =>
      'Сервер надто багато разів перенаправляв. Перевірте адресу сервера.';

  @override
  String get audioAnnouncementsTitle => 'Голосові оголошення';

  @override
  String get audioAnnouncementsSubtitle =>
      'Голосові оновлення про відстань, час, темп або швидкість';

  @override
  String get audioAnnouncementsMasterSwitch => 'Оголошувати прогрес активності';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Вимовляє вашу відстань, час, темп або швидкість під час запису';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Приглушувати інший звук під час озвучення';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Тимчасово знижує гучність іншого звуку під час кожного оголошення';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Інтервал оголошень за видом активності';

  @override
  String get audioAnnouncementsByDistance => 'Відстань';

  @override
  String get audioAnnouncementsByTime => 'Час';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Кожні $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Кожні $minutes хв';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Зменшити інтервал';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Збільшити інтервал';

  @override
  String get audioAnnouncementsPreview => 'Прослухати приклад';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'Попереднє відтворення оголошення недоступне на цьому пристрої';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Зміни застосуються до наступного запису.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Відстань $distance. Час $duration. Коло: $lapMetric. Загалом: $overallMetric.';
  }
}
