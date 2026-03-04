import '../game/entities/entity_model.dart';

/// Loại tác dụng khi dùng item (mở rộng sau).
enum ItemEffect {
  none,
  evilMode,
}

/// Model item dùng chung cho shop / inventory / các màn sau.
class ItemModel {
  const ItemModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.price,
    this.effect = ItemEffect.none,
  });

  final String id;
  final String name;
  final String icon;
  final String description;
  /// Giá (đơn vị 💎).
  final int price;
  final ItemEffect effect;

  @override
  String toString() => 'ItemModel($id, $name, $icon, $price💎)';
}

/// Danh sách item mặc định — gọi từ các màn (shop, inventory, ...).
final List<ItemModel> commonItemList = [
  ItemModel(
    id: ProjectType.preyCoconut.typeId,
    name: 'Quả dừa',
    icon: '🥥',
    description: 'Ăn vào sâu vào chế độ cứng đầu, phá được chướng ngại vật.',
    price: 5,
    effect: ItemEffect.evilMode,
  ),
  const ItemModel(
    id: 'snail',
    name:  'Sâu vào chế độ đi chậm, dễ dàng điều khiển.',
    icon: '🐌',
    description: 'Ốc sên.',
    price: 1,
  ),
  const ItemModel(
    id: 'magnet',
    name: 'Hút tất cả các lá cây trong khoảng cách 2 ô.',
    icon: '🧲',
    description: 'Nam châm.',
    price: 10,
  ),
  const ItemModel(
    id: 'shield',
    name: 'Khiên',
    icon: '🛡',
    description: '1 Khiên sẽ bảo vệ 1 lần khi đâm vào chướng ngại vật hoặc nhận sát thương.',
    price: 1,
  ),
  const ItemModel(
    id: 'bomb',
    name: 'Bom',
    icon: '💣',
    description: 'Phá huỷ chướng ngại vậy và gây sát thương lên kẻ địch trong 3 ô.',
    price: 10,
  ),
  const ItemModel(
    id: 'seed',
    name: 'Hạt giống',
    icon: '🌱',
    description: 'Tạo thêm 3 lá cây .',
    price: 2,
  ),
];
