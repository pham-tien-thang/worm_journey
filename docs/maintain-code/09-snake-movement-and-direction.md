# Sâu di chuyển, đổi hướng & thân/đuôi tại góc — Vị trí code

Tài liệu chỉ rõ **đoạn code** xử lý: (1) sâu di chuyển theo nhịp, (2) đổi hướng từ input, (3) các đốt thân và đuôi di chuyển đúng và xoay đúng tại các góc đổi hướng.

---

## 1. Sâu di chuyển (bước từng ô theo nhịp)

### 1.1. Game quyết định “đến giờ bước chưa”

**File:** `lib/game/worm_journey_game.dart`

- **Tích lũy thời gian và tính progress** (khoảng dòng 471–477):
  - `interval = _snake.moveInterval` — số giây giữa mỗi bước (vd. 0.28).
  - `progress = (_moveAccumulator / interval).clamp(0.0, 1.0)` — tiến độ 0→1 trong khoảng giữa hai bước.
  - `_snake.setVisualProgress(progress)` — đưa progress vào Snake để nội suy vị trí (đầu/thân/đuôi) giữa ô cũ và ô mới.
  - `_moveAccumulator += dt`; nếu `_moveAccumulator >= interval` thì trừ `interval` và **thực hiện một bước** (xem dưới).

- **Gọi bước di chuyển** (khoảng dòng 511):
  - `_snake.step()` — thực hiện di chuyển một ô (cập nhật lưới, thêm đầu mới, bỏ đuôi trừ khi vừa grow).

```dart
final interval = _snake.moveInterval;
final progress = (_moveAccumulator / interval).clamp(0.0, 1.0);
_snake.setVisualProgress(progress);

_moveAccumulator += dt;
if (_moveAccumulator < interval) return;
_moveAccumulator -= interval;
// ... kiểm tra va chạm peekNextHead() ...
_snake.step();
```

### 1.2. Snake thực hiện một bước (cập nhật lưới)

**File:** `lib/components/snake/snake.dart`

- **`step()`** (khoảng dòng 297–322):
  - Lưu vị trí lưới hiện tại vào `_previousGridPositions` (để sau đó lerp từ ô cũ → ô mới).
  - Đặt `_visualProgress = 0.0` (đầu bước mới).
  - Áp dụng `_nextDirection` nếu có: `_direction = _nextDirection!`, `_nextDirection = null`.
  - Tính ô đầu mới: `newHead = _gridPositions.first + _direction.toVector()`.
  - Insert `newHead` vào đầu `_gridPositions`.
  - Nếu không grow: `_gridPositions.removeLast()` (bỏ đuôi cũ); nếu `_pendingGrow > 0` thì không bỏ đuôi (sâu dài ra).
  - Gọi `_syncVisuals()` để cập nhật vị trí/ góc đầu, thân, đuôi.

```dart
Vector2? step() {
  _previousGridPositions = List.from(_gridPositions);
  _visualProgress = 0.0;
  if (_nextDirection != null) {
    _direction = _nextDirection!;
    _nextDirection = null;
  }
  final move = _direction.toVector();
  final newHead = _gridPositions.first + move;
  _gridPositions.insert(0, newHead);
  if (_pendingGrow > 0) {
    _pendingGrow--;
  } else {
    _gridPositions.removeLast();
  }
  _syncVisuals();
  return newHead;
}
```

- **`moveInterval`** — set khi tạo Snake (vd. từ `GameConfig.moveInterval`), quy định tốc độ di chuyển (giây/bước).

---

## 2. Đổi hướng (input → hướng sắp đi)

### 2.1. Game nhận input và đặt hướng “cho bước tiếp theo”

**File:** `lib/game/worm_journey_game.dart`

- **API cho UI/joystick** (khoảng dòng 129–133):
  - `setDirection(SnakeDirection d)` — không cho quay ngược (so với `currentDirection`), rồi gọi `_snake.setNextDirection(d)`.

- **Bàn phím** (khoảng dòng 544–559): mũi tên ↑↓←→ gọi `_snake.setNextDirection(SnakeDirection.up/down/left/right)`.

- Joystick / nút: gọi `game.setDirection(dir)` (vd. `lib/widgets/game_joystick.dart`, `lib/widgets/direction_buttons.dart`), nên cũng đi qua `setDirection` → `setNextDirection`.

### 2.2. Snake lưu hướng “cho bước tiếp theo” và chặn quay ngược

**File:** `lib/components/snake/snake.dart`

- **`setNextDirection(SnakeDirection d)`** (khoảng dòng 146–152):
  - Không cho đi ngược với hướng hiện tại (up↔down, left↔right): nếu ngược thì `return`.
  - Gán `_nextDirection = d`. Hướng này sẽ được áp dụng khi gọi `step()` (trong `step()` có `_direction = _nextDirection!`).

- **`peekNextHead()`** (khoảng dòng 91–96): dùng `_nextDirection ?? _direction` để trả về ô đầu **sẽ tới** nếu bước tiếp — game dùng để kiểm tra va chạm trước khi gọi `step()`.

- **`SnakeDirection`** (`lib/components/snake/snake_direction.dart`): enum up/down/left/right; `toVector()` (0,±1), `isOppositeOf(other)`.

---

## 3. Thân và đuôi di chuyển đúng tại các góc đổi hướng

Ý tưởng: mỗi đốt có **vị trí world** = lerp giữa ô cũ và ô mới theo `_visualProgress`; **hướng** của từng đốt = hướng từ đốt đó **về phía đầu** (thân/đuôi xoay theo hướng đó).

