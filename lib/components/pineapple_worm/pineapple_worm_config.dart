import 'package:flame/components.dart';

import '../worm/worm_body_config.dart';
import '../worm/worm_config.dart';
import '../worm/worm_direction.dart';
import '../worm/worm_head_config.dart';
import '../worm/worm_tail_config.dart';

class PineappleWormHeadConfig extends WormHeadConfig {
  PineappleWormHeadConfig()
    : super(
        assetVertical:
            'component/worm/pineapple_worm/pink_worm_head_vertical.png',
        assetHorizontal:
            'component/worm/pineapple_worm/pink_worm_head_horizontal.png',
        assetBack: 'component/worm/pineapple_worm/pink_worm_head_back.png',
        assetCry: 'component/worm/pineapple_worm/pink_worm_head_cry.png',
        assetHelmetVertical:
            'component/worm/pineapple_worm/helmet/pink_worm_helmet_vertical.png',
        assetHelmetHorizontal:
            'component/worm/pineapple_worm/helmet/pink_worm_helmet_horizontal.png',
        assetHelmetBack:
            'component/worm/pineapple_worm/helmet/pink_worm_helmet_back.png',
        assetHelmetCry:
            'component/worm/pineapple_worm/helmet/pink_worm_helmet_cry.png',
        imageScale: 1.32,
        antennaOffsetHorizontal: 0.18,
        antennaOffsetUp: 0.1,
        antennaOffsetDown: 0.18,
      );
}

class PineappleWormBodyConfig extends WormBodyConfig {
  PineappleWormBodyConfig()
    : super(
        assetVertical:
            'component/worm/pineapple_worm/pink_worm_body_vertical.png',
        assetHorizontal:
            'component/worm/pineapple_worm/pink_warm_body_horizonal.png',
        imageScale: 1.2,
      );
}

class PineappleWormTailConfig extends WormTailConfig {
  PineappleWormTailConfig() : super(bodyConfig: PineappleWormBodyConfig());
}

class PineappleWormConfig extends WormConfig {
  PineappleWormConfig({
    double segmentSize = 28.0,
    double moveInterval = 0.28,
    int initialLength = 10,
    int? maxLength,
    int? gridRows,
    List<Vector2>? initialGridPositions,
    WormDirection? initialDirection,
  }) : super(
         headConfig: PineappleWormHeadConfig(),
         bodyConfig: PineappleWormBodyConfig(),
         tailConfig: PineappleWormTailConfig(),
         segmentSize: segmentSize,
         moveInterval: moveInterval,
         initialLength: initialLength,
         maxLength: maxLength,
         gridRows: gridRows,
         initialGridPositions: initialGridPositions,
         initialDirection: initialDirection,
       );
}
