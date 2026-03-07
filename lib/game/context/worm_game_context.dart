import 'package:flame/components.dart';

/// Context game cho [WormBehavior]: spawn mồi, mission, phá entity, lose segment, gameTime, triggerMagnetPull.
abstract class WormGameContext {
  double get gameTime;
  void spawnPrey();
  void addMissionLeaves(int count);
  void destroyObstacleAt(Vector2 grid);
  void loseSegment();
  void triggerMagnetPull();
  /// Số lá (prey_leaf) còn trên map. Dùng để chỉ spawn khi ăn lá cuối cùng.
  int get preyLeafCountOnMap;
}

class WormGameContextImpl extends WormGameContext {
  WormGameContextImpl({
    required this.gameTimeGetter,
    required this.spawnPreyCallback,
    required this.addMissionLeavesCallback,
    required this.destroyObstacleAtCallback,
    required this.loseSegmentCallback,
    required this.triggerMagnetPullCallback,
    required this.preyLeafCountOnMapGetter,
  });

  final double Function() gameTimeGetter;
  final void Function() spawnPreyCallback;
  final void Function(int) addMissionLeavesCallback;
  final void Function(Vector2) destroyObstacleAtCallback;
  final void Function() loseSegmentCallback;
  final void Function() triggerMagnetPullCallback;
  final int Function() preyLeafCountOnMapGetter;

  @override
  int get preyLeafCountOnMap => preyLeafCountOnMapGetter();

  @override
  double get gameTime => gameTimeGetter();

  @override
  void spawnPrey() => spawnPreyCallback();

  @override
  void addMissionLeaves(int count) => addMissionLeavesCallback(count);

  @override
  void destroyObstacleAt(Vector2 grid) => destroyObstacleAtCallback(grid);

  @override
  void loseSegment() => loseSegmentCallback();

  @override
  void triggerMagnetPull() => triggerMagnetPullCallback();
}
