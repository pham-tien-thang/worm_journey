import '../../components/prey.dart' show PreyType;
import '../../core/buff/buff_config.dart';
import '../managers/obstacle_manager.dart';
import 'worm_agents.dart';
import 'worm_behavior.dart';
import '../context/worm_game_context.dart';

/// Hành vi sâu người chơi: ăn lá → grow + mission + spawn; ăn táo → grow + buff dừa; va chướng → trừ đốt hoặc phá nếu có dừa.
class PlayerWormBehavior extends WormBehavior {
  @override
  void onEatPrey(WormAgent agent, PreyType type, WormGameContext context) {
    agent.grow();
    switch (type) {
      case PreyType.leaf:
        context.addMissionLeaves(1);
        context.spawnPrey();
        break;
      case PreyType.apple:
        const itemId = 'coconut';
        final duration = BuffConfig.durationSecondsFor(itemId);
        if (duration > 0) {
          agent.addItemEffect(itemId, context.gameTime + duration);
        }
        break;
    }
  }

  @override
  HitObstacleResult onHitObstacle(
    WormAgent agent,
    ObstacleType obstacleType,
    ObstacleBehavior behavior,
    WormGameContext context,
  ) {
    if (behavior.buffIdToDestroy != null && context.hasBuff(behavior.buffIdToDestroy!)) {
      return HitObstacleResult.destroyAndStep;
    }
    if (behavior.loseSegmentIfNotDestroyed) {
      return HitObstacleResult.loseSegment;
    }
    return HitObstacleResult.none;
  }

  @override
  void onEatBuff(WormAgent agent, String buffId, double duration, WormGameContext context) {
    agent.addItemEffect(buffId, context.gameTime + duration);
  }
}
