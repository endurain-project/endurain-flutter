// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get error => '错误';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get back => '返回';

  @override
  String get requiredField => '此字段为必填项';

  @override
  String get invalidUrl => '请输入有效的网址';

  @override
  String get errorActivityUploadFailed => '无法上传活动';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return '无法上传活动：$details';
  }

  @override
  String get errorActivityIngestionUnsupportedFormat => '不支持该文件格式';

  @override
  String get errorActivityIngestionInvalidFile => '文件已损坏或无法读取';

  @override
  String get errorActivityIngestionNoActivitiesFound => '文件中未找到任何活动';

  @override
  String get errorActivityIngestionProcessingFailed => '导入活动时出错，请重试。';

  @override
  String get errorActivityIngestionProviderUnavailable => '活动提供方当前不可用，请稍后重试。';

  @override
  String get errorActivityUploadNotConfigured => '尚未配置活动上传';

  @override
  String get errorActivityGpxCleanupFailed => '无法删除临时活动文件';

  @override
  String get errorActivityGpxFileWriteFailed => '无法准备活动上传文件';

  @override
  String get errorActivityLocalActivityNotFound => '找不到此本地活动';

  @override
  String get errorActivityLocalDeleteFailed => '无法删除本地活动';

  @override
  String get errorActivityLocalGpxMissing => '本地 GPX 文件不可用';

  @override
  String get errorActivityLocalLoadFailed => '无法加载本地活动';

  @override
  String get errorActivityLocalRecordInvalid => '无法保存此活动';

  @override
  String get errorActivityLocalSaveFailed => '无法在本地保存活动';

  @override
  String get errorFetchProvidersFailed => '无法加载登录提供商';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return '无法加载登录提供商：$details';
  }

  @override
  String get errorFetchServerSettingsFailed => '无法加载服务器设置';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return '无法加载服务器设置：$details';
  }

  @override
  String get errorHealthGpxBuildFailed => '无法将锻炼数据转换为 GPX';

  @override
  String get errorHealthImportFailed => '无法导入锻炼';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return '无法导入锻炼：$details';
  }

  @override
  String get errorHealthPermissionDenied => '健康数据访问被拒绝';

  @override
  String get errorHealthUnavailable => '此设备上无法使用健康数据';

  @override
  String get errorHealthReadFailed => '无法读取健康数据';

  @override
  String get errorLoginError => '无法登录';

  @override
  String errorLoginErrorWithDetails(String details) {
    return '无法登录：$details';
  }

  @override
  String get errorLoginFailed => '登录失败';

  @override
  String errorLoginFailedWithDetails(String details) {
    return '登录失败：$details';
  }

  @override
  String get errorMfaVerificationError => '无法验证 MFA 代码';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return '无法验证 MFA 代码：$details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA 验证失败';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA 验证失败：$details';
  }

  @override
  String get errorNoSessionIdReceived => '未从服务器收到会话 ID';

  @override
  String get errorMfaSessionMissing => '您的登录会话已丢失。请重新登录。';

  @override
  String get errorSsoCallbackFailed => '无法完成单点登录。请重试。';

  @override
  String get errorNotAuthenticated => '您尚未登录';

  @override
  String get errorPkceVerifierMissingRestartLogin => '未找到登录验证器。请重新开始登录。';

  @override
  String get errorServerUrlNotConfigured => '未配置服务器网址';

  @override
  String get errorInsecureTransportNotAllowed => '此服务器需要安全（HTTPS）连接';

  @override
  String get errorSessionExpired => '您的会话已过期。请重新登录。';

  @override
  String get errorSsoTokenExchangeError => '无法完成 SSO 登录';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return '无法完成 SSO 登录：$details';
  }

  @override
  String get errorTokenExchangeFailed => '令牌交换失败';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return '令牌交换失败：$details';
  }

  @override
  String get errorRequestTimeout => '请求超时。请检查您的连接并重试。';

  @override
  String get errorSecureStorageDeleteFailed => '无法从安全存储中删除。您的设备存储可能不可用。';

  @override
  String get errorSecureStorageReadFailed => '无法从安全存储中读取。您的设备存储可能不可用。';

  @override
  String get errorSecureStorageWriteFailed => '无法写入安全存储。您的设备存储可能不可用。';

  @override
  String get errorUnexpectedResponseFormat => '服务器返回了意外的响应';

  @override
  String get errorUnsupportedHttpMethod => '不支持的 HTTP 方法';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return '不支持的 HTTP 方法：$details';
  }

  @override
  String get loginTitle => '登录';

  @override
  String get login => '登录';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirmTitle => '退出登录';

  @override
  String get logoutConfirmMessage => '确定要退出登录吗？';

  @override
  String get legacyDataTitle => '服务器更新前的活动';

  @override
  String legacyDataMessageWithUsername(String username) {
    return '此设备上保存有服务器更新前属于此服务器上某个账户的活动。它们是你的吗，$username？如果是，仍在等待的活动将上传到你的账户。';
  }

  @override
  String get legacyDataMessage =>
      '此设备上保存有服务器更新前属于此服务器上某个账户的活动。它们属于你刚刚登录的账户吗？如果是，仍在等待的活动将上传到该账户。';

  @override
  String get legacyDataConfirm => '是我的';

  @override
  String get legacyDataDecline => '不是我的';

  @override
  String get errorActivityUploadLimit => '服务器上你正在进行的上传过多。应用稍后会重试。';

  @override
  String get errorPasswordChangeFailed => '无法更改密码';

  @override
  String errorPasswordChangeFailedWithDetails(String details) {
    return '无法更改密码：$details';
  }

  @override
  String get errorSignInStepUnsupported => '此服务器要求的登录步骤不受此版本应用支持。请更新应用后重试。';

  @override
  String get errorSsoEmailMissing => '你的身份提供方未共享电子邮件地址，而创建账户需要该地址。';

  @override
  String get errorSsoEmailUnverified => '你的身份提供方尚未验证你的电子邮件地址。请在那里验证后重试。';

  @override
  String get errorSsoAutoCreateDisabled => '没有与此次登录匹配的账户，且此服务器不会自动创建账户。请联系管理员。';

  @override
  String get errorSsoLinkByEmailDisabled =>
      '已有账户使用此电子邮件地址，但此身份提供方无法登录该账户。请改用其他方式登录，或联系管理员。';

  @override
  String get errorSsoApprovalPending => '你的账户正在等待管理员批准。';

  @override
  String get errorSsoAccountDisabled => '此账户已停用。请联系管理员。';

  @override
  String get errorSsoRedirectNotAllowed =>
      '此服务器不允许从此应用进行单点登录。请让管理员将 com.endurain.endurain:/auth/sso/callback 添加到 ALLOWED_REDIRECT_URIS。';

  @override
  String get errorActivityMfaEnrolmentRequired =>
      '你的管理员要求启用两步验证。请在 Endurain 网页应用中设置，然后重试。';

  @override
  String get errorActivityFileTooLarge => '活动文件对此服务器来说太大';

  @override
  String get errorActivityUnsupportedFileType => '此服务器不接受这种类型的活动文件';

  @override
  String get errorTooManyRequests => '尝试次数过多。请稍候再试。';

  @override
  String get passwordChangeTitle => '选择新密码';

  @override
  String get passwordChangeMessage => '管理员为你设置了密码。请选择新密码以完成登录。';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get passwordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get changePassword => '更改密码';

  @override
  String get logoutServerFailedWarning => '无法从服务器退出登录，但已在本地退出';

  @override
  String get ssoBrowserLaunchFailed => '无法在系统浏览器中打开 SSO 登录';

  @override
  String ssoSignInWith(String provider) {
    return '使用 $provider 登录';
  }

  @override
  String get ssoOrDivider => '或';

  @override
  String get next => '下一步';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => '请输入您的用户名';

  @override
  String get password => '密码';

  @override
  String get passwordHint => '请输入您的密码';

  @override
  String get showPassword => '显示密码';

  @override
  String get mfaTitle => '双重身份验证';

  @override
  String get mfaCode => 'MFA 代码';

  @override
  String get mfaCodeHint => '请输入 6 位代码';

  @override
  String get mfaCodeRequired => '请输入 MFA 代码';

  @override
  String get mfaBackupCode => '备用代码';

  @override
  String get mfaBackupCodeHint => '请输入一个 8 位备用代码';

  @override
  String get mfaUseBackupCode => '使用备用代码';

  @override
  String get mfaUseAuthenticatorCode => '使用身份验证器代码';

  @override
  String get verify => '验证';

  @override
  String get activityDiscard => '放弃';

  @override
  String get activityDiscardConfirmMessage => '这将删除此活动已记录的点。';

  @override
  String get activityDiscardConfirmTitle => '放弃活动？';

  @override
  String get activityLocationPermissionDenied => '记录活动需要位置权限。';

  @override
  String get activityLocationPermissionDeniedForever =>
      '位置权限已被阻止。请打开设置以允许位置访问。';

  @override
  String get activityLocationServiceDisabled => '位置服务已禁用。';

  @override
  String get activityLocationStreamFailed => '位置更新意外停止。';

  @override
  String get activityGpxGenerationFailed => '无法创建活动 GPX 文件。';

  @override
  String get activityLocalSaveFailed => '无法在此设备上保存此活动。';

  @override
  String get activityOpenSettings => '打开设置';

  @override
  String get activityPause => '暂停';

  @override
  String get activityRecordingEmpty => '未记录任何 GPS 点。';

  @override
  String get activityRecordingFailed => '记录失败。';

  @override
  String get activityResume => '继续';

  @override
  String get activityRetryUpload => '重试上传';

  @override
  String get activityDone => '完成';

  @override
  String get activityViewHistory => '查看历史记录';

  @override
  String get activityDeleteLocal => '删除本地副本';

  @override
  String get activityExportGpx => '分享 GPX 文件';

  @override
  String get activityExportGpxSubject => 'Endurain 活动 GPX';

  @override
  String get activityDeleteLocalConfirmTitle => '删除本地活动？';

  @override
  String get activityDeleteLocalConfirmMessage => '这将从此设备中移除本地活动记录和 GPX 文件。';

  @override
  String get activityStart => '开始';

  @override
  String get activityBackgroundPermissionTitle => '允许后台跟踪？';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain 需要将后台位置设置为“始终”，以便在应用处于后台、屏幕锁定或切换应用时继续记录。';

  @override
  String get activityBackgroundPermissionContinue => '继续';

  @override
  String get activityBackgroundPermissionRequired =>
      '在 iPhone 和 iPad 上进行后台跟踪需要将位置设置为“始终”。';

  @override
  String get activityBackgroundPermissionSettingsTitle => '后台跟踪已关闭';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      '若要在后台或锁屏时可靠地记录，请打开“设置”并将 Endurain 的位置设置为“始终”。';

  @override
  String get activityTrackingNotificationTitle => '正在记录活动';

  @override
  String get activityTrackingNotificationText => 'Endurain 正在跟踪您的位置以记录此活动。';

  @override
  String get activityStatDistance => '距离';

  @override
  String get activityStatDuration => '时间';

  @override
  String get activityStatSpeed => '速度';

  @override
  String get activityStatPace => '配速';

  @override
  String get activityStatMaxSpeed => '最高速度';

  @override
  String get activityStatElevationGain => '累计爬升';

  @override
  String get activityStatHeartRate => '心率';

  @override
  String get activityStatAvgHeartRate => '平均心率';

  @override
  String get activityStatPower => '功率';

  @override
  String get activityStatAvgPower => '平均功率';

  @override
  String get activityStatCadence => '踏频';

  @override
  String get activityStatAvgCadence => '平均踏频';

  @override
  String get activityStop => '停止';

  @override
  String get activityStopAndSave => '停止并保存';

  @override
  String get activityStopConfirmMessage => '请选择保留此记录还是放弃它。';

  @override
  String get activityStopConfirmTitle => '结束活动？';

  @override
  String get activityStopping => '正在停止';

  @override
  String get activityTypeHike => '徒步';

  @override
  String get activityTypeLabel => '活动类型';

  @override
  String get activityTypeOther => '其他';

  @override
  String get activityTypeRide => '骑行';

  @override
  String get activityTypeRun => '跑步';

  @override
  String get activityTypeWalk => '步行';

  @override
  String get activityUploadFailed => '上传失败';

  @override
  String get activityUploadCleanupFailed => '已上传，但清理失败';

  @override
  String get activityUploadReady => '准备上传';

  @override
  String get activityUploadAwaitingSignIn => '已保存在此设备上。登录后将上传。';

  @override
  String get activityUploaded => '已上传';

  @override
  String get activityUploading => '正在上传';

  @override
  String get activityUploadStatusPending => '待处理';

  @override
  String get activityUploadStatusUploaded => '已上传';

  @override
  String get activityUploadStatusFailed => '失败';

  @override
  String get activityHistoryTitle => '活动历史记录';

  @override
  String get activityHistorySettingsSubtitle => '保存在此设备上的已完成活动';

  @override
  String get activityRetainUploadedGpx => '保留已上传的 GPX 文件';

  @override
  String get activityRetainUploadedGpxSubtitle => '上传后将已完成的路线文件存储在应用的私有存储中。';

  @override
  String get activityAutoPauseTitle => '自动暂停';

  @override
  String get activityAutoPauseSubtitle => '停止移动时自动暂停';

  @override
  String get activityAutoPauseToggleLabel => '自动暂停';

  @override
  String get activityAutoPauseToggleDescription =>
      '当您停止移动时自动暂停记录,一旦您重新开始移动即恢复。';

  @override
  String get activityAutoPauseDelayHelperText => '选择在暂停前等待多长时间没有移动。';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get activityAutoPausedIndicator => '自动暂停中';

  @override
  String get activityPausedIndicator => '已暂停';

  @override
  String get startCountdownSettingsTitle => '开始倒计时';

  @override
  String get startCountdownSettingsSubtitle => '开始记录前倒计时';

  @override
  String get startCountdownToggleLabel => '开始前倒计时';

  @override
  String get startCountdownToggleDescription => '让你在记录开始前有时间收好手机。';

  @override
  String get startCountdownDurationHelperText => '选择倒计时的时长。';

  @override
  String startCountdownDurationOptionLabel(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get startCountdownVoiceLabel => '语音播报倒计时';

  @override
  String get startCountdownVoiceDescription => '播报最后几秒，并在记录开始时提示。';

  @override
  String get activityStartCountdownTitle => '距离开始记录';

  @override
  String activityStartCountdownRemaining(int seconds) {
    return '剩余秒数：$seconds';
  }

  @override
  String get activityStartCountdownStartNow => '立即开始';

  @override
  String activityStartCountdownAddSeconds(int seconds) {
    return '+$seconds 秒';
  }

  @override
  String get audioAnnouncementsRecordingStarted => '记录已开始';

  @override
  String get audioAnnouncementsAutoPaused => '记录已暂停';

  @override
  String get audioAnnouncementsAutoResumed => '记录已恢复';

  @override
  String get activityHistoryEmpty => '此设备上未保存已完成的活动。';

  @override
  String get activityHistoryLoadFailed => '无法加载本地活动。';

  @override
  String get activityHistoryRefresh => '刷新';

  @override
  String get activityHistoryLocalActivities => '本地活动';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return '时长：$duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return '距离：$distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return '上传：$status';
  }

  @override
  String get activityHistoryLoadMore => '加载更多';

  @override
  String get activityHistoryDetailsTitle => '活动详情';

  @override
  String get activityHistoryDetailsMissing => '此本地活动不再可用。';

  @override
  String get activityHistorySummary => '摘要';

  @override
  String get activityHistoryActions => '操作';

  @override
  String get activityHistoryType => '类型';

  @override
  String get activityHistoryStartedAt => '开始';

  @override
  String get activityHistoryEndedAt => '结束';

  @override
  String get activityHistoryDurationLabel => '时长';

  @override
  String get activityHistoryDistanceLabel => '距离';

  @override
  String get activityHistoryAverageSpeed => '平均速度';

  @override
  String get activityHistoryPointCount => 'GPS 点';

  @override
  String get activityHistoryUploadStatusLabel => '上传';

  @override
  String get activityHistoryGpxStatus => 'GPX 文件';

  @override
  String get activityHistoryGpxAvailable => '已保存在此设备上';

  @override
  String get activityHistoryGpxMissing => '此设备上不可用';

  @override
  String get mapTab => '地图';

  @override
  String get myLocation => '我的位置';

  @override
  String get settingsTab => '设置';

  @override
  String get endurainTrademarkNotice => 'Endurain® 是 João Vitória Silva 的注册商标。';

  @override
  String get settingsScreen => '设置';

  @override
  String get settingsSectionAccount => '账户';

  @override
  String get settingsSectionGeneral => '通用';

  @override
  String get settingsSectionRecording => '记录';

  @override
  String get settingsSectionDevices => '设备与集成';

  @override
  String get settingsSectionData => '数据';

  @override
  String get settingsSectionPrivacySupport => '隐私与支持';

  @override
  String get deviceAccessTitle => '设备访问权限';

  @override
  String get deviceAccessSubtitle => '管理位置和健康数据访问';

  @override
  String get deviceAccessLocationSection => '位置';

  @override
  String get deviceAccessHealthSection => '健康数据';

  @override
  String get deviceAccessLocationTitle => '位置访问权限';

  @override
  String get deviceAccessHealthTitle => '健康数据访问权限';

  @override
  String get deviceAccessBluetoothSection => 'Bluetooth';

  @override
  String get deviceAccessBluetoothTitle => '蓝牙访问权限';

  @override
  String get deviceAccessBluetoothAllowed => '已允许';

  @override
  String get deviceAccessBluetoothOff => '蓝牙已关闭';

  @override
  String get deviceAccessBluetoothBlocked => '已在系统设置中阻止';

  @override
  String get deviceAccessBluetoothNotAllowed => '不允许';

  @override
  String get deviceAccessBluetoothUnavailable => '在此设备上不可用';

  @override
  String get deviceAccessChecking => '正在检查访问权限…';

  @override
  String get deviceAccessLocationServicesOff => '定位服务已关闭';

  @override
  String get deviceAccessLocationAlways => '一直允许';

  @override
  String get deviceAccessLocationWhileUsing => '使用应用期间允许';

  @override
  String get deviceAccessLocationBlocked => '已在系统设置中阻止';

  @override
  String get deviceAccessLocationNotAllowed => '不允许';

  @override
  String get deviceAccessHealthUnavailable => '在此设备上不可用';

  @override
  String get deviceAccessHealthRequired => '需要 Health Connect';

  @override
  String get deviceAccessHealthSetUp => '已设置健康数据访问权限';

  @override
  String get deviceAccessHealthNeedsAttention => '访问需要注意';

  @override
  String get deviceAccessHealthNotConnected => '未连接';

  @override
  String get language => '语言';

  @override
  String get languageSystemDefault => '系统默认';

  @override
  String get serverSettings => '服务器';

  @override
  String get signInConnectServer => '登录';

  @override
  String get signInConnectServerSubtitle => '立即离线记录，稍后同步您的活动';

  @override
  String get serverSettingsTitle => '服务器设置';

  @override
  String connectedToServer(String server) {
    return '已连接到$server';
  }

  @override
  String get loggedIn => '已登录';

  @override
  String get serverNotSecure => '不安全 (HTTP)';

  @override
  String get notConfigured => '未配置';

  @override
  String get notLoggedIn => '未登录';

  @override
  String get serverUrl => '服务器网址';

  @override
  String get serverProtocol => '协议';

  @override
  String get serverUrlHint => 'https://example.com';

  @override
  String get warnHttpServerUrlTitle => '不安全的连接';

  @override
  String get warnHttpServerUrlMessage =>
      '此服务器网址使用普通 HTTP。您的登录凭据和数据将在不加密的情况下传输。仅在您了解并接受风险时才继续。';

  @override
  String get warnHttpServerUrlConfirm => '仍然继续';

  @override
  String get tileServerUrl => '地图瓦片服务器网址';

  @override
  String get mapTilesSettingsTitle => '地图瓦片';

  @override
  String get mapTilesSettingsSubtitle => '用于绘制地图的瓦片服务器';

  @override
  String get mapTilesSettingsNote => '仅在连接此服务器时生效。重新登录后，如果服务器有瓦片设置，将替换为该设置。';

  @override
  String get mapTilesSettingsLoadFailed => '无法加载地图瓦片设置。';

  @override
  String get tryAgain => '重试';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => '不同的瓦片服务器主机';

  @override
  String get tileServerHostWarningMessage =>
      '瓦片服务器主机与您的 Endurain 服务器主机不同。瓦片将从第三方服务器加载。是否要继续？';

  @override
  String get savedSuccessfully => '设置已成功保存';

  @override
  String get diagnostics => '诊断';

  @override
  String get diagnosticsSubtitle => '本地崩溃上下文';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => '无法打开链接';

  @override
  String get diagnosticsTitle => '诊断';

  @override
  String get diagnosticsCollection => '收集';

  @override
  String get diagnosticsEnable => '收集诊断信息';

  @override
  String get diagnosticsEnableSubtitle => '在此设备上存储最近的应用事件和错误';

  @override
  String get diagnosticsDisabled => '诊断信息收集已关闭。开启后即可开始在此设备上记录应用事件和错误。';

  @override
  String get diagnosticsEmpty => '尚未捕获任何诊断信息。';

  @override
  String get diagnosticsCopy => '复制';

  @override
  String get diagnosticsCopied => '诊断已复制';

  @override
  String get diagnosticsClear => '清除';

  @override
  String get diagnosticsCleared => '诊断已清除';

  @override
  String get diagnosticsSummary => '摘要';

  @override
  String get diagnosticsLastUpdated => '上次更新';

  @override
  String diagnosticsEventsCount(int count) {
    return '事件：$count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return '错误：$count';
  }

  @override
  String get diagnosticsEvents => '事件';

  @override
  String get diagnosticsNoEvents => '未捕获任何事件';

  @override
  String diagnosticsEventTitle(String event) {
    return '事件：$event';
  }

  @override
  String get diagnosticsErrors => '错误';

  @override
  String diagnosticsErrorTitle(String type) {
    return '错误：$type';
  }

  @override
  String get diagnosticsActions => '操作';

  @override
  String get diagnosticsRawReport => '原始报告';

  @override
  String get healthSyncSettingsTitle => '健康同步';

  @override
  String get healthSyncSettingsSubtitle => '从您的健康平台导入锻炼数据';

  @override
  String get healthSyncScreenTitle => '健康同步';

  @override
  String get healthAccessScreenTitle => '健康数据访问权限';

  @override
  String get healthAccessRequestedData => '请求的数据';

  @override
  String get healthAccessWorkouts => '锻炼';

  @override
  String get healthAccessWorkoutRoutes => '锻炼路线';

  @override
  String get healthAccessHeartRate => '心率';

  @override
  String get healthAccessAllowed => '已允许';

  @override
  String get healthAccessNeedsAttention => '需要注意';

  @override
  String get healthAccessManagedBySystem => '由系统设置管理';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit 不会透露 Endurain 可以读取哪些数据。请在“健康”App 中查看访问权限。';

  @override
  String get healthAccessReview => '查看健康数据访问权限';

  @override
  String get healthAccessReviewIos => '如何查看访问权限';

  @override
  String get healthAccessDisconnect => '断开健康数据连接';

  @override
  String get healthAccessDisconnectTitle => '要断开健康数据连接吗？';

  @override
  String get healthAccessDisconnectMessage =>
      '将重置此服务器的自动导入和本地导入历史。现有活动会保留在历史记录中。';

  @override
  String get healthAccessReviewIosInstructions =>
      '打开“健康”App，轻点您的个人资料图片，然后轻点“App 和服务”。选择 Endurain 并更新数据类别。';

  @override
  String get healthAccessBlockedTitle => '在 Health Connect 中允许访问';

  @override
  String get healthAccessBlockedMessage =>
      '在访问被拒绝两次后，Health Connect 将不再询问。请打开 Health Connect，允许 Endurain 读取您的锻炼、路线和心率。';

  @override
  String get healthAccessOpenHealthConnect => '打开 Health Connect';

  @override
  String get healthSyncAuthorize => '连接到健康数据';

  @override
  String get healthSyncInstallProvider => '安装 Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      '需要 Health Connect 才能同步锻炼。请安装后继续。';

  @override
  String get healthSyncUnsupported => '健康同步在此设备上不可用。';

  @override
  String get healthSyncSelectAll => '全选';

  @override
  String get healthSyncClearSelection => '清除';

  @override
  String healthSyncImportSelected(int count) {
    return '导入所选内容 ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '已导入 $count 项锻炼。';
  }

  @override
  String get healthSyncNoRouteLabel => '没有 GPS 路线';

  @override
  String get healthSyncEmptyState => '所选日期范围内未找到锻炼。';

  @override
  String get healthSyncRouteConsentGuidance =>
      '由于未授予锻炼路线访问权限，部分锻炼已被跳过。请打开 Health Connect → 权限，并允许 Endurain 访问锻炼路线。';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      '由于 Endurain 无法读取部分锻炼的 GPS 路线，这些锻炼已被跳过。在“健康”App 中打开您的个人资料，然后打开“App 和服务”，选择 Endurain，并允许“体能训练路线”。';

  @override
  String get healthSyncHistoryAccessGuidance =>
      '由于未在 Health Connect 中授予访问过往数据的权限，较早的锻炼未显示。请在 Health Connect 中为 Endurain 允许“访问过往数据”以导入它们。';

  @override
  String get healthSyncReviewAccess => '查看访问权限';

  @override
  String get healthSyncAutoSyncTitle => '自动导入';

  @override
  String get healthSyncAutoSyncSubtitle => '新的锻炼：在打开应用时导入，若获允许也会在后台导入。';

  @override
  String get healthSyncNoRoutesExplanation =>
      '这些锻炼不包含 GPS 路线，因此无法导入。某些应用（例如 Garmin Connect）会将活动记录到 Apple Health，但不共享路线。使用 Apple Watch 记录的锻炼包含路线，可以导入。';

  @override
  String get healthSyncBadgeNonImportable => '无法导入';

  @override
  String get healthSyncViewAvailable => '可导入';

  @override
  String get healthSyncViewImported => '已导入';

  @override
  String get healthSyncDateRange => '锻炼日期范围';

  @override
  String get healthSyncRange30Days => '最近30天';

  @override
  String get healthSyncRange3Months => '最近3个月';

  @override
  String get healthSyncRange6Months => '最近6个月';

  @override
  String get healthSyncRangeYear => '最近一年';

  @override
  String get healthSyncRangeAll => '全部历史';

  @override
  String get healthSyncRangeCustom => '自定义范围';

  @override
  String get healthSyncImportedEmpty => '此连接没有已导入的锻炼。';

  @override
  String healthSyncImportedAt(String dateTime) {
    return '导入时间：$dateTime';
  }

  @override
  String get healthSyncRestore => '恢复';

  @override
  String get sensorsTitle => '传感器';

  @override
  String get sensorsSettingsSubtitle => '心率监测器和其他外部传感器';

  @override
  String get sensorsHeartRateSection => '心率';

  @override
  String get sensorsHeartRateHelp => '配对蓝牙心率监测器以实时查看您的心率。';

  @override
  String get sensorsBluetoothOff => '蓝牙已关闭。请开启以连接传感器。';

  @override
  String get sensorsBluetoothUnauthorized => '请允许蓝牙访问以连接传感器。';

  @override
  String get sensorsBluetoothUnsupported =>
      '此设备不支持蓝牙低功耗（Bluetooth Low Energy）。';

  @override
  String get sensorsScan => '扫描传感器';

  @override
  String get sensorsScanning => '正在扫描…';

  @override
  String get sensorsStopScan => '停止';

  @override
  String get sensorsNoDevices => '尚未找到心率传感器。';

  @override
  String get sensorsAvailableSection => '可用传感器';

  @override
  String get sensorsSavedSection => '已保存的传感器';

  @override
  String get sensorsConnect => '连接';

  @override
  String get sensorsConnecting => '正在连接…';

  @override
  String get sensorsConnected => '已连接';

  @override
  String get sensorsDisconnect => '断开连接';

  @override
  String get sensorsForget => '忘记';

  @override
  String get sensorsConnectionFailed => '无法连接。请重试。';

  @override
  String get sensorsPermissionRequired => '查找传感器需要蓝牙权限。';

  @override
  String get sensorsUnknownDevice => '未知传感器';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => '功率';

  @override
  String get sensorsPowerHelp => '配对蓝牙功率计以实时查看您的功率。';

  @override
  String get sensorsNoPowerDevices => '尚未找到功率计。';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => '踏频';

  @override
  String get sensorsCadenceHelp => '配对蓝牙踏频传感器以实时查看您的踏频。';

  @override
  String get sensorsNoCadenceDevices => '尚未找到踏频传感器。';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => '远程崩溃报告';

  @override
  String get diagnosticsRemoteEnable => '发送崩溃报告';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      '将崩溃和错误报告发送到诊断服务器。这与本地诊断相互独立；您可以同时启用两者、其中之一或都不启用。';

  @override
  String get diagnosticsRemoteActive => '正在发送崩溃报告';

  @override
  String get diagnosticsRemoteNeedsServer => '此版本不支持远程崩溃报告。';

  @override
  String unitMeter(String value) {
    return '$value 米';
  }

  @override
  String unitKilometer(String value) {
    return '$value 公里';
  }

  @override
  String unitFoot(String value) {
    return '$value 英尺';
  }

  @override
  String unitMile(String value) {
    return '$value 英里';
  }

  @override
  String unitKilometersPerHour(String value) {
    return '$value 公里/小时';
  }

  @override
  String unitMilesPerHour(String value) {
    return '$value 英里/小时';
  }

  @override
  String unitMinutesPerKilometer(String value) {
    return '$value 分钟/公里';
  }

  @override
  String unitMinutesPerMile(String value) {
    return '$value 分钟/英里';
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
  String get unitsTitle => '单位';

  @override
  String get unitsSubtitle => '距离、速度和海拔单位';

  @override
  String get unitsSystemDefault => '跟随设备区域';

  @override
  String get unitsMetric => '公制（公里）';

  @override
  String get unitsImperial => '英制（英里）';

  @override
  String get errorInsecureRedirectRejected =>
      '服务器试图重定向到不安全的连接。为保护您的凭据，该请求已被拦截。';

  @override
  String get errorTooManyRedirects => '服务器重定向次数过多。请检查服务器地址。';

  @override
  String get audioAnnouncementsTitle => '语音播报';

  @override
  String get audioAnnouncementsSubtitle => '播报距离、时间以及配速或速度的语音更新';

  @override
  String get audioAnnouncementsMasterSwitch => '播报活动进度';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      '在记录过程中语音播报您的距离、时间以及配速或速度';

  @override
  String get audioAnnouncementsDuckSwitch => '播报时降低其他音频音量';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle => '在每次播报期间暂时降低其他音频的音量';

  @override
  String get audioAnnouncementsIntervalsHeader => '按活动类型设置的播报间隔';

  @override
  String get audioAnnouncementsByDistance => '距离';

  @override
  String get audioAnnouncementsByTime => '时间';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return '每 $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return '每 $minutes 分钟';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => '减小间隔';

  @override
  String get audioAnnouncementsIncreaseInterval => '增大间隔';

  @override
  String get audioAnnouncementsPreview => '播放示例';

  @override
  String get audioAnnouncementsPreviewUnavailable => '此设备不支持播报试听';

  @override
  String get audioAnnouncementsAppliesNextRecording => '更改将在下次记录时生效。';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return '距离$distance。时间$duration。本圈：$lapMetric。全程：$overallMetric。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get error => '錯誤';

  @override
  String get ok => '確定';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get back => '返回';

  @override
  String get requiredField => '此欄位為必填';

  @override
  String get invalidUrl => '請輸入有效的網址';

  @override
  String get errorActivityUploadFailed => '無法上傳活動';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return '無法上傳活動：$details';
  }

  @override
  String get errorActivityIngestionUnsupportedFormat => '不支援此檔案格式';

  @override
  String get errorActivityIngestionInvalidFile => '檔案已損毀或無法讀取';

  @override
  String get errorActivityIngestionNoActivitiesFound => '檔案中找不到任何活動';

  @override
  String get errorActivityIngestionProcessingFailed => '匯入活動時發生錯誤，請重試。';

  @override
  String get errorActivityIngestionProviderUnavailable => '活動提供者目前無法使用，請稍後再試。';

  @override
  String get errorActivityUploadNotConfigured => '尚未設定活動上傳';

  @override
  String get errorActivityGpxCleanupFailed => '無法刪除暫存活動檔案';

  @override
  String get errorActivityGpxFileWriteFailed => '無法準備活動上傳檔案';

  @override
  String get errorActivityLocalActivityNotFound => '找不到此本機活動';

  @override
  String get errorActivityLocalDeleteFailed => '無法刪除本機活動';

  @override
  String get errorActivityLocalGpxMissing => '本機 GPX 檔案無法使用';

  @override
  String get errorActivityLocalLoadFailed => '無法載入本機活動';

  @override
  String get errorActivityLocalRecordInvalid => '無法儲存此活動';

  @override
  String get errorActivityLocalSaveFailed => '無法在本機儲存活動';

  @override
  String get errorFetchProvidersFailed => '無法載入登入提供者';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return '無法載入登入提供者：$details';
  }

  @override
  String get errorFetchServerSettingsFailed => '無法載入伺服器設定';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return '無法載入伺服器設定：$details';
  }

  @override
  String get errorHealthGpxBuildFailed => '無法將運動轉換為 GPX';

  @override
  String get errorHealthImportFailed => '無法匯入運動';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return '無法匯入運動：$details';
  }

  @override
  String get errorHealthPermissionDenied => '健康資料存取遭拒';

  @override
  String get errorHealthUnavailable => '此裝置無法使用健康資料';

  @override
  String get errorHealthReadFailed => '無法讀取健康資料';

  @override
  String get errorLoginError => '無法登入';

  @override
  String errorLoginErrorWithDetails(String details) {
    return '無法登入：$details';
  }

  @override
  String get errorLoginFailed => '登入失敗';

  @override
  String errorLoginFailedWithDetails(String details) {
    return '登入失敗：$details';
  }

  @override
  String get errorMfaVerificationError => '無法驗證 MFA 代碼';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return '無法驗證 MFA 代碼：$details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA 驗證失敗';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA 驗證失敗：$details';
  }

  @override
  String get errorNoSessionIdReceived => '未從伺服器收到工作階段 ID';

  @override
  String get errorMfaSessionMissing => '您的登入工作階段已遺失。請重新登入。';

  @override
  String get errorSsoCallbackFailed => '無法完成單一登入。請重試。';

  @override
  String get errorNotAuthenticated => '您尚未登入';

  @override
  String get errorPkceVerifierMissingRestartLogin => '找不到登入驗證器。請重新開始登入。';

  @override
  String get errorServerUrlNotConfigured => '未設定伺服器網址';

  @override
  String get errorInsecureTransportNotAllowed => '此伺服器需要安全（HTTPS）連線';

  @override
  String get errorSessionExpired => '您的工作階段已過期。請重新登入。';

  @override
  String get errorSsoTokenExchangeError => '無法完成 SSO 登入';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return '無法完成 SSO 登入：$details';
  }

  @override
  String get errorTokenExchangeFailed => '權杖交換失敗';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return '權杖交換失敗：$details';
  }

  @override
  String get errorRequestTimeout => '要求逾時。請檢查您的連線並重試。';

  @override
  String get errorSecureStorageDeleteFailed => '無法從安全儲存空間刪除。您的裝置儲存空間可能無法使用。';

  @override
  String get errorSecureStorageReadFailed => '無法從安全儲存空間讀取。您的裝置儲存空間可能無法使用。';

  @override
  String get errorSecureStorageWriteFailed => '無法寫入安全儲存空間。您的裝置儲存空間可能無法使用。';

  @override
  String get errorUnexpectedResponseFormat => '伺服器傳回非預期的回應';

  @override
  String get errorUnsupportedHttpMethod => '不支援的 HTTP 方法';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return '不支援的 HTTP 方法：$details';
  }

  @override
  String get loginTitle => '登入';

  @override
  String get login => '登入';

  @override
  String get logout => '登出';

  @override
  String get logoutConfirmTitle => '登出';

  @override
  String get logoutConfirmMessage => '確定要登出嗎？';

  @override
  String get legacyDataTitle => '伺服器更新前的活動';

  @override
  String legacyDataMessageWithUsername(String username) {
    return '此裝置上儲存了伺服器更新前屬於此伺服器上某個帳號的活動。這些是你的嗎，$username？如果是，仍在等待的活動將上傳到你的帳號。';
  }

  @override
  String get legacyDataMessage =>
      '此裝置上儲存了伺服器更新前屬於此伺服器上某個帳號的活動。這些屬於你剛剛登入的帳號嗎？如果是，仍在等待的活動將上傳到該帳號。';

  @override
  String get legacyDataConfirm => '是我的';

  @override
  String get legacyDataDecline => '不是我的';

  @override
  String get errorActivityUploadLimit => '伺服器上你正在進行的上傳過多。應用程式稍後會重試。';

  @override
  String get errorPasswordChangeFailed => '無法變更密碼';

  @override
  String errorPasswordChangeFailedWithDetails(String details) {
    return '無法變更密碼：$details';
  }

  @override
  String get errorSignInStepUnsupported => '此伺服器要求的登入步驟不受此版本應用程式支援。請更新應用程式後重試。';

  @override
  String get errorSsoEmailMissing => '你的身分提供者未分享電子郵件地址，而建立帳號需要該地址。';

  @override
  String get errorSsoEmailUnverified => '你的身分提供者尚未驗證你的電子郵件地址。請在那裡驗證後重試。';

  @override
  String get errorSsoAutoCreateDisabled => '沒有與此次登入相符的帳號，且此伺服器不會自動建立帳號。請聯絡管理員。';

  @override
  String get errorSsoLinkByEmailDisabled =>
      '已有帳號使用此電子郵件地址，但此身分提供者無法登入該帳號。請改用其他方式登入，或聯絡管理員。';

  @override
  String get errorSsoApprovalPending => '你的帳號正在等待管理員核准。';

  @override
  String get errorSsoAccountDisabled => '此帳號已停用。請聯絡管理員。';

  @override
  String get errorSsoRedirectNotAllowed =>
      '此伺服器不允許從此應用程式進行單一登入。請管理員將 com.endurain.endurain:/auth/sso/callback 加入 ALLOWED_REDIRECT_URIS。';

  @override
  String get errorActivityMfaEnrolmentRequired =>
      '你的管理員要求啟用兩步驟驗證。請在 Endurain 網頁應用程式中設定，然後重試。';

  @override
  String get errorActivityFileTooLarge => '活動檔案對此伺服器來說太大';

  @override
  String get errorActivityUnsupportedFileType => '此伺服器不接受這種類型的活動檔案';

  @override
  String get errorTooManyRequests => '嘗試次數過多。請稍候再試。';

  @override
  String get passwordChangeTitle => '選擇新密碼';

  @override
  String get passwordChangeMessage => '管理員為你設定了密碼。請選擇新密碼以完成登入。';

  @override
  String get newPassword => '新密碼';

  @override
  String get confirmNewPassword => '確認新密碼';

  @override
  String get passwordsDoNotMatch => '兩次輸入的密碼不一致';

  @override
  String get changePassword => '變更密碼';

  @override
  String get logoutServerFailedWarning => '無法從伺服器登出，但已在本機登出';

  @override
  String get ssoBrowserLaunchFailed => '無法在系統瀏覽器中開啟 SSO 登入';

  @override
  String ssoSignInWith(String provider) {
    return '使用 $provider 登入';
  }

  @override
  String get ssoOrDivider => '或';

  @override
  String get next => '下一步';

  @override
  String get username => '使用者名稱';

  @override
  String get usernameHint => '請輸入您的使用者名稱';

  @override
  String get password => '密碼';

  @override
  String get passwordHint => '請輸入您的密碼';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get mfaTitle => '雙重驗證';

  @override
  String get mfaCode => 'MFA 代碼';

  @override
  String get mfaCodeHint => '請輸入 6 位數代碼';

  @override
  String get mfaCodeRequired => '請輸入 MFA 代碼';

  @override
  String get mfaBackupCode => '備用代碼';

  @override
  String get mfaBackupCodeHint => '請輸入一組 8 位備用代碼';

  @override
  String get mfaUseBackupCode => '使用備用代碼';

  @override
  String get mfaUseAuthenticatorCode => '使用驗證器代碼';

  @override
  String get verify => '驗證';

  @override
  String get activityDiscard => '捨棄';

  @override
  String get activityDiscardConfirmMessage => '這將刪除此活動已記錄的點。';

  @override
  String get activityDiscardConfirmTitle => '捨棄活動？';

  @override
  String get activityLocationPermissionDenied => '記錄活動需要位置權限。';

  @override
  String get activityLocationPermissionDeniedForever =>
      '位置權限已遭封鎖。請開啟設定以允許位置存取。';

  @override
  String get activityLocationServiceDisabled => '定位服務已停用。';

  @override
  String get activityLocationStreamFailed => '位置更新意外停止。';

  @override
  String get activityGpxGenerationFailed => '無法建立活動 GPX 檔案。';

  @override
  String get activityLocalSaveFailed => '無法在此裝置上儲存此活動。';

  @override
  String get activityOpenSettings => '開啟設定';

  @override
  String get activityPause => '暫停';

  @override
  String get activityRecordingEmpty => '未記錄任何 GPS 點。';

  @override
  String get activityRecordingFailed => '記錄失敗。';

  @override
  String get activityResume => '繼續';

  @override
  String get activityRetryUpload => '重試上傳';

  @override
  String get activityDone => '完成';

  @override
  String get activityViewHistory => '查看歷史記錄';

  @override
  String get activityDeleteLocal => '刪除本機副本';

  @override
  String get activityExportGpx => '分享 GPX 檔案';

  @override
  String get activityExportGpxSubject => 'Endurain 活動 GPX';

  @override
  String get activityDeleteLocalConfirmTitle => '刪除本機活動？';

  @override
  String get activityDeleteLocalConfirmMessage => '這將從此裝置移除本機活動記錄和 GPX 檔案。';

  @override
  String get activityStart => '開始';

  @override
  String get activityBackgroundPermissionTitle => '允許背景追蹤？';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain 需要將背景位置設定為「永遠」，以便在應用程式處於背景、螢幕鎖定或切換應用程式時繼續記錄。';

  @override
  String get activityBackgroundPermissionContinue => '繼續';

  @override
  String get activityBackgroundPermissionRequired =>
      '在 iPhone 和 iPad 上進行背景追蹤需要將位置設定為「永遠」。';

  @override
  String get activityBackgroundPermissionSettingsTitle => '背景追蹤已關閉';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      '若要在背景或鎖定螢幕時可靠地記錄，請開啟「設定」並將 Endurain 的位置設定為「永遠」。';

  @override
  String get activityTrackingNotificationTitle => '正在記錄活動';

  @override
  String get activityTrackingNotificationText => 'Endurain 正在追蹤您的位置以記錄此活動。';

  @override
  String get activityStatDistance => '距離';

  @override
  String get activityStatDuration => '時間';

  @override
  String get activityStatSpeed => '速度';

  @override
  String get activityStatPace => '配速';

  @override
  String get activityStatMaxSpeed => '最高速度';

  @override
  String get activityStatElevationGain => '累計爬升';

  @override
  String get activityStatHeartRate => '心率';

  @override
  String get activityStatAvgHeartRate => '平均心率';

  @override
  String get activityStatPower => '功率';

  @override
  String get activityStatAvgPower => '平均功率';

  @override
  String get activityStatCadence => '踏頻';

  @override
  String get activityStatAvgCadence => '平均踏頻';

  @override
  String get activityStop => '停止';

  @override
  String get activityStopAndSave => '停止並儲存';

  @override
  String get activityStopConfirmMessage => '請選擇保留此記錄或捨棄它。';

  @override
  String get activityStopConfirmTitle => '結束活動？';

  @override
  String get activityStopping => '正在停止';

  @override
  String get activityTypeHike => '健行';

  @override
  String get activityTypeLabel => '活動類型';

  @override
  String get activityTypeOther => '其他';

  @override
  String get activityTypeRide => '騎行';

  @override
  String get activityTypeRun => '跑步';

  @override
  String get activityTypeWalk => '步行';

  @override
  String get activityUploadFailed => '上傳失敗';

  @override
  String get activityUploadCleanupFailed => '已上傳，但清理失敗';

  @override
  String get activityUploadReady => '準備上傳';

  @override
  String get activityUploadAwaitingSignIn => '已儲存在此裝置上。登入後將上傳。';

  @override
  String get activityUploaded => '已上傳';

  @override
  String get activityUploading => '正在上傳';

  @override
  String get activityUploadStatusPending => '待處理';

  @override
  String get activityUploadStatusUploaded => '已上傳';

  @override
  String get activityUploadStatusFailed => '失敗';

  @override
  String get activityHistoryTitle => '活動歷史記錄';

  @override
  String get activityHistorySettingsSubtitle => '儲存在此裝置上的已完成活動';

  @override
  String get activityRetainUploadedGpx => '保留已上傳的 GPX 檔案';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      '上傳後將已完成的路線檔案儲存在應用程式的私人儲存空間中。';

  @override
  String get activityAutoPauseTitle => '自動暫停';

  @override
  String get activityAutoPauseSubtitle => '停止移動時自動暫停';

  @override
  String get activityAutoPauseToggleLabel => '自動暫停';

  @override
  String get activityAutoPauseToggleDescription =>
      '當您停止移動時自動暫停記錄，一旦您重新開始移動即恢復。';

  @override
  String get activityAutoPauseDelayHelperText => '選擇在暫停前等待多長時間沒有移動。';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get activityAutoPausedIndicator => '自動暫停中';

  @override
  String get activityPausedIndicator => '已暫停';

  @override
  String get startCountdownSettingsTitle => '開始倒數';

  @override
  String get startCountdownSettingsSubtitle => '開始記錄前倒數';

  @override
  String get startCountdownToggleLabel => '開始前倒數';

  @override
  String get startCountdownToggleDescription => '讓你在記錄開始前有時間收好手機。';

  @override
  String get startCountdownDurationHelperText => '選擇倒數的時長。';

  @override
  String startCountdownDurationOptionLabel(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get startCountdownVoiceLabel => '語音播報倒數';

  @override
  String get startCountdownVoiceDescription => '播報最後幾秒，並在記錄開始時提示。';

  @override
  String get activityStartCountdownTitle => '距離開始記錄';

  @override
  String activityStartCountdownRemaining(int seconds) {
    return '剩餘秒數：$seconds';
  }

  @override
  String get activityStartCountdownStartNow => '立即開始';

  @override
  String activityStartCountdownAddSeconds(int seconds) {
    return '+$seconds 秒';
  }

  @override
  String get audioAnnouncementsRecordingStarted => '記錄已開始';

  @override
  String get audioAnnouncementsAutoPaused => '記錄已暫停';

  @override
  String get audioAnnouncementsAutoResumed => '記錄已恢復';

  @override
  String get activityHistoryEmpty => '此裝置上未儲存已完成的活動。';

  @override
  String get activityHistoryLoadFailed => '無法載入本機活動。';

  @override
  String get activityHistoryRefresh => '重新整理';

  @override
  String get activityHistoryLocalActivities => '本機活動';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return '時長：$duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return '距離：$distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return '上傳：$status';
  }

  @override
  String get activityHistoryLoadMore => '載入更多';

  @override
  String get activityHistoryDetailsTitle => '活動詳細資料';

  @override
  String get activityHistoryDetailsMissing => '此本機活動已無法使用。';

  @override
  String get activityHistorySummary => '摘要';

  @override
  String get activityHistoryActions => '操作';

  @override
  String get activityHistoryType => '類型';

  @override
  String get activityHistoryStartedAt => '開始';

  @override
  String get activityHistoryEndedAt => '結束';

  @override
  String get activityHistoryDurationLabel => '時長';

  @override
  String get activityHistoryDistanceLabel => '距離';

  @override
  String get activityHistoryAverageSpeed => '平均速度';

  @override
  String get activityHistoryPointCount => 'GPS 點';

  @override
  String get activityHistoryUploadStatusLabel => '上傳';

  @override
  String get activityHistoryGpxStatus => 'GPX 檔案';

  @override
  String get activityHistoryGpxAvailable => '已儲存在此裝置上';

  @override
  String get activityHistoryGpxMissing => '此裝置上無法使用';

  @override
  String get mapTab => '地圖';

  @override
  String get myLocation => '我的位置';

  @override
  String get settingsTab => '設定';

  @override
  String get endurainTrademarkNotice => 'Endurain® 是 João Vitória Silva 的註冊商標。';

  @override
  String get settingsScreen => '設定';

  @override
  String get settingsSectionAccount => '帳戶';

  @override
  String get settingsSectionGeneral => '一般';

  @override
  String get settingsSectionRecording => '記錄';

  @override
  String get settingsSectionDevices => '裝置與整合';

  @override
  String get settingsSectionData => '資料';

  @override
  String get settingsSectionPrivacySupport => '隱私與支援';

  @override
  String get deviceAccessTitle => '裝置存取權限';

  @override
  String get deviceAccessSubtitle => '管理位置和健康資料存取權限';

  @override
  String get deviceAccessLocationSection => '位置';

  @override
  String get deviceAccessHealthSection => '健康資料';

  @override
  String get deviceAccessLocationTitle => '位置存取權限';

  @override
  String get deviceAccessHealthTitle => '健康資料存取權限';

  @override
  String get deviceAccessBluetoothSection => 'Bluetooth';

  @override
  String get deviceAccessBluetoothTitle => '藍牙存取權限';

  @override
  String get deviceAccessBluetoothAllowed => '已允許';

  @override
  String get deviceAccessBluetoothOff => '藍牙已關閉';

  @override
  String get deviceAccessBluetoothBlocked => '已在系統設定中封鎖';

  @override
  String get deviceAccessBluetoothNotAllowed => '不允許';

  @override
  String get deviceAccessBluetoothUnavailable => '此裝置上無法使用';

  @override
  String get deviceAccessChecking => '正在檢查存取權限…';

  @override
  String get deviceAccessLocationServicesOff => '定位服務已關閉';

  @override
  String get deviceAccessLocationAlways => '永遠允許';

  @override
  String get deviceAccessLocationWhileUsing => '使用應用程式期間允許';

  @override
  String get deviceAccessLocationBlocked => '已在系統設定中封鎖';

  @override
  String get deviceAccessLocationNotAllowed => '不允許';

  @override
  String get deviceAccessHealthUnavailable => '此裝置上無法使用';

  @override
  String get deviceAccessHealthRequired => '需要 Health Connect';

  @override
  String get deviceAccessHealthSetUp => '已設定健康資料存取權限';

  @override
  String get deviceAccessHealthNeedsAttention => '存取權限需要注意';

  @override
  String get deviceAccessHealthNotConnected => '未連接';

  @override
  String get language => '語言';

  @override
  String get languageSystemDefault => '系統預設';

  @override
  String get serverSettings => '伺服器';

  @override
  String get signInConnectServer => '登入';

  @override
  String get signInConnectServerSubtitle => '立即離線記錄，稍後同步您的活動';

  @override
  String get serverSettingsTitle => '伺服器設定';

  @override
  String connectedToServer(String server) {
    return '已連線至 $server';
  }

  @override
  String get loggedIn => '已登入';

  @override
  String get serverNotSecure => '不安全 (HTTP)';

  @override
  String get notConfigured => '未設定';

  @override
  String get notLoggedIn => '未登入';

  @override
  String get serverUrl => '伺服器網址';

  @override
  String get serverProtocol => '協定';

  @override
  String get serverUrlHint => 'https://example.com';

  @override
  String get warnHttpServerUrlTitle => '不安全的連線';

  @override
  String get warnHttpServerUrlMessage =>
      '此伺服器網址使用一般 HTTP。您的登入憑證和資料將在未加密的情況下傳輸。僅在您了解並接受風險時才繼續。';

  @override
  String get warnHttpServerUrlConfirm => '仍要繼續';

  @override
  String get tileServerUrl => '地圖圖磚伺服器網址';

  @override
  String get mapTilesSettingsTitle => '地圖圖磚';

  @override
  String get mapTilesSettingsSubtitle => '用於繪製地圖的圖磚伺服器';

  @override
  String get mapTilesSettingsNote => '僅在連線此伺服器時生效。重新登入後，如果伺服器有圖磚設定，將改用該設定。';

  @override
  String get mapTilesSettingsLoadFailed => '無法載入地圖圖磚設定。';

  @override
  String get tryAgain => '重試';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => '不同的圖磚伺服器主機';

  @override
  String get tileServerHostWarningMessage =>
      '圖磚伺服器主機與您的 Endurain 伺服器主機不同。圖磚將從第三方伺服器載入。是否要繼續？';

  @override
  String get savedSuccessfully => '設定已成功儲存';

  @override
  String get diagnostics => '診斷';

  @override
  String get diagnosticsSubtitle => '本機當機內容';

  @override
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => '無法開啟連結';

  @override
  String get diagnosticsTitle => '診斷';

  @override
  String get diagnosticsCollection => '收集';

  @override
  String get diagnosticsEnable => '收集診斷資訊';

  @override
  String get diagnosticsEnableSubtitle => '在此裝置上儲存最近的應用程式事件和錯誤';

  @override
  String get diagnosticsDisabled => '診斷資訊收集已關閉。開啟後即可開始在此裝置上記錄應用程式事件和錯誤。';

  @override
  String get diagnosticsEmpty => '尚未擷取任何診斷資料。';

  @override
  String get diagnosticsCopy => '複製';

  @override
  String get diagnosticsCopied => '診斷已複製';

  @override
  String get diagnosticsClear => '清除';

  @override
  String get diagnosticsCleared => '診斷已清除';

  @override
  String get diagnosticsSummary => '摘要';

  @override
  String get diagnosticsLastUpdated => '上次更新';

  @override
  String diagnosticsEventsCount(int count) {
    return '事件：$count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return '錯誤：$count';
  }

  @override
  String get diagnosticsEvents => '事件';

  @override
  String get diagnosticsNoEvents => '未擷取任何事件';

  @override
  String diagnosticsEventTitle(String event) {
    return '事件：$event';
  }

  @override
  String get diagnosticsErrors => '錯誤';

  @override
  String diagnosticsErrorTitle(String type) {
    return '錯誤：$type';
  }

  @override
  String get diagnosticsActions => '操作';

  @override
  String get diagnosticsRawReport => '原始報告';

  @override
  String get healthSyncSettingsTitle => '健康同步';

  @override
  String get healthSyncSettingsSubtitle => '從您的健康平台匯入運動';

  @override
  String get healthSyncScreenTitle => '健康同步';

  @override
  String get healthAccessScreenTitle => '健康資料存取權限';

  @override
  String get healthAccessRequestedData => '要求的資料';

  @override
  String get healthAccessWorkouts => '運動';

  @override
  String get healthAccessWorkoutRoutes => '運動路線';

  @override
  String get healthAccessHeartRate => '心率';

  @override
  String get healthAccessAllowed => '已允許';

  @override
  String get healthAccessNeedsAttention => '需要注意';

  @override
  String get healthAccessManagedBySystem => '由系統設定管理';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit 不會透露 Endurain 可以讀取哪些資料。請在「健康」App 中檢查存取權限。';

  @override
  String get healthAccessReview => '檢查健康資料存取權限';

  @override
  String get healthAccessReviewIos => '如何檢查存取權限';

  @override
  String get healthAccessDisconnect => '中斷健康資料連線';

  @override
  String get healthAccessDisconnectTitle => '要中斷健康資料連線嗎？';

  @override
  String get healthAccessDisconnectMessage =>
      '將重設此伺服器的自動匯入與本機匯入記錄。現有活動會保留在歷史記錄中。';

  @override
  String get healthAccessReviewIosInstructions =>
      '開啟「健康」App，點一下您的個人資料照片，然後點一下「App 和服務」。選擇 Endurain 並更新資料類別。';

  @override
  String get healthAccessBlockedTitle => '在 Health Connect 中允許存取';

  @override
  String get healthAccessBlockedMessage =>
      '在存取權限被拒絕兩次後，Health Connect 將不再詢問。請開啟 Health Connect，允許 Endurain 讀取您的運動、路線和心率。';

  @override
  String get healthAccessOpenHealthConnect => '開啟 Health Connect';

  @override
  String get healthSyncAuthorize => '連結健康資料';

  @override
  String get healthSyncInstallProvider => '安裝 Health Connect';

  @override
  String get healthSyncInstallProviderDescription =>
      '需要 Health Connect 才能同步運動。請安裝後繼續。';

  @override
  String get healthSyncUnsupported => '此裝置不支援健康同步。';

  @override
  String get healthSyncSelectAll => '全選';

  @override
  String get healthSyncClearSelection => '清除';

  @override
  String healthSyncImportSelected(int count) {
    return '匯入所選項目 ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '已匯入 $count 項運動。';
  }

  @override
  String get healthSyncNoRouteLabel => '無 GPS 路線';

  @override
  String get healthSyncEmptyState => '所選日期範圍內找不到運動。';

  @override
  String get healthSyncRouteConsentGuidance =>
      '由於未授予運動路線存取權限，已略過部分運動。請開啟 Health Connect → 權限，並允許 Endurain 存取運動路線。';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      '由於 Endurain 無法讀取部分運動的 GPS 路線，已略過這些運動。在「健康」App 中開啟您的個人資料，然後開啟「App 和服務」，選擇 Endurain，並允許「體能訓練路線」。';

  @override
  String get healthSyncHistoryAccessGuidance =>
      '由於未在 Health Connect 中授予存取過往資料的權限，因此未顯示較早的運動。若要匯入這些運動，請在 Health Connect 中允許 Endurain「存取過往資料」。';

  @override
  String get healthSyncReviewAccess => '檢查存取權限';

  @override
  String get healthSyncAutoSyncTitle => '自動匯入';

  @override
  String get healthSyncAutoSyncSubtitle => '新的運動：在開啟應用程式時匯入，若獲允許也會在背景匯入。';

  @override
  String get healthSyncNoRoutesExplanation =>
      '這些運動不包含 GPS 路線，因此無法匯入。某些應用程式（例如 Garmin Connect）會將活動記錄到 Apple Health，但不分享路線。使用 Apple Watch 記錄的運動包含路線，可以匯入。';

  @override
  String get healthSyncBadgeNonImportable => '無法匯入';

  @override
  String get healthSyncViewAvailable => '可匯入';

  @override
  String get healthSyncViewImported => '已匯入';

  @override
  String get healthSyncDateRange => '運動日期範圍';

  @override
  String get healthSyncRange30Days => '最近30天';

  @override
  String get healthSyncRange3Months => '最近3個月';

  @override
  String get healthSyncRange6Months => '最近6個月';

  @override
  String get healthSyncRangeYear => '最近一年';

  @override
  String get healthSyncRangeAll => '全部歷史';

  @override
  String get healthSyncRangeCustom => '自訂範圍';

  @override
  String get healthSyncImportedEmpty => '此連線沒有已匯入的運動。';

  @override
  String healthSyncImportedAt(String dateTime) {
    return '匯入時間：$dateTime';
  }

  @override
  String get healthSyncRestore => '還原';

  @override
  String get sensorsTitle => '感測器';

  @override
  String get sensorsSettingsSubtitle => '心率監測器和其他外部感測器';

  @override
  String get sensorsHeartRateSection => '心率';

  @override
  String get sensorsHeartRateHelp => '配對藍牙心率監測器以即時查看您的心率。';

  @override
  String get sensorsBluetoothOff => '藍牙已關閉。請開啟以連接感測器。';

  @override
  String get sensorsBluetoothUnauthorized => '請允許藍牙存取以連接感測器。';

  @override
  String get sensorsBluetoothUnsupported =>
      '此裝置不支援藍牙低功耗（Bluetooth Low Energy）。';

  @override
  String get sensorsScan => '掃描感測器';

  @override
  String get sensorsScanning => '正在掃描…';

  @override
  String get sensorsStopScan => '停止';

  @override
  String get sensorsNoDevices => '尚未找到心率感測器。';

  @override
  String get sensorsAvailableSection => '可用感測器';

  @override
  String get sensorsSavedSection => '已儲存的感測器';

  @override
  String get sensorsConnect => '連接';

  @override
  String get sensorsConnecting => '正在連接…';

  @override
  String get sensorsConnected => '已連接';

  @override
  String get sensorsDisconnect => '中斷連接';

  @override
  String get sensorsForget => '忘記';

  @override
  String get sensorsConnectionFailed => '無法連接。請重試。';

  @override
  String get sensorsPermissionRequired => '尋找感測器需要藍牙權限。';

  @override
  String get sensorsUnknownDevice => '未知感測器';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => '功率';

  @override
  String get sensorsPowerHelp => '配對藍牙功率計以即時查看您的功率。';

  @override
  String get sensorsNoPowerDevices => '尚未找到功率計。';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => '踏頻';

  @override
  String get sensorsCadenceHelp => '配對藍牙踏頻感測器以即時查看您的踏頻。';

  @override
  String get sensorsNoCadenceDevices => '尚未找到踏頻感測器。';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => '遠端當機報告';

  @override
  String get diagnosticsRemoteEnable => '傳送當機報告';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      '將當機和錯誤報告傳送到診斷伺服器。這與本機診斷相互獨立；您可以同時啟用兩者、其中之一或都不啟用。';

  @override
  String get diagnosticsRemoteActive => '正在傳送當機報告';

  @override
  String get diagnosticsRemoteNeedsServer => '此版本不支援遠端當機報告。';

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
  String get unitsTitle => '單位';

  @override
  String get unitsSubtitle => '距離、速度與海拔單位';

  @override
  String get unitsSystemDefault => '依裝置地區設定';

  @override
  String get unitsMetric => '公制（公里）';

  @override
  String get unitsImperial => '英制（英里）';

  @override
  String get errorInsecureRedirectRejected =>
      '伺服器嘗試重新導向至不安全的連線。為保護您的憑證，此請求已被封鎖。';

  @override
  String get errorTooManyRedirects => '伺服器重新導向次數過多。請檢查伺服器位址。';

  @override
  String get audioAnnouncementsTitle => '語音播報';

  @override
  String get audioAnnouncementsSubtitle => '播報距離、時間以及配速或速度的語音更新';

  @override
  String get audioAnnouncementsMasterSwitch => '播報活動進度';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      '在記錄過程中語音播報您的距離、時間以及配速或速度';

  @override
  String get audioAnnouncementsDuckSwitch => '播報時降低其他音訊音量';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle => '在每次播報期間暫時降低其他音訊的音量';

  @override
  String get audioAnnouncementsIntervalsHeader => '按活動類型設定的播報間隔';

  @override
  String get audioAnnouncementsByDistance => '距離';

  @override
  String get audioAnnouncementsByTime => '時間';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return '每 $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return '每 $minutes 分鐘';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => '減小間隔';

  @override
  String get audioAnnouncementsIncreaseInterval => '增大間隔';

  @override
  String get audioAnnouncementsPreview => '播放範例';

  @override
  String get audioAnnouncementsPreviewUnavailable => '此裝置不支援播報試聽';

  @override
  String get audioAnnouncementsAppliesNextRecording => '變更將於下次記錄時生效。';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return '距離$distance。時間$duration。本圈：$lapMetric。全程：$overallMetric。';
  }
}
