# Config màn chơi (JSON)

Mỗi màn có một file JSON: `level_1.json`, `level_2.json`, ... Game load theo số màn (vd. màn 1 → `level_1.json`).

## Tên file

- `level_<số_màn>.json` (vd. `level_1.json`, `level_2.json`).
- Thư mục mặc định: `assets/levels/` (khai báo trong `pubspec.yaml`).

## Định dạng JSON

Tất cả key đều tùy chọn. Thiếu hoặc `null` thì dùng giá trị mặc định.

| Key | Kiểu | Mặc định | Mô tả |
|-----|------|----------|--------|
| `missions` | `array` | 1 nhiệm vụ "ăn 10 lá" | Danh sách nhiệm vụ (id, typeId, target). Icon/label từ model + l10n. |
| `timeLimitSeconds` | `number` | `120` | Thời gian chơi (giây), đếm ngược. |
| `timeUrgentThresholdSeconds` | `number` | `30` | Còn ≤ X giây thì HUD cảnh báo đỏ nháy. |
| `rule` | `string` | `"none"` | Quy tắc: `none` (sau có thể: `noItems`, ...). |
| `grid` | `object` | nâu nhạt | Màu ô lưới trong vùng chơi. |
| `outside` | `object` | nâu + 🌱 | Màu và icon vùng ngoài grid. |
| `map` | `object` | `{}` | Chướng ngại và mồi đặt sẵn theo tọa độ grid. |
| `spawnCycle` | `array` | `[]` | Sinh mồi theo chu kỳ: mỗi phần tử `{ objType, intervalSeconds }`. Mỗi map config khác nhau. |

### `missions` (array)

Mỗi phần tử là object:

- `id` (string): mã nhiệm vụ, vd. `"leaves"`, `"mission2"`.
- `typeId` (string): loại entity (prey_leaf, prey_apple, x_mark). Icon và label lấy từ model + l10n.
- `target` (number): mục tiêu (vd. 10 lá).

Ví dụ:

```json
"missions": [
  { "id": "leaves", "typeId": "prey_leaf", "target": 10 }
]
```

### `grid` (object)

Màu hai loại ô xen kẽ trong vùng chơi:

- `colorLight` (string): hex, vd. `"0xFFE8DED5"` hoặc `"#E8DED5"`.
- `colorLighter` (string): hex.

Thiếu hoặc null → dùng màu nâu mặc định.

### `outside` (object)

Vùng trên/dưới vùng chơi (ô không thuộc grid):

- `color` (string): hex.
- `icon` (string): ký tự/emoji vẽ trên mỗi ô, vd. `"🌱"`, `"🌿"`.

### `map` (object)

Mỗi **key** = loại entity (typeId), **value** = list tọa độ grid `[[col, row], ...]`. Game dùng factory đăng ký từng typeId → hàm tạo entity tại ô (chướng ngại → ObstacleManager, mồi → PreyManager, bot → list agent...). Thêm loại mới (đá, nước, mồi chuối, bot nhỏ) chỉ cần đăng ký thêm trong game, không gom hết vào một manager.

- `x_mark` (array): dấu X 🪦 — chướng ngại, có buff dừa thì phá được.
- `prey_leaf` (array): mồi lá 🌿.
- `prey_apple` (array): mồi táo/dừa 🥥.
- *(Tương thích cũ: `obstacles` → coi là `x_mark`, `prey` → coi là `prey_leaf`.)*
- *Sau có thể thêm: `rock`, `water`, `prey_banana`, `small_bot`, ...*

### `spawnCycle` (array)

Sinh mồi theo chu kỳ: mỗi **intervalSeconds** giây game thử sinh 1 entity loại **objType** (trong tầm camera, ô trống). Dùng cho mồi quả dừa, sau có thể thêm loại khác. Mỗi map có thể config khác nhau.

Mỗi phần tử là object:

- `objType` (string): typeId entity eatable, vd. `"prey_coconut"`.
- `intervalSeconds` (number): chu kỳ (giây). Có thể dùng key `interval` thay cho `intervalSeconds`.

Ví dụ:

```json
"spawnCycle": [
  { "objType": "prey_coconut", "intervalSeconds": 10 }
]
```

Ví dụ map:

```json
"map": {
  "x_mark": [[5, 10], [6, 10]],
  "prey_leaf": [[1, 2], [3, 4]],
  "prey_apple": [[8, 9]]
}
```

## Ví dụ file đầy đủ

```json
{
  "missions": [
    { "id": "leaves", "typeId": "prey_leaf", "target": 10 }
  ],
  "timeLimitSeconds": 120,
  "rule": "none",
  "grid": {
    "colorLight": "0xFFE8DED5",
    "colorLighter": "0xFFD7CCC8"
  },
  "outside": {
    "color": "0xFF8B7355",
    "icon": "🌱"
  },
  "map": {
    "obstacles": [],
    "prey": []
  },
  "spawnCycle": [
    { "objType": "prey_coconut", "intervalSeconds": 10 }
  ]
}
```

## Load trong code

- Load cả màn: `await loadLevelJsonConfig(level)` → [LevelJsonConfig].
- Parse từ Map: `LevelJsonConfig.loadAllConfig(json)`.
- Load từng phần: `LevelJsonConfig.loadMapConfig(json)`, `loadRuleConfig(json)`, `loadMissionsConfig(json)`, `loadStatsConfig(json)`, `loadGridConfig(json)`, `loadOutsideConfig(json)`, `loadSpawnCycleConfig(json)`.

Chi tiết API xem trong `lib/game/level_json_config.dart`.
