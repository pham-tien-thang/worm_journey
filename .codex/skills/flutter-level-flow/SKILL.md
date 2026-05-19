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
2. Trước khi sửa guide, đọc và giữ nguyên snapshot hiện tại của `guide_vi`/`guide_en` trong output terminal. Current worktree là nguồn thật; không lấy `HEAD` làm rollback khi có thay đổi chưa commit.
3. Cập nhật JSON theo schema đang dùng (map, missions, timeLimit, guide_vi/guide_en, rule...).
4. Đối chiếu guide với config và code gameplay trước khi kết thúc:
   - target nhiệm vụ, thời gian, boss, bot, điều kiện thắng/thua, cờ, revive.
   - item mở/cấm trong `itemBlock`, item thưởng đầu màn, item spawn trong map/spawnCycle.
   - hiệu ứng thật của item/entity trong code, không chỉ tên item.
   - rút guide về các rule người chơi cần ra quyết định; bỏ mô tả item cơ bản hoặc thông tin có thể tự thấy trên HUD/map.
5. Đảm bảo parse qua `loadLevelJsonConfig` trong `lib/game/config/level_json_config.dart`.
6. Nối luồng vào màn ở `GameScreen` + `WormJourneyGame` để show `GuideGameDialog` khi guide không rỗng.
7. Khi đóng dialog, gọi `dismissGuide()` để resume game.
8. Chạy `flutter analyze --no-fatal-infos --no-fatal-warnings`.

## Implementation Rules

- Không load asset, parse JSON, hoặc gọi async trong Flame `update`/`render`.
- Không đổi logic thắng/thua, mission progress, collision, revive, buff duration nếu không được yêu cầu rõ ràng.
- Tái sử dụng luồng hiện có thay vì tạo luồng song song cho guide dialog.
- Ưu tiên giữ `GameWidget` ổn định; không recreate game object vì rebuild HUD/overlay.
- Guide là contract với người chơi: không được ghi sai hoặc mơ hồ về số lượng lá, thời gian, cờ, boss, bot, item bị cấm/mở, item mới unlock, sát thương, hiệu ứng bất lợi, hoặc điều kiện thắng/thua. Nếu đổi gameplay hoặc JSON thì phải cập nhật cả `guide_vi` và `guide_en` trong cùng lượt.
- Khi guide nhắc item/entity mới, phải mô tả đúng hiệu ứng runtime hiện tại. Ví dụ: thuốc giải phải ghi rõ nó xoá hiệu ứng độc/đảo hướng nếu code làm vậy; item đi lộn ngược phải ghi rõ dùng lần nữa để triệt tiêu nếu code làm vậy.
- Guide theo style màn 1-2: tất cả các ý phải tách dòng bằng dòng trống. Ghi nhiệm vụ riêng, mỗi item một dòng dạng `emoji: tác dụng ngắn`, rồi cảnh báo nguy hiểm/chiến thuật bắt buộc.
- Không viết các câu thừa kiểu "đã mở", "is unlocked", "all items are unlocked", hoặc "màn này mở..." trong guide. Nếu item cần được giới thiệu thì chỉ ghi `emoji: tác dụng`.
- Không dùng chữ `Hint:` trong guide. Chỉ ý nguy hiểm trực tiếp cho người chơi mới bắt đầu bằng `⚠️` như guide màn 2; hint chiến thuật hoặc cơ chế có lợi thì không dùng warning.
- Với màn có sâu xanh boss như level 4, guide phải có 2 ý riêng: sâu xanh bỏ chạy khi bị tấn công kiệt sức (không warning), và cảnh báo `⚠️` sâu xanh sẽ "chiếm lấy" player nếu bắt kịp.
- Guide phải ngắn theo từng ý: mỗi đoạn 1 ý, 1 câu; chỉ giữ mục tiêu thắng/thua và mechanic mới hoặc khác thường của màn. Không liệt kê lại mọi item, không giải thích icon cơ bản, không viết cảnh báo dài nếu một câu đủ.
- Không sửa guide của màn khác chỉ vì đang rà soát. Nếu user nói "check guide các màn khác", chỉ đọc và báo sai lệch; muốn sửa phải có yêu cầu rõ level nào.
- Rollback guide chỉ được dùng snapshot current-worktree đã đọc trong lượt làm việc. Nếu không có snapshot chính xác, phải hỏi lại user; tuyệt đối không revert guide về `HEAD`/placeholder vì có thể đè rule chưa commit.

## Edit Targets

- `assets/levels/level_<n>.json`: dữ liệu màn.
- `lib/game/config/level_json_config.dart`: parse/fallback guide và config màn.
- `lib/game/scene_level/scene_1/worm_journey_game_scene1.dart`: callback `onGuideLoaded`, `dismissGuide`, pause/resume đầu màn.
- `lib/game/scene_level/game_screen.dart`: show `GuideGameDialog`, chọn ngôn ngữ, đóng dialog.
- `lib/widgets/guide_game_dialog.dart`: UI dialog hướng dẫn.

## Validation Checklist

- JSON level parse được, không văng exception.
- Guide hiển thị đúng ngôn ngữ theo locale, có fallback khi thiếu `guide_vi` hoặc `guide_en`.
- Guide khớp 1:1 với `missions.target`, `timeLimitSeconds`, `boss`, `itemBlock`, `entryItemRewards`, `spawnCycle`, `missionCompleteSpawns`, và các nhánh thắng/thua trong `WormJourneyGame`.
- Guide không dài dòng: đọc nhanh trong 5-8 giây, không quá 4 đoạn trừ khi màn có nhiều rule mới bắt buộc.
- Rà ít nhất các màn liền kề hoặc màn có cùng mechanic để tránh guide mâu thuẫn giữa các màn.
- Nếu có rollback guide, xác nhận diff chỉ thay `guide_vi`/`guide_en` đúng level được yêu cầu và nguồn rollback là snapshot current-worktree.
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
