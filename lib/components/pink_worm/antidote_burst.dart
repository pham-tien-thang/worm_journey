import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'pink_worm.dart';

/// Tia sáng xanh lá toả từ vòng 1 ô khi dùng antidote; sau khi tạo ra các tia ngắn dần rồi mất.
class AntidoteBurstComponent extends PositionComponent {
  AntidoteBurstComponent({
    required this.segmentSize,
    super.priority,
  });

  final double segmentSize;

  static const int _rayCount = 16;
  static const double burstDuration = 0.36;
  static const double _innerRadiusTiles = 1.0;
  static const double _maxRayLengthRatio = 1.9;

  @override
  void update(double dt) {
    super.update(dt);
    final worm = parent;
    if (worm is PinkWorm) {
      position.setFrom(worm.headLocalPosition);
    }
  }

  @override
  void render(Canvas canvas) {
    final worm = parent;
    if (worm is! PinkWorm) return;

    final remaining = worm.antidoteBurstRemaining;
    if (remaining <= 0) return;

    final t = 1.0 - (remaining / burstDuration);
    if (t <= 0) return;

    final innerR = segmentSize * _innerRadiusTiles;
    final maxExpansion = segmentSize * _maxRayLengthRatio;
    final outerR = innerR + maxExpansion;
    final startR = innerR + maxExpansion * t;
    final alpha = (0.85 * (1.0 - t)).clamp(0.0, 0.85);
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: alpha)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < _rayCount; i++) {
      final angle = i * (2 * math.pi / _rayCount);
      final start = Offset(startR * math.cos(angle), startR * math.sin(angle));
      final end = Offset(outerR * math.cos(angle), outerR * math.sin(angle));
      canvas.drawLine(start, end, paint);
    }
  }
}
