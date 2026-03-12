import 'entity_model.dart';
import 'grey_model.dart';
import 'obstacle_model.dart';

export 'entity_model.dart';

/// Registry: typeId (trùng key trong JSON) → model. Icon và hardness lấy từ đây.
class EntityModels {
  EntityModels._();

  static final Map<String, EntityModel> _registry = {
    ProjectType.preyLeaf.typeId: PreyLeafModel(),
    ProjectType.preyCoconut.typeId: PreyCoconutModel(),
    ProjectType.preyFlag.typeId: PreyFlagModel(),
    ProjectType.xMark.typeId: XMarkModel(),
  };

  static EntityModel? get(String typeId) => _registry[typeId];

  static String icon(String typeId) => get(typeId)?.icon ?? '❓';

  static int hardness(String typeId) => get(typeId)?.hardness ?? 0;

  static ProjectType? projectType(String typeId) => get(typeId)?.type;

  /// Tạo view cho onEatEntity / onHitEntity. Null nếu typeId không có trong registry.
  static GameEntityView? view(String typeId) {
    final model = get(typeId);
    return model != null ? GameEntityView(typeId: typeId, model: model) : null;
  }
}
