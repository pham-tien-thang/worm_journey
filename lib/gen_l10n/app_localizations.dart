import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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
    Locale('vi'),
  ];

  /// No description provided for @entityPreyLeafName.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get entityPreyLeafName;

  /// No description provided for @entityPreyCoconutName.
  ///
  /// In en, this message translates to:
  /// **'Coconut'**
  String get entityPreyCoconutName;

  /// No description provided for @entityXMarkName.
  ///
  /// In en, this message translates to:
  /// **'Obstacle'**
  String get entityXMarkName;

  /// No description provided for @entityPreyFlagName.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get entityPreyFlagName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Worm Journey'**
  String get appTitle;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Lv{level}'**
  String levelLabel(int level);

  /// No description provided for @sceneLabel.
  ///
  /// In en, this message translates to:
  /// **'Scene {n}'**
  String sceneLabel(int n);

  /// No description provided for @stageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage {n}'**
  String stageLabel(int n);

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @tapToPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Tap to play again'**
  String get tapToPlayAgain;

  /// No description provided for @gameOverPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get gameOverPlayAgain;

  /// No description provided for @gameOverEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get gameOverEnd;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @quantityShort.
  ///
  /// In en, this message translates to:
  /// **'x{quantity}'**
  String quantityShort(int quantity);

  /// No description provided for @buyCoins.
  ///
  /// In en, this message translates to:
  /// **'Buy {price} {coinIcon}'**
  String buyCoins(int price, String coinIcon);

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @getCoins.
  ///
  /// In en, this message translates to:
  /// **'Get {amount} {coinIcon}'**
  String getCoins(int amount, String coinIcon);

  /// No description provided for @buttonJourney.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get buttonJourney;

  /// No description provided for @buttonChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get buttonChallenge;

  /// No description provided for @buttonShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get buttonShop;

  /// No description provided for @buttonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get buttonSettings;

  /// No description provided for @itemCoconutName.
  ///
  /// In en, this message translates to:
  /// **'Coconut'**
  String get itemCoconutName;

  /// No description provided for @itemCoconutDescription.
  ///
  /// In en, this message translates to:
  /// **'Snake enters tough mode and can break obstacles.'**
  String get itemCoconutDescription;

  /// No description provided for @itemSnailName.
  ///
  /// In en, this message translates to:
  /// **'Snail'**
  String get itemSnailName;

  /// No description provided for @itemSnailDescription.
  ///
  /// In en, this message translates to:
  /// **'Snake moves slowly, easier to control.'**
  String get itemSnailDescription;

  /// No description provided for @itemMagnetName.
  ///
  /// In en, this message translates to:
  /// **'Magnet'**
  String get itemMagnetName;

  /// No description provided for @itemMagnetDescription.
  ///
  /// In en, this message translates to:
  /// **'Attracts all leaves within 2 tiles.'**
  String get itemMagnetDescription;

  /// No description provided for @itemShieldName.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get itemShieldName;

  /// No description provided for @itemShieldDescription.
  ///
  /// In en, this message translates to:
  /// **'One shield blocks one hit from obstacle or damage.'**
  String get itemShieldDescription;

  /// No description provided for @itemBombName.
  ///
  /// In en, this message translates to:
  /// **'Bomb'**
  String get itemBombName;

  /// No description provided for @itemBombDescription.
  ///
  /// In en, this message translates to:
  /// **'Destroys obstacles and damages enemies in 3 tiles.'**
  String get itemBombDescription;

  /// No description provided for @itemSeedName.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get itemSeedName;

  /// No description provided for @itemSeedDescription.
  ///
  /// In en, this message translates to:
  /// **'Spawns more leaves.'**
  String get itemSeedDescription;

  /// No description provided for @itemAntidoteName.
  ///
  /// In en, this message translates to:
  /// **'Antidote'**
  String get itemAntidoteName;

  /// No description provided for @itemAntidoteDescription.
  ///
  /// In en, this message translates to:
  /// **'Removes all active effects from the snake.'**
  String get itemAntidoteDescription;

  /// No description provided for @itemSpeedName.
  ///
  /// In en, this message translates to:
  /// **'Speed Boost'**
  String get itemSpeedName;

  /// No description provided for @itemSpeedDescription.
  ///
  /// In en, this message translates to:
  /// **'Snake moves faster for a short duration.'**
  String get itemSpeedDescription;

  /// No description provided for @itemClockName.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get itemClockName;

  /// No description provided for @itemClockDescription.
  ///
  /// In en, this message translates to:
  /// **'Adds 10 seconds to the game timer.'**
  String get itemClockDescription;

  /// No description provided for @itemFreezeName.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get itemFreezeName;

  /// No description provided for @itemFreezeDescription.
  ///
  /// In en, this message translates to:
  /// **'Freezes the game for 5 seconds.'**
  String get itemFreezeDescription;

  /// No description provided for @itemDizzyName.
  ///
  /// In en, this message translates to:
  /// **'Dizzy'**
  String get itemDizzyName;

  /// No description provided for @itemDizzyDescription.
  ///
  /// In en, this message translates to:
  /// **'Reverses the snake\'s movement direction.'**
  String get itemDizzyDescription;

  /// No description provided for @exitGameWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'The game will end?'**
  String get exitGameWarningMessage;

  /// No description provided for @exitGameConfirm.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get exitGameConfirm;

  /// No description provided for @exitGameCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get exitGameCancel;

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get notEnoughCoins;

  /// No description provided for @waitCountdown.
  ///
  /// In en, this message translates to:
  /// **'Wait {time}'**
  String waitCountdown(String time);

  /// No description provided for @itemBlockedInLevel.
  ///
  /// In en, this message translates to:
  /// **'Item is blocked in this level'**
  String get itemBlockedInLevel;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @gameRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Game rules'**
  String get gameRulesTitle;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @victoryContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get victoryContinue;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
