import '../../core/buff/buff_config.dart';
import '../../models/item_model.dart';
import '../entities/entity_model.dart';
import 'worm_agents.dart';
import 'worm_behavior.dart';
import '../context/worm_game_context.dart';

/// Hành vi sâu người chơi: ăn lá → grow + mission + spawn; ăn dừa → buff (effectTypeId từ entity).
/// Va chạm: sâu <= độ cứng vật cản → trừ đuôi; sâu > độ cứng vật cản → phá.
class PlayerWormBehavior extends WormBehavior {
  @override
  void onEatEntity(WormAgent agent, GameEntityView entity, WormGameContext context) {
    if (entity.projectType == ProjectType.preyLeaf) {
      agent.grow();
      agent.worm.playSwallowPreyEffect();
      context.addMissionLeaves(1);
      // Chỉ spawn thêm lá khi vừa ăn lá cuối cùng (sau khi ăn, số lá trên map = 0).
      if (context.preyLeafCountOnMap == 0) {
        context.spawnPrey();
      }
    } else {
      final effectId = entity.effectTypeId;
      if (effectId != null) {
        if (effectId == ItemType.antidote.effectTypeId) {
          agent.removeItemEffects(BuffConfig.removableByAntidoteEffectIds);
          agent.removeItemEffects([ItemType.antidote.effectTypeId]);
        } else if (effectId == ItemType.magnet.effectTypeId) {
          final duration = BuffConfig.durationSecondsFor(effectId);
          if (duration > 0) {
            agent.addItemEffect(effectId, context.gameTime + duration);
          }
          context.triggerMagnetPull();
        } else if (effectId == ItemType.seed.effectTypeId) {
          context.spawnPrey();
          context.spawnPrey();
        } else {
          final duration = BuffConfig.durationSecondsFor(effectId);
          if (duration > 0) {
            agent.addItemEffect(effectId, context.gameTime + duration);
          }
        }
      }
    }
  }

  @override
  HitResult onHitEntity(
    WormAgent agent,
    GameEntityView entity,
    int wormHardness,
    WormGameContext context,
  ) {
    if (wormHardness <= entity.hardness) {
      return HitResult.loseSegment;
    }
    return HitResult.destroyAndStep;
  }
}
