import 'package:go_router/go_router.dart';

import 'game/game_screen.dart';
import 'game/level_selection_screen.dart';
import 'main_menu/main_menu_screen.dart';

/// Routes: màn chính → chọn level → game.
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  /// Màn chọn level (Lv1, Lv2, Lv3).
  static const String play = '/play';
  static String game(int level) => '/game/$level';
}

GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const MainMenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.play,
        builder: (_, __) => const LevelSelectionScreen(),
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
