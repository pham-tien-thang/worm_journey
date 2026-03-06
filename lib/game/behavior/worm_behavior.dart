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
  void onEatEntity(WormAgent agent, GameEntityView entity, WormGameContext context);

  /// Sâu đâm vào vật cản [entity]. [wormHardness] từ sâu; hardness lấy từ [entity.hardness].
  HitResult onHitEntity(
    WormAgent agent,
    GameEntityView entity,
    int wormHardness,
    WormGameContext context,
  );
}
