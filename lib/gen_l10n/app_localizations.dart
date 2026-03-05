import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static AppLocalizations lookup(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        return AppLocalizationsVi();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('vi'),
  ];

  String get appTitle;
  String levelLabel(int level);
  String get gameOver;
  String get tapToPlayAgain;
  String get gameOverPlayAgain;
  String get gameOverEnd;
  String get view;
  String quantityShort(int quantity);
  String buyCoins(int price);
  String get receive;
  String getCoins(int amount);
  String get buttonJourney;
  String get buttonChallenge;
  String get buttonShop;
  String get buttonSettings;
  String get itemCoconutName;
  String get itemCoconutDescription;
  String get itemSnailName;
  String get itemSnailDescription;
  String get itemMagnetName;
  String get itemMagnetDescription;
  String get itemShieldName;
  String get itemShieldDescription;
  String get itemBombName;
  String get itemBombDescription;
  String get itemSeedName;
  String get itemSeedDescription;
  String get itemAntidoteName;
  String get itemAntidoteDescription;
  String get itemSpeedName;
  String get itemSpeedDescription;
  String get itemClockName;
  String get itemClockDescription;
  String get itemFreezeName;
  String get itemFreezeDescription;
  String get entityPreyLeafName;
  String get entityPreyCoconutName;
  String get entityXMarkName;
  String get exitGameWarningMessage;
  String get exitGameConfirm;
  String get exitGameCancel;

  /// Tên hiển thị entity theo typeId — lấy từ ARB (entityPreyLeafName, ...).
  String entityDisplayName(String typeId) {
    switch (typeId) {
      case 'prey_leaf':
        return entityPreyLeafName;
      case 'prey_apple':
        return entityPreyCoconutName;
      case 'x_mark':
        return entityXMarkName;
      default:
        return typeId;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsVi());
      case 'en':
      default:
        return SynchronousFuture<AppLocalizations>(AppLocalizationsEn());
    }
  }

  @override
  bool isSupported(Locale locale) =>
      ['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
