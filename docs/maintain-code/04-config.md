# 04 — Cấu hình

## GameConfig (`lib/config/game_config.dart`)

| Thành viên | Ý nghĩa |
|------------|--------|
| `segmentSize` | Kích thước 1 ô (mặc định 28); runtime có thể tính theo màn hình |
| `snakePink` | Màu rắn (đầu, đuôi, thân) |
| `snakeInnerOrange` | Màu vòng trong đốt thân |
| `preyGreen` | Màu mồi (dùng khi vẽ circle; hiện tại mồi dùng emoji) |
| `moveInterval` | Giây giữa mỗi bước rắn (0.28 → ~3.5 bước/s) |
| `gridColumns` | Số cột lưới (16) |
| `gridRows` | Số hàng lưới (12) |

## Kích thước thực tế

- Trong `WormJourneyGame.onGameResize`: `_segmentSize = min(size.x/gridColumns, size.y/gridRows)` để lưới vừa màn.
- Viewport: `FixedResolutionViewport(resolution: size)` (full vùng game).

## Hằng số khác

- `lib/config/app_constants.dart`: ví dụ `gameTitle` (nếu cần).
- Táo: spawn mỗi 10s khi không 😈; 😈 kéo dài 10s (`_appleSpawnInterval`, `_devilModeEndTime` trong game).
