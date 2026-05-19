import 'entity_model.dart';

/// Model cha cho chướng ngại vật (obtain). Mặc định độ cứng 10, không cho sâu đi xuyên.
abstract class ObstacleModel extends EntityModel {
  @override
  int get hardness => 10;

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

/// Đá 🪨: vật cản cứng, không bị phá bởi mũ bảo hiểm dừa.
class StoneModel extends ObstacleModel {
  @override
  String get icon => '🪨';

  @override
  int get hardness => 50;

  @override
  ProjectType get type => ProjectType.stone;
}

/// Chướng ngại mà sâu có thể đi xuyên qua (không trừ đuôi, không phá). VD: mây, bụi.
abstract class PassThroughObstacleModel extends ObstacleModel {
  @override
  bool get wormCanPassThrough => true;
}
