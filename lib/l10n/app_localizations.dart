import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Generic error title - Used in: dialog_utils.dart
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// OK button label - Used in: dialog_utils.dart
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Cancel button label - Used in: dialog_utils.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button label - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Back button label - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Validation message for required fields - Used in: validators.dart
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// Validation message for invalid URL - Used in: validators.dart
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get invalidUrl;

  /// Title for login screen
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button label - Used in: settings_screen.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation dialog title - Used in: dialog_utils.dart (via server_settings_screen)
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// Logout confirmation dialog message - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// Username field label - Used in: login_screen.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Username field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// Password field label - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Show/hide password toggle label
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// MFA screen title
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get mfaTitle;

  /// MFA code field label
  ///
  /// In en, this message translates to:
  /// **'MFA code'**
  String get mfaCode;

  /// MFA code field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get mfaCodeHint;

  /// MFA code validation error message
  ///
  /// In en, this message translates to:
  /// **'Please enter MFA code'**
  String get mfaCodeRequired;

  /// MFA verification button label
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Map tab label - Used in: app_bottom_nav.dart
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// Settings tab label - Used in: app_bottom_nav.dart
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// Settings screen title - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreen;

  /// Server settings navigation label - Used in: settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverSettings;

  /// Server settings screen title - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get serverSettingsTitle;

  /// Logged in section header - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get loggedIn;

  /// Server URL field label - Used in: login_screen.dart, server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// Server URL field hint text - Used in: login_screen.dart
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get serverUrlHint;

  /// Tile server URL field label - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Map tile server URL'**
  String get tileServerUrl;

  /// Tile server URL field hint text
  ///
  /// In en, this message translates to:
  /// **'https://tile.openstreetmap.org/...'**
  String get tileServerUrlHint;

  /// Settings save success message - Used in: server_settings_screen.dart
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get savedSuccessfully;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