### 3.1. Nội suy vị trí (lerp) và đồng bộ visual

**File:** `lib/components/snake/snake.dart`

- **`_visualProgress`** (0→1): game gọi `setVisualProgress(progress)` mỗi frame; trong khoảng giữa hai lần `step()`, progress tăng dần → đầu/thân/đuôi trượt mượt từ ô cũ sang ô mới.

- **`_lerpWorld(gridFrom, gridTo)`** (khoảng dòng 184–188): đổi hai ô lưới sang world rồi lerp theo `_visualProgress`:
  - `from = _gridToWorld(gridFrom)`, `to = _gridToWorld(gridTo)`.
  - `return from + (to - from) * _visualProgress`.

- **`_syncVisuals()`** (khoảng dòng 196–251) — **đoạn chính** làm thân/đuôi đúng góc:
  - **Đầu:** vị trí = `_lerpWorld(headPrev, _gridPositions.first)`, `_head.direction = _direction`.
  - **Đuôi:** vị trí = `_lerpWorld(tailPrev, tailGrid)`. Hướng đuôi = hướng từ đốt áp chót tới đuôi: `prev = _gridPositions[length-2]`, `diff = tailGrid - prev` → set `_tail.direction` (right/left/down/up theo diff).
  - **Thân:** với mỗi index `i` (1 .. length-2):
    - Vị trí = `_lerpWorld(prev, _gridPositions[i])` (prev = ô trước đó của cùng đốt, từ `_previousGridPositions` hoặc `_gridPositions`).
    - **Hướng thân = hướng từ đốt đó về phía đầu:** `towardHead = _gridPositions[i - 1] - _gridPositions[i]`, `bodyDir = _vectorToDirection(towardHead)`.
    - Gán `position` và `setDirection(bodyDir)` cho segment tương ứng; nếu thiếu segment thì tạo `SnakeBodySegment(direction: bodyDir, ...)` và add.

- **`_vectorToDirection(Vector2 v)`** (khoảng dòng 190–195): đổi vector (vd. towardHead) thành SnakeDirection (ưu tiên |x| >= |y| → left/right, còn lại up/down).

Nhờ **towardHead** và **diff đuôi** tính từ **ô hiện tại** (`_gridPositions`), tại các góc đổi hướng (vd. đi ngang rồi rẽ lên), mỗi đốt thân/đuôi tự nhận đúng hướng (ngang/dọc) và vị trí lerp nên di chuyển đúng tại góc.

### 3.2. Đốt thân vẽ theo hướng

**File:** `lib/components/snake/snake_body_segment.dart`

- **`direction`** + **`setDirection(SnakeDirection value)`**: Snake gọi `setDirection(bodyDir)` mỗi lần `_syncVisuals()`.
- **Render:** chọn sprite vertical/horizontal theo hướng, lật (flipX cho trái, flipY cho lên) để đốt thân khớp với góc (ngang/ dọc).

### 3.3. Đuôi vẽ theo hướng

**File:** `lib/components/snake/snake_tail.dart`

- **`direction`** + **`setDirection(SnakeDirection value)`**: Snake set `_tail.direction` theo `diff = tailGrid - prev` như trên.
- **Render:** đuôi dùng sprite thân + chấm đuôi; hướng chấm có thể lerp mượt (`_dotDirection`) theo `direction` trong `update(dt)`.

---

## 4. Luồng tóm tắt

| Bước | Vị trí code | Việc chính |
|------|-------------|------------|
| Input (joystick/nút/phím) | `worm_journey_game.dart`: `setDirection`; joystick/buttons gọi `game.setDirection` | `_snake.setNextDirection(d)` |
| Cấm quay ngược, lưu hướng | `snake.dart`: `setNextDirection` | `_nextDirection = d` (nếu không ngược) |
| Đếm thời gian, tính progress | `worm_journey_game.dart`: `update`, `_moveAccumulator`, `interval` | `setVisualProgress(progress)` |
| Mỗi frame cập nhật vị trí/góc | `snake.dart`: `update` → `_syncVisuals` | Đầu/thân/đuôi: lerp vị trí, set hướng từ towardHead / diff đuôi |
| Đến giờ thì bước một ô | `worm_journey_game.dart`: `_moveAccumulator >= interval` → `_snake.step()` | `step()`: lưu previous, áp dụng _nextDirection, insert newHead, removeLast (hoặc grow), _syncVisuals |

---

## 5. Tóm tắt file & đoạn quan trọng

| Nội dung | File | Đoạn / tên |
|----------|------|------------|
| Nhịp di chuyển, progress, gọi step | `worm_journey_game.dart` | `update`: interval, _moveAccumulator, setVisualProgress, step() |
| Một bước: lưới + áp dụng nextDirection | `snake.dart` | `step()` |
| Đặt hướng cho bước tiếp theo | `snake.dart` | `setNextDirection` |
| Input → setDirection | `worm_journey_game.dart`, `game_joystick.dart`, `direction_buttons.dart` | `setDirection`, phím/joystick |
| Lerp world, sync đầu/thân/đuôi, hướng thân/đuôi tại góc | `snake.dart` | `_lerpWorld`, `_syncVisuals`, `_vectorToDirection` |
| Thân vẽ theo direction | `snake_body_segment.dart` | `direction`, `setDirection`, render vertical/horizontal + flip |
| Đuôi vẽ theo direction | `snake_tail.dart` | `direction`, `setDirection`, diff từ đốt áp chót |
