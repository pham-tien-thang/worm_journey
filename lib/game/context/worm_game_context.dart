import 'package:flame/components.dart';

/// Context game dành cho [WormBehavior]: chỉ expose thao tác cần thiết (spawn mồi, mission, thời gian...).
/// Config JSON theo màn (nhiệm vụ, thời gian, rule, map): dùng [LevelJsonConfig] trong [level_json_config.dart].
/// Game tạo implementation (vd. bằng closure) để truyền vào behavior; bot/player có thể dùng context khác nhau.
abstract class WormGameContext {
  double get gameTime;
  void spawnPrey();
  void addMissionLeaves(int count);
  void destroyObstacleAt(Vector2 grid);
  void loseSegment();
  bool hasBuff(String buffId);
}

/// Implementation dùng closure; game truyền getter/setter để không lộ private.
class WormGameContextImpl extends WormGameContext {
  WormGameContextImpl({
    required this.gameTimeGetter,
    required this.spawnPreyCallback,
    required this.addMissionLeavesCallback,
    required this.destroyObstacleAtCallback,
    required this.loseSegmentCallback,
    required this.hasBuffCallback,
  });

  final double Function() gameTimeGetter;
  final void Function() spawnPreyCallback;
  final void Function(int) addMissionLeavesCallback;
  final void Function(Vector2) destroyObstacleAtCallback;
  final void Function() loseSegmentCallback;
  final bool Function(String) hasBuffCallback;

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
  bool hasBuff(String buffId) => hasBuffCallback(buffId);
}
