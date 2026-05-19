import 'package:flame/components.dart';

import '../../entities/entities.dart';
import '../pink_worm/pink_worm.dart';
import 'green_boss_worm_config.dart';

class GreenBossWorm extends PinkWorm {
  GreenBossWorm({
    GreenBossWormConfig? config,
    WormInfo? info,
    Vector2? position,
    int? gridRowsOverride,
    WormStats? stats,
  }) : super(
         config: config ?? GreenBossWormConfig(),
         info: info,
         position: position,
         gridRowsOverride: gridRowsOverride,
         stats:
             stats ??
             WormStats(
               moveInterval: (config ?? GreenBossWormConfig()).moveInterval,
               baseHardness: 30,
             ),
       );

  @override
  double get speedMoveIntervalScale => 0.9;
}
