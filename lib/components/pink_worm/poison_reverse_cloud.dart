import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../worm/worm.dart';

/// Poisoned reverse effect: three toxic puffs pulse one by one around the head.
class PoisonReverseCloudComponent extends PositionComponent {
  PoisonReverseCloudComponent({required this.segmentSize, super.priority});

  final double segmentSize;
  double _elapsed = 0;
  static const double _pulseSeconds = 0.78;
  static const double _nextDotDelaySeconds = 0.04;
  final Paint _paint =
      Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  final Paint _rimPaint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

  @override
  void update(double dt) {
    super.update(dt);
    final worm = parent;
    if (worm is! Worm || !worm.isPoisonedReverse) return;
    position.setFrom(worm.headLocalPosition);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    final worm = parent;
    if (worm is! Worm || !worm.isPoisonedReverse) return;

    final slotSeconds = _pulseSeconds + _nextDotDelaySeconds;
    final cycleSeconds = slotSeconds * 3;
    final cycleTime = _elapsed % cycleSeconds;
    final activeIndex = (cycleTime / slotSeconds).floor().clamp(0, 2);
    final localTime = cycleTime - activeIndex * slotSeconds;
    if (localTime > _pulseSeconds) return;

    final t = (localTime / _pulseSeconds).clamp(0.0, 1.0);
    final eased = 1 - pow(1 - t, 2).toDouble();
    final headRadius = segmentSize * 0.5;
    final centerRadius = headRadius * 0.92;
    final halfSide = centerRadius * 0.8660254038;
    final center = switch (activeIndex) {
      0 => Offset(0, -centerRadius),
      1 => Offset(halfSide, centerRadius * 0.5),
      _ => Offset(-halfSide, centerRadius * 0.5),
    };
    final radius = segmentSize * (0.11 + eased * 0.125);
    final alpha = (1 - t) * 0.76;

    _paint.color = const Color(0xFF7EFF46).withValues(alpha: alpha);
    _rimPaint.color = const Color(0xFF1E8D31).withValues(alpha: alpha * 0.78);
    canvas.drawCircle(center, radius, _paint);
    canvas.drawCircle(center, radius * (0.72 + eased * 0.2), _rimPaint);
  }
}
