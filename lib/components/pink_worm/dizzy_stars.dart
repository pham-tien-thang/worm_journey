import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../worm/worm.dart';

/// Sao vàng nhỏ xoay theo hình elip phía trên đầu khi có effect dizzy.
/// Khi còn 1 giây: nhấp nháy vàng + trắng (fill và stroke). Khi remove dizzy thì không vẽ.
class DizzyStarsComponent extends PositionComponent {
  DizzyStarsComponent({
    required this.segmentSize,
    super.priority,
  });

  final double segmentSize;

  static const int _starCount = 5;
  static const double _ellipseARatio = 0.5;
  static const double _ellipseBRatio = 0.28;
  static const double _ellipseOffsetYRatio = -0.42;
  static const double _rotateSpeed = 2.5;
  static const double _starRadiusRatio = 0.14;
  static const double _blinkWhenSecondsLeft = 1.0;
  /// Cùng tốc độ nhấp nháy với radar magnet — rất nhanh.
  static const double _blinkInterval = 0.08;

  double _angle = 0;

  double? _dizzyTimeLeft(Worm worm) {
    if (worm.gameTime == null) return null;
    for (final e in worm.itemEffects) {
      if (e.itemId == ItemType.dizzy.effectTypeId && e.endTime != null) {
        return e.endTime! - worm.gameTime!;
      }
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worm = parent;
    if (worm is! Worm) return;
    if (!worm.hasItemEffect(ItemType.dizzy.effectTypeId)) return;

    position.setFrom(worm.headLocalPosition);
    _angle += dt * _rotateSpeed;
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color fill, Color stroke) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.4;
      final a = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    final strokeWidth = (radius * 0.4).clamp(1.5, 3.0);
    canvas.drawPath(path, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
  }

  @override
  void render(Canvas canvas) {
    final worm = parent;
    if (worm is! Worm || !worm.hasItemEffect(ItemType.dizzy.effectTypeId)) return;

    final timeLeft = _dizzyTimeLeft(worm);
    final isBlinkZone = timeLeft != null && timeLeft > 0 && timeLeft <= _blinkWhenSecondsLeft;
    final showWhite = isBlinkZone && worm.gameTime != null && ((worm.gameTime! / _blinkInterval).floor() % 2 == 1);
    final fillColor = showWhite ? Colors.white : Colors.yellow;
    final strokeColor = showWhite ? Colors.white : Colors.yellow;

    final a = segmentSize * _ellipseARatio;
    final b = segmentSize * _ellipseBRatio;
    final cy = segmentSize * _ellipseOffsetYRatio;
    final starR = segmentSize * _starRadiusRatio;

    for (var k = 0; k < _starCount; k++) {
      final t = _angle + k * (2 * math.pi / _starCount);
      final x = a * math.cos(t);
      final y = cy - b * math.sin(t);
      _drawStar(canvas, Offset(x, y), starR, fillColor, strokeColor);
    }
  }
}
