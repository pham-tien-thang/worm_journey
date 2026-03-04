import '../worm/worm_body_config.dart';
import '../worm/worm_config.dart';
import '../worm/worm_head_config.dart';
import '../worm/worm_tail_config.dart';

/// Cấu hình pink worm: chỉ khởi tạo game object với các thông số (assets, scale, ...).
class PinkWormHeadConfig extends WormHeadConfig {
  PinkWormHeadConfig()
      : super(
          assetVertical: 'component/worm/pink_worm/pink_worm_head_vertical.png',
          assetHorizontal: 'component/worm/pink_worm/pink_worm_head_horizontal.png',
          assetBack: 'component/worm/pink_worm/pink_worm_head_back.png',
          assetCry: 'component/worm/pink_worm/pink_worm_head_cry.png',
          assetHelmetVertical: 'component/worm/pink_worm/helmet/pink_worm_helmet_vertical.png',
          assetHelmetHorizontal: 'component/worm/pink_worm/helmet/pink_worm_helmet_horizontal.png',
          assetHelmetBack: 'component/worm/pink_worm/helmet/pink_worm_helmet_back.png',
          assetHelmetCry: 'component/worm/pink_worm/helmet/pink_worm_helmet_cry.png',
          imageScale: 1.32,
          antennaOffsetHorizontal: 0.18,
          antennaOffsetUp: 0.1,
          antennaOffsetDown: 0.18,
        );
}

class PinkWormBodyConfig extends WormBodyConfig {
  PinkWormBodyConfig()
      : super(
          assetVertical: 'component/worm/pink_worm/pink_worm_body_vertical.png',
          assetHorizontal: 'component/worm/pink_worm/pink_warm_body_horizonal.png',
          imageScale: 1.2,
        );
}

class PinkWormTailConfig extends WormTailConfig {
  PinkWormTailConfig() : super(bodyConfig: PinkWormBodyConfig());
}

/// Config pink worm: head + body + tail assets và thông số.
class PinkWormConfig extends WormConfig {
  PinkWormConfig({
    double segmentSize = 28.0,
    double moveInterval = 0.28,
    int initialLength = 10,
    int? gridRows,
  }) : super(
          headConfig: PinkWormHeadConfig(),
          bodyConfig: PinkWormBodyConfig(),
          tailConfig: PinkWormTailConfig(),
          segmentSize: segmentSize,
          moveInterval: moveInterval,
          initialLength: initialLength,
          gridRows: gridRows,
        );
}
