# 03 — Cấu trúc thư mục và file chính

## Thư mục `lib/`

```
lib/
├── main.dart                 # runApp(WormJourneyApp)
├── core/
│   ├── app.dart              # WormJourneyApp → GameScreen
│   └── core.dart             # barrel export
├── game/
│   ├── game_screen.dart      # Màn game: GameWidget + overlay + SafeArea
│   ├── worm_journey_game.dart # Logic game (FlameGame)
│   └── game.dart             # barrel export
├── config/
│   ├── game_config.dart      # Lưới, tốc độ, màu
│   ├── app_constants.dart    # Hằng số app
│   └── config.dart           # barrel export
├── components/
│   ├── snake/
│   │   ├── snake.dart        # Rắn (head + body + tail), peekNextHead, step
│   │   ├── snake_head.dart   # Đầu (emoji 🙂 / 😈)
│   │   ├── snake_body_segment.dart
│   │   ├── snake_tail.dart   # Đuôi tam giác
│   │   └── snake_direction.dart
│   ├── prey.dart             # Mồi lá 🌿 / táo 🍎
│   ├── x_obstacle.dart       # Chướng ngại dấu X
│   ├── game_over_overlay.dart
│   ├── placeholder_component.dart
│   └── components.dart      # barrel export
└── widgets/
    └── direction_buttons.dart # 4 nút ↑↓←→
```

## File quan trọng

| File | Vai trò |
|------|--------|
| `worm_journey_game.dart` | Game loop, va chạm, spawn mồi/táo, 😈, trừ đốt, phá X |
| `snake.dart` | Vị trí lưới, `peekNextHead()`, `step()`, độ dài 10 khởi điểm |
| `game_screen.dart` | SafeArea, GameWidget, overlay DirectionButtons |
| `game_config.dart` | gridColumns, gridRows, moveInterval, segmentSize (gợi ý) |

Chi tiết config và component xem [04-config.md](04-config.md), [05-components.md](05-components.md).
