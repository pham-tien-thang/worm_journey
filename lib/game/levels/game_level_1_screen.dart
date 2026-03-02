import 'package:flutter/material.dart';

import '../game_play_scaffold.dart';
import '../worm_journey_game.dart';

/// Màn chơi level 1. Tạo game với level 1, về sau init map design riêng ở đây.
class GameLevel1Screen extends StatefulWidget {
  const GameLevel1Screen({super.key});

  @override
  State<GameLevel1Screen> createState() => _GameLevel1ScreenState();
}

class _GameLevel1ScreenState extends State<GameLevel1Screen> {
  late final WormJourneyGame _game;

  @override
  void initState() {
    super.initState();
    _game = WormJourneyGame(level: 1);
    // TODO: init map design cho level 1 (preset obstacles, v.v.)
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(game: _game);
  }
}
