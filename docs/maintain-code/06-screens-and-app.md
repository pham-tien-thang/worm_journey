# 06 — Màn hình và App

## Safe area

- **GameScreen** bọc toàn bộ nội dung trong **`SafeArea`**.
- Game và overlay nút không vẽ dưới notch, status bar hay vùng home indicator.

## GameScreen (`lib/game/game_screen.dart`)

- StatefulWidget, tạo `WormJourneyGame` trong `initState`.
- Build: `Scaffold` → `SafeArea` → `SizedBox.expand` → **GameWidget**.
- **GameWidget:**
  - `game: _game`
  - `overlayBuilderMap`: overlay `'directionButtons'` → `Align(bottomCenter, DirectionButtons(...))`
  - `initialActiveOverlays: ['directionButtons']` → luôn hiện nút khi vào game.

## DirectionButtons

- Nằm **trong màn game** (overlay của GameWidget), không đặt trong app.
- 4 nút ↑ ↓ ← →; bấm gọi `game.setDirection(SnakeDirection)`.

## App (`lib/core/app.dart`)

- **WormJourneyApp** (StatelessWidget): `build` trả về `const GameScreen()`.
- Không còn Column hay DirectionButtons trực tiếp; mọi thứ đi qua GameScreen.

## Luồng hiển thị

```
main() → WormJourneyApp → GameScreen
  → SafeArea
    → GameWidget (game + overlay directionButtons)
```

Như vậy DirectionButtons được gọi trong màn game và có Safe area cho toàn màn.
