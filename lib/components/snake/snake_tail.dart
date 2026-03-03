import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';
import 'snake_direction.dart';
import 'snake_body_segment.dart';

/// Đốt đuôi: dùng ảnh thân (vertical/horizontal), tỉ lệ như thân, vẽ thêm chấm để phân biệt đuôi.
/// Hitbox passive, isSolid — logic va chạm đầu-đuôi xử lý trong game.
class SnakeTail extends PositionComponent {
  SnakeTail({
    required this.direction,
    required double segmentSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
          priority: 9, // vẽ trên thân, không bị che
        );

  SnakeDirection direction;

  /// Hướng chấm đuôi (lerp từ từ về [direction]).
  Vector2 _dotDirection = Vector2(1, 0);

  static const double _dotLerpSpeed = 8.0;

  Sprite? _spriteVertical;
  Sprite? _spriteHorizontal;

  void setDirection(SnakeDirection value) {
    direction = value;
  }

  Vector2 _directionToVector(SnakeDirection d) {
    switch (d) {
      case SnakeDirection.left:
        return Vector2(-1, 0);
      case SnakeDirection.right:
        return Vector2(1, 0);
      case SnakeDirection.up:
        return Vector2(0, -1);
      case SnakeDirection.down:
        return Vector2(0, 1);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _directionToVector(direction);
    final t = (1.0 - (_dotLerpSpeed * dt).clamp(0.0, 1.0));
    final next = _dotDirection * t + target * (1 - t);
    if (next.length2 < 0.0001) {
      _dotDirection.setFrom(target);
    } else {
      _dotDirection.setFrom(next.normalized());
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _dotDirection = _directionToVector(direction);
    add(RectangleHitbox(
      collisionType: CollisionType.passive,
      isSolid: true,
    ));

    final game = findParent<FlameGame>();
    if (game == null) return;
    _spriteVertical = await Sprite.load(
      SnakeBodyAssets.vertical,
      images: game.images,
    );
    _spriteHorizontal = await Sprite.load(
      SnakeBodyAssets.horizontal,
      images: game.images,
    );
  }

  @override
  void render(Canvas canvas) {
    final sprite = _currentSprite;
    if (sprite == null) return;

    final center = Vector2(size.x / 2, size.y / 2);
    final cx = center.x;
    final cy = center.y;

    canvas.save();
    final bool flipX = direction == SnakeDirection.left;
    final bool flipY = direction == SnakeDirection.up;
    if (flipX || flipY) {
      canvas.translate(cx, cy);
      if (flipX) canvas.scale(-1.0, 1.0);
      if (flipY) canvas.scale(1.0, -1.0);
      canvas.translate(-cx, -cy);
    }
    final drawSize = size * SnakeBodySegment.bodyImageScale;
    sprite.render(
      canvas,
      position: center,
      size: drawSize,
      anchor: Anchor.center,
    );
    canvas.restore();

    // Hai chấm đuôi: vị trí dùng _dotDirection (lerp từ từ khi đổi hướng)
    final step = size.x * 0.22;
    final startOffset = size.x * 0.55;
    final ux = _dotDirection.x;
    final uy = _dotDirection.y;
    final dotRadius = size.x * 0.12;
    final fillPaint = Paint()..color = GameConfig.snakePink;

    for (var i = 0; i < 2; i++) {
      final d = startOffset + step * i;
      final dx = center.x + ux * d;
      final dy = center.y + uy * d;
      canvas.drawCircle(Offset(dx, dy), dotRadius, fillPaint);
    }
  }

  Sprite? get _currentSprite {
    final isVertical = direction == SnakeDirection.up ||
        direction == SnakeDirection.down;
    return isVertical ? _spriteVertical : _spriteHorizontal;
  }
}
