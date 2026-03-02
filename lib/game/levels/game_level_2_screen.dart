import 'package:flutter/material.dart';

import '../game_play_scaffold.dart';
import '../worm_journey_game.dart';

/// Màn chơi level 2. Tạo game với level 2, về sau init map design riêng ở đây.
class GameLevel2Screen extends StatefulWidget {
  const GameLevel2Screen({super.key});

  @override
  State<GameLevel2Screen> createState() => _GameLevel2ScreenState();
}

class _GameLevel2ScreenState extends State<GameLevel2Screen> {
  late final WormJourneyGame _game;

  @override
  void initState() {
    super.initState();
    _game = WormJourneyGame(level: 2);
    // TODO: init map design cho level 2 (preset obstacles, v.v.)
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(game: _game);
  }
}
