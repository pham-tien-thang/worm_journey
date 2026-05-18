import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/game_pause_observer.dart';
import 'game/scene_level/game_screen.dart';
import 'screens/challenge/challenge_screen.dart';
import 'screens/level_selection/level_selection_screen.dart';
import 'screens/main_menu/main_menu_screen.dart';
import 'screens/scene_selection/scene_selection_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shop/shop_screen.dart';

/// Routes: màn chính → chọn level / thử thách / cửa hàng / cài đặt → game.
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String play = '/play';
  static const String playSceneLevels = '/play/scene/:sceneIndex';
  static const String challenge = '/challenge';
  static const String shop = '/shop';
  static const String settings = '/settings';
  static String game(int level) => '/game/$level';
  static String sceneLevels(int sceneIndex) => '/play/scene/$sceneIndex';
}

GoRouter createAppRouter(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    navigatorKey: navigatorKey,
    observers: [GamePauseObserver()],
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const MainMenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.play,
        builder: (_, __) => const SceneSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.playSceneLevels,
        builder: (context, state) {
          final sceneIndex =
              int.tryParse(state.pathParameters['sceneIndex'] ?? '1') ?? 1;
          return LevelSelectionScreen(sceneIndex: sceneIndex);
        },
      ),
      GoRoute(
        path: AppRoutes.challenge,
        builder: (_, __) => const ChallengeScreen(),
      ),
      GoRoute(
        path: AppRoutes.shop,
        builder: (_, __) => const ShopScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/game/:level',
        builder: (context, state) {
          final level =
              int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
          return GameScreen(level: level);
        },
      ),
    ],
  );
}
