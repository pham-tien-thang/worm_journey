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
  static const String back =
      'component/worm/pink_worm/pink_worm_head_back.png';
  static const String cry =
      'component/worm/pink_worm/pink_worm_head_cry.png';
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
  static const double antennaOffsetUp = 0.1; // đi lên: dịch xuống vừa
  static const double antennaOffsetDown = 0.18; // đi xuống: dịch lên

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

  /// Mặt khóc (khi đâm chướng ngại, hiện 0.5s). Game gọi [setShowCryFace].
  bool _showCryFace = false;
  void setShowCryFace(bool value) => _showCryFace = value;

  Sprite? _spriteVertical;
  Sprite? _spriteHorizontal;
  Sprite? _spriteBack;
  Sprite? _spriteCry;

  @override
  void update(double dt) {
    super.update(dt);
    // Mặt khóc luôn vẽ trên cùng. Đi lên (không khóc): đầu vẽ dưới thân; các hướng khác: đầu trên thân.
    priority = _showCryFace ? 10 : (direction == SnakeDirection.up ? -1 : 10);
  }

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
    _spriteBack = await Sprite.load(
      SnakeHeadAssets.back,
      images: game.images,
    );
    _spriteCry = await Sprite.load(
      SnakeHeadAssets.cry,
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
    // Lật: trái = lật ngang; đi lên dùng ảnh back nên không lật dọc. Mặt khóc không lật dọc để luôn thấy rõ.
    final bool flipX = direction == SnakeDirection.left;
    final bool flipY = !_showCryFace && direction == SnakeDirection.up && sprite != _spriteBack;
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
        drawCenter = center + Vector2(0, size.y * antennaOffsetUp); // dịch xuống
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
    // Không dùng mặt khóc khi đi lên; các hướng khác thì hiện mặt khóc nếu đang bật.
    if (_showCryFace && _spriteCry != null && direction != SnakeDirection.up) return _spriteCry;
    if (direction == SnakeDirection.up) return _spriteBack;
    if (direction == SnakeDirection.down) return _spriteVertical;
    return _spriteHorizontal;
  }
}
