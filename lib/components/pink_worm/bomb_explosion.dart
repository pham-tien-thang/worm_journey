import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/buff/buff_config.dart';
import 'pink_worm.dart';

/// Hiệu ứng nổ từ đầu rắn khi dùng bom — lượn sóng, vân mây, đứt đoạn xen kẽ, toả tới [bombRadiusTiles] ô.
class BombExplosionComponent extends PositionComponent {
  BombExplosionComponent({
    required this.segmentSize,
    super.priority,
  });

  final double segmentSize;

  static const double explosionDuration = 0.52;
  static const int _ringCount = 3;
  static const int _arcCount = 10;
  static const double _gapRatio = 0.22;
  static const double _ringStrokeWidthRatio = 0.11;

  @override
  void update(double dt) {
    super.update(dt);
    final worm = parent;
    if (worm is PinkWorm) {
      position.setFrom(worm.headLocalPosition);
    }
  }

  double _wavyRadius(double baseR, double angle, int ring, double t) {
    final phase = ring * 1.2 + t * 2;
    return baseR * (1 +
        0.08 * math.sin(4 * angle + phase) +
        0.05 * math.sin(7 * angle + phase * 0.6));
  }

  @override
  void render(Canvas canvas) {
    final worm = parent;
    if (worm is! PinkWorm) return;

    final remaining = worm.bombExplosionRemaining;
    if (remaining <= 0) return;

    final t = 1.0 - (remaining / explosionDuration);
    if (t <= 0) return;

    final maxR = segmentSize * BuffConfig.bombRadiusTiles.toDouble();
    final center = Offset.zero;

    for (var ring = 0; ring < _ringCount; ring++) {
      final delay = ring * 0.12;
      final ringT = ((t - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (ringT <= 0) continue;
      final baseRadius = maxR * _easeOutCubic(ringT);
      final alpha = (0.9 * (1 - ringT)).clamp(0.0, 0.9);
      final hue = 8.0 + ring * 5;
      final paint = Paint()
        ..color = HSLColor.fromAHSL(alpha, hue, 0.9, 0.55).toColor()
        ..strokeWidth = segmentSize * _ringStrokeWidthRatio
        ..style = PaintingStyle.stroke;

      final step = 2 * math.pi / _arcCount;
      for (var i = 0; i < _arcCount; i++) {
        final startAngle = i * step;
        final endAngle = startAngle + step * (1 - _gapRatio);
        final steps = 8;
        final path = Path();
        for (var k = 0; k <= steps; k++) {
          final angle = startAngle + (endAngle - startAngle) * (k / steps);
          final r = _wavyRadius(baseRadius, angle, ring, t);
          final x = center.dx + r * math.cos(angle);
          final y = center.dy + r * math.sin(angle);
          if (k == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        canvas.drawPath(path, paint);
      }
    }

    final coreT = (t / 0.2).clamp(0.0, 1.0);
    final coreBaseR = segmentSize * 0.6 * coreT;
    final coreAlpha = 0.85 * (1 - coreT);
    if (coreAlpha > 0.01 && coreBaseR > 2) {
      final corePath = Path();
      const corePoints = 10;
      for (var i = 0; i <= corePoints; i++) {
        final angle = i * (2 * math.pi / corePoints);
        final r = coreBaseR * (1 + 0.1 * math.sin(5 * angle));
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) corePath.moveTo(x, y);
        else corePath.lineTo(x, y);
      }
      corePath.close();
      canvas.drawPath(
        corePath,
        Paint()
          ..color = Colors.deepOrange.withValues(alpha: coreAlpha)
          ..style = PaintingStyle.fill,
      );
    }
  }

  static double _easeOutCubic(double t) =>
      1.0 - math.pow(1.0 - t, 3);
}
