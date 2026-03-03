import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get appTitle => 'Worm Journey';

  @override
  String levelLabel(int level) => 'Lv$level';

  @override
  String get gameOver => 'Game Over';

  @override
  String get tapToPlayAgain => 'Tap to play again';

  @override
  String get view => 'View';

  @override
  String quantityShort(int quantity) => 'x$quantity';

  @override
  String buyDiamonds(int price) => 'Buy $price💎';

  @override
  String get receive => 'Receive';

  @override
  String get buttonJourney => 'Journey';

  @override
  String get buttonChallenge => 'Challenge';

  @override
  String get itemCoconutName => 'Coconut';

  @override
  String get itemCoconutDescription =>
      'Snake enters tough mode and can break obstacles.';

  @override
  String get itemSnailName => 'Snail';

  @override
  String get itemSnailDescription =>
      'Snake moves slowly, easier to control.';

  @override
  String get itemMagnetName => 'Magnet';

  @override
  String get itemMagnetDescription =>
      'Attracts all leaves within 2 tiles.';

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
  String get itemSeedDescription => 'Spawns 3 more leaves.';
}
