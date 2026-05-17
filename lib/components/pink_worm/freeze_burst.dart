import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'pink_worm.dart';

/// Khi dùng/ăn freeze: emoji ❄️ từ đầu rắn to ra 3 ô rồi biến mất. Mờ, stack cao hơn worm.
class FreezeBurstComponent extends PositionComponent {
  FreezeBurstComponent({
    required this.segmentSize,
    super.priority,
  });

  final double segmentSize;

  static const double burstDuration = 0.5;
  static const double _maxSizeTiles = 3.0;
  static const double _baseAlpha = 0.55;

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

    final remaining = worm.freezeBurstRemaining;
    if (remaining <= 0) return;

    final t = 1.0 - (remaining / burstDuration);
    if (t <= 0) return;

    final size = segmentSize * _maxSizeTiles * t;
    final alpha = (_baseAlpha * (1 - t * 0.7)).clamp(0.0, _baseAlpha);

    final text = '❄️';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size * 0.85,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(-painter.width / 2, -painter.height / 2);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
