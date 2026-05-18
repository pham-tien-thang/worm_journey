import 'package:flame/components.dart';

import '../../entities/entities.dart';
import '../worm/worm.dart';
import 'pineapple_worm_config.dart';

class PineappleWorm extends Worm {
  PineappleWorm({
    PineappleWormConfig? config,
    WormInfo? info,
    Vector2? position,
    int? gridRowsOverride,
    WormStats? stats,
  }) : super(
         config: config ?? PineappleWormConfig(),
         info: info,
         stats: stats ?? WormStats(baseHardness: 2),
         position: position,
         gridRowsOverride: gridRowsOverride,
       );
}
