# Worm Journey — Tài liệu dự án

Game rắn săn mồi (Flutter + Flame), hỗ trợ mồi lá/táo, chế độ 😈, chướng ngại X.

## Cấu trúc thư mục doc

- **document/** — Luồng & nghiệp vụ (tổng quan, luật chơi).
- **maintain-code/** — Vị trí code, đọc/sửa code (cấu trúc, config, component, màn hình, ăn mồi/mất đuôi, thiết kế đối tượng).

## Mục lục

### document (luồng & nghiệp vụ)

| File | Nội dung |
|------|----------|
| [document/01-overview.md](document/01-overview.md) | Tổng quan dự án, chạy app, luồng chính |
| [document/02-game-rules.md](document/02-game-rules.md) | Luật chơi, điều khiển, thắng/thua |

### maintain-code (vị trí code / đọc code)

| File | Nội dung |
|------|----------|
| [maintain-code/03-structure.md](maintain-code/03-structure.md) | Cấu trúc thư mục và file chính |
| [maintain-code/04-config.md](maintain-code/04-config.md) | Cấu hình (GameConfig, hằng số) |
| [maintain-code/05-components.md](maintain-code/05-components.md) | Component: rắn, mồi, chướng ngại, overlay |
| [maintain-code/06-screens-and-app.md](maintain-code/06-screens-and-app.md) | Màn hình game, app, SafeArea, nút điều khiển |
| [maintain-code/07-eat-and-lose-segment.md](maintain-code/07-eat-and-lose-segment.md) | Sâu ăn vật thể & đâm chướng ngại mất đuôi — vị trí trong code |
| [maintain-code/08-game-objects-design.md](maintain-code/08-game-objects-design.md) | Thiết kế đối tượng: mồi, chướng ngại, sâu (player/BOT) |
| [maintain-code/09-snake-movement-and-direction.md](maintain-code/09-snake-movement-and-direction.md) | Sâu di chuyển, đổi hướng, thân/đuôi tại góc — vị trí code |

## Công nghệ

- **Flutter** (SDK ^3.7.0)
- **Flame** 1.30.x (game loop, component, input, overlay)

## Điểm chính

- Đầu rắn chỉ **chạm** vùng chết (dùng `peekNextHead()`), không cho đầu đi vào ô chết.
- Độ dài khởi điểm: **10** đốt.
- Mồi lá 🌿, mồi táo 🍎 (mỗi 10s khi không 😈); ăn táo → 😈 10s, có thể phá dấu X.
