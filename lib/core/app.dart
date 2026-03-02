import 'package:flutter/material.dart';

import '../game/game_screen.dart';

/// App chỉ mở màn game; DirectionButtons được gọi trong GameScreen (overlay).
class WormJourneyApp extends StatelessWidget {
  const WormJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameScreen();
  }
}
