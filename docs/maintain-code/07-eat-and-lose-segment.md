# Sâu ăn vật thể & đâm chướng ngại mất đuôi — Vị trí trong code

Tài liệu này chỉ rõ **đoạn code nào** xử lý:
1. **Sâu ăn vật thể** (mồi lá, mồi táo) → tăng độ dài / buff.
2. **Sâu đâm chướng ngại vật** (hoặc tường/đuôi/thân) → mất 1 đốt đuôi, để lại dấu X.

---

## 1. Sâu ăn vật thể

Luồng: mỗi nhịp di chuyển, game gọi `_snake.step()` rồi kiểm tra ô đầu mới có trùng ô mồi không. Nếu trùng thì gọi `_snake.grow()` (và thêm buff nếu là táo).

### 1.1. File: `lib/game/worm_journey_game.dart`

- **Sau khi sâu bước một ô:** `_snake.step()`, `newHead = _snake.headGridPosition`.
- **Ăn mồi:** `consumed = _preyManager.consumeAt(newHead)`; nếu không null thì `consumed.component.removeFromParent()`, `_snake.grow()`, và xử lý theo `consumed.type` (leaf → mission + _spawnPrey(); apple → buff coconut).

### 1.2. File: `lib/components/snake/snake.dart`

- **`grow()`:** tăng `_pendingGrow`. Ở lần `step()` tiếp theo, sâu không xóa đuôi nên dài thêm 1 đốt.
- **`addBuff(String itemId, double endTime)`:** xóa buff cùng `itemId` (nếu có) rồi thêm buff mới với thời điểm hết hạn.

---

## 2. Đâm chướng ngại vật (hoặc tường/đuôi/thân) → mất đuôi

Luồng: trước khi gọi `_snake.step()`, game kiểm tra ô đầu **sắp tới** (`nextHead`). Nếu trùng tường, chướng ngại, đuôi hoặc thân thì gọi `_onHitHazard(...)` → `_loseSegment()` (trừ 1 đốt, tạo dấu X). Có buff dừa thì đâm chướng ngại sẽ phá X và vẫn `step()`, không gọi `_loseSegment()`.

### 2.1. File: `lib/game/worm_journey_game.dart`

- **Lấy ô đầu sắp tới:** `nextHead = _snake.peekNextHead()`.
- **Kiểm tra đâm tường:** `outOfBounds` → `_onHitHazard(HazardType.wall, nextHead)`.
- **Kiểm tra đâm chướng ngại:** `_obstacleManager.hasObstacleAt(nextHead)` → `_onHitHazard(HazardType.obstacle, nextHead)`.
- **Kiểm tra đâm đuôi / thân:** đầu trùng tailGrid hoặc body → `_onHitHazard(HazardType.tail/body, nextHead)`.
- **`_onHitHazard(type, nextHead)`:** `_snake.applyNextDirectionAndSyncVisuals()`; wall/tail/body → `_loseSegment()`; obstacle → `ObstacleManager.behaviorFor(entry.type)`, nếu có buff phá được thì `_destroyObstacleAt` + `_snake.step()`, không thì `_loseSegment()`.
- **`_loseSegment()`:** `_snake.showCryFace()`, `tailGrid = _snake.tailGridPosition`, `_snake.removeTail()`, tạo component qua `_obstacleManager.createComponent(ObstacleType.xMark, tailGrid)` + add + `world.add(comp)`, nếu `_snake.segmentCount <= 2` thì `_setGameOver()`.

### 2.2. File: `lib/components/snake/snake.dart`

- **`removeTail()`:** xóa phần tử cuối của `_gridPositions` (và đồng bộ `_previousGridPositions` nếu cần), rồi gọi `_syncVisuals()`.

---

## Tóm tắt vị trí

| Hành vi | File |
|--------|------|
| Ăn mồi (PreyManager.consumeAt, grow, mission/buff) | `worm_journey_game.dart` |
| Sâu dài thêm 1 đốt (`grow`) | `snake.dart` |
| Kiểm tra đâm tường/chướng ngại/đuôi/thân | `worm_journey_game.dart` |
| Xử lý va chạm → trừ đốt hoặc phá X | `worm_journey_game.dart` (_onHitHazard, ObstacleManager.behaviorFor) |
| Trừ 1 đốt + tạo dấu X (`_loseSegment`) | `worm_journey_game.dart` |
| Bỏ 1 đốt đuôi (`removeTail`) | `snake.dart` |
