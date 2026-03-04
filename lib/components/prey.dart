import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Mồi: vẽ [icon] (emoji). Hitbox passive — logic ăn xử lý trong game.
class Prey extends PositionComponent {
  Prey({
    required this.segmentSize,
    required this.icon,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  final double segmentSize;
  final String icon;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      collisionType: CollisionType.passive,
      isSolid: false,
    ));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final fontSize = size.x * 0.9;

    final painter = TextPainter(
      text: TextSpan(
        text: icon,
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
