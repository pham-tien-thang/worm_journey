// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get entityPreyLeafName => 'Leaf';

  @override
  String get entityPreyCoconutName => 'Coconut';

  @override
  String get entityXMarkName => 'Obstacle';

  @override
  String get entityPreyFlagName => 'Flag';

  @override
  String get entityCoinName => 'Coin';

  @override
  String get appTitle => 'Worm Journey';

  @override
  String levelLabel(int level) {
    return 'Lv$level';
  }

  @override
  String sceneLabel(int n) {
    return 'Scene $n';
  }

  @override
  String stageLabel(int n) {
    return 'Stage $n';
  }

  @override
  String get gameOver => 'Game Over';

  @override
  String get tapToPlayAgain => 'Tap to play again';

  @override
  String get gameOverPlayAgain => 'Play again';

  @override
  String get gameOverRevive => 'Revive';

  @override
  String get gameOverEnd => 'End';

  @override
  String get view => 'View';

  @override
  String quantityShort(int quantity) {
    return 'x$quantity';
  }

  @override
  String buyCoins(int price, String coinIcon) {
    return 'Buy $price $coinIcon';
  }

  @override
  String get receive => 'Receive';

  @override
  String getCoins(int amount, String coinIcon) {
    return 'Get $amount $coinIcon';
  }

  @override
  String get buttonJourney => 'Journey';

  @override
  String get buttonChallenge => 'Challenge';

  @override
  String get buttonShop => 'Shop';

  @override
  String get buttonSettings => 'Settings';

  @override
  String get itemCoconutName => 'Coconut';

  @override
  String get itemCoconutDescription =>
      'Snake enters tough mode and can break obstacles.';

  @override
  String get itemSnailName => 'Snail';

  @override
  String get itemSnailDescription => 'Snake moves slowly, easier to control.';

  @override
  String get itemMagnetName => 'Magnet';

  @override
  String get itemMagnetDescription => 'Attracts all leaves within 2 tiles.';

  @override
  String get itemShieldName => 'Shield';

  @override
  String get itemShieldDescription =>
      'One shield blocks one hit from obstacle or damage.';

  @override
  String get itemBombName => 'Bomb';

  @override
  String get itemBombDescription =>
      'Destroys obstacles and damages enemies in 3 tiles.';

  @override
  String get itemSeedName => 'Seed';

  @override
  String get itemSeedDescription => 'Spawns more leaves.';

  @override
  String get itemAntidoteName => 'Antidote';

  @override
  String get itemAntidoteDescription =>
      'Removes all active effects from the snake.';

  @override
  String get itemSpeedName => 'Speed Boost';

  @override
  String get itemSpeedDescription => 'Snake moves faster for a short duration.';

  @override
  String get itemClockName => 'Clock';

  @override
  String get itemClockDescription => 'Adds 10 seconds to the game timer.';

  @override
  String get itemFreezeName => 'Freeze';

  @override
  String get itemFreezeDescription => 'Freezes the game for 5 seconds.';

  @override
  String get itemDizzyName => 'Dizzy';

  @override
  String get itemDizzyDescription =>
      'Reverses the snake\'s movement direction.';

  @override
  String get exitGameWarningMessage => 'The game will end?';

  @override
  String get exitGameConfirm => 'End';

  @override
  String get exitGameCancel => 'Cancel';

  @override
  String get notEnoughCoins => 'Not enough coins';

  @override
  String waitCountdown(String time) {
    return 'Wait $time';
  }

  @override
  String get itemBlockedInLevel => 'Item is blocked in this level';

  @override
  String get understood => 'Understood';

  @override
  String get gameRulesTitle => 'Game rules';

  @override
  String get ready => 'Ready';

  @override
  String get victory => 'Victory';

  @override
  String get victoryContinue => 'Continue';

  @override
  String victoryClaimReward(int amount) {
    return 'Claim $amount coins';
  }

  @override
  String get victoryExit => 'Exit';

  @override
  String get victoryExitLoseRewardWarning => 'You will lose the large reward';

  @override
  String get victoryRewardLevelLabel => 'Level';

  @override
  String get victoryRewardTimeLabel => 'Time';

  @override
  String get victoryRewardCoinsLabel => 'Coins';

  @override
  String victoryRewardReceived(int amount, String coinIcon) =>
      'Reward received: $amount $coinIcon';
}
