import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'game/game_screen.dart';
import 'game/menu_screen.dart';
import 'main_menu/main_menu_screen.dart';
import 'settings/settings_screen.dart';

/// Router: / = MainMenuScreen, /play = chọn level, /play/game/:level = GameScreen, /settings = Settings.
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
                path: 'game/:level',
                builder: (context, state) {
                  final level =
                      int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
                  return GameScreen(level: level);
                },
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
