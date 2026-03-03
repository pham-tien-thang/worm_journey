import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';

/// Đốt thân rắn: hình tròn màu hồng, bên trong có hình tròn nhỏ màu cam.
/// Hitbox passive, isSolid (chặn) — logic va chạm đầu-thân xử lý trong game.
class SnakeBodySegment extends PositionComponent {
  SnakeBodySegment({
    required double segmentSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

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
    final r = size.x / 2;
    final center = size / 2;

    // Vòng tròn hồng
    canvas.drawCircle(
      center.toOffset(),
      r,
      Paint()..color = GameConfig.snakePink,
    );
    canvas.drawCircle(
      center.toOffset(),
      r - 1,
      Paint()
        ..color = GameConfig.snakePink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Tròn nhỏ màu cam bên trong
    canvas.drawCircle(
      center.toOffset(),
      r * 0.4,
      Paint()..color = GameConfig.snakeInnerOrange,
    );
  }
}
