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
    ProjectType.preyCoin.typeId: PreyCoinModel(),
    ProjectType.xMark.typeId: XMarkModel(),
    ProjectType.stone.typeId: StoneModel(),
    ProjectType.snail.typeId: ItemEntityModel(
      type: ProjectType.snail,
      icon: '🐌',
    ),
    ProjectType.magnet.typeId: ItemEntityModel(
      type: ProjectType.magnet,
      icon: '🧲',
    ),
    ProjectType.bomb.typeId: ItemEntityModel(
      type: ProjectType.bomb,
      icon: '💣',
    ),
    ProjectType.seed.typeId: ItemEntityModel(
      type: ProjectType.seed,
      icon: '🌱',
    ),
    ProjectType.antidote.typeId: ItemEntityModel(
      type: ProjectType.antidote,
      icon: '🧪',
    ),
    ProjectType.speed.typeId: ItemEntityModel(
      type: ProjectType.speed,
      icon: '💨',
    ),
    ProjectType.clock.typeId: ItemEntityModel(
      type: ProjectType.clock,
      icon: '⏱',
    ),
    ProjectType.freeze.typeId: ItemEntityModel(
      type: ProjectType.freeze,
      icon: '❄️',
    ),
    ProjectType.dizzy.typeId: ItemEntityModel(
      type: ProjectType.dizzy,
      icon: '😵‍💫',
    ),
    ProjectType.poison.typeId: PoisonEntityModel(),
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
