import 'entity_model.dart';

/// Model cha cho chướng ngại vật (obtain). Mặc định độ cứng 1, không cho sâu đi xuyên.
abstract class ObstacleModel extends EntityModel {
  @override
  int get hardness => 1;

  @override
  bool get wormCanPassThrough => false;
}

/// Dấu X 🪦 (để lại khi mất đuôi).
class XMarkModel extends ObstacleModel {
  @override
  String get icon => '🪦';
  @override
  ProjectType get type => ProjectType.xMark;
}

/// Chướng ngại mà sâu có thể đi xuyên qua (không trừ đuôi, không phá). VD: mây, bụi.
abstract class PassThroughObstacleModel extends ObstacleModel {
  @override
  bool get wormCanPassThrough => true;
}
