// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get error => 'Fout';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get back => 'Terug';

  @override
  String get requiredField => 'Dit veld is verplicht';

  @override
  String get invalidUrl => 'Voer een geldige URL in';

  @override
  String get errorActivityUploadFailed => 'Kan activiteit niet uploaden';

  @override
  String errorActivityUploadFailedWithDetails(String details) {
    return 'Kan activiteit niet uploaden: $details';
  }

  @override
  String get errorActivityUploadNotConfigured =>
      'Het uploaden van activiteiten is nog niet geconfigureerd';

  @override
  String get errorActivityGpxCleanupFailed =>
      'Kan het tijdelijke activiteitsbestand niet verwijderen';

  @override
  String get errorActivityGpxFileWriteFailed =>
      'Kan het bestand voor het uploaden van de activiteit niet voorbereiden';

  @override
  String get errorActivityLocalActivityNotFound =>
      'Kan deze lokale activiteit niet vinden';

  @override
  String get errorActivityLocalDeleteFailed =>
      'Kan de lokale activiteit niet verwijderen';

  @override
  String get errorActivityLocalGpxMissing =>
      'Het lokale GPX-bestand is niet beschikbaar';

  @override
  String get errorActivityLocalLoadFailed =>
      'Kan lokale activiteiten niet laden';

  @override
  String get errorActivityLocalRecordInvalid =>
      'Kan deze activiteit niet opslaan';

  @override
  String get errorActivityLocalSaveFailed =>
      'Kan de activiteit niet lokaal opslaan';

  @override
  String get errorFetchProvidersFailed => 'Kan aanmeldproviders niet laden';

  @override
  String errorFetchProvidersFailedWithDetails(String details) {
    return 'Kan aanmeldproviders niet laden: $details';
  }

  @override
  String get errorFetchServerSettingsFailed =>
      'Kan serverinstellingen niet laden';

  @override
  String errorFetchServerSettingsFailedWithDetails(String details) {
    return 'Kan serverinstellingen niet laden: $details';
  }

  @override
  String get errorLoginError => 'Kan niet aanmelden';

  @override
  String errorLoginErrorWithDetails(String details) {
    return 'Kan niet aanmelden: $details';
  }

  @override
  String get errorLoginFailed => 'Aanmelden mislukt';

  @override
  String errorLoginFailedWithDetails(String details) {
    return 'Aanmelden mislukt: $details';
  }

  @override
  String get errorMfaVerificationError => 'Kan MFA-code niet verifiëren';

  @override
  String errorMfaVerificationErrorWithDetails(String details) {
    return 'Kan MFA-code niet verifiëren: $details';
  }

  @override
  String get errorMfaVerificationFailed => 'MFA-verificatie mislukt';

  @override
  String errorMfaVerificationFailedWithDetails(String details) {
    return 'MFA-verificatie mislukt: $details';
  }

  @override
  String get errorNoSessionIdReceived =>
      'Er is geen sessie-ID van de server ontvangen';

  @override
  String get errorNotAuthenticated => 'Je bent niet aangemeld';

  @override
  String get errorPkceVerifierMissing => 'De aanmeldverifier is niet gevonden';

  @override
  String get errorPkceVerifierMissingRestartLogin =>
      'De aanmeldverifier is niet gevonden. Start het aanmelden opnieuw.';

  @override
  String get errorServerUrlNotConfigured => 'Server-URL is niet geconfigureerd';

  @override
  String get errorInsecureTransportNotAllowed =>
      'Deze server vereist een beveiligde (HTTPS-)verbinding';

  @override
  String get errorSessionExpired =>
      'Je sessie is verlopen. Meld je opnieuw aan.';

  @override
  String get errorSsoTokenExchangeError => 'Kan SSO-aanmelding niet voltooien';

  @override
  String errorSsoTokenExchangeErrorWithDetails(String details) {
    return 'Kan SSO-aanmelding niet voltooien: $details';
  }

  @override
  String get errorTokenExchangeFailed => 'Tokenuitwisseling mislukt';

  @override
  String errorTokenExchangeFailedWithDetails(String details) {
    return 'Tokenuitwisseling mislukt: $details';
  }

  @override
  String get errorRequestTimeout =>
      'De aanvraag is verlopen. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get errorSecureStorageDeleteFailed =>
      'Kan niet verwijderen uit beveiligde opslag. De opslag van je apparaat is mogelijk niet beschikbaar.';

  @override
  String get errorSecureStorageReadFailed =>
      'Kan niet lezen uit beveiligde opslag. De opslag van je apparaat is mogelijk niet beschikbaar.';

  @override
  String get errorSecureStorageWriteFailed =>
      'Kan niet schrijven naar beveiligde opslag. De opslag van je apparaat is mogelijk niet beschikbaar.';

  @override
  String get errorUnexpectedResponseFormat =>
      'De server gaf een onverwacht antwoord';

  @override
  String get errorUnsupportedHttpMethod => 'Niet-ondersteunde HTTP-methode';

  @override
  String errorUnsupportedHttpMethodWithDetails(String details) {
    return 'Niet-ondersteunde HTTP-methode: $details';
  }

  @override
  String get loginTitle => 'Aanmelden';

  @override
  String get login => 'Aanmelden';

  @override
  String get logout => 'Afmelden';

  @override
  String get logoutConfirmTitle => 'Afmelden';

  @override
  String get logoutConfirmMessage => 'Weet je zeker dat je je wilt afmelden?';

  @override
  String get logoutServerFailedWarning =>
      'Kan niet afmelden bij de server, maar lokaal afgemeld';

  @override
  String get ssoBrowserLaunchFailed =>
      'Kan SSO-aanmelding niet openen in de systeembrowser';

  @override
  String get ssoMissingSessionId => 'De SSO-callback bevatte geen sessie-ID';

  @override
  String ssoSignInWith(String provider) {
    return 'Aanmelden met $provider';
  }

  @override
  String get ssoOrDivider => 'OF';

  @override
  String get next => 'Volgende';

  @override
  String get username => 'Gebruikersnaam';

  @override
  String get usernameHint => 'Voer je gebruikersnaam in';

  @override
  String get password => 'Wachtwoord';

  @override
  String get passwordHint => 'Voer je wachtwoord in';

  @override
  String get showPassword => 'Wachtwoord tonen';

  @override
  String get mfaTitle => 'Tweestapsverificatie';

  @override
  String get mfaCode => 'MFA-code';

  @override
  String get mfaCodeHint => 'Voer de 6-cijferige code in';

  @override
  String get mfaCodeRequired => 'Voer de MFA-code in';

  @override
  String get verify => 'Verifiëren';

  @override
  String get activityDiscard => 'Weggooien';

  @override
  String get activityDiscardConfirmMessage =>
      'Hiermee worden de opgenomen punten van deze activiteit verwijderd.';

  @override
  String get activityDiscardConfirmTitle => 'Activiteit weggooien?';

  @override
  String get activityLocationPermissionDenied =>
      'Locatietoestemming is vereist om een activiteit op te nemen.';

  @override
  String get activityLocationPermissionDeniedForever =>
      'Locatietoestemming is geblokkeerd. Open de instellingen om locatietoegang toe te staan.';

  @override
  String get activityLocationServiceDisabled =>
      'Locatievoorzieningen zijn uitgeschakeld.';

  @override
  String get activityLocationStreamFailed =>
      'Locatie-updates zijn onverwacht gestopt.';

  @override
  String get activityGpxGenerationFailed =>
      'Kan het GPX-bestand van de activiteit niet aanmaken.';

  @override
  String get activityLocalSaveFailed =>
      'Kan deze activiteit niet op dit apparaat opslaan.';

  @override
  String get activityOpenSettings => 'Instellingen openen';

  @override
  String get activityPause => 'Pauzeren';

  @override
  String get activityRecordingEmpty => 'Er zijn geen GPS-punten opgenomen.';

  @override
  String get activityRecordingFailed => 'Opname mislukt.';

  @override
  String get activityResume => 'Hervatten';

  @override
  String get activityRetryUpload => 'Upload opnieuw proberen';

  @override
  String get activityDone => 'Klaar';

  @override
  String get activityViewHistory => 'Geschiedenis bekijken';

  @override
  String get activityDeleteLocal => 'Lokale kopie verwijderen';

  @override
  String get activityExportGpx => 'GPX-bestand delen';

  @override
  String get activityExportGpxSubject => 'Endurain-activiteit-GPX';

  @override
  String get activityDeleteLocalConfirmTitle =>
      'Lokale activiteit verwijderen?';

  @override
  String get activityDeleteLocalConfirmMessage =>
      'Hiermee worden het lokale activiteitsrecord en het GPX-bestand van dit apparaat verwijderd.';

  @override
  String get activityStart => 'Starten';

  @override
  String get activityBackgroundPermissionTitle =>
      'Tracken op de achtergrond toestaan?';

  @override
  String get activityBackgroundPermissionMessage =>
      'Endurain heeft de achtergrondlocatie ingesteld op Altijd nodig zodat de opname doorgaat wanneer de app op de achtergrond is, het scherm vergrendeld is of je van app wisselt.';

  @override
  String get activityBackgroundPermissionContinue => 'Doorgaan';

  @override
  String get activityBackgroundPermissionRequired =>
      'Tracken op de achtergrond op iPhone en iPad vereist Locatie ingesteld op Altijd.';

  @override
  String get activityBackgroundPermissionSettingsTitle =>
      'Tracken op de achtergrond staat uit';

  @override
  String get activityBackgroundPermissionSettingsMessage =>
      'Om betrouwbaar op de achtergrond of met vergrendeld scherm op te nemen, open Instellingen en zet Locatie op Altijd voor Endurain.';

  @override
  String get activityTrackingNotificationTitle => 'Activiteit opnemen';

  @override
  String get activityTrackingNotificationText =>
      'Endurain volgt je locatie om deze activiteit op te nemen.';

  @override
  String get activityStatDistance => 'Afstand';

  @override
  String get activityStatDuration => 'Tijd';

  @override
  String get activityStatSpeed => 'Snelheid';

  @override
  String get activityStop => 'Stoppen';

  @override
  String get activityStopAndSave => 'Stoppen en opslaan';

  @override
  String get activityStopConfirmMessage =>
      'Kies of je deze opname wilt bewaren of weggooien.';

  @override
  String get activityStopConfirmTitle => 'Activiteit beëindigen?';

  @override
  String get activityStopping => 'Bezig met stoppen';

  @override
  String get activityTypeHike => 'Wandeltocht';

  @override
  String get activityTypeLabel => 'Activiteitstype';

  @override
  String get activityTypeOther => 'Overig';

  @override
  String get activityTypeRide => 'Fietsen';

  @override
  String get activityTypeRun => 'Hardlopen';

  @override
  String get activityTypeWalk => 'Wandelen';

  @override
  String get activityUploadFailed => 'Uploaden mislukt';

  @override
  String get activityUploadCleanupFailed => 'Geüpload, maar opschonen mislukt';

  @override
  String get activityUploadReady => 'Klaar om te uploaden';

  @override
  String get activityUploaded => 'Geüpload';

  @override
  String get activityUploading => 'Bezig met uploaden';

  @override
  String get activityUploadStatusPending => 'In behandeling';

  @override
  String get activityUploadStatusUploaded => 'Geüpload';

  @override
  String get activityUploadStatusFailed => 'Mislukt';

  @override
  String get activityHistoryTitle => 'Activiteitengeschiedenis';

  @override
  String get activityHistorySettingsSubtitle =>
      'Voltooide activiteiten opgeslagen op dit apparaat';

  @override
  String get activityRetainUploadedGpx => 'Geüploade GPX-bestanden bewaren';

  @override
  String get activityRetainUploadedGpxSubtitle =>
      'Bewaart voltooide routebestanden na het uploaden in de privéopslag van de app.';

  @override
  String get activityHistoryEmpty =>
      'Geen voltooide activiteiten opgeslagen op dit apparaat.';

  @override
  String get activityHistoryLoadFailed => 'Kan lokale activiteiten niet laden.';

  @override
  String get activityHistoryRefresh => 'Vernieuwen';

  @override
  String get activityHistoryLocalActivities => 'Lokale activiteiten';

  @override
  String activityHistoryEntryTitle(String activityType, String endedAt) {
    return '$activityType • $endedAt';
  }

  @override
  String activityHistoryDuration(String duration) {
    return 'Duur: $duration';
  }

  @override
  String activityHistoryDistance(String distance) {
    return 'Afstand: $distance';
  }

  @override
  String activityHistoryUploadStatus(String status) {
    return 'Upload: $status';
  }

  @override
  String get activityHistoryLoadMore => 'Meer laden';

  @override
  String get activityHistoryDetailsTitle => 'Activiteitsdetails';

  @override
  String get activityHistoryDetailsMissing =>
      'Deze lokale activiteit is niet meer beschikbaar.';

  @override
  String get activityHistorySummary => 'Samenvatting';

  @override
  String get activityHistoryActions => 'Acties';

  @override
  String get activityHistoryType => 'Type';

  @override
  String get activityHistoryStartedAt => 'Gestart';

  @override
  String get activityHistoryEndedAt => 'Beëindigd';

  @override
  String get activityHistoryDurationLabel => 'Duur';

  @override
  String get activityHistoryDistanceLabel => 'Afstand';

  @override
  String get activityHistoryAverageSpeed => 'Gemiddelde snelheid';

  @override
  String get activityHistoryPointCount => 'GPS-punten';

  @override
  String get activityHistoryUploadStatusLabel => 'Upload';

  @override
  String get activityHistoryGpxStatus => 'GPX-bestand';

  @override
  String get activityHistoryGpxAvailable => 'Opgeslagen op dit apparaat';

  @override
  String get activityHistoryGpxMissing => 'Niet beschikbaar op dit apparaat';

  @override
  String get mapTab => 'Kaart';

  @override
  String get myLocation => 'Mijn locatie';

  @override
  String get settingsTab => 'Instellingen';

  @override
  String get settingsScreen => 'Instellingen';

  @override
  String get language => 'Taal';

  @override
  String get languageSystemDefault => 'Systeemstandaard';

  @override
  String get serverSettings => 'Server';

  @override
  String get signInConnectServer => 'Aanmelden';

  @override
  String get signInConnectServerSubtitle =>
      'Neem nu offline op en synchroniseer je activiteiten later';

  @override
  String get serverSettingsTitle => 'Serverinstellingen';

  @override
  String get loggedIn => 'Aangemeld';

  @override
  String get notConfigured => 'Niet geconfigureerd';

  @override
  String get notLoggedIn => 'Niet aangemeld';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverUrlHint => 'https://voorbeeld.com';

  @override
  String get warnHttpServerUrlTitle => 'Onveilige verbinding';

  @override
  String get warnHttpServerUrlMessage =>
      'Deze server-URL gebruikt gewone HTTP. Je aanmeldgegevens en gegevens worden zonder versleuteling verzonden. Ga alleen door als je het risico begrijpt en accepteert.';

  @override
  String get warnHttpServerUrlConfirm => 'Toch doorgaan';

  @override
  String get tileServerUrl => 'URL van kaarttegelserver';

  @override
  String get tileServerUrlHint => 'https://tile.openstreetmap.org/...';

  @override
  String get tileServerHostWarningTitle => 'Andere tegelserverhost';

  @override
  String get tileServerHostWarningMessage =>
      'De host van de tegelserver verschilt van de host van je Endurain-server. Tegels worden geladen van een externe server. Wil je doorgaan?';

  @override
  String get savedSuccessfully => 'Instellingen opgeslagen';

  @override
  String get diagnostics => 'Diagnostiek';

  @override
  String get diagnosticsSubtitle => 'Lokale crashcontext';

  @override
  String get sourceCode => 'Broncode';

  @override
  String get sourceCodeSubtitle => 'codeberg.org/endurain-project';

  @override
  String get openLinkFailed => 'Kan de link niet openen';

  @override
  String get diagnosticsTitle => 'Diagnostiek';

  @override
  String get diagnosticsEmpty =>
      'Er is nog geen diagnostische informatie vastgelegd.';

  @override
  String get diagnosticsCopy => 'Kopiëren';

  @override
  String get diagnosticsCopied => 'Diagnostiek gekopieerd';

  @override
  String get diagnosticsClear => 'Wissen';

  @override
  String get diagnosticsCleared => 'Diagnostiek gewist';

  @override
  String get diagnosticsSummary => 'Samenvatting';

  @override
  String get diagnosticsLastUpdated => 'Laatst bijgewerkt';

  @override
  String diagnosticsEventsCount(int count) {
    return 'Gebeurtenissen: $count';
  }

  @override
  String diagnosticsErrorsCount(int count) {
    return 'Fouten: $count';
  }

  @override
  String get diagnosticsEvents => 'Gebeurtenissen';

  @override
  String get diagnosticsNoEvents => 'Geen gebeurtenissen vastgelegd';

  @override
  String diagnosticsEventTitle(String event) {
    return 'Gebeurtenis: $event';
  }

  @override
  String get diagnosticsErrors => 'Fouten';

  @override
  String diagnosticsErrorTitle(String type) {
    return 'Fout: $type';
  }

  @override
  String get diagnosticsActions => 'Acties';

  @override
  String get diagnosticsRawReport => 'Ruw rapport';
}
