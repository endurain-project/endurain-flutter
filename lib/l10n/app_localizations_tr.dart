// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get error => 'Hata';

  @override
  String get ok => 'Tamam';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get back => 'Geri';

  @override
  String get requiredField => 'Bu alan zorunludur';

  @override
  String get invalidUrl => 'Lütfen geçerli bir URL girin';

  @override
  String get errorActivityUploadFailed => 'Etkinlik yüklenemedi';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Etkinlik yüklenemedi: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Etkinlik yükleme henüz yapılandırılmadı';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Geçici etkinlik dosyası silinemedi';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Etkinlik yükleme dosyası hazırlanamadı';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Bu yerel etkinlik bulunamadı';

  @override
  String get errorActivityLocalDeleteFailed => 'Yerel etkinlik silinemedi';

  @override
  String get errorActivityLocalGpxMissing => 'Yerel GPX dosyası kullanılamıyor';

  @override
  String get errorActivityLocalLoadFailed => 'Yerel etkinlikler yüklenemedi';

  @override
  String get errorActivityLocalRecordInvalid => 'Bu etkinlik kaydedilemedi';

  @override
  String get errorActivityLocalSaveFailed =>
      'Etkinlik yerel olarak kaydedilemedi';

  @override
  String get errorFetchProvidersFailed =>
      'Oturum açma sağlayıcıları yüklenemedi';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Oturum açma sağlayıcıları yüklenemedi: $details';
  }

  @override
  String get errorFetchServerSettingsFailed => 'Sunucu ayarları yüklenemedi';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Sunucu ayarları yüklenemedi: $details';
  }

  @override
  String get errorHealthGpxBuildFailed => 'Antrenman GPX\'e dönüştürülemedi';

  @override
  String get errorHealthImportFailed => 'Antrenman içe aktarılamadı';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Antrenman içe aktarılamadı: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Sağlık verilerine erişim reddedildi';

  @override
  String get errorHealthReadFailed => 'Sağlık verileri okunamadı';

  @override
  String get errorHealthUnavailable =>
      'Sağlık senkronizasyonu bu cihazda kullanılamıyor';

  @override
  String get errorLoginError => 'Oturum açılamadı';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Oturum açılamadı: $details';
  }

  @override
  String get errorLoginFailed => 'Oturum açma başarısız oldu';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Oturum açma başarısız oldu: $details';
  }

  @override
  String get errorMfaVerificationError => 'MFA kodu doğrulanamadı';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'MFA kodu doğrulanamadı: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA doğrulaması başarısız oldu';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA doğrulaması başarısız oldu: $details';
  }

  @override
  String get errorNoSessionIdReceived => 'Sunucudan oturum kimliği alınmadı';

  @override
  String get errorNotAuthenticated => 'Oturum açmadınız';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'Oturum açma doğrulayıcısı bulunamadı. Lütfen oturum açmayı yeniden başlatın.';

  @override
  String get errorServerUrlNotConfigured => 'Sunucu URL\'si yapılandırılmadı';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Bu sunucu güvenli (HTTPS) bir bağlantı gerektiriyor';

  @override
  String get errorSessionExpired =>
      'Oturumunuzun süresi doldu. Lütfen tekrar oturum açın.';

  @override
  String get errorSsoTokenExchangeError => 'SSO oturum açma tamamlanamadı';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'SSO oturum açma tamamlanamadı: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Belirteç değişimi başarısız oldu';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Belirteç değişimi başarısız oldu: $details';
  }

  @override
  String get errorRequestTimeout =>
      'İstek zaman aşımına uğradı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Güvenli depolamadan silinemiyor. Cihaz depolamanız kullanılamıyor olabilir.';

  @override
  String get errorSecureStorageReadFailed =>
      'Güvenli depolamadan okunamıyor. Cihaz depolamanız kullanılamıyor olabilir.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Güvenli depolamaya yazılamıyor. Cihaz depolamanız kullanılamıyor olabilir.';

  @override
  String get errorUnexpectedResponseFormat =>
      'Sunucu beklenmeyen bir yanıt döndürdü';

  @override
  String get errorUnsupportedHttpMethod => 'Desteklenmeyen HTTP yöntemi';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Desteklenmeyen HTTP yöntemi: $details';
  }

  @override
  String get loginTitle => 'Oturum aç';

  @override
  String get login => 'Oturum aç';

  @override
  String get logout => 'Oturumu kapat';

  @override
  String get logoutConfirmTitle => 'Oturumu kapat';

  @override
  String get logoutConfirmMessage =>
      'Oturumu kapatmak istediğinizden emin misiniz?';

  @override
  String get logoutServerFailedWarning =>
      'Sunucudan oturum kapatılamadı, ancak yerel olarak kapatıldı';

  @override
  String get ssoBrowserLaunchFailed =>
      'SSO oturum açma sistem tarayıcısında açılamadı';

  @override
  String ssoSignInWith(String provider) {
    return '$provider ile oturum aç';
  }

  @override
  String get ssoOrDivider => 'VEYA';

  @override
  String get next => 'İleri';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get usernameHint => 'Kullanıcı adınızı girin';

  @override
  String get password => 'Parola';

  @override
  String get passwordHint => 'Parolanızı girin';

  @override
  String get showPassword => 'Parolayı göster';

  @override
  String get mfaTitle => 'İki faktörlü kimlik doğrulama';

  @override
  String get mfaCode => 'MFA kodu';

  @override
  String get mfaCodeHint => '6 haneli kodu girin';

  @override
  String get mfaCodeRequired => 'Lütfen MFA kodunu girin';

  @override
  String get verify => 'Doğrula';

  @override
  String get activityDiscard => 'At';

  @override
  String get activityDiscardConfirmMessage =>
      'Bu, bu etkinlik için kaydedilen noktaları silecektir.';

  @override
  String get activityDiscardConfirmTitle => 'Etkinlik atılsın mı?';

  @override
  String get activityLocationPermissionDenied =>
      'Bir etkinlik kaydetmek için konum izni gereklidir.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Konum izni engellendi. Konum erişimine izin vermek için ayarları açın.';

  @override
  String get activityLocationServiceDisabled => 'Konum hizmetleri devre dışı.';

  @override
  String get activityLocationStreamFailed =>
      'Konum güncellemeleri beklenmedik şekilde durdu.';

  @override
  String get activityGpxGenerationFailed =>
      'Etkinlik GPX dosyası oluşturulamadı.';

  @override
  String get activityLocalSaveFailed => 'Bu etkinlik bu cihaza kaydedilemedi.';

  @override
  String get activityOpenSettings => 'Ayarları aç';

  @override
  String get activityPause => 'Duraklat';

  @override
  String get activityRecordingEmpty => 'Hiç GPS noktası kaydedilmedi.';

  @override
  String get activityRecordingFailed => 'Kayıt başarısız oldu.';

  @override
  String get activityResume => 'Sürdür';

  @override
  String get activityRetryUpload => 'Yüklemeyi yeniden dene';

  @override
  String get activityDone => 'Bitti';

  @override
  String get activityViewHistory => 'Geçmişi görüntüle';

  @override
  String get activityDeleteLocal => 'Yerel kopyayı sil';

  @override
  String get activityExportGpx => 'GPX dosyasını paylaş';

  @override
  String get activityExportGpxSubject => 'Endurain etkinlik GPX\'i';

  @override
  String get activityDeleteLocalConfirmTitle => 'Yerel etkinlik silinsin mi?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Bu, yerel etkinlik kaydını ve GPX dosyasını bu cihazdan kaldırır.';

  @override
  String get activityStart => 'Başlat';

  @override
  String get activityBackgroundPermissionTitle =>
      'Arka planda izlemeye izin verilsin mi?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain, uygulama arka plandayken, ekran kilitliyken veya uygulama değiştirdiğinizde kaydın devam etmesi için arka plan konumunun Her zaman olarak ayarlanmasını gerektirir.';

  @override
  String get activityBackgroundPermissionContinue => 'Devam et';

  @override
  String get activityBackgroundPermissionRequired =>
      'iPhone ve iPad\'de arka planda izleme, Konumun Her zaman olarak ayarlanmasını gerektirir.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Arka planda izleme kapalı';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Arka planda veya ekran kilitliyken güvenilir şekilde kaydetmek için Ayarlar\'ı açın ve Endurain için Konumu Her zaman olarak ayarlayın.';

  @override
  String get activityTrackingNotificationTitle => 'Etkinlik kaydediliyor';

  @override
  String get activityTrackingNotificationText =>
      'Endurain, bu etkinliği kaydetmek için konumunuzu izliyor.';

  @override
  String get activityStatDistance => 'Mesafe';

  @override
  String get activityStatDuration => 'Süre';

  @override
  String get activityStatSpeed => 'Hız';

  @override
  String get activityStatPace => 'Tempo';

  @override
  String get activityStop => 'Durdur';

  @override
  String get activityStopAndSave => 'Durdur ve kaydet';

  @override
  String get activityStopConfirmMessage =>
      'Bu kaydı tutmak mı yoksa atmak mı istediğinizi seçin.';

  @override
  String get activityStopConfirmTitle => 'Etkinlik sonlandırılsın mı?';

  @override
  String get activityStopping => 'Durduruluyor';

  @override
  String get activityTypeHike => 'Doğa yürüyüşü';

  @override
  String get activityTypeLabel => 'Etkinlik türü';

  @override
  String get activityTypeOther => 'Diğer';

  @override
  String get activityTypeRide => 'Bisiklet';

  @override
  String get activityTypeRun => 'Koşu';

  @override
  String get activityTypeWalk => 'Yürüyüş';

  @override
  String get activityUploadFailed => 'Yükleme başarısız oldu';

  @override
  String get activityUploadCleanupFailed =>
      'Yüklendi, ancak temizleme başarısız oldu';

  @override
  String get activityUploadReady => 'Yüklemeye hazır';

  @override
  String get activityUploaded => 'Yüklendi';

  @override
  String get activityUploading => 'Yükleniyor';

  @override
  String get activityUploadStatusPending => 'Beklemede';

  @override
  String get activityUploadStatusUploaded => 'Yüklendi';

  @override
  String get activityUploadStatusFailed => 'Başarısız';

  @override
  String get activityHistoryTitle => 'Etkinlik geçmişi';

  @override
  String get activityHistorySettingsSubtitle =>
      'Bu cihaza kaydedilmiş tamamlanan etkinlikler';

  @override
  String get activityRetainUploadedGpx => 'Yüklenen GPX dosyalarını sakla';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Tamamlanan rota dosyalarını yükledikten sonra uygulamanın özel deposunda saklar.';

  @override
  String get activityHistoryEmpty =>
      'Bu cihaza kaydedilmiş tamamlanan etkinlik yok.';

  @override
  String get activityHistoryLoadFailed => 'Yerel etkinlikler yüklenemedi.';

  @override
  String get activityHistoryRefresh => 'Yenile';

  @override
  String get activityHistoryLocalActivities => 'Yerel etkinlikler';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Süre: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Mesafe: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Yükleme: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Daha fazla yükle';

  @override
  String get activityHistoryDetailsTitle => 'Etkinlik ayrıntıları';

  @override
  String get activityHistoryDetailsMissing =>
      'Bu yerel etkinlik artık kullanılamıyor.';

  @override
  String get activityHistorySummary => 'Özet';

  @override
  String get activityHistoryActions => 'İşlemler';

  @override
  String get activityHistoryType => 'Tür';

  @override
  String get activityHistoryStartedAt => 'Başladı';

  @override
  String get activityHistoryEndedAt => 'Bitti';

  @override
  String get activityHistoryDurationLabel => 'Süre';

  @override
  String get activityHistoryDistanceLabel => 'Mesafe';

  @override
  String get activityHistoryAverageSpeed => 'Ortalama hız';

  @override
  String get activityHistoryPointCount => 'GPS noktaları';

  @override
  String get activityHistoryUploadStatusLabel => 'Yükleme';

  @override
  String get activityHistoryGpxStatus => 'GPX dosyası';

  @override
  String get activityHistoryGpxAvailable => 'Bu cihaza kaydedildi';

  @override
  String get activityHistoryGpxMissing => 'Bu cihazda kullanılamıyor';

  @override
  String get mapTab => 'Harita';

  @override
  String get myLocation => 'Konumum';

  @override
  String get settingsTab => 'Ayarlar';

  @override
  String get endurainTrademarkNotice =>
      'Endurain®, João Vitória Silva\'nın tescilli ticari markasıdır.';

  @override
  String get settingsScreen => 'Ayarlar';

  @override
  String get deviceAccessTitle => 'Cihaz erişimi';

  @override
  String get deviceAccessSubtitle =>
      'Konum ve sağlık verilerine erişimi yönetin';

  @override
  String get deviceAccessLocationSection => 'Konum';

  @override
  String get deviceAccessHealthSection => 'Sağlık verileri';

  @override
  String get deviceAccessLocationTitle => 'Konum erişimi';

  @override
  String get deviceAccessHealthTitle => 'Sağlık verilerine erişim';

  @override
  String get deviceAccessChecking => 'Erişim kontrol ediliyor…';

  @override
  String get deviceAccessLocationServicesOff => 'Konum hizmetleri kapalı';

  @override
  String get deviceAccessLocationAlways => 'Her zaman izin verilir';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Uygulamayı kullanırken izin veriliyor';

  @override
  String get deviceAccessLocationBlocked => 'Sistem ayarlarında engellendi';

  @override
  String get deviceAccessLocationNotAllowed => 'İzin verilmiyor';

  @override
  String get deviceAccessHealthUnavailable => 'Bu cihazda kullanılamıyor';

  @override
  String get deviceAccessHealthRequired => 'Sağlık Bağlantısı gerekli';

  @override
  String get deviceAccessHealthSetUp => 'Sağlık erişimi kuruldu';

  @override
  String get deviceAccessHealthNeedsAttention =>
      'Erişime dikkat edilmesi gerekiyor';

  @override
  String get deviceAccessHealthNotConnected => 'Bağlı değil';

  @override
  String get language => 'Dil';

  @override
  String get languageSystemDefault => 'Sistem varsayılanı';

  @override
  String get serverSettings => 'Sunucu';

  @override
  String get signInConnectServer => 'Oturum aç';

  @override
  String get signInConnectServerSubtitle =>
      'Şimdi çevrimdışı kaydedin ve etkinliklerinizi daha sonra senkronize edin';

  @override
  String get serverSettingsTitle => 'Sunucu ayarları';

  @override
  String connectedToServer(String server) {
    return '$server\'ya bağlanıldı';
  }

  @override
  String get loggedIn => 'Oturum açıldı';

  @override
  String get notConfigured => 'Yapılandırılmadı';

  @override
  String get notLoggedIn => 'Oturum açılmadı';

  @override
  String get serverUrl => 'Sunucu URL\'si';

  @override
  String get serverProtocol => 'Protokol';

  @override
  String get serverUrlHint => 'https://ornek.com';

  @override
  String get warnHttpServerUrlTitle => 'Güvenli olmayan bağlantı';

  @override
  String get warnHttpServerUrlMessage =>
      'Bu sunucu URL\'si düz HTTP kullanıyor. Oturum açma bilgileriniz ve verileriniz şifrelenmeden iletilecek. Yalnızca riski anlıyor ve kabul ediyorsanız devam edin.';

  @override
  String get warnHttpServerUrlConfirm => 'Yine de devam et';

  @override
  String get tileServerUrl => 'Harita döşeme sunucusu URL\'si';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle =>
      'Farklı döşeme sunucusu ana bilgisayarı';

  @override
  String get tileServerHostWarningMessage =>
      'Döşeme sunucusu ana bilgisayarı, Endurain sunucunuzun ana bilgisayarından farklı. Döşemeler üçüncü taraf bir sunucudan yüklenecek. Devam etmek istiyor musunuz?';

  @override
  String get savedSuccessfully => 'Ayarlar başarıyla kaydedildi';

  @override
  String get diagnostics => 'Tanılama';

  @override
  String get diagnosticsSubtitle => 'Yerel çökme bağlamı';

  @override
  String get sourceCode => 'Kaynak kodu';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Bağlantı açılamadı';

  @override
  String get diagnosticsTitle => 'Tanılama';

  @override
  String get diagnosticsCollection => 'Toplama';

  @override
  String get diagnosticsEnable => 'Tanılama verilerini topla';

  @override
  String get diagnosticsEnableSubtitle =>
      'Son uygulama olaylarını ve hataları bu cihazda sakla';

  @override
  String get diagnosticsDisabled =>
      'Tanılama verisi toplama kapalı. Bu cihazda uygulama olaylarını ve hataları kaydetmeye başlamak için açın.';

  @override
  String get diagnosticsEmpty => 'Henüz hiç tanılama verisi yakalanmadı.';

  @override
  String get diagnosticsCopy => 'Kopyala';

  @override
  String get diagnosticsCopied => 'Tanılama kopyalandı';

  @override
  String get diagnosticsClear => 'Temizle';

  @override
  String get diagnosticsCleared => 'Tanılama temizlendi';

  @override
  String get diagnosticsSummary => 'Özet';

  @override
  String get diagnosticsLastUpdated => 'Son güncelleme';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Olaylar: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Hatalar: $count';
  }

  @override
  String get diagnosticsEvents => 'Olaylar';

  @override
  String get diagnosticsNoEvents => 'Hiç olay yakalanmadı';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Olay: $event';
  }

  @override
  String get diagnosticsErrors => 'Hatalar';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Hata: $type';
  }

  @override
  String get diagnosticsActions => 'İşlemler';

  @override
  String get diagnosticsRawReport => 'Ham rapor';

  @override
  String get healthSyncSettingsTitle => 'Sağlık senkronizasyonu';

  @override
  String get healthSyncSettingsSubtitle =>
      'Sağlık platformunuzdan antrenmanları içe aktarın';

  @override
  String get healthSyncScreenTitle => 'Sağlık senkronizasyonu';

  @override
  String get healthAccessScreenTitle => 'Sağlık erişimi';

  @override
  String get healthAccessRequestedData => 'İstenen veriler';

  @override
  String get healthAccessWorkouts => 'Antrenmanlar';

  @override
  String get healthAccessWorkoutRoutes => 'Egzersiz rotaları';

  @override
  String get healthAccessHeartRate => 'Kalp atış hızı';

  @override
  String get healthAccessWorkoutSummary =>
      'Antrenman mesafesi, kaloriler ve adımlar';

  @override
  String get healthAccessAllowed => 'İzin verildi';

  @override
  String get healthAccessNeedsAttention => 'Dikkat edilmesi gerekiyor';

  @override
  String get healthAccessManagedBySystem => 'Sistem ayarlarında yönetilir';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit, Endurain\'in hangi verileri okuyabildiğini açıklamaz. Sağlık uygulamasında erişimi inceleyin.';

  @override
  String get healthAccessReview => 'Sağlık erişimini inceleyin';

  @override
  String get healthAccessReviewIos => 'Erişim nasıl incelenir?';

  @override
  String get healthAccessDisconnect => 'Sağlık verilerinin bağlantısını kes';

  @override
  String get healthAccessDisconnectTitle =>
      'Sağlık verilerinin bağlantısı kesilsin mi?';

  @override
  String get healthAccessDisconnectMessage =>
      'Bu sunucu için otomatik içe aktarma ve yerel içe aktarma geçmişi sıfırlanır. Mevcut etkinlikler geçmişte kalır.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Sağlık uygulamasını açın, profil resminize, ardından Uygulamalar ve Hizmetler\'e dokunun. Endurain\'i seçin ve veri kategorilerini güncelleyin.';

  @override
  String get healthSyncAuthorize => 'Sağlık verilerine bağlanma';

  @override
  String get healthSyncInstallProvider => 'Health Connect\'i yükleyin';

  @override
  String get healthSyncInstallProviderDescription =>
      'Antrenmanları senkronize etmek için Health Connect gereklidir. Devam etmek için yükleyin.';

  @override
  String get healthSyncUnsupported =>
      'Sağlık senkronizasyonu bu cihazda kullanılamıyor.';

  @override
  String get healthSyncSelectAll => 'Tümünü seç';

  @override
  String get healthSyncClearSelection => 'Temizle';

  @override
  String healthSyncImportSelected(int count) {
    return 'Seçilenleri içe aktar ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    return '$count antrenman içe aktarıldı.';
  }

  @override
  String get healthSyncNoRouteLabel => 'GPS rotası yok';

  @override
  String get healthSyncEmptyState => 'Seçilen dönemde antrenman bulunamadı.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Egzersiz rotasına erişim izni verilmediğinden bazı antrenmanlar atlandı. Health Connect → İzinler\'i açın ve Endurain için egzersiz rotalarına izin verin.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Endurain GPS rotalarını okuyamadığı için bazı antrenmanlar atlandı. Sağlık uygulamasında profilinizi açın, ardından Uygulamalar ve Hizmetler, Endurain\'i seçin ve Antrenman Rotalarına izin verin.';

  @override
  String get healthSyncReviewAccess => 'Erişimi inceleyin';

  @override
  String get healthSyncAutoSyncTitle => 'Özgeçmişte otomatik senkronizasyon';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Uygulama açıldığında yeni antrenmanları otomatik olarak içe aktarın.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Bu antrenmanlar GPS rotası içermediğinden içe aktarılamaz. Bazı uygulamalar (Garmin Connect gibi) etkinlikleri rotayı paylaşmadan Apple Health\'e kaydeder. Apple Watch ile kaydedilen antrenmanlar rotaları içerir ve içe aktarılabilir.';

  @override
  String get healthSyncBadgeNonImportable => 'İthal edilemez';

  @override
  String get healthSyncViewAvailable => 'Mevcut';

  @override
  String get healthSyncViewImported => 'İçe aktarılan';

  @override
  String get healthSyncDateRange => 'Antrenman dönemi';

  @override
  String get healthSyncRange30Days => 'Son 30 gün';

  @override
  String get healthSyncRange3Months => 'Son 3 ay';

  @override
  String get healthSyncRange6Months => 'Son 6 ay';

  @override
  String get healthSyncRangeYear => 'Son yıl';

  @override
  String get healthSyncRangeAll => 'Tüm geçmiş';

  @override
  String get healthSyncRangeCustom => 'Özel dönem';

  @override
  String get healthSyncImportedEmpty =>
      'Bu bağlantı için içe aktarılmış antrenman yok.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'İçe aktarıldı: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Geri yükle';
}
