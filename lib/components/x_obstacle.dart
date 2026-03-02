import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Chướng ngại vật: ô có bia mộ 🪦, để lại khi rắn mất đuôi. Đâm vào = trừ 1 đốt.
class XObstacle extends PositionComponent {
  XObstacle({
    required double segmentSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  static const String _emoji = '🪦';

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final fontSize = size.x * 0.9;

    final painter = TextPainter(
      text: TextSpan(
        text: _emoji,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Apple Color Emoji',
          fontFamilyFallback: const ['Noto Color Emoji', 'Segoe UI Emoji'],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    painter.layout(minWidth: 0, maxWidth: size.x);
    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
  }
}
