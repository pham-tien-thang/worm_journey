import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'game/levels/game_level_1_screen.dart';
import 'game/levels/game_level_2_screen.dart';
import 'game/levels/game_level_3_screen.dart';
import 'game/menu_screen.dart';
import 'main_menu/main_menu_screen.dart';
import 'settings/settings_screen.dart';

/// Router: / = MainMenuScreen, /play = chọn level, /play/game/1|2|3 = màn level riêng, /settings = Settings.
GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const MainMenuScreen(key: ValueKey('main menu')),
        routes: [
          GoRoute(
            path: 'play',
            builder: (context, state) =>
                const MenuScreen(key: ValueKey('level selection')),
            routes: [
              GoRoute(
                path: 'game/1',
                builder: (_, __) => const GameLevel1Screen(),
              ),
              GoRoute(
                path: 'game/2',
                builder: (_, __) => const GameLevel2Screen(),
              ),
              GoRoute(
                path: 'game/3',
                builder: (_, __) => const GameLevel3Screen(),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) =>
                const SettingsScreen(key: ValueKey('settings')),
          ),
        ],
      ),
    ],
  );
}
