# Cấu trúc thư mục `lib/`

## Game (`game/`)

- **`worm_journey_game.dart`** – Game Flame chính (logic màn chơi, va chạm, thời gian).
- **`game.dart`** – Barrel file, export `WormJourneyGame`.

### `game/config/`
- **`level_json_config.dart`** – Config màn từ JSON (missions, timeLimit, rule, map, grid, outside). Load từ `assets/levels/level_N.json`.

### `game/context/`
- **`worm_game_context.dart`** – Context cho behavior (spawn mồi, mission, destroy obstacle, buff). Game tạo implementation (closure) truyền vào behavior.

### `game/behavior/`
- **`worm_behavior.dart`** – **HitResult** enum. Interface: onEatEntity, **onHitEntity**(projectType, entityHardness, wormHardness), onEatBuff.
- **`worm_agents.dart`** – Worm + WormBehavior (WormAgent).
- **`player_worm_behavior.dart`** – Implement: ăn lá/táo, **va chạm** (so độ cứng → loseSegment hoặc destroyAndStep), buff dừa.

### `game/config/`
- **`type_obj_config.dart`** – Load từ `assets/jsonTypeObj.json`: **chỉ** định nghĩa type thuộc category nào (obtain/grey). Không chứa icon/hardness.

### `game/entities/`
- **`entity_model.dart`** – **ProjectType** enum (preyLeaf, preyCoconut, xMark). Abstract **EntityModel** (icon, hardness, type).
- **`grey_model.dart`** – **GreyModel** (mồi, hardness 0), **PreyLeafModel** (type preyLeaf), **PreyCoconutModel** (type preyCoconut).
- **`obstacle_model.dart`** – **ObstacleModel** (vật cản, hardness 1), **XMarkModel** (type xMark).
- **`entity_models.dart`** – Registry **EntityModels**: typeId → model; icon, hardness, projectType.

### `game/managers/`
- **`map_entity_manager.dart`** – placeAt(grid, typeId). Tạo component theo TypeObjConfig.getCategory; icon lấy từ EntityModels.icon(typeId).

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
