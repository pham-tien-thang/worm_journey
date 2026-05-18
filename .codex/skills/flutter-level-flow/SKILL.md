---
name: flutter-level-flow
description: Tạo hoặc chỉnh luồng màn chơi Flutter cho project Worm Journey. Dùng khi cần thêm màn mới hoặc sửa màn hiện có theo dữ liệu JSON trong assets (assets/levels/level_*.json), map dữ liệu đó vào cấu hình/game state, và hiển thị dialog hướng dẫn của màn khi người chơi vừa vào màn.
---

# Flutter Level Flow

## Overview

Triển khai luồng vào màn theo thứ tự: load JSON level từ `assets`, parse vào `LevelJsonConfig`, khởi tạo game state theo config, và mở dialog hướng dẫn trước khi bắt đầu chơi.
Giữ nguyên gameplay hiện tại; chỉ thay đổi những phần cần cho level mới và hướng dẫn đầu màn.

## Workflow

1. Xác định level cần thêm/sửa và file đích `assets/levels/level_<n>.json`.
2. Cập nhật JSON theo schema đang dùng (map, missions, timeLimit, guide_vi/guide_en, rule...).
3. Đảm bảo parse qua `loadLevelJsonConfig` trong `lib/game/config/level_json_config.dart`.
4. Nối luồng vào màn ở `GameScreen` + `WormJourneyGame` để show `GuideGameDialog` khi guide không rỗng.
5. Khi đóng dialog, gọi `dismissGuide()` để resume game.
6. Chạy `flutter analyze --no-fatal-infos --no-fatal-warnings`.

## Implementation Rules

- Không load asset, parse JSON, hoặc gọi async trong Flame `update`/`render`.
- Không đổi logic thắng/thua, mission progress, collision, revive, buff duration nếu không được yêu cầu rõ ràng.
- Tái sử dụng luồng hiện có thay vì tạo luồng song song cho guide dialog.
- Ưu tiên giữ `GameWidget` ổn định; không recreate game object vì rebuild HUD/overlay.

## Edit Targets

- `assets/levels/level_<n>.json`: dữ liệu màn.
- `lib/game/config/level_json_config.dart`: parse/fallback guide và config màn.
- `lib/game/scene_level/scene_1/worm_journey_game_scene1.dart`: callback `onGuideLoaded`, `dismissGuide`, pause/resume đầu màn.
- `lib/game/scene_level/game_screen.dart`: show `GuideGameDialog`, chọn ngôn ngữ, đóng dialog.
- `lib/widgets/guide_game_dialog.dart`: UI dialog hướng dẫn.

## Validation Checklist

- JSON level parse được, không văng exception.
- Guide hiển thị đúng ngôn ngữ theo locale, có fallback khi thiếu `guide_vi` hoặc `guide_en`.
- Game pause khi dialog mở và resume khi đóng.
- Không có thay đổi ngoài phạm vi level flow.
- Analyze pass:
  `flutter analyze --no-fatal-infos --no-fatal-warnings`

## References

Đọc `references/code-map.md` để tra nhanh vị trí file và trách nhiệm từng điểm chạm.

## Level 2 Template (Pineapple Worm)

Khi tạo màn có bot cạnh tranh ăn lá (như level 2), triển khai theo checklist sau:

1. Cập nhật `assets/levels/level_2.json`:
   - `timeLimitSeconds = 90`
   - mission lá của player `target = 10`
   - thêm `spawnCycle` cho `speed` mỗi 10s
   - bỏ block `magnet` và `speed` trong `itemBlock`
   - guide có cảnh báo: không để bot ăn 10 lá, bot mạnh, magnet/speed mở ở màn này
2. Tạo bot worm riêng trong `WormJourneyGame` cho level 2:
   - speed nhanh hơn player một chút (`moveInterval * 0.95`)
   - hardness cao hơn player 1 nấc
   - tự tìm lá gần nhất và né vật cản/wall/body
3. Theo dõi bộ đếm lá bot đã ăn:
   - bot ăn đủ 10 lá => game over ngay
   - player hoàn thành mission 10 lá trước => win ngay (không cần cờ)
4. Khi unlock level 2 lần đầu (từ win level 1):
   - cộng thêm `+1 magnet`, `+1 speed` vào `SharedPrefsService`
5. Asset bot:
   - giữ thư mục asset bot ngang hàng với `pink_worm` tại `assets/images/component/worm/pineapple_worm`
   - dùng cùng sprite nếu chưa có art riêng.
