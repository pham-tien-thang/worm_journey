import 'entity_model.dart';

/// Model cha cho chướng ngại vật (obtain). Mặc định độ cứng 1.
abstract class ObstacleModel extends EntityModel {
  @override
  int get hardness => 1;
}

/// Dấu X 🪦 (để lại khi mất đuôi).
class XMarkModel extends ObstacleModel {
  @override
  String get icon => '🪦';
  @override
  ProjectType get type => ProjectType.xMark;
}
