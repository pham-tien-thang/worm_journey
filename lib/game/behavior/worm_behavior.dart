import '../../components/prey.dart' show PreyType;
import '../managers/obstacle_manager.dart';
import 'worm_agents.dart';
import '../context/worm_game_context.dart';

/// Kết quả xử lý khi sâu đâm chướng ngại: trừ đốt, phá rồi bước, hoặc không làm gì.
enum HitObstacleResult {
  loseSegment,
  destroyAndStep,
  none,
}

/// Hành vi sâu: ăn mồi, va chướng ngại, ăn buff (và sau này chiêu thức) xử lý khác nhau theo loại.
/// Game gọi [onEatPrey], [onHitObstacle], [onEatBuff]; mỗi loại worm (player, bot, hệ thống) implement khác.
abstract class WormBehavior {
  /// Sâu vừa ăn mồi [type]. Context cung cấp spawnPrey, addMissionLeaves, gameTime...
  void onEatPrey(WormAgent agent, PreyType type, WormGameContext context);

  /// Sâu sắp đâm chướng ngại [obstacleType]. Trả về cách xử lý: trừ đốt, phá rồi bước, hoặc none.
  /// [behavior] là ObstacleBehavior của chướng đó (buffIdToDestroy, loseSegmentIfNotDestroyed).
  HitObstacleResult onHitObstacle(
    WormAgent agent,
    ObstacleType obstacleType,
    ObstacleBehavior behavior,
    WormGameContext context,
  );

  /// Sâu vừa ăn buff [buffId], thời lượng [duration] (endTime = context.gameTime + duration).
  void onEatBuff(WormAgent agent, String buffId, double duration, WormGameContext context);
}
