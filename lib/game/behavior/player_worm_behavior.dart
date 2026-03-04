import '../../core/buff/buff_config.dart';
import '../entities/entity_model.dart';
import 'worm_agents.dart';
import 'worm_behavior.dart';
import '../context/worm_game_context.dart';

/// Hành vi sâu người chơi: ăn lá → grow + mission + spawn; ăn dừa → buff độ cứng.
/// Va chạm: sâu <= độ cứng vật cản → trừ đuôi; sâu > độ cứng vật cản → phá.
class PlayerWormBehavior extends WormBehavior {
  @override
  void onEatEntity(WormAgent agent, String typeId, WormGameContext context) {
    agent.grow();
    if (typeId == ProjectType.preyLeaf.typeId) {
      context.addMissionLeaves(1);
      context.spawnPrey();
    } else if (typeId == ProjectType.preyCoconut.typeId) {
      final duration = BuffConfig.durationSecondsFor(ProjectType.preyCoconut.typeId);
      if (duration > 0) {
        agent.addItemEffect(ProjectType.preyCoconut.typeId, context.gameTime + duration);
      }
    }
  }

  @override
  HitResult onHitEntity(
    WormAgent agent,
    ProjectType projectType,
    int entityHardness,
    int wormHardness,
    WormGameContext context,
  ) {
    if (wormHardness <= entityHardness) {
      return HitResult.loseSegment;
    }
    return HitResult.destroyAndStep;
  }

  @override
  void onEatBuff(WormAgent agent, String buffId, double duration, WormGameContext context) {
    agent.addItemEffect(buffId, context.gameTime + duration);
  }
}
