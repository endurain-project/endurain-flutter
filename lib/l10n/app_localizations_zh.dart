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
  String get activityStatHeartRate => 'Heart rate';

  @override
  String get activityStatAvgHeartRate => 'Avg heart rate';

  @override
  String get activityStatPower => 'Power';

  @override
  String get activityStatAvgPower => 'Avg power';

  @override
  String get activityStatCadence => 'Cadence';

  @override
  String get activityStatAvgCadence => 'Avg cadence';

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
  String get deviceAccessTitle => '设备接入';

  @override
  String get deviceAccessSubtitle => '管理位置和健康数据访问';

  @override
  String get deviceAccessLocationSection => '地点';

  @override
  String get deviceAccessHealthSection => '健康数据';

  @override
  String get deviceAccessLocationTitle => '位置访问';

  @override
  String get deviceAccessHealthTitle => '健康数据访问';

  @override
  String get deviceAccessChecking => '正在检查访问...';

  @override
  String get deviceAccessLocationServicesOff => '定位服务已关闭';

  @override
  String get deviceAccessLocationAlways => '一直允许';

  @override
  String get deviceAccessLocationWhileUsing => '使用应用程序时允许';

  @override
  String get deviceAccessLocationBlocked => '系统设置中屏蔽了';

  @override
  String get deviceAccessLocationNotAllowed => '不允许';

  @override
  String get deviceAccessHealthUnavailable => '在此设备上不可用';

  @override
  String get deviceAccessHealthRequired => '需要健康连接';

  @override
  String get deviceAccessHealthSetUp => '健康访问设置';

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
  String get sourceCode => '源代码';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

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
  String get healthAccessScreenTitle => '健康获取';

  @override
  String get healthAccessRequestedData => '请求的数据';

  @override
  String get healthAccessWorkouts => '锻炼';

  @override
  String get healthAccessWorkoutRoutes => '锻炼路线';

  @override
  String get healthAccessHeartRate => '心率';

  @override
  String get healthAccessWorkoutSummary => '锻炼距离、热量和步数';

  @override
  String get healthAccessAllowed => '允许';

  @override
  String get healthAccessNeedsAttention => '需要注意';

  @override
  String get healthAccessManagedBySystem => '在系统设置中管理';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit 没有透露 Endurain 可以读取哪些数据。在“健康”应用程序中查看访问权限。';

  @override
  String get healthAccessReview => '审查健康访问权限';

  @override
  String get healthAccessReviewIos => '如何审查访问权限';

  @override
  String get healthAccessDisconnect => '断开健康数据连接';

  @override
  String get healthAccessDisconnectTitle => '要断开健康数据连接吗？';

  @override
  String get healthAccessDisconnectMessage =>
      '将重置此服务器的自动导入和本地导入历史。现有活动会保留在历史记录中。';

  @override
  String get healthAccessReviewIosInstructions =>
      '打开“健康”应用程序，点击您的个人资料图片，然后点击“应用程序和服务”。选择 Endurain 并更新数据类别。';

  @override
  String get healthSyncAuthorize => '连接到健康数据';

  @override
  String get healthSyncInstallProvider => '安装健康连接';

  @override
  String get healthSyncInstallProviderDescription =>
      '需要 Health Connect 才能同步锻炼。安装它以继续。';

  @override
  String get healthSyncUnsupported => '健康同步在此设备上不可用。';

  @override
  String get healthSyncSelectAll => '选择全部';

  @override
  String get healthSyncClearSelection => '清除';

  @override
  String healthSyncImportSelected(int count) {
    return '导入所选内容 ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '导入了 $count 项锻炼。';
  }

  @override
  String get healthSyncNoRouteLabel => '没有 GPS 路线';

  @override
  String get healthSyncEmptyState => '所选日期范围内未找到锻炼。';

  @override
  String get healthSyncRouteConsentGuidance =>
      '由于未授予锻炼路线访问权限，因此跳过了一些锻炼。打开 Health Connect → 权限并允许 Endurain 的锻炼路线。';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      '由于 Endurain 无法读取 GPS 路线，一些锻炼被跳过。在“健康”应用程序中，打开您的个人资料，然后打开“应用程序和服务”，选择“Endurain”，然后允许“锻炼路线”。';

  @override
  String get healthSyncReviewAccess => '审查访问权限';

  @override
  String get healthSyncAutoSyncTitle => '恢复时自动同步';

  @override
  String get healthSyncAutoSyncSubtitle => '应用程序打开时自动导入新的锻炼。';

  @override
  String get healthSyncNoRoutesExplanation =>
      '这些锻炼不包括 GPS 路线，因此无法导入。某些应用程序（例如 Garmin Connect）将活动记录到 Apple Health，但不共享路线。使用Apple Watch记录的锻炼包括路线并且可以导入。';

  @override
  String get healthSyncBadgeNonImportable => '不可进口';

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
  String get sensorsTitle => 'Sensors';

  @override
  String get sensorsSettingsSubtitle =>
      'Heart rate monitors and other external sensors';

  @override
  String get sensorsHeartRateSection => 'Heart rate';

  @override
  String get sensorsHeartRateHelp =>
      'Pair a Bluetooth heart rate monitor to see your live heart rate.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth is off. Turn it on to connect a sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Allow Bluetooth access to connect a sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'This device doesn\'t support Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Scan for sensors';

  @override
  String get sensorsScanning => 'Scanning…';

  @override
  String get sensorsStopScan => 'Stop';

  @override
  String get sensorsNoDevices => 'No heart rate sensors found yet.';

  @override
  String get sensorsAvailableSection => 'Available sensors';

  @override
  String get sensorsSavedSection => 'Saved sensor';

  @override
  String get sensorsConnect => 'Connect';

  @override
  String get sensorsConnecting => 'Connecting…';

  @override
  String get sensorsConnected => 'Connected';

  @override
  String get sensorsDisconnect => 'Disconnect';

  @override
  String get sensorsForget => 'Forget';

  @override
  String get sensorsConnectionFailed => 'Couldn\'t connect. Try again.';

  @override
  String get sensorsPermissionRequired =>
      'Bluetooth permission is required to find sensors.';

  @override
  String get sensorsUnknownDevice => 'Unknown sensor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Power';

  @override
  String get sensorsPowerHelp =>
      'Pair a Bluetooth power meter to see your live power.';

  @override
  String get sensorsNoPowerDevices => 'No power meters found yet.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadence';

  @override
  String get sensorsCadenceHelp =>
      'Pair a Bluetooth cadence sensor to see your live cadence.';

  @override
  String get sensorsNoCadenceDevices => 'No cadence sensors found yet.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
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
  String get errorHealthGpxBuildFailed => '無法將鍛鍊資料轉換為 GPX';

  @override
  String get errorHealthImportFailed => '無法導入鍛煉';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return '無法匯入鍛鍊：$details';
  }

  @override
  String get errorHealthPermissionDenied => '健康數據存取被拒絕';

  @override
  String get errorHealthReadFailed => '無法讀取健康數據';

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
  String get activityStatHeartRate => 'Heart rate';

  @override
  String get activityStatAvgHeartRate => 'Avg heart rate';

  @override
  String get activityStatPower => 'Power';

  @override
  String get activityStatAvgPower => 'Avg power';

  @override
  String get activityStatCadence => 'Cadence';

  @override
  String get activityStatAvgCadence => 'Avg cadence';

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
  String get deviceAccessTitle => '裝置存取';

  @override
  String get deviceAccessSubtitle => '管理位置和健康數據訪問';

  @override
  String get deviceAccessLocationSection => '地點';

  @override
  String get deviceAccessHealthSection => '健康數據';

  @override
  String get deviceAccessLocationTitle => '位置訪問';

  @override
  String get deviceAccessHealthTitle => '健康數據訪問';

  @override
  String get deviceAccessChecking => '正在檢查訪問...';

  @override
  String get deviceAccessLocationServicesOff => '定位服務已關閉';

  @override
  String get deviceAccessLocationAlways => '一直允許';

  @override
  String get deviceAccessLocationWhileUsing => '使用應用程式時允許';

  @override
  String get deviceAccessLocationBlocked => '系統設定中屏蔽了';

  @override
  String get deviceAccessLocationNotAllowed => '不允許';

  @override
  String get deviceAccessHealthUnavailable => '在此設備上不可用';

  @override
  String get deviceAccessHealthRequired => '需要健康連接';

  @override
  String get deviceAccessHealthSetUp => '健康訪問設置';

  @override
  String get deviceAccessHealthNeedsAttention => '訪問需要注意';

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
    return '已連接到$server';
  }

  @override
  String get loggedIn => '已登入';

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
  String get sourceCode => '原始碼';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

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
  String get healthSyncSettingsSubtitle => '從您的健康平台匯入鍛鍊數據';

  @override
  String get healthSyncScreenTitle => '健康同步';

  @override
  String get healthAccessScreenTitle => '健康獲取';

  @override
  String get healthAccessRequestedData => '請求的數據';

  @override
  String get healthAccessWorkouts => '鍛鍊';

  @override
  String get healthAccessWorkoutRoutes => '鍛鍊路線';

  @override
  String get healthAccessHeartRate => '心率';

  @override
  String get healthAccessWorkoutSummary => '運動距離、熱量與步數';

  @override
  String get healthAccessAllowed => '允許';

  @override
  String get healthAccessNeedsAttention => '需要注意';

  @override
  String get healthAccessManagedBySystem => '在系統設定中管理';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit 並未透露 Endurain 可以讀取哪些資料。在“健康”應用程式中查看存取權限。';

  @override
  String get healthAccessReview => '審查健康存取權限';

  @override
  String get healthAccessReviewIos => '如何審查存取權限';

  @override
  String get healthAccessDisconnect => '中斷健康資料連線';

  @override
  String get healthAccessDisconnectTitle => '要中斷健康資料連線嗎？';

  @override
  String get healthAccessDisconnectMessage =>
      '將重設此伺服器的自動匯入與本機匯入記錄。現有活動會保留在歷史記錄中。';

  @override
  String get healthAccessReviewIosInstructions =>
      '打開“健康”應用程序，點擊您的個人資料圖片，然後點擊“應用程式和服務”。選擇 Endurain 並更新資料類別。';

  @override
  String get healthSyncAuthorize => '連接到健康數據';

  @override
  String get healthSyncInstallProvider => '安裝健康連接';

  @override
  String get healthSyncInstallProviderDescription =>
      '需要 Health Connect 才能同步鍛鍊。安裝它以繼續。';

  @override
  String get healthSyncUnsupported => '健康同步在此裝置上不可用。';

  @override
  String get healthSyncSelectAll => '選擇全部';

  @override
  String get healthSyncClearSelection => '清除';

  @override
  String healthSyncImportSelected(int count) {
    return '匯入所選內容 ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '導入了 $count 項鍛鍊。';
  }

  @override
  String get healthSyncNoRouteLabel => '沒有 GPS 路線';

  @override
  String get healthSyncEmptyState => '所選日期範圍內找不到運動。';

  @override
  String get healthSyncRouteConsentGuidance =>
      '由於未授予鍛煉路線訪問權限，因此跳過了一些鍛煉。開啟 Health Connect → 權限並允許 Endurain 的鍛鍊路線。';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      '由於 Endurain 無法讀取 GPS 路線，一些鍛鍊被跳過。在“健康”應用程式中，打開您的個人資料，然後打開“應用程式和服務”，選擇“Endurain”，然後允許“鍛鍊路線”。';

  @override
  String get healthSyncReviewAccess => '審查存取權限';

  @override
  String get healthSyncAutoSyncTitle => '恢復時自動同步';

  @override
  String get healthSyncAutoSyncSubtitle => '應用程式開啟時自動匯入新的鍛鍊。';

  @override
  String get healthSyncNoRoutesExplanation =>
      '這些鍛鍊不包括 GPS 路線，因此無法匯入。某些應用程式（例如 Garmin Connect）會將活動記錄到 Apple Health，但不共用路線。使用Apple Watch記錄的鍛鍊包括路線並且可以導入。';

  @override
  String get healthSyncBadgeNonImportable => '不可進口';

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
  String get healthSyncRestore => '恢復';

  @override
  String get sensorsTitle => 'Sensors';

  @override
  String get sensorsSettingsSubtitle =>
      'Heart rate monitors and other external sensors';

  @override
  String get sensorsHeartRateSection => 'Heart rate';

  @override
  String get sensorsHeartRateHelp =>
      'Pair a Bluetooth heart rate monitor to see your live heart rate.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth is off. Turn it on to connect a sensor.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Allow Bluetooth access to connect a sensor.';

  @override
  String get sensorsBluetoothUnsupported =>
      'This device doesn\'t support Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Scan for sensors';

  @override
  String get sensorsScanning => 'Scanning…';

  @override
  String get sensorsStopScan => 'Stop';

  @override
  String get sensorsNoDevices => 'No heart rate sensors found yet.';

  @override
  String get sensorsAvailableSection => 'Available sensors';

  @override
  String get sensorsSavedSection => 'Saved sensor';

  @override
  String get sensorsConnect => 'Connect';

  @override
  String get sensorsConnecting => 'Connecting…';

  @override
  String get sensorsConnected => 'Connected';

  @override
  String get sensorsDisconnect => 'Disconnect';

  @override
  String get sensorsForget => 'Forget';

  @override
  String get sensorsConnectionFailed => 'Couldn\'t connect. Try again.';

  @override
  String get sensorsPermissionRequired =>
      'Bluetooth permission is required to find sensors.';

  @override
  String get sensorsUnknownDevice => 'Unknown sensor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Power';

  @override
  String get sensorsPowerHelp =>
      'Pair a Bluetooth power meter to see your live power.';

  @override
  String get sensorsNoPowerDevices => 'No power meters found yet.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadence';

  @override
  String get sensorsCadenceHelp =>
      'Pair a Bluetooth cadence sensor to see your live cadence.';

  @override
  String get sensorsNoCadenceDevices => 'No cadence sensors found yet.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }
}
