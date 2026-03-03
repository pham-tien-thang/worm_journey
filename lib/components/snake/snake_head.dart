import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

import 'snake_direction.dart';

/// Đường dẫn ảnh đầu sâu trong assets.
class SnakeHeadAssets {
  static const String vertical =
      'component/worm/pink_worm/pink_worm_head_vertical.png';
  static const String horizontal =
      'component/worm/pink_worm/pink_worm_head_horizontal.png';
}

/// Đầu rắn: ảnh từ assets — đi dọc dùng vertical, đi ngang dùng horizontal.
/// Evil mode (ăn dừa) vẫn dùng cùng ảnh, không đổi.
/// Hitbox active — tham gia phát hiện va chạm với mồi, chướng ngại, đuôi, thân.
/// Ảnh vẽ to hơn 1 chút (scale) để lấn ô bên cạnh nhưng va chạm vẫn theo 1 ô.
class SnakeHead extends PositionComponent {
  /// Scale ảnh đầu (> 1 = to hơn ô, va chạm vẫn theo size component).
  static const double headImageScale = 1.32;
  /// Dịch vẽ để râu lòi ra (tỉ lệ size.y).
  static const double antennaOffsetHorizontal = 0.18; // đi ngang: dịch lên
  static const double antennaOffsetUp = 0.28; // đi lên: dịch lên đáng kể
  static const double antennaOffsetDown = 0.14; // đi xuống: dịch lên

  SnakeHead({
    required this.direction,
    required double segmentSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
          priority: 10, // vẽ trên cùng, đè lên thân không bị che
        );

  SnakeDirection direction;

  Sprite? _spriteVertical;
  Sprite? _spriteHorizontal;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      collisionType: CollisionType.active,
      isSolid: false,
    ));

    final game = findParent<FlameGame>();
    if (game == null) return;
    _spriteVertical = await Sprite.load(
      SnakeHeadAssets.vertical,
      images: game.images,
    );
    _spriteHorizontal = await Sprite.load(
      SnakeHeadAssets.horizontal,
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
    // Lật quanh tâm: trái = lật ngang, lên = lật dọc (ảnh mặc định: phải = hướng phải, xuống = hướng xuống).
    final bool flipX = direction == SnakeDirection.left;
    final bool flipY = direction == SnakeDirection.up;
    if (flipX || flipY) {
      canvas.translate(cx, cy);
      if (flipX) canvas.scale(-1.0, 1.0);
      if (flipY) canvas.scale(1.0, -1.0);
      canvas.translate(-cx, -cy);
    }
    final drawSize = size * headImageScale;
    Vector2 drawCenter = center;
    switch (direction) {
      case SnakeDirection.left:
      case SnakeDirection.right:
        drawCenter = center + Vector2(0, -size.y * antennaOffsetHorizontal);
        break;
      case SnakeDirection.up:
        drawCenter = center + Vector2(0, -size.y * antennaOffsetUp); // dịch lên
        break;
      case SnakeDirection.down:
        drawCenter = center + Vector2(0, -size.y * antennaOffsetDown);
        break;
    }
    sprite.render(
      canvas,
      position: drawCenter,
      size: drawSize,
      anchor: Anchor.center,
    );
    canvas.restore();
  }

  Sprite? get _currentSprite {
    final isVertical = direction == SnakeDirection.up ||
        direction == SnakeDirection.down;
    return isVertical ? _spriteVertical : _spriteHorizontal;
  }
}
