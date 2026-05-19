import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HeartBurstEffect extends PositionComponent {
  HeartBurstEffect({required Vector2 position, required double segmentSize})
    : _segmentSize = segmentSize,
      super(
        position: position,
        size: Vector2.all(segmentSize * 4.2),
        anchor: Anchor.center,
        priority: 30,
      );

  static const double duration = 1.2;
  static final Path _unitHeartPath = _buildUnitHeartPath();
  final double _segmentSize;
  final Paint _mainPaint = Paint();
  final Paint _smallPaint = Paint();
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    final fade = 1.0 - Curves.easeIn.transform(t);
    final alpha = (fade * 220).round();
    final centerX = size.x / 2;
    final centerY = size.y / 2 - _segmentSize * 0.18;
    final mainScale = _segmentSize * (0.42 + eased * 0.62);
    _mainPaint.color = const Color(0xFFE53935).withAlpha(alpha);
    _drawHeart(canvas, centerX, centerY, mainScale, _mainPaint);

    _smallPaint.color = const Color(
      0xFFFF8A80,
    ).withAlpha((alpha * 0.58).round());
    _drawHeart(
      canvas,
      centerX - _segmentSize * 0.86 * eased,
      centerY - _segmentSize * 0.96 * eased,
      _segmentSize * (0.16 + eased * 0.18),
      _smallPaint,
    );
    _drawHeart(
      canvas,
      centerX + _segmentSize * 0.92 * eased,
      centerY - _segmentSize * 0.72 * eased,
      _segmentSize * (0.14 + eased * 0.16),
      _smallPaint,
    );
    _drawHeart(
      canvas,
      centerX + _segmentSize * 0.18 * eased,
      centerY - _segmentSize * 1.18 * eased,
      _segmentSize * (0.12 + eased * 0.14),
      _smallPaint,
    );
  }

  static Path _buildUnitHeartPath() {
    final path = Path();
    for (var i = 0; i <= 48; i++) {
      final a = (math.pi * 2 * i) / 48;
      final x = 16 * math.pow(math.sin(a), 3).toDouble();
      final y =
          -(13 * math.cos(a) -
              5 * math.cos(2 * a) -
              2 * math.cos(3 * a) -
              math.cos(4 * a));
      final px = x / 18;
      final py = y / 18;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  void _drawHeart(
    Canvas canvas,
    double centerX,
    double centerY,
    double scale,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(scale);
    canvas.drawPath(_unitHeartPath, paint);
    canvas.restore();
  }
}
