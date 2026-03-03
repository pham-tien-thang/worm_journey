import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';
import 'snake_direction.dart';

/// Đốt đuôi: hình tam giác màu hồng.
/// [direction] là hướng từ thân tới đuôi (đuôi nhọn hướng ngược lại).
/// Hitbox passive, isSolid (chặn) — logic va chạm đầu-đuôi xử lý trong game.
class SnakeTail extends PositionComponent {
  SnakeTail({
    required this.direction,
    required double segmentSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  SnakeDirection direction;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      collisionType: CollisionType.passive,
      isSolid: true,
    ));
  }

  @override
  void render(Canvas canvas) {
    final center = size / 2;
    final half = size.x / 2;

    final path = Path();
    switch (direction) {
      case SnakeDirection.up:
        path.moveTo(center.x, center.y - half);
        path.lineTo(center.x - half, center.y + half * 0.6);
        path.lineTo(center.x + half, center.y + half * 0.6);
        break;
      case SnakeDirection.down:
        path.moveTo(center.x, center.y + half);
        path.lineTo(center.x - half, center.y - half * 0.6);
        path.lineTo(center.x + half, center.y - half * 0.6);
        break;
      case SnakeDirection.left:
        path.moveTo(center.x - half, center.y);
        path.lineTo(center.x + half * 0.6, center.y - half);
        path.lineTo(center.x + half * 0.6, center.y + half);
        break;
      case SnakeDirection.right:
        path.moveTo(center.x + half, center.y);
        path.lineTo(center.x - half * 0.6, center.y - half);
        path.lineTo(center.x - half * 0.6, center.y + half);
        break;
    }
    path.close();
    canvas.drawPath(path, Paint()..color = GameConfig.snakePink);
    canvas.drawPath(
      path,
      Paint()
        ..color = GameConfig.snakePink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
