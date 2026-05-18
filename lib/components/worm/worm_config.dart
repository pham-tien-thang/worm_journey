import 'package:flame/components.dart';

import 'worm_body_config.dart';
import 'worm_head_config.dart';
import 'worm_tail_config.dart';
import 'worm_direction.dart';

/// Cấu hình sâu (class tổng): mọi thông số, asset head/body/tail setup lúc khởi tạo.
class WormConfig {
  WormConfig({
    required this.headConfig,
    required this.bodyConfig,
    required this.tailConfig,
    this.segmentSize = 28.0,
    this.moveInterval = 0.28,
    this.initialLength = 10,
    this.maxLength,
    this.gridRows,
    this.initialGridPositions,
    this.initialDirection,
  });

  final WormHeadConfig headConfig;
  final WormBodyConfig bodyConfig;
  final WormTailConfig tailConfig;
  final double segmentSize;
  final double moveInterval;
  final int initialLength;
  /// Độ dài tối đa (số đốt). Null = không giới hạn.
  final int? maxLength;
  /// Null thì Worm dùng GameConfig.gridRows.
  final int? gridRows;
  /// Nếu có: dùng làm vị trí grid ban đầu (đầu → đuôi), bỏ qua tính toán từ initialLength. Dùng khi hồi sinh tại "vị trí an toàn".
  final List<Vector2>? initialGridPositions;
  /// Hướng đầu khi dùng [initialGridPositions].
  final WormDirection? initialDirection;
}
