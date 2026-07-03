// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get error => 'Hiba';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Mégse';

  @override
  String get save => 'Mentés';

  @override
  String get back => 'Vissza';

  @override
  String get requiredField => 'Ez a mező kötelező';

  @override
  String get invalidUrl => 'Adjon meg egy érvényes URL-t';

  @override
  String get errorActivityUploadFailed =>
      'Nem sikerült feltölteni a tevékenységet';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Nem sikerült feltölteni a tevékenységet: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'A tevékenységek feltöltése még nincs beállítva';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Nem sikerült törölni az ideiglenes tevékenységfájlt';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Nem sikerült előkészíteni a tevékenység feltöltési fájlját';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Nem található ez a helyi tevékenység';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Nem sikerült törölni a helyi tevékenységet';

  @override
  String get errorActivityLocalGpxMissing => 'A helyi GPX-fájl nem érhető el';

  @override
  String get errorActivityLocalLoadFailed =>
      'Nem sikerült betölteni a helyi tevékenységeket';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Nem sikerült menteni ezt a tevékenységet';

  @override
  String get errorActivityLocalSaveFailed =>
      'Nem sikerült helyben menteni a tevékenységet';

  @override
  String get errorFetchProvidersFailed =>
      'Nem sikerült betölteni a bejelentkezési szolgáltatókat';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Nem sikerült betölteni a bejelentkezési szolgáltatókat: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Nem sikerült betölteni a kiszolgálóbeállításokat';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Nem sikerült betölteni a kiszolgálóbeállításokat: $details';
  }

  @override
  String get errorLoginError => 'Nem sikerült bejelentkezni';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Nem sikerült bejelentkezni: $details';
  }

  @override
  String get errorLoginFailed => 'A bejelentkezés sikertelen';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'A bejelentkezés sikertelen: $details';
  }

  @override
  String get errorMfaVerificationError =>
      'Nem sikerült ellenőrizni az MFA-kódot';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Nem sikerült ellenőrizni az MFA-kódot: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'Az MFA-ellenőrzés sikertelen';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'Az MFA-ellenőrzés sikertelen: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Nem érkezett munkamenet-azonosító a kiszolgálótól';

  @override
  String get errorNotAuthenticated => 'Nincs bejelentkezve';

  @override
  String get errorPkceVerifierMissing =>
      'A bejelentkezési ellenőrző nem található';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'A bejelentkezési ellenőrző nem található. Kezdje újra a bejelentkezést.';

  @override
  String get errorServerUrlNotConfigured =>
      'A kiszolgáló URL-címe nincs beállítva';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Ez a kiszolgáló biztonságos (HTTPS-) kapcsolatot igényel';

  @override
  String get errorSessionExpired =>
      'A munkamenete lejárt. Jelentkezzen be újra.';

  @override
  String get errorSsoTokenExchangeError =>
      'Nem sikerült befejezni az SSO-bejelentkezést';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Nem sikerült befejezni az SSO-bejelentkezést: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'A tokencsere sikertelen';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'A tokencsere sikertelen: $details';
  }

  @override
  String get errorRequestTimeout =>
      'A kérés időtúllépést eredményezett. Ellenőrizze a kapcsolatot, és próbálja újra.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Nem lehet törölni a biztonságos tárolóból. Előfordulhat, hogy az eszköz tárhelye nem érhető el.';

  @override
  String get errorSecureStorageReadFailed =>
      'Nem lehet olvasni a biztonságos tárolóból. Előfordulhat, hogy az eszköz tárhelye nem érhető el.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Nem lehet írni a biztonságos tárolóba. Előfordulhat, hogy az eszköz tárhelye nem érhető el.';

  @override
  String get errorUnexpectedResponseFormat =>
      'A kiszolgáló váratlan választ adott';

  @override
  String get errorUnsupportedHttpMethod => 'Nem támogatott HTTP-metódus';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Nem támogatott HTTP-metódus: $details';
  }

  @override
  String get loginTitle => 'Bejelentkezés';

  @override
  String get login => 'Bejelentkezés';

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get logoutConfirmTitle => 'Kijelentkezés';

  @override
  String get logoutConfirmMessage => 'Biztosan ki szeretne jelentkezni?';

  @override
  String get logoutServerFailedWarning =>
      'Nem sikerült kijelentkezni a kiszolgálóból, de a helyi kijelentkezés megtörtént';

  @override
  String get ssoBrowserLaunchFailed =>
      'Nem sikerült megnyitni az SSO-bejelentkezést a rendszer böngészőjében';

  @override
  String get ssoMissingSessionId =>
      'Az SSO-válasz nem tartalmazott munkamenet-azonosítót';

  @override
  String ssoSignInWith(String provider) {
    return 'Bejelentkezés ezzel: $provider';
  }

  @override
  String get ssoOrDivider => 'VAGY';

  @override
  String get next => 'Tovább';

  @override
  String get username => 'Felhasználónév';

  @override
  String get usernameHint => 'Adja meg a felhasználónevét';

  @override
  String get password => 'Jelszó';

  @override
  String get passwordHint => 'Adja meg a jelszavát';

  @override
  String get showPassword => 'Jelszó megjelenítése';

  @override
  String get mfaTitle => 'Kétfaktoros hitelesítés';

  @override
  String get mfaCode => 'MFA-kód';

  @override
  String get mfaCodeHint => 'Adja meg a 6 jegyű kódot';

  @override
  String get mfaCodeRequired => 'Adja meg az MFA-kódot';

  @override
  String get verify => 'Ellenőrzés';

  @override
  String get activityDiscard => 'Elvetés';

  @override
  String get activityDiscardConfirmMessage =>
      'Ez törli a tevékenység rögzített pontjait.';

  @override
  String get activityDiscardConfirmTitle => 'Elveti a tevékenységet?';

  @override
  String get activityLocationPermissionDenied =>
      'A tevékenység rögzítéséhez helymeghatározási engedély szükséges.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'A helymeghatározási engedély le van tiltva. Nyissa meg a beállításokat a helyhozzáférés engedélyezéséhez.';

  @override
  String get activityLocationServiceDisabled =>
      'A helymeghatározási szolgáltatások le vannak tiltva.';

  @override
  String get activityLocationStreamFailed =>
      'A helyfrissítések váratlanul leálltak.';

  @override
  String get activityGpxGenerationFailed =>
      'Nem sikerült létrehozni a tevékenység GPX-fájlját.';

  @override
  String get activityLocalSaveFailed =>
      'Nem sikerült elmenteni ezt a tevékenységet erre az eszközre.';

  @override
  String get activityOpenSettings => 'Beállítások megnyitása';

  @override
  String get activityPause => 'Szünet';

  @override
  String get activityRecordingEmpty => 'Nem rögzültek GPS-pontok.';

  @override
  String get activityRecordingFailed => 'A rögzítés sikertelen.';

  @override
  String get activityResume => 'Folytatás';

  @override
  String get activityRetryUpload => 'Feltöltés újrapróbálása';

  @override
  String get activityDone => 'Kész';

  @override
  String get activityViewHistory => 'Előzmények megtekintése';

  @override
  String get activityDeleteLocal => 'Helyi másolat törlése';

  @override
  String get activityExportGpx => 'GPX-fájl megosztása';

  @override
  String get activityExportGpxSubject => 'Endurain tevékenység GPX';

  @override
  String get activityDeleteLocalConfirmTitle => 'Törli a helyi tevékenységet?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Ez eltávolítja a helyi tevékenységrekordot és a GPX-fájlt erről az eszközről.';

  @override
  String get activityStart => 'Indítás';

  @override
  String get activityBackgroundPermissionTitle =>
      'Engedélyezi a háttérben történő követést?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Az Endurainnek a háttérben lévő helymeghatározást Mindig értékre kell állítani, hogy a rögzítés folytatódjon, amikor az alkalmazás a háttérben van, a képernyő zárolva van, vagy alkalmazást vált.';

  @override
  String get activityBackgroundPermissionContinue => 'Folytatás';

  @override
  String get activityBackgroundPermissionRequired =>
      'A háttérben történő követéshez iPhone-on és iPaden a Helymeghatározást Mindig értékre kell állítani.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'A háttérben történő követés ki van kapcsolva';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'A háttérben vagy zárolt képernyővel történő megbízható rögzítéshez nyissa meg a Beállításokat, és állítsa a Helymeghatározást Mindig értékre az Endurain számára.';

  @override
  String get activityTrackingNotificationTitle => 'Tevékenység rögzítése';

  @override
  String get activityTrackingNotificationText =>
      'Az Endurain követi a helyzetét a tevékenység rögzítéséhez.';

  @override
  String get activityStatDistance => 'Távolság';

  @override
  String get activityStatDuration => 'Idő';

  @override
  String get activityStatSpeed => 'Sebesség';

  @override
  String get activityStop => 'Leállítás';

  @override
  String get activityStopAndSave => 'Leállítás és mentés';

  @override
  String get activityStopConfirmMessage =>
      'Válassza ki, hogy megtartja vagy elveti ezt a felvételt.';

  @override
  String get activityStopConfirmTitle => 'Befejezi a tevékenységet?';

  @override
  String get activityStopping => 'Leállítás';

  @override
  String get activityTypeHike => 'Túra';

  @override
  String get activityTypeLabel => 'Tevékenység típusa';

  @override
  String get activityTypeOther => 'Egyéb';

  @override
  String get activityTypeRide => 'Kerékpározás';

  @override
  String get activityTypeRun => 'Futás';

  @override
  String get activityTypeWalk => 'Séta';

  @override
  String get activityUploadFailed => 'A feltöltés sikertelen';

  @override
  String get activityUploadCleanupFailed =>
      'Feltöltve, de a takarítás sikertelen';

  @override
  String get activityUploadReady => 'Feltöltésre kész';

  @override
  String get activityUploaded => 'Feltöltve';

  @override
  String get activityUploading => 'Feltöltés';

  @override
  String get activityUploadStatusPending => 'Függőben';

  @override
  String get activityUploadStatusUploaded => 'Feltöltve';

  @override
  String get activityUploadStatusFailed => 'Sikertelen';

  @override
  String get activityHistoryTitle => 'Tevékenységelőzmények';

  @override
  String get activityHistorySettingsSubtitle =>
      'Az eszközön mentett befejezett tevékenységek';

  @override
  String get activityRetainUploadedGpx => 'Feltöltött GPX-fájlok megtartása';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'A befejezett útvonalfájlokat a feltöltés után az alkalmazás privát tárhelyén tárolja.';

  @override
  String get activityHistoryEmpty =>
      'Nincsenek az eszközön mentett befejezett tevékenységek.';

  @override
  String get activityHistoryLoadFailed =>
      'Nem sikerült betölteni a helyi tevékenységeket.';

  @override
  String get activityHistoryRefresh => 'Frissítés';

  @override
  String get activityHistoryLocalActivities => 'Helyi tevékenységek';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Időtartam: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Távolság: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Feltöltés: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Több betöltése';

  @override
  String get activityHistoryDetailsTitle => 'Tevékenység részletei';

  @override
  String get activityHistoryDetailsMissing =>
      'Ez a helyi tevékenység már nem érhető el.';

  @override
  String get activityHistorySummary => 'Összegzés';

  @override
  String get activityHistoryActions => 'Műveletek';

  @override
  String get activityHistoryType => 'Típus';

  @override
  String get activityHistoryStartedAt => 'Kezdés';

  @override
  String get activityHistoryEndedAt => 'Befejezés';

  @override
  String get activityHistoryDurationLabel => 'Időtartam';

  @override
  String get activityHistoryDistanceLabel => 'Távolság';

  @override
  String get activityHistoryAverageSpeed => 'Átlagsebesség';

  @override
  String get activityHistoryPointCount => 'GPS-pontok';

  @override
  String get activityHistoryUploadStatusLabel => 'Feltöltés';

  @override
  String get activityHistoryGpxStatus => 'GPX-fájl';

  @override
  String get activityHistoryGpxAvailable => 'Az eszközön mentve';

  @override
  String get activityHistoryGpxMissing => 'Az eszközön nem érhető el';

  @override
  String get mapTab => 'Térkép';

  @override
  String get myLocation => 'Saját hely';

  @override
  String get settingsTab => 'Beállítások';

  @override
  String get settingsScreen => 'Beállítások';

  @override
  String get language => 'Nyelv';

  @override
  String get languageSystemDefault => 'Rendszer alapértelmezése';

  @override
  String get serverSettings => 'Kiszolgáló';

  @override
  String get signInConnectServer => 'Bejelentkezés';

  @override
  String get signInConnectServerSubtitle =>
      'Rögzítsen offline most, és szinkronizálja a tevékenységeit később';

  @override
  String get serverSettingsTitle => 'Kiszolgálóbeállítások';

  @override
  String get loggedIn => 'Bejelentkezve';

  @override
  String get notConfigured => 'Nincs beállítva';

  @override
  String get notLoggedIn => 'Nincs bejelentkezve';

  @override
  String get serverUrl => 'Kiszolgáló URL-címe';

  @override
  String get serverUrlHint => 'https://pelda.com';

  @override
  String get warnHttpServerUrlTitle => 'Nem biztonságos kapcsolat';

  @override
  String get warnHttpServerUrlMessage =>
      'Ez a kiszolgáló URL-címe egyszerű HTTP-t használ. A bejelentkezési adatait és adatait titkosítás nélkül továbbítja. Csak akkor folytassa, ha megérti és elfogadja a kockázatot.';

  @override
  String get warnHttpServerUrlConfirm => 'Folytatás mindenképp';

  @override
  String get tileServerUrl => 'Térképcsempe-kiszolgáló URL-címe';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Eltérő csempekiszolgáló-gazdagép';

  @override
  String get tileServerHostWarningMessage =>
      'A csempekiszolgáló gazdagépe eltér az Endurain-kiszolgáló gazdagépétől. A csempék egy harmadik féltől származó kiszolgálóról töltődnek be. Szeretné folytatni?';

  @override
  String get savedSuccessfully => 'A beállítások sikeresen elmentve';

  @override
  String get diagnostics => 'Diagnosztika';

  @override
  String get diagnosticsSubtitle => 'Helyi összeomlási kontextus';

  @override
  String get sourceCode => 'Forráskód';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'A hivatkozás nem nyitható meg';

  @override
  String get diagnosticsTitle => 'Diagnosztika';

  @override
  String get diagnosticsEmpty => 'Még nem rögzült diagnosztikai adat.';

  @override
  String get diagnosticsCopy => 'Másolás';

  @override
  String get diagnosticsCopied => 'Diagnosztika másolva';

  @override
  String get diagnosticsClear => 'Törlés';

  @override
  String get diagnosticsCleared => 'Diagnosztika törölve';

  @override
  String get diagnosticsSummary => 'Összegzés';

  @override
  String get diagnosticsLastUpdated => 'Utoljára frissítve';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Események: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Hibák: $count';
  }

  @override
  String get diagnosticsEvents => 'Események';

  @override
  String get diagnosticsNoEvents => 'Nincs rögzített esemény';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Esemény: $event';
  }

  @override
  String get diagnosticsErrors => 'Hibák';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Hiba: $type';
  }

  @override
  String get diagnosticsActions => 'Műveletek';

  @override
  String get diagnosticsRawReport => 'Nyers jelentés';
}
