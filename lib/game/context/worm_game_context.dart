import 'package:flame/components.dart';

/// Context game cho [WormBehavior]: spawn mồi, mission, phá entity, lose segment, gameTime.
abstract class WormGameContext {
  double get gameTime;
  void spawnPrey();
  void addMissionLeaves(int count);
  void destroyObstacleAt(Vector2 grid);
  void loseSegment();
}

class WormGameContextImpl extends WormGameContext {
  WormGameContextImpl({
    required this.gameTimeGetter,
    required this.spawnPreyCallback,
    required this.addMissionLeavesCallback,
    required this.destroyObstacleAtCallback,
    required this.loseSegmentCallback,
  });

  final double Function() gameTimeGetter;
  final void Function() spawnPreyCallback;
  final void Function(int) addMissionLeavesCallback;
  final void Function(Vector2) destroyObstacleAtCallback;
  final void Function() loseSegmentCallback;

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
}
