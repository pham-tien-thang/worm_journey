import '../../models/item_model.dart';

/// Loại entity dùng chung: mồi (prey_leaf, prey_apple) và vật cản (x_mark). Mở rộng thêm khi có type mới.
enum ProjectType {
  preyLeaf,
  preyCoconut,
  xMark,
  // rock, water, ...
}

/// Chuỗi typeId dùng trong JSON / registry / buff. Một nguồn duy nhất.
extension ProjectTypeExtension on ProjectType {
  String get typeId {
    switch (this) {
      case ProjectType.preyLeaf:
        return 'prey_leaf';
      case ProjectType.preyCoconut:
        return 'prey_coconut';
      case ProjectType.xMark:
        return 'x_mark';
    }
  }

  /// ItemType tương ứng với ProjectType (cùng effectTypeId / logic). Null nếu không có item.
  ItemType? get itemType {
    switch (this) {
      case ProjectType.preyLeaf:
        return ItemType.seed;
      case ProjectType.preyCoconut:
        return ItemType.coconut;
      case ProjectType.xMark:
        return null;
    }
  }

  /// effectTypeId của [itemType]. Null nếu [itemType] null.
  String? get itemTypeId => itemType?.effectTypeId;
}

/// Model gốc cho entity: icon, độ cứng, type. Tên hiển thị lấy từ ARB qua [AppLocalizations.entityDisplayName(typeId)].
abstract class EntityModel {
  String get icon;
  int get hardness;
  ProjectType get type;
}
