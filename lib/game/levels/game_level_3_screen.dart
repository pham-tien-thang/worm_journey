import 'package:flutter/material.dart';

import '../game_play_scaffold.dart';
import '../worm_journey_game.dart';

/// Màn chơi level 3. Tạo game với level 3, về sau init map design riêng ở đây.
class GameLevel3Screen extends StatefulWidget {
  const GameLevel3Screen({super.key});

  @override
  State<GameLevel3Screen> createState() => _GameLevel3ScreenState();
}

class _GameLevel3ScreenState extends State<GameLevel3Screen> {
  late final WormJourneyGame _game;

  @override
  void initState() {
    super.initState();
    _game = WormJourneyGame(level: 3);
    // TODO: init map design cho level 3 (preset obstacles, v.v.)
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(game: _game);
  }
}
