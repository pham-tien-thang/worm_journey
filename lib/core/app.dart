import 'package:flutter/material.dart';

import '../game/menu_screen.dart';

/// App mở màn menu; chọn LV 1/2/3 để vào game.
class WormJourneyApp extends StatelessWidget {
  const WormJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MenuScreen(),
    );
  }
}
