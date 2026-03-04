import '../entities/entity_model.dart';
import 'worm_agents.dart';
import '../context/worm_game_context.dart';

/// Kết quả xử lý va chạm với vật cản.
enum HitResult {
  loseSegment,
  destroyAndStep,
  none,
}

/// Hành vi sâu: ăn entity, ăn buff, va chạm vật cản. Game gọi [onHitEntity] khi đâm vào entity chặn.
abstract class WormBehavior {
  void onEatEntity(WormAgent agent, String typeId, WormGameContext context);

  /// Sâu đâm vào vật cản [projectType]. [entityHardness], [wormHardness] để behavior quyết định trừ đuôi hay phá.
  HitResult onHitEntity(
    WormAgent agent,
    ProjectType projectType,
    int entityHardness,
    int wormHardness,
    WormGameContext context,
  );

  void onEatBuff(WormAgent agent, String buffId, double duration, WormGameContext context);
}
