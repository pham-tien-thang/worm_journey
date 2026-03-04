import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

import 'worm.dart';
import 'worm_body_config.dart';
import 'worm_direction.dart';

/// Đốt thân sâu (class cha): vẽ theo [WormBodyConfig]. Assets và thông số truyền lúc khởi tạo.
class WormBodySegment extends PositionComponent {
  WormBodySegment({
    required this.config,
    required this.direction,
    required double segmentSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  final WormBodyConfig config;
  WormDirection direction;

  Sprite? _spriteVertical;
  Sprite? _spriteHorizontal;

  void setDirection(WormDirection value) {
    direction = value;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive, isSolid: true));

    final game = findParent<FlameGame>();
    if (game == null) return;
    _spriteVertical = await Sprite.load(config.assetVertical, images: game.images);
    _spriteHorizontal = await Sprite.load(config.assetHorizontal, images: game.images);
  }

  @override
  void render(Canvas canvas) {
    // Nhấp nháy khi đợi ready: Worm bật/tắt [isBlinkVisible], đốt thân không vẽ khi ẩn.
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
    final drawSize = size * config.imageScale;
    sprite.render(canvas, position: center, size: drawSize, anchor: Anchor.center);
    canvas.restore();
  }

  Sprite? get currentSprite {
    final isVertical = direction == WormDirection.up || direction == WormDirection.down;
    return isVertical ? _spriteVertical : _spriteHorizontal;
  }
}
