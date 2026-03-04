# Thiết kế đối tượng game — Mồi, chướng ngại, sâu (player / BOT)

Tài liệu mô tả cách đóng gói **mồi**, **chướng ngại**, **sâu** thành object để dễ mở rộng: list mồi, nhiều loại mồi/chướng ngại, nhiều sâu BOT.

---

## 1. Mồi (Prey) — `PreyManager` + `PreyEntry`

**File:** `lib/game/prey_manager.dart`

- **PreyEntry:** một mồi trên map: `grid` (Vector2), `type` (PreyType), `component` (Prey — Flame component để vẽ).
- **PreyManager:** giữ **list mồi** (`entries`), không giới hạn 1 mồi lá + 1 mồi táo.
  - `occupiedGridKeys(snakePositions, obstaclePositions)` — set ô bị chiếm (snake + mồi + chướng ngại) để spawn không trùng.
  - `spawn(PreyType type, Set<String> occupied)` — tạo mồi tại ô random trống, trả về `PreyEntry`; game gọi `world.add(entry.component)`.
  - `consumeAt(Vector2 grid)` — ăn mồi tại ô: xóa khỏi list, trả về entry; game gọi `removeFromParent()` và xử lý effect theo `entry.type`.
  - `hasPreyAt(grid)`, `clear()`.

**Thêm loại mồi mới:** thêm enum trong `lib/components/prey.dart`; trong `Prey` thêm emoji/hình; trong game sau `consumeAt` thêm `case PreyType.xxx`.

---

## 2. Chướng ngại (Obstacle) — `ObstacleManager` + `ObstacleType` + `ObstacleBehavior`

**File:** `lib/game/obstacle_manager.dart`

- **ObstacleType:** enum (xMark; sau thêm spike, mud, …).
- **ObstacleBehavior:** `buffIdToDestroy`, `loseSegmentIfNotDestroyed`.
- **ObstacleEntry:** `grid`, `type`, `component`.
- **ObstacleManager:** `behaviorFor(type)`, `createComponent(type, grid)`, `add`/`removeAt`/`getAt`/`hasObstacleAt`/`gridPositions`/`clear()`.

**Thêm loại chướng ngại mới:** thêm enum + case trong `behaviorFor` và `createComponent`.

---

## 3. Sâu (Snake) — `SnakeAgent` (player + BOT)

**File:** `lib/game/snake_agents.dart`

- **SnakeAgent:** bọc `Snake` + `WormEntity`; expose headGridPosition, step(), removeTail(), grow(), addBuff, showCryFace, …
- Game: `_playerAgent`, getter `_snake` = `_playerAgent.snake`.

**Thêm BOT:** tạo thêm Snake + WormEntity (bot), add SnakeAgent vào list; game loop xử lý từng agent và va chạm giữa mọi body/đuôi.

---

## 4. WormJourneyGame dùng gì

| Trước | Sau |
|-------|-----|
| `_prey`, `_preyGrid`, `_applePrey`, `_applePreyGrid` | `PreyManager _preyManager` |
| `List<Vector2> _obstacles`, `List<XObstacle> _obstacleComponents` | `ObstacleManager _obstacleManager` |
| `Snake _snake` | `SnakeAgent _playerAgent`, getter `_snake` |

Spawn mồi: `_preyManager.spawn(type, _occupiedGridKeys())` rồi `world.add(entry.component)`. Ăn mồi: `_preyManager.consumeAt(newHead)` → removeFromParent + switch type. Mất đuôi: `_obstacleManager.createComponent` + add + world.add. Đâm chướng ngại: `_obstacleManager.getAt(nextHead)` → `ObstacleManager.behaviorFor(entry.type)` → phá bằng buff hoặc `_loseSegment()`.
