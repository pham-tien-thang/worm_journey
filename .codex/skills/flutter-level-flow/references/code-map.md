# Worm Journey Level Flow Code Map

## JSON Level
- `assets/levels/level_<n>.json`
- Mỗi màn đọc từ `assets/levels`, tên file theo format `level_<level>.json`.

## Parse Config
- `lib/game/config/level_json_config.dart`
- Entry point: `loadLevelJsonConfig(int level, {String assetsPath = 'assets/levels'})`
- Guide keys: `guide_vi`, `guide_en`, fallback từ `guide`.

## Game Runtime
- `lib/game/scene_level/scene_1/worm_journey_game_scene1.dart`
- Game load config và gọi callback `onGuideLoaded(guideVi, guideEn)` khi có nội dung guide.
- Khi user đóng guide dialog, gọi `dismissGuide()` để bắt đầu/resume gameplay.
- Level 2 có thêm bot `PineappleWorm`: tự tìm lá, né vật cản, đếm số lá bot ăn để quyết định game over.

## Flutter Screen + Dialog
- `lib/game/scene_level/game_screen.dart`
- `GameScreen` nhận callback `onGuideLoaded`, gọi `_showGuideDialog(...)`, rồi gọi `_game.dismissGuide()`.
- `lib/widgets/guide_game_dialog.dart` là UI dialog hướng dẫn.

## Unlock Rewards
- `performVictoryUnlockAndDismiss()` trong `worm_journey_game_scene1.dart` là nơi xử lý unlock level/scene.
- Dùng cùng chỗ này để thưởng item one-time khi lần đầu mở level mới (ví dụ mở level 2: +1 magnet, +1 speed).
