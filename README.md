# Worm Journey

Tập làm game (Flutter + Flame). Có main menu, chọn level, âm thanh, settings.

## Getting Started

```bash
flutter pub get
flutter run
```

## Cấu trúc lib (gộp từ basic toolkit)

- `app_lifecycle` – lifecycle app (audio pause/resume)
- `audio` – AudioController, SFX, nhạc
- `main_menu` – màn menu chính (Play, Settings)
- `settings` – SettingsController, màn Settings
- `style` – Palette, ResponsiveScreen, MyButton
- `game` – WormJourneyGame, GameScreen, MenuScreen (chọn level)
- `core` – app, buff, services
- `components` – snake, prey, grid, obstacles
- `widgets` – joystick, dialogs

Tài nguyên: `assets/images/`, `assets/sfx/`, `assets/music/`, `assets/fonts/`.
