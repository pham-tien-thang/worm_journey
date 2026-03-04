import 'package:flutter/material.dart';

import 'game_play_scaffold.dart';
import '../worm_journey_game.dart';

/// Màn game theo level (giữ để tương thích). Ưu tiên dùng [GameLevel1Screen], [GameLevel2Screen], [GameLevel3Screen] để init map design từng level.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.level = 1});

  final int level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final WormJourneyGame _game;

  @override
  void initState() {
    super.initState();
    _game = WormJourneyGame(level: widget.level);
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(game: _game);
  }
}
