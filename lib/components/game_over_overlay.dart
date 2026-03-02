import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Overlay khi game over: nền mờ + chữ "Game Over" và "Chạm để chơi lại".
class GameOverOverlay extends PositionComponent {
  GameOverOverlay({required Vector2 size})
      : super(
          position: Vector2.zero(),
          size: size,
          priority: 100,
        );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xCC000000),
    );

    const title = 'Game Over';
    const subtitle = 'Chạm để chơi lại';

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(
        centerX - titlePainter.width / 2,
        centerY - 40,
      ),
    );

    final subPainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(
      canvas,
      Offset(
        centerX - subPainter.width / 2,
        centerY + 10,
      ),
    );
  }
}
