# Worm Journey — Tài liệu dự án

Game rắn săn mồi (Flutter + Flame), hỗ trợ mồi lá/táo, chế độ 😈, chướng ngại X.

## Mục lục tài liệu

| File | Nội dung |
|------|----------|
| [01-overview.md](01-overview.md) | Tổng quan dự án, chạy app |
| [02-game-rules.md](02-game-rules.md) | Luật chơi, điều khiển, thắng/thua |
| [03-structure.md](03-structure.md) | Cấu trúc thư mục và file chính |
| [04-config.md](04-config.md) | Cấu hình (GameConfig, hằng số) |
| [05-components.md](05-components.md) | Component: rắn, mồi, chướng ngại, overlay |
| [06-screens-and-app.md](06-screens-and-app.md) | Màn hình game, app, SafeArea, nút điều khiển |

## Công nghệ

- **Flutter** (SDK ^3.7.0)
- **Flame** 1.30.x (game loop, component, input, overlay)

## Điểm chính

- Đầu rắn chỉ **chạm** vùng chết (dùng `peekNextHead()`), không cho đầu đi vào ô chết.
- Độ dài khởi điểm: **10** đốt.
- Mồi lá 🍃, mồi táo 🍎 (mỗi 10s khi không 😈); ăn táo → 😈 10s, có thể phá dấu X.
