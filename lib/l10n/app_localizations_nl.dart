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
  String get errorActivityIngestionUnsupportedFormat =>
      'Het bestandsformaat wordt niet ondersteund';

  @override
  String get errorActivityIngestionInvalidFile =>
      'Het bestand is beschadigd of kon niet worden gelezen';

  @override
  String get errorActivityIngestionNoActivitiesFound =>
      'Er zijn geen activiteiten gevonden in het bestand';

  @override
  String get errorActivityIngestionProcessingFailed =>
      'Er is iets misgegaan bij het importeren van de activiteit. Probeer het opnieuw.';

  @override
  String get errorActivityIngestionProviderUnavailable =>
      'De activiteitenprovider is momenteel niet beschikbaar. Probeer het later opnieuw.';

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
  String get errorHealthGpxBuildFailed =>
      'Kan training niet converteren naar GPX';

  @override
  String get errorHealthImportFailed => 'Kan training niet importeren';

  @override
  String errorHealthImportFailedWithDetails(String details) {
    return 'Kan training niet importeren: $details';
  }

  @override
  String get errorHealthPermissionDenied =>
      'Toegang tot gezondheidsgegevens werd geweigerd';

  @override
  String get errorHealthUnavailable =>
      'Gezondheidsgegevens zijn niet beschikbaar op dit apparaat';

  @override
  String get errorHealthReadFailed => 'Kan gezondheidsgegevens niet lezen';

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
  String get errorMfaSessionMissing =>
      'Je inlogsessie is verloren gegaan. Meld je opnieuw aan.';

  @override
  String get errorSsoCallbackFailed =>
      'Eenmalige aanmelding (SSO) kon niet worden voltooid. Probeer het opnieuw.';

  @override
  String get errorNotAuthenticated => 'Je bent niet aangemeld';

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
  String get legacyDataTitle => 'Activiteiten van vóór de serverupdate';

  @override
  String legacyDataMessageWithUsername(String username) {
    return 'Op dit apparaat staan activiteiten die zijn opgeslagen voor een account op deze server van vóór de update van de server. Zijn ze van jou, $username? Zo ja, dan worden de activiteiten die nog wachten naar je account geüpload.';
  }

  @override
  String get legacyDataMessage =>
      'Op dit apparaat staan activiteiten die zijn opgeslagen voor een account op deze server van vóór de update van de server. Horen ze bij het account waarmee je net bent ingelogd? Zo ja, dan worden de activiteiten die nog wachten daarnaar geüpload.';

  @override
  String get legacyDataConfirm => 'Ze zijn van mij';

  @override
  String get legacyDataDecline => 'Niet van mij';

  @override
  String get errorActivityUploadLimit =>
      'De server heeft te veel uploads van je in behandeling. De app probeert het later opnieuw.';

  @override
  String get errorPasswordChangeFailed => 'Kan het wachtwoord niet wijzigen';

  @override
  String errorPasswordChangeFailedWithDetails(String details) {
    return 'Kan het wachtwoord niet wijzigen: $details';
  }

  @override
  String get errorSignInStepUnsupported =>
      'Deze server vroeg om een inlogstap die deze versie van de app niet ondersteunt. Werk de app bij en probeer het opnieuw.';

  @override
  String get errorSsoEmailMissing =>
      'Je identiteitsprovider heeft geen e-mailadres gedeeld, en dat is nodig om je account aan te maken.';

  @override
  String get errorSsoEmailUnverified =>
      'Je identiteitsprovider heeft je e-mailadres niet geverifieerd. Verifieer het daar en probeer het opnieuw.';

  @override
  String get errorSsoAutoCreateDisabled =>
      'Geen enkel account past bij deze aanmelding en deze server maakt niet automatisch accounts aan. Vraag het je beheerder.';

  @override
  String get errorSsoLinkByEmailDisabled =>
      'Een account gebruikt dit e-mailadres al, maar deze provider kan daarop niet inloggen. Log op een andere manier in of vraag het je beheerder.';

  @override
  String get errorSsoApprovalPending =>
      'Je account wacht op goedkeuring door een beheerder.';

  @override
  String get errorSsoAccountDisabled =>
      'Dit account is uitgeschakeld. Neem contact op met je beheerder.';

  @override
  String get errorSsoRedirectNotAllowed =>
      'Deze server staat single sign-on vanuit deze app niet toe. Vraag je beheerder om com.endurain.endurain:/auth/sso/callback toe te voegen aan ALLOWED_REDIRECT_URIS.';

  @override
  String get errorActivityMfaEnrolmentRequired =>
      'Je beheerder vereist verificatie in twee stappen. Stel die in via de Endurain-webapp en probeer het opnieuw.';

  @override
  String get errorActivityFileTooLarge =>
      'Het activiteitsbestand is te groot voor deze server';

  @override
  String get errorActivityUnsupportedFileType =>
      'Deze server accepteert dit soort activiteitsbestand niet';

  @override
  String get errorTooManyRequests =>
      'Te veel pogingen. Wacht even en probeer het opnieuw.';

  @override
  String get passwordChangeTitle => 'Kies een nieuw wachtwoord';

  @override
  String get passwordChangeMessage =>
      'Een beheerder heeft je wachtwoord ingesteld. Kies een nieuw wachtwoord om het inloggen af te ronden.';

  @override
  String get newPassword => 'Nieuw wachtwoord';

  @override
  String get confirmNewPassword => 'Bevestig nieuw wachtwoord';

  @override
  String get passwordsDoNotMatch => 'De wachtwoorden komen niet overeen';

  @override
  String get changePassword => 'Wachtwoord wijzigen';

  @override
  String get logoutServerFailedWarning =>
      'Kan niet afmelden bij de server, maar lokaal afgemeld';

  @override
  String get ssoBrowserLaunchFailed =>
      'Kan SSO-aanmelding niet openen in de systeembrowser';

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
  String get mfaBackupCode => 'Back-upcode';

  @override
  String get mfaBackupCodeHint =>
      'Voer een van je back-upcodes van 8 tekens in';

  @override
  String get mfaUseBackupCode => 'Een back-upcode gebruiken';

  @override
  String get mfaUseAuthenticatorCode =>
      'Een code uit je authenticator-app gebruiken';

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
  String get activityStatPace => 'Tempo';

  @override
  String get activityStatMaxSpeed => 'Max. snelheid';

  @override
  String get activityStatElevationGain => 'Stijging';

  @override
  String get activityStatHeartRate => 'Hartslag';

  @override
  String get activityStatAvgHeartRate => 'Gem. hartslag';

  @override
  String get activityStatPower => 'Vermogen';

  @override
  String get activityStatAvgPower => 'Gem. vermogen';

  @override
  String get activityStatCadence => 'Cadans';

  @override
  String get activityStatAvgCadence => 'Gem. cadans';

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
  String get activityAutoPauseTitle => 'Automatisch pauzeren';

  @override
  String get activityAutoPauseSubtitle =>
      'Pauzeert automatisch wanneer je stopt met bewegen';

  @override
  String get activityAutoPauseToggleLabel => 'Automatisch pauzeren';

  @override
  String get activityAutoPauseToggleDescription =>
      'Pauzeert de opname wanneer je stopt met bewegen en hervat zodra je weer beweegt.';

  @override
  String get activityAutoPauseDelayHelperText =>
      'Kies hoe lang zonder beweging gewacht moet worden voordat er wordt gepauzeerd.';

  @override
  String activityAutoPauseDelayOptionLabel(int seconds) {
    return '$seconds seconden';
  }

  @override
  String get activityAutoPausedIndicator => 'Automatisch gepauzeerd';

  @override
  String get startCountdownSettingsTitle => 'Startaftelling';

  @override
  String get startCountdownSettingsSubtitle =>
      'Aftellen voordat de opname begint';

  @override
  String get startCountdownToggleLabel => 'Aftellen voor het starten';

  @override
  String get startCountdownToggleDescription =>
      'Geeft je tijd om je telefoon weg te stoppen voordat de opname begint.';

  @override
  String get startCountdownDurationHelperText =>
      'Kies hoe lang het aftellen duurt.';

  @override
  String startCountdownDurationOptionLabel(int seconds) {
    return '$seconds seconden';
  }

  @override
  String get startCountdownVoiceLabel => 'Aftellen uitspreken';

  @override
  String get startCountdownVoiceDescription =>
      'Spreekt de laatste seconden uit en meldt wanneer de opname is begonnen.';

  @override
  String get activityStartCountdownTitle => 'Opname begint over';

  @override
  String activityStartCountdownRemaining(int seconds) {
    return 'Resterende seconden: $seconds';
  }

  @override
  String get activityStartCountdownStartNow => 'Nu starten';

  @override
  String activityStartCountdownAddSeconds(int seconds) {
    return '+$seconds s';
  }

  @override
  String get audioAnnouncementsRecordingStarted => 'Opname gestart';

  @override
  String get audioAnnouncementsAutoPaused => 'Opname gepauzeerd';

  @override
  String get audioAnnouncementsAutoResumed => 'Opname hervat';

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
  String get endurainTrademarkNotice =>
      'Endurain® is een geregistreerd handelsmerk van João Vitória Silva';

  @override
  String get settingsScreen => 'Instellingen';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionGeneral => 'Algemeen';

  @override
  String get settingsSectionRecording => 'Opnemen';

  @override
  String get settingsSectionDevices => 'Apparaten en integraties';

  @override
  String get settingsSectionData => 'Gegevens';

  @override
  String get settingsSectionPrivacySupport => 'Privacy en ondersteuning';

  @override
  String get deviceAccessTitle => 'Toegang tot apparaat';

  @override
  String get deviceAccessSubtitle =>
      'Toegang tot locatie- en gezondheidsgegevens beheren';

  @override
  String get deviceAccessLocationSection => 'Locatie';

  @override
  String get deviceAccessHealthSection => 'Gezondheidsgegevens';

  @override
  String get deviceAccessLocationTitle => 'Toegang tot locatie';

  @override
  String get deviceAccessHealthTitle => 'Toegang tot gezondheidsgegevens';

  @override
  String get deviceAccessChecking => 'Toegang wordt gecontroleerd…';

  @override
  String get deviceAccessLocationServicesOff =>
      'Locatieservices zijn uitgeschakeld';

  @override
  String get deviceAccessLocationAlways => 'Altijd toegestaan';

  @override
  String get deviceAccessLocationWhileUsing =>
      'Toegestaan tijdens het gebruik van de app';

  @override
  String get deviceAccessLocationBlocked =>
      'Geblokkeerd in systeeminstellingen';

  @override
  String get deviceAccessLocationNotAllowed => 'Niet toegestaan';

  @override
  String get deviceAccessHealthUnavailable =>
      'Niet beschikbaar op dit apparaat';

  @override
  String get deviceAccessHealthRequired => 'Health Connect is vereist';

  @override
  String get deviceAccessHealthSetUp =>
      'Toegang tot gezondheidsgegevens ingesteld';

  @override
  String get deviceAccessHealthNeedsAttention => 'Toegang heeft aandacht nodig';

  @override
  String get deviceAccessHealthNotConnected => 'Niet verbonden';

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
  String connectedToServer(String server) {
    return 'Verbonden met $server';
  }

  @override
  String get loggedIn => 'Aangemeld';

  @override
  String get serverNotSecure => 'Niet beveiligd (HTTP)';

  @override
  String get notConfigured => 'Niet geconfigureerd';

  @override
  String get notLoggedIn => 'Niet aangemeld';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverProtocol => 'Serverprotocol';

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
  String get mapTilesSettingsTitle => 'Kaarttegels';

  @override
  String get mapTilesSettingsSubtitle =>
      'Tegelserver voor het tekenen van kaarten';

  @override
  String get mapTilesSettingsNote =>
      'Geldt zolang je met deze server verbonden bent. Opnieuw inloggen vervangt deze door de tegelinstelling van je server, als die er een heeft.';

  @override
  String get mapTilesSettingsLoadFailed =>
      'De kaarttegelinstelling kon niet worden geladen.';

  @override
  String get tryAgain => 'Opnieuw proberen';

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
  String get sourceCode => 'GitHub';

  @override
  String get sourceCodeSubtitle => 'github.com/endurain-project';

  @override
  String get openLinkFailed => 'Kan de link niet openen';

  @override
  String get diagnosticsTitle => 'Diagnostiek';

  @override
  String get diagnosticsCollection => 'Verzameling';

  @override
  String get diagnosticsEnable => 'Diagnostiek verzamelen';

  @override
  String get diagnosticsEnableSubtitle =>
      'Recente app-gebeurtenissen en fouten op dit apparaat opslaan';

  @override
  String get diagnosticsDisabled =>
      'Het verzamelen van diagnostiek staat uit. Schakel het in om app-gebeurtenissen en fouten op dit apparaat vast te leggen.';

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

  @override
  String get healthSyncSettingsTitle => 'Gezondheidssynchronisatie';

  @override
  String get healthSyncSettingsSubtitle =>
      'Trainingen importeren van je gezondheidsplatform';

  @override
  String get healthSyncScreenTitle => 'Gezondheidssynchronisatie';

  @override
  String get healthAccessScreenTitle => 'Toegang tot gezondheidsgegevens';

  @override
  String get healthAccessRequestedData => 'Gevraagde gegevens';

  @override
  String get healthAccessWorkouts => 'Trainingen';

  @override
  String get healthAccessWorkoutRoutes => 'Trainingsroutes';

  @override
  String get healthAccessHeartRate => 'Hartslag';

  @override
  String get healthAccessAllowed => 'Toegestaan';

  @override
  String get healthAccessNeedsAttention => 'Heeft aandacht nodig';

  @override
  String get healthAccessManagedBySystem => 'Beheerd in systeeminstellingen';

  @override
  String get healthAccessSystemManagedNotice =>
      'HealthKit geeft niet prijs welke gegevens Endurain kan lezen. Controleer de toegang in de Gezondheid-app.';

  @override
  String get healthAccessReview =>
      'Toegang tot gezondheidsgegevens controleren';

  @override
  String get healthAccessReviewIos => 'Zo controleer je de toegang';

  @override
  String get healthAccessDisconnect => 'Gezondheidsgegevens loskoppelen';

  @override
  String get healthAccessDisconnectTitle => 'Gezondheidsgegevens loskoppelen?';

  @override
  String get healthAccessDisconnectMessage =>
      'Automatische import en de lokale importgeschiedenis voor deze server worden opnieuw ingesteld. Bestaande activiteiten blijven in de geschiedenis.';

  @override
  String get healthAccessReviewIosInstructions =>
      'Open de Gezondheid-app, tik op je profielfoto en vervolgens op Apps en services. Selecteer Endurain en werk de gegevenscategorieën bij.';

  @override
  String get healthSyncAuthorize => 'Verbinden met gezondheidsgegevens';

  @override
  String get healthSyncInstallProvider => 'Health Connect installeren';

  @override
  String get healthSyncInstallProviderDescription =>
      'Health Connect is vereist om trainingen te synchroniseren. Installeer het om door te gaan.';

  @override
  String get healthSyncUnsupported =>
      'Gezondheidssynchronisatie is niet beschikbaar op dit apparaat.';

  @override
  String get healthSyncSelectAll => 'Alles selecteren';

  @override
  String get healthSyncClearSelection => 'Selectie wissen';

  @override
  String healthSyncImportSelected(int count) {
    return 'Selectie importeren ($count)';
  }

  @override
  String healthSyncImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trainingen geïmporteerd.',
      one: '$count training geïmporteerd.',
    );
    return '$_temp0';
  }

  @override
  String get healthSyncNoRouteLabel => 'Geen GPS-route';

  @override
  String get healthSyncEmptyState =>
      'Geen trainingen gevonden in de geselecteerde periode.';

  @override
  String get healthSyncRouteConsentGuidance =>
      'Sommige trainingen zijn overgeslagen omdat er geen toegang tot trainingsroutes is verleend. Open Health Connect → Rechten en sta trainingsroutes toe voor Endurain.';

  @override
  String get healthSyncRouteConsentGuidanceIos =>
      'Sommige trainingen zijn overgeslagen omdat Endurain hun GPS-routes niet kon lezen. Open in de Gezondheid-app je profiel en vervolgens Apps en services, selecteer Endurain en sta Trainingsroutes toe.';

  @override
  String get healthSyncHistoryAccessGuidance =>
      'Oudere trainingen worden niet getoond omdat geen toegang tot eerdere gegevens in Health Connect is verleend. Sta \'Toegang tot eerdere gegevens\' toe voor Endurain in Health Connect om ze te importeren.';

  @override
  String get healthSyncReviewAccess => 'Toegang controleren';

  @override
  String get healthSyncAutoSyncTitle => 'Automatisch synchroniseren bij openen';

  @override
  String get healthSyncAutoSyncSubtitle =>
      'Nieuwe trainingen automatisch importeren wanneer de app wordt geopend.';

  @override
  String get healthSyncNoRoutesExplanation =>
      'Deze trainingen bevatten geen GPS-route en kunnen dus niet worden geïmporteerd. Sommige apps (zoals Garmin Connect) registreren activiteiten in Apple Health zonder de route te delen. Trainingen opgenomen met Apple Watch bevatten routes en kunnen worden geïmporteerd.';

  @override
  String get healthSyncBadgeNonImportable => 'Niet-importeerbaar';

  @override
  String get healthSyncViewAvailable => 'Beschikbaar';

  @override
  String get healthSyncViewImported => 'Geïmporteerd';

  @override
  String get healthSyncDateRange => 'Trainingsperiode';

  @override
  String get healthSyncRange30Days => 'Laatste 30 dagen';

  @override
  String get healthSyncRange3Months => 'Laatste 3 maanden';

  @override
  String get healthSyncRange6Months => 'Laatste 6 maanden';

  @override
  String get healthSyncRangeYear => 'Afgelopen jaar';

  @override
  String get healthSyncRangeAll => 'Volledige geschiedenis';

  @override
  String get healthSyncRangeCustom => 'Aangepaste periode';

  @override
  String get healthSyncImportedEmpty =>
      'Geen geïmporteerde trainingen voor deze verbinding.';

  @override
  String healthSyncImportedAt(String dateTime) {
    return 'Geïmporteerd: $dateTime';
  }

  @override
  String get healthSyncRestore => 'Herstellen';

  @override
  String get sensorsTitle => 'Sensoren';

  @override
  String get sensorsSettingsSubtitle =>
      'Hartslagmeters en andere externe sensoren';

  @override
  String get sensorsHeartRateSection => 'Hartslag';

  @override
  String get sensorsHeartRateHelp =>
      'Koppel een bluetooth-hartslagmeter om je hartslag live te zien.';

  @override
  String get sensorsBluetoothOff =>
      'Bluetooth staat uit. Schakel het in om een sensor te verbinden.';

  @override
  String get sensorsBluetoothUnauthorized =>
      'Geef toegang tot bluetooth om een sensor te verbinden.';

  @override
  String get sensorsBluetoothUnsupported =>
      'Dit apparaat ondersteunt geen Bluetooth Low Energy.';

  @override
  String get sensorsScan => 'Naar sensoren zoeken';

  @override
  String get sensorsScanning => 'Zoeken…';

  @override
  String get sensorsStopScan => 'Stoppen';

  @override
  String get sensorsNoDevices => 'Nog geen hartslagsensoren gevonden.';

  @override
  String get sensorsAvailableSection => 'Beschikbare sensoren';

  @override
  String get sensorsSavedSection => 'Opgeslagen sensor';

  @override
  String get sensorsConnect => 'Verbinden';

  @override
  String get sensorsConnecting => 'Verbinden…';

  @override
  String get sensorsConnected => 'Verbonden';

  @override
  String get sensorsDisconnect => 'Verbinding verbreken';

  @override
  String get sensorsForget => 'Vergeten';

  @override
  String get sensorsConnectionFailed =>
      'Verbinden mislukt. Probeer het opnieuw.';

  @override
  String get sensorsPermissionRequired =>
      'Bluetooth-toestemming is vereist om sensoren te vinden.';

  @override
  String get sensorsUnknownDevice => 'Onbekende sensor';

  @override
  String sensorsBpm(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get sensorsPowerSection => 'Vermogen';

  @override
  String get sensorsPowerHelp =>
      'Koppel een bluetooth-vermogensmeter om je vermogen live te zien.';

  @override
  String get sensorsNoPowerDevices => 'Nog geen vermogensmeters gevonden.';

  @override
  String sensorsWatts(String watts) {
    return '$watts W';
  }

  @override
  String get sensorsCadenceSection => 'Cadans';

  @override
  String get sensorsCadenceHelp =>
      'Koppel een bluetooth-cadanssensor om je cadans live te zien.';

  @override
  String get sensorsNoCadenceDevices => 'Nog geen cadanssensoren gevonden.';

  @override
  String sensorsRpm(String rpm) {
    return '$rpm rpm';
  }

  @override
  String get diagnosticsRemoteTitle => 'Externe crashrapportage';

  @override
  String get diagnosticsRemoteEnable => 'Crashrapporten verzenden';

  @override
  String get diagnosticsRemoteEnableSubtitle =>
      'Verstuur crash- en foutrapporten naar een diagnoseserver. Dit staat los van lokale diagnostiek; je kunt beide, één of geen van beide inschakelen.';

  @override
  String get diagnosticsRemoteActive => 'Crashrapporten worden verzonden';

  @override
  String get diagnosticsRemoteNeedsServer =>
      'Externe crashrapportage is niet beschikbaar in deze versie.';

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
  String get unitsTitle => 'Eenheden';

  @override
  String get unitsSubtitle => 'Eenheden voor afstand, snelheid en hoogte';

  @override
  String get unitsSystemDefault => 'Regio van apparaat volgen';

  @override
  String get unitsMetric => 'Metrisch (km)';

  @override
  String get unitsImperial => 'Imperiaal (mi)';

  @override
  String get errorInsecureRedirectRejected =>
      'De server probeerde door te verwijzen naar een onveilige verbinding. Het verzoek is geblokkeerd om je inloggegevens te beschermen.';

  @override
  String get errorTooManyRedirects =>
      'De server heeft te vaak doorverwezen. Controleer het serveradres.';

  @override
  String get audioAnnouncementsTitle => 'Audiomeldingen';

  @override
  String get audioAnnouncementsSubtitle =>
      'Gesproken updates over afstand, tijd, tempo of snelheid';

  @override
  String get audioAnnouncementsMasterSwitch =>
      'Voortgang van activiteit aankondigen';

  @override
  String get audioAnnouncementsMasterSwitchSubtitle =>
      'Spreekt tijdens een opname je afstand, tijd, tempo of snelheid uit';

  @override
  String get audioAnnouncementsDuckSwitch =>
      'Ander geluid dempen tijdens het spreken';

  @override
  String get audioAnnouncementsDuckSwitchSubtitle =>
      'Verlaagt tijdelijk het volume van ander geluid tijdens elke melding';

  @override
  String get audioAnnouncementsIntervalsHeader =>
      'Meldingsinterval per activiteit';

  @override
  String get audioAnnouncementsByDistance => 'Afstand';

  @override
  String get audioAnnouncementsByTime => 'Tijd';

  @override
  String audioAnnouncementsIntervalDistance(String value, String unit) {
    return 'Elke $value $unit';
  }

  @override
  String audioAnnouncementsIntervalTime(String minutes) {
    return 'Elke $minutes min';
  }

  @override
  String get audioAnnouncementsDecreaseInterval => 'Interval verkleinen';

  @override
  String get audioAnnouncementsIncreaseInterval => 'Interval vergroten';

  @override
  String get audioAnnouncementsPreview => 'Voorbeeld afspelen';

  @override
  String get audioAnnouncementsPreviewUnavailable =>
      'Een voorbeeld van de melding is niet beschikbaar op dit apparaat';

  @override
  String get audioAnnouncementsAppliesNextRecording =>
      'Wijzigingen gelden vanaf je volgende opname.';

  @override
  String audioAnnouncementsSpokenMessage(
    String distance,
    String duration,
    String lapMetric,
    String overallMetric,
  ) {
    return 'Afstand $distance. Tijd $duration. Ronde: $lapMetric. Totaal: $overallMetric.';
  }
}
