import 'package:flame/components.dart';

import '../worm/worm_body_config.dart';
import '../worm/worm_config.dart';
import '../worm/worm_direction.dart';
import '../worm/worm_head_config.dart';
import '../worm/worm_tail_config.dart';

class GreenBossWormHeadConfig extends WormHeadConfig {
  GreenBossWormHeadConfig()
    : super(
        assetVertical: 'component/worm/boss_green_worm/green_head_all.png',
        assetHorizontal: 'component/worm/boss_green_worm/green_head_all.png',
        assetBack: 'component/worm/boss_green_worm/green_head_back.png',
        assetCry: 'component/worm/boss_green_worm/green_head_all.png',
        imageScale: 1.5,
        antennaOffsetHorizontal: 0.18,
        antennaOffsetUp: 0.1,
        antennaOffsetDown: 0.18,
        downRotationRadians: -0.12,
        downSkewX: -0.08,
      );
}

class GreenBossWormBodyConfig extends WormBodyConfig {
  GreenBossWormBodyConfig()
    : super(
        assetVertical: 'component/worm/boss_green_worm/green_body_all.png',
        assetHorizontal: 'component/worm/boss_green_worm/green_body_all.png',
        imageScale: 1.2,
        reverseUpFlipY: true,
      );
}

class GreenBossWormTailConfig extends WormTailConfig {
  GreenBossWormTailConfig() : super(bodyConfig: GreenBossWormBodyConfig());
}

class GreenBossWormConfig extends WormConfig {
  GreenBossWormConfig({
    double segmentSize = 28.0,
    double moveInterval = 0.28,
    int initialLength = 8,
    int? maxLength,
    int? gridRows,
    List<Vector2>? initialGridPositions,
    WormDirection? initialDirection,
  }) : super(
         headConfig: GreenBossWormHeadConfig(),
         bodyConfig: GreenBossWormBodyConfig(),
         tailConfig: GreenBossWormTailConfig(),
         segmentSize: segmentSize,
         moveInterval: moveInterval,
         initialLength: initialLength,
         maxLength: maxLength ?? initialLength,
         gridRows: gridRows,
         initialGridPositions: initialGridPositions,
         initialDirection: initialDirection,
       );
}
