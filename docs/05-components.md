# 05 — Components

## Rắn (Snake)

- **Snake** (`components/snake/snake.dart`):
  - Danh sách ô lưới `_gridPositions`, hướng `_direction` / `_nextDirection`.
  - **`peekNextHead()`:** trả về ô đầu **sẽ tới** nếu bước tiếp (không gọi `step()`). Game dùng để kiểm tra va chạm trước khi cho di chuyển.
  - **`step()`:** di chuyển 1 ô (thêm đầu mới, bỏ đuôi trừ khi vừa grow).
  - **`setHasHelmet(bool)`:** đổi emoji đầu 🙂 ↔ 😈.
  - Độ dài khởi điểm: **10** đốt (`_initialLength = 10`).

- **SnakeHead:** vẽ 1 emoji (🙂 hoặc 😈), xoay theo hướng.
- **SnakeBodySegment:** tròn hồng + tròn cam bên trong.
- **SnakeTail:** tam giác hồng.

## Mồi (Prey)

- **Prey** (`components/prey.dart`):
  - `PreyType`: `leaf` (🍃) hoặc `apple` (🍎).
  - Vẽ bằng emoji (TextPainter), không vẽ circle nữa.

## Chướng ngại X

- **XObstacle** (`components/x_obstacle.dart`): ô vuông trắng có dấu X.
- Game lưu `_obstacles` (vị trí lưới) và `_obstacleComponents` để có thể **phá** từng ô khi 😈 đâm vào.

## Overlay

- **GameOverOverlay:** nền mờ + chữ "Game Over" + "Chạm để chơi lại".
- **DirectionButtons:** 4 nút ↑ ↓ ← →, gọi `game.setDirection(...)`.

## Barrel

- `config/config.dart`, `game/game.dart`, `components/components.dart`, `core/core.dart`: export gộp cho từng nhóm file.
