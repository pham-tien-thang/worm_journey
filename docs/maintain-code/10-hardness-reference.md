# Hardness Reference

File này là bảng tra cứu độ cứng hiện tại của sâu và vật thể trong game. Mục tiêu là để khi thêm boss, bot, mini-bot hoặc vật thể mới, team biết đang dùng hardness bao nhiêu và rule va chạm nào sẽ chạy.

## Rule va chạm

### Sâu đâm vật thể chặn

Code xử lý tại `PlayerWormBehavior.onHitEntity`:

| Điều kiện | Kết quả |
|---|---|
| `wormHardness <= entity.hardness` | Sâu mất 1 đốt |
| `wormHardness > entity.hardness` | Vật thể bị phá, sâu bước vào ô đó |

Nguồn code:

- `lib/game/behavior/player_worm_behavior.dart`
- `lib/game/scene_level/scene_1/worm_journey_game_scene1.dart` (`_resolveBlockingEntityAt`)

### Sâu đâm sâu

Code xử lý tại `_onHitWorm`:

| Điều kiện | Kết quả |
|---|---|
| `attackerHardness <= defenderHardness` | Sâu đang đâm mất 1 đốt |
| `attackerHardness > defenderHardness` | Sâu bị đâm mất 1 đốt |

Nguồn code:

- `lib/game/scene_level/scene_1/worm_journey_game_scene1.dart` (`_onHitWorm`)

## Sâu / Worm

| Tên trong game | Code / type | Hardness gốc | Hardness hiện tại khi có buff | Ghi chú |
|---|---|---:|---:|---|
| Pink worm / sâu hồng | `PinkWorm` | `1` | `2` khi có buff dừa | `WormStats` mặc định `baseHardness = 1`; `PinkWorm` tăng `currentHardness = originalBaseHardness + 1` khi có dừa. |
| Pineapple worm / sâu dứa / boss hiện tại | `PineappleWorm` | `2` | Theo `currentHardness` nếu sau này gắn buff/effect | Constructor set `WormStats(baseHardness: 2)`. |
| Boss tương lai | Chưa có class riêng | Chưa khai báo | Chưa khai báo | Nếu boss mới cũng là worm, khai báo qua `WormStats(baseHardness: X)` và đăng ký `WormAgent` để dùng gateway va chạm chung. |
| Mini-bot tương lai | Chưa có class riêng | Chưa khai báo | Chưa khai báo | Không code va chạm riêng; dùng `WormAgent` + `WormBehavior`. |

Nguồn code:

- `lib/entities/worm/worm_stats.dart`
- `lib/components/pineapple_worm/pineapple_worm.dart`
- `lib/components/pink_worm/pink_worm.dart`

## Vật thể / Entity

| Tên | typeId | Icon | Category model | Hardness | Blocking | Ghi chú |
|---|---|---|---|---:|---|---|
| Leaf / lá | `prey_leaf` | `🌿` | `GreyModel` | `0` | Không | Mồi ăn được. |
| Coconut / dừa | `prey_coconut` | `🥥` | `GreyModel` | `0` | Không | Mồi buff độ cứng cho Pink. |
| Flag / cờ | `prey_flag` | `🚩` | `GreyModel` | `0` | Không | Ăn để thắng ở flow cũ. |
| Coin / xu | `prey_coin` | Theo platform | `GreyModel` | `0` | Không | Ăn để cộng thưởng victory. |
| X mark / bia mộ | `x_mark` | `🪦` | `ObstacleModel` | `1` | Có | Để lại ở vị trí đuôi khi sâu mất đốt. |

Nguồn code:

- `lib/game/entities/grey_model.dart`
- `lib/game/entities/obstacle_model.dart`
- `lib/game/entities/entity_models.dart`

## Kết quả mẫu

| Tình huống | So sánh | Kết quả hiện tại |
|---|---|---|
| Pink đâm `x_mark` | `1 <= 1` | Pink mất 1 đốt. |
| Pink có dừa đâm `x_mark` | `2 > 1` | `x_mark` bị phá. |
| Pineapple/Boss đâm `x_mark` | `2 > 1` | `x_mark` bị phá. |
| Pink đâm Pineapple/Boss | `1 <= 2` | Pink mất 1 đốt. |
| Pineapple/Boss đâm Pink | `2 > 1` | Pink mất 1 đốt. |
| Hai sâu hardness ngang nhau đâm nhau | `attacker <= defender` | Sâu đang đâm mất 1 đốt. |

## Khi thêm object mới

1. Thêm `ProjectType` nếu cần type mới.
2. Tạo `EntityModel` và khai báo `hardness` rõ ràng.
3. Đăng ký vào `EntityModels._registry`.
4. Nếu là vật thể chặn, đảm bảo category trong `type_obj_config.json` là blocking theo config hiện tại.
5. Cập nhật bảng này để người sau không phải đọc code mới biết hardness.

## Khi thêm boss/bot mới

1. Tạo worm class hoặc config stats với `WormStats(baseHardness: X)`.
2. Bọc bằng `WormAgent`.
3. Đăng ký vào `_registerBotAgent` hoặc registry bot tương ứng.
4. Không viết lại logic va chạm riêng nếu chỉ khác hardness; để `_advanceAgentOneStep` xử lý chung.
5. Cập nhật bảng này.
