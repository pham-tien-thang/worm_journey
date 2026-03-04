# 01 — Tổng quan dự án

## Mô tả

**Worm Journey** là game rắn săn mồi 2D: điều khiển rắn ăn mồi (lá, táo), tránh tường, đuôi và chướng ngại X. Có chế độ đặc biệt 😈 (sau khi ăn táo) cho phép phá dấu X và không bị trừ đốt khi đâm X.

## Cách chạy

```bash
cd Worm_journey
flutter pub get
flutter run
```

Chạy trên thiết bị/emulator đã cài Flutter.

## Entry point

- `lib/main.dart`: `runApp(WormJourneyApp())`
- `lib/core/app.dart`: `WormJourneyApp` → mở `GameScreen`
- `lib/game/game_screen.dart`: `GameScreen` chứa `GameWidget` + overlay nút + SafeArea

## Luồng chính

1. App → GameScreen (SafeArea + GameWidget).
2. GameWidget hiển thị WormJourneyGame và overlay DirectionButtons.
3. WormJourneyGame: Snake, Prey (lá), Prey (táo nếu có), XObstacle; xử lý input, va chạm, spawn táo/😈.

Chi tiết luật chơi và component xem các file doc tương ứng.
