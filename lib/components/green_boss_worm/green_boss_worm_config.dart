import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../pink_worm/pink_worm_config.dart';
import '../worm/worm_config.dart';
import '../worm/worm_direction.dart';
import '../worm/worm_head_config.dart';
import '../worm/worm_tail_config.dart';

class GreenBossWormHeadConfig extends WormHeadConfig {
  GreenBossWormHeadConfig()
    : super(
        assetVertical: 'component/worm/pink_worm/pink_worm_head_vertical.png',
        assetHorizontal:
            'component/worm/pink_worm/pink_worm_head_horizontal.png',
        assetBack: 'component/worm/pink_worm/pink_worm_head_back.png',
        assetCry: 'component/worm/pink_worm/pink_worm_head_cry.png',
        imageScale: 1.32,
        antennaOffsetHorizontal: 0.18,
        antennaOffsetUp: 0.1,
        antennaOffsetDown: 0.18,
        circleColor: const Color(0xFF2DCE89),
        circleBorderColor: const Color(0xFF0E6B3D),
      );
}

class GreenBossWormTailConfig extends WormTailConfig {
  GreenBossWormTailConfig()
    : super(
        bodyConfig: PinkWormBodyConfig(),
        circleColor: const Color(0xFF2DCE89),
        dotColor: const Color(0xFF0E6B3D),
      );
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
         bodyConfig: PinkWormBodyConfig(),
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
