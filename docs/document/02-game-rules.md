# 02 — Luật chơi

## Điều khiển

- **Bàn phím:** mũi tên ↑ ↓ ← →
- **Vuốt (swipe):** vuốt theo hướng muốn đi (ưu tiên velocity, tránh chéo).
- **Nút trên màn:** 4 nút ↑ ↓ ← → ở cuối màn (overlay).

## Vùng chết và chạm (không đâm xuyên)

- Đầu rắn **chỉ chạm** vùng chết: game dùng **`peekNextHead()`** để biết ô **sắp tới**.
- Nếu ô sắp tới là tường / dấu X / đuôi / thân → **không** gọi `step()`: áp dụng phạt (trừ đốt hoặc game over), đầu **không** đi vào ô đó.
- Nhờ vậy khi đổi hướng nhanh hoặc đâm vào tường/X/đuôi sẽ không bị chết liên tục do đầu đã nằm trong ô chết.

## Độ dài khởi điểm

- Rắn bắt đầu với **10 đốt** (head + 8 body + tail).

## Mồi

- **Lá 🍃:** mồi thường, luôn có 1 trên map; ăn → dài thêm 1 đốt, spawn lá mới.
- **Táo 🍎:** xuất hiện **10 giây** một lần **chỉ khi không đang 😈**. Sau khi 😈 hết, đợi **10 giây** nữa mới spawn táo tiếp.

## Chế độ 😈 (ăn táo)

- Ăn táo → đầu thành **😈**, kéo dài **10 giây** rồi tự trở lại **🙂**.
- Trong lúc 😈:
  - **Đâm dấu X:** phá hủy dấu X đó, **không** trừ đốt, rắn vẫn bước vào ô vừa phá.
  - Táo **không** spawn.
- Sau khi 😈 hết → reset bộ đếm táo, 10s sau mới có táo lại.

## Phạt khi chạm vùng chết (đầu không đi vào)

- **Tường:** trừ 1 đốt đuôi, để lại 1 dấu X tại vị trí đuôi; nếu còn ≤ 2 đốt → game over.
- **Dấu X (không phải 😈):** giống tường (trừ 1 đốt, để lại X, có thể game over).
- **Đuôi rắn:** giống tường.
- **Thân rắn:** game over ngay (không trừ đốt).

## Thắng / Thua

- **Thua:** khi sau phạt còn **≤ 2 đốt** (chỉ đầu + đuôi), hoặc đâm vào **thân**.
- Không có điều kiện thắng; chơi càng lâu càng cao điểm (số đốt / số mồi ăn).
