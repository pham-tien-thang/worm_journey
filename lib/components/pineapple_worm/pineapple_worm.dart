import 'package:flame/components.dart';

import '../../entities/entities.dart';
import '../pink_worm/pink_worm.dart';
import 'pineapple_worm_config.dart';

class PineappleWorm extends PinkWorm {
  PineappleWorm({
    PineappleWormConfig? config,
    WormInfo? info,
    Vector2? position,
    int? gridRowsOverride,
    WormStats? stats,
  }) : super(
         config: config ?? PineappleWormConfig(),
         info: info,
         stats: stats ?? WormStats(baseHardness: 25),
         position: position,
         gridRowsOverride: gridRowsOverride,
       );
}
