import 'worm_body_config.dart';

/// Cấu hình đuôi sâu: dùng asset thân (vertical/horizontal), scale, tốc độ lerp chấm đuôi.
class WormTailConfig {
  const WormTailConfig({
    required this.bodyConfig,
    this.dotLerpSpeed = 8.0,
    this.dotStepRatio = 0.22,
    this.dotStartOffsetRatio = 0.55,
    this.dotRadiusRatio = 0.12,
  });

  /// Đuôi dùng chung asset với thân.
  final WormBodyConfig bodyConfig;
  final double dotLerpSpeed;
  final double dotStepRatio;
  final double dotStartOffsetRatio;
  final double dotRadiusRatio;
}
