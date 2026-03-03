import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'snake_direction.dart';

/// Đầu rắn: ký tự đặc biệt (mặt cười). Ăn táo thì đổi thành mũ/ nón bảo hiểm.
/// Hitbox active — tham gia phát hiện va chạm với mồi, chướng ngại, đuôi, thân.
class SnakeHead extends PositionComponent {
  SnakeHead({
    required this.direction,
    required double segmentSize,
    String emoji = '🙂',
    Vector2? position,
  })  : _emoji = emoji,
        super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  SnakeDirection direction;
  String _emoji;

  set emoji(String value) => _emoji = value;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      collisionType: CollisionType.active,
      isSolid: false,
    ));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final fontSize = size.x * 0.85;

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
