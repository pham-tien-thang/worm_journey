import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

import 'snake_direction.dart';

/// Đường dẫn ảnh thân sâu trong assets.
class SnakeBodyAssets {
  static const String vertical =
      'component/worm/pink_worm/pink_worm_body_vertical.png';
  /// Đi ngang (trái/phải) dùng ảnh này.
  static const String horizontal =
      'component/worm/pink_worm/pink_warm_body_horizonal.png';
}

/// Đốt thân rắn: ảnh từ assets — dọc dùng vertical, ngang dùng horizontal, lật như head.
/// Hitbox passive, isSolid — logic va chạm đầu-thân xử lý trong game.
class SnakeBodySegment extends PositionComponent {
  /// Scale ảnh thân (> 1 = to hơn ô, va chạm vẫn theo size component).
  static const double bodyImageScale = 1.2;

  SnakeBodySegment({
    required this.direction,
    required double segmentSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  SnakeDirection direction;

  Sprite? _spriteVertical;
  Sprite? _spriteHorizontal;

  void setDirection(SnakeDirection value) {
    direction = value;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
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
    final drawSize = size * bodyImageScale;
    sprite.render(
      canvas,
      position: center,
      size: drawSize,
      anchor: Anchor.center,
    );
    canvas.restore();
  }

  Sprite? get _currentSprite {
    // Đi ngang (trái/phải) -> pink_warm_body_horizonal; đi dọc (lên/xuống) -> vertical.
    final isVertical = direction == SnakeDirection.up ||
        direction == SnakeDirection.down;
    return isVertical ? _spriteVertical : _spriteHorizontal;
  }
}
