# Cấu trúc thư mục `lib/`

## Game (`game/`)

- **`scene_level/scene_1/worm_journey_game_scene1.dart`** – Game Flame chính hiện tại (logic màn chơi, camera, spawn, va chạm, nhiệm vụ, thời gian).
- **`game.dart`** – Barrel file, export `WormJourneyGame`.
- **`scene_level/game_screen.dart`** – Màn game theo level (StatefulWidget, tạo `WormJourneyGame` theo level).
- **`scene_level/game_play_scaffold.dart`** – Scaffold chung: `GameWidget` + HUD + item bar + joystick + overlays.

### `game/config/`
- **`level_json_config.dart`** – Config màn từ JSON (missions, timeLimit, rule, map, grid, outside). Load từ `assets/levels/level_N.json`.
- **`type_obj_config.dart`** – Load từ `assets/jsonTypeObj.json`: định nghĩa type thuộc category nào để manager tạo component đúng.

### `game/context/`
- **`worm_game_context.dart`** – Context cho behavior (spawn mồi, mission, destroy obstacle, buff). Game tạo implementation (closure) truyền vào behavior.

### `game/behavior/`
- **`worm_behavior.dart`** – **HitResult** enum. Interface xử lý ăn entity, va chạm entity, buff.
- **`worm_agents.dart`** – Worm + WormBehavior (WormAgent).
- **`player_worm_behavior.dart`** – Implement hành vi player: ăn mồi, va chạm, buff.

### `game/entities/`
- **`entity_model.dart`** – **ProjectType** enum (preyLeaf, preyCoconut, xMark). Abstract **EntityModel** (icon, hardness, type).
- **`grey_model.dart`** – **GreyModel** (mồi, hardness 0), **PreyLeafModel** (type preyLeaf), **PreyCoconutModel** (type preyCoconut).
- **`obstacle_model.dart`** – **ObstacleModel** (vật cản, hardness 1), **XMarkModel** (type xMark).
- **`entity_models.dart`** – Registry **EntityModels**: typeId → model; icon, hardness, projectType.

### `game/managers/`
- **`map_entity_manager.dart`** – placeAt(grid, typeId). Tạo component theo TypeObjConfig.getCategory; icon lấy từ EntityModels.icon(typeId).

## Các thư mục khác

- **`components/`** – Component Flame (worm, pink_worm, prey, grid_background, x_obstacle, …).
- **`core/`** – App, buff, services (shared_prefs).
- **`config/`** – Cấu hình game tĩnh (`game_config`).
- **`entities/`** – Entity (worm_info, worm_stats, worm_team, worm_type).
- **`models/`** – Model Flutter/shared (item_model, scene_model).
- **`screens/`** – Màn Flutter (main_menu, scene_selection, level_selection, challenge, shop, settings).
- **`widgets/`** – Widget dùng chung (game_hud, game_joystick, green_button, item_info_dialog).
- **`common/`** – Tiện ích chung (debug_apply).
- **`gen_l10n/`** – Localization generated.
