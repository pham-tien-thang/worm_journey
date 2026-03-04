import 'worm_body_config.dart';
import 'worm_head_config.dart';
import 'worm_tail_config.dart';

import '../../config/config.dart';

/// Cấu hình sâu (class tổng): mọi thông số, asset head/body/tail setup lúc khởi tạo.
class WormConfig {
  WormConfig({
    required this.headConfig,
    required this.bodyConfig,
    required this.tailConfig,
    this.segmentSize = 28.0,
    this.moveInterval = 0.28,
    this.initialLength = 10,
    this.gridRows,
  });

  final WormHeadConfig headConfig;
  final WormBodyConfig bodyConfig;
  final WormTailConfig tailConfig;
  final double segmentSize;
  final double moveInterval;
  final int initialLength;
  /// Null thì Worm dùng GameConfig.gridRows.
  final int? gridRows;
}
