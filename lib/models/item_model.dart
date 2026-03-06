import '../gen_l10n/app_localizations.dart';

/// Loại item. [effectTypeId] dùng cho l10n (tên, mô tả), SharedPrefs, addItemEffect, BuffConfig.
enum ItemType {
  coconut('prey_coconut'),
  snail('snail'),
  magnet('magnet'),
  bomb('bomb'),
  seed('seed'),
  // shield('shield'),
  antidote('antidote'),
  speed('speed'),
  clock('clock'),
  freeze('freeze');

  const ItemType(this.effectTypeId);
  final String effectTypeId;
}

/// Extension: tên và mô tả từ l10n. Switch [ItemType] và trả về getter tương ứng (itemCoconutName, ...).
/// Không dùng l10n.itemName(id) / l10n.itemDescription(id) — chỉ switch type và gọi getter trực tiếp.
extension ItemTypeExt on ItemType {
  String name(AppLocalizations l10n) {
    switch (this) {
      case ItemType.coconut: return l10n.itemCoconutName;
      case ItemType.snail: return l10n.itemSnailName;
      case ItemType.magnet: return l10n.itemMagnetName;
      case ItemType.bomb: return l10n.itemBombName;
      case ItemType.seed: return l10n.itemSeedName;
     // case ItemType.shield: return l10n.itemShieldName;
      case ItemType.antidote: return l10n.itemAntidoteName;
      case ItemType.speed: return l10n.itemSpeedName;
      case ItemType.clock: return l10n.itemClockName;
      case ItemType.freeze: return l10n.itemFreezeName;
    }
  }
  String description(AppLocalizations l10n) {
    switch (this) {
      case ItemType.coconut: return l10n.itemCoconutDescription;
      case ItemType.snail: return l10n.itemSnailDescription;
      case ItemType.magnet: return l10n.itemMagnetDescription;
      case ItemType.bomb: return l10n.itemBombDescription;
      case ItemType.seed: return l10n.itemSeedDescription;
     // case ItemType.shield: return l10n.itemShieldDescription;
      case ItemType.antidote: return l10n.itemAntidoteDescription;
      case ItemType.speed: return l10n.itemSpeedDescription;
      case ItemType.clock: return l10n.itemClockDescription;
      case ItemType.freeze: return l10n.itemFreezeDescription;
    }
  }
}

/// Model item dùng chung cho shop / inventory / các màn sau.
/// Tên và mô tả: dùng extension [ItemTypeExt] — [type.name(l10n)], [type.description(l10n)].
/// Hiệu ứng khi dùng: theo [type] (vd. [GamePlayScaffold._onUseItem] switch [type]).
class ItemModel {
  const ItemModel({
    required this.type,
    required this.icon,
    required this.price,
  });

  final ItemType type;
  final String icon;
  /// Giá (đơn vị 🪙).
  final int price;

  String get effectTypeId => type.effectTypeId;

  @override
  String toString() => 'ItemModel(${type.effectTypeId}, $icon, $price🪙)';
}

/// Danh sách item mặc định — gọi từ các màn (shop, inventory, ...).
/// Hiển thị: [item.type.name(l10n)], [item.type.description(l10n)]. Hiệu ứng: theo [item.type].
final List<ItemModel> commonItemList = [
  const ItemModel(
    type: ItemType.coconut,
    icon: '🥥',
    price: 500,
  ),
  const ItemModel(
    type: ItemType.snail,
    icon: '🐌',
    price: 100,
  ),
  const ItemModel(
    type: ItemType.magnet,
    icon: '🧲',
    price: 1000,
  ),
  const ItemModel(
    type: ItemType.bomb,
    icon: '💣',
    price: 1000,
  ),
  const ItemModel(
    type: ItemType.seed,
    icon: '🌱',
    price: 200,
  ),
  const ItemModel(
    type: ItemType.antidote,
    icon: '🧪',
    price: 200,
  ),
  const ItemModel(
    type: ItemType.speed,
    icon: '💨',
    price: 200,
  ),
  const ItemModel(
    type: ItemType.clock,
    icon: '⏱',
    price: 200,
  ),
  const ItemModel(
    type: ItemType.freeze,
    icon: '❄️',
    price: 100,
  ),
];
