import '../../models/item_model.dart';

/// Loại entity dùng chung: mồi (prey_leaf, prey_coconut), vật cản (x_mark), và mỗi [ItemType] có [ProjectType] tương ứng.
enum ProjectType {
  preyLeaf,
  preyCoconut,
  xMark,
  // Mỗi ItemType có ProjectType tương ứng (effectTypeId = typeId)
  snail,
  magnet,
  bomb,
  seed,
  antidote,
  speed,
  clock,
  freeze,
  dizzy,
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
      case ProjectType.snail:
        return 'snail';
      case ProjectType.magnet:
        return 'magnet';
      case ProjectType.bomb:
        return 'bomb';
      case ProjectType.seed:
        return 'seed';
      case ProjectType.antidote:
        return 'antidote';
      case ProjectType.speed:
        return 'speed';
      case ProjectType.clock:
        return 'clock';
      case ProjectType.freeze:
        return 'freeze';
      case ProjectType.dizzy:
        return 'dizzy';
    }
  }

  /// ItemType tương ứng với ProjectType (cùng effectTypeId / logic). Null nếu không có item (vd. x_mark).
  ItemType? get itemType {
    switch (this) {
      case ProjectType.preyLeaf:
        return ItemType.seed;
      case ProjectType.preyCoconut:
        return ItemType.coconut;
      case ProjectType.xMark:
        return null;
      case ProjectType.snail:
        return ItemType.snail;
      case ProjectType.magnet:
        return ItemType.magnet;
      case ProjectType.bomb:
        return ItemType.bomb;
      case ProjectType.seed:
        return ItemType.seed;
      case ProjectType.antidote:
        return ItemType.antidote;
      case ProjectType.speed:
        return ItemType.speed;
      case ProjectType.clock:
        return ItemType.clock;
      case ProjectType.freeze:
        return ItemType.freeze;
      case ProjectType.dizzy:
        return ItemType.dizzy;
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

  /// Vật cản mà sâu có thể đi xuyên qua mà không bị trừ đuôi / phá. Grey (mồi) không áp dụng.
  bool get wormCanPassThrough => false;
}

/// View của entity dùng khi gọi onEatEntity / onHitEntity: lấy typeId, projectType, effectTypeId (cho buff), hardness từ model.
class GameEntityView {
  GameEntityView({required this.typeId, required this.model});

  final String typeId;
  final EntityModel model;

  ProjectType get projectType => model.type;
  /// effectTypeId dùng cho addItemEffect (vd. prey_coconut). Null nếu entity không gắn item buff.
  String? get effectTypeId => projectType.itemTypeId;
  int get hardness => model.hardness;
  bool get wormCanPassThrough => model.wormCanPassThrough;
}
