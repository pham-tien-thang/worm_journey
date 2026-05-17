import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';
import 'worm.dart';
import 'worm_direction.dart';
import 'worm_tail_config.dart';

/// Đuôi sâu (class cha): vẽ theo [WormTailConfig], dùng asset thân + chấm đuôi.
class WormTail extends PositionComponent {
  WormTail({
    required this.config,
    required this.direction,
    required double segmentSize,
    Vector2? position,
  })  : _segmentSize = segmentSize,
        super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
          priority: 9,
        );

  final WormTailConfig config;
  WormDirection direction;

  final double _segmentSize;
  Vector2 _dotDirection = Vector2(1, 0);

  Sprite? _spriteVertical;
  Sprite? _spriteHorizontal;

  void setDirection(WormDirection value) {
    direction = value;
  }

  Vector2 _directionToVector(WormDirection d) {
    switch (d) {
      case WormDirection.left:
        return Vector2(-1, 0);
      case WormDirection.right:
        return Vector2(1, 0);
      case WormDirection.up:
        return Vector2(0, -1);
      case WormDirection.down:
        return Vector2(0, 1);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _directionToVector(direction);
    final t = (1.0 - (config.dotLerpSpeed * dt).clamp(0.0, 1.0));
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
    add(RectangleHitbox(collisionType: CollisionType.passive, isSolid: true));

    final game = findParent<FlameGame>();
    if (game == null) return;
    final c = config.bodyConfig;
    _spriteVertical = await Sprite.load(c.assetVertical, images: game.images);
    _spriteHorizontal = await Sprite.load(c.assetHorizontal, images: game.images);
  }

  @override
  void render(Canvas canvas) {
    // Nhấp nháy khi đợi ready: Worm bật/tắt [isBlinkVisible], đuôi không vẽ khi ẩn.
    if (findParent<Worm>()?.isBlinkVisible == false) return;
    final sprite = currentSprite;
    if (sprite == null) return;

    final center = Vector2(size.x / 2, size.y / 2);
    final cx = center.x;
    final cy = center.y;

    canvas.save();
    final bool flipX = direction == WormDirection.left;
    final bool flipY = direction == WormDirection.up;
    if (flipX || flipY) {
      canvas.translate(cx, cy);
      if (flipX) canvas.scale(-1.0, 1.0);
      if (flipY) canvas.scale(1.0, -1.0);
      canvas.translate(-cx, -cy);
    }
    final drawSize = size * config.bodyConfig.imageScale;
    sprite.render(canvas, position: center, size: drawSize, anchor: Anchor.center);
    canvas.restore();

    final step = size.x * config.dotStepRatio;
    final startOffset = size.x * config.dotStartOffsetRatio;
    final ux = _dotDirection.x;
    final uy = _dotDirection.y;
    final dotRadius = size.x * config.dotRadiusRatio;
    final fillPaint = Paint()..color = GameConfig.snakePink;
    for (var i = 0; i < 2; i++) {
      final d = startOffset + step * i;
      final dx = center.x + ux * d;
      final dy = center.y + uy * d;
      canvas.drawCircle(Offset(dx, dy), dotRadius, fillPaint);
    }
  }

  Sprite? get currentSprite {
    final isVertical = direction == WormDirection.up || direction == WormDirection.down;
    return isVertical ? _spriteVertical : _spriteHorizontal;
  }
}
