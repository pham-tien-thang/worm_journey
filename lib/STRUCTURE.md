# Cấu trúc thư mục `lib/`

## Game (`game/`)

- **`worm_journey_game.dart`** – Game Flame chính (logic màn chơi, va chạm, thời gian).
- **`game.dart`** – Barrel file, export `WormJourneyGame`.

### `game/config/`
- **`level_json_config.dart`** – Config màn từ JSON (missions, timeLimit, rule, map, grid, outside). Load từ `assets/levels/level_N.json`.

### `game/context/`
- **`worm_game_context.dart`** – Context cho behavior (spawn mồi, mission, destroy obstacle, buff). Game tạo implementation (closure) truyền vào behavior.

### `game/behavior/`
- **`worm_behavior.dart`** – Interface hành vi sâu: onEatPrey, onHitObstacle, onEatBuff.
- **`worm_agents.dart`** – Worm + WormBehavior (WormAgent); game giữ `List<WormAgent>`.
- **`player_worm_behavior.dart`** – Implement WormBehavior cho người chơi (ăn lá/táo, va chướng, buff dừa).

### `game/managers/`
- **`prey_manager.dart`** – Quản lý mồi (spawn, consumeAt, occupiedGridKeys).
- **`obstacle_manager.dart`** – Quản lý chướng ngại (ObstacleType, add, removeAt, behaviorFor).

### `game/screens/`
- **`game_screen.dart`** – Màn game theo level (StatefulWidget, tạo WormJourneyGame theo level).
- **`game_play_scaffold.dart`** – Scaffold chung: GameWidget + HUD + items + joystick.

## Các thư mục khác

- **`components/`** – Component Flame (worm, pink_worm, prey, grid_background, x_obstacle, …).
- **`core/`** – App, buff, services (shared_prefs).
- **`config/`** – Cấu hình app (game_config, app_constants).
- **`entities/`** – Entity (worm_info, worm_stats, worm_team, worm_type).
- **`models/`** – Model (item_model).
- **`screens/`** – Màn Flutter (main_menu, level_selection, challenge, shop, settings).
- **`widgets/`** – Widget dùng chung (game_hud, game_joystick, green_button, item_info_dialog).
- **`common/`** – Tiện ích chung (debug_apply).
- **`gen_l10n/`** – Localization generated.
