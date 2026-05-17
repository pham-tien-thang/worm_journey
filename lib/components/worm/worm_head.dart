import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

import 'worm.dart';
import 'worm_direction.dart';
import 'worm_head_config.dart';

/// Đầu sâu (class cha): vẽ theo [WormHeadConfig]. Assets và thông số truyền lúc khởi tạo.
class WormHead extends PositionComponent {
  WormHead({
    required this.config,
    required this.direction,
    required double segmentSize,
    Vector2? position,
  })  : _segmentSize = segmentSize,
        super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
          priority: 10,
        );

  final WormHeadConfig config;
  WormDirection direction;

  final double _segmentSize;

  bool _showCryFace = false;
  void setShowCryFace(bool value) => _showCryFace = value;

  bool _useHelmet = false;
  void setUseHelmet(bool value) => _useHelmet = value;

  Sprite? _spriteVertical;
  Sprite? _spriteHorizontal;
  Sprite? _spriteBack;
  Sprite? _spriteCry;
  Sprite? _helmetVertical;
  Sprite? _helmetHorizontal;
  Sprite? _helmetBack;
  Sprite? _helmetCry;

  @override
  void update(double dt) {
    super.update(dt);
    priority = _showCryFace ? 10 : (direction == WormDirection.up ? -1 : 10);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.active, isSolid: false));

    final game = findParent<FlameGame>();
    if (game == null) return;
    _spriteVertical = await Sprite.load(config.assetVertical, images: game.images);
    _spriteHorizontal = await Sprite.load(config.assetHorizontal, images: game.images);
    _spriteBack = await Sprite.load(config.assetBack, images: game.images);
    _spriteCry = await Sprite.load(config.assetCry, images: game.images);

    if (config.hasHelmetAssets) {
      _helmetVertical = await Sprite.load(config.assetHelmetVertical!, images: game.images);
      _helmetHorizontal = await Sprite.load(config.assetHelmetHorizontal!, images: game.images);
      _helmetBack = await Sprite.load(config.assetHelmetBack!, images: game.images);
      _helmetCry = await Sprite.load(config.assetHelmetCry!, images: game.images);
    }
  }

  @override
  void render(Canvas canvas) {
    // Nhấp nháy khi đợi ready: Worm bật/tắt [isBlinkVisible], đầu không vẽ khi ẩn.
    if (findParent<Worm>()?.isBlinkVisible == false) return;
    final sprite = currentSprite;
    if (sprite == null) return;

    final center = Vector2(size.x / 2, size.y / 2);
    final cx = center.x;
    final cy = center.y;

    canvas.save();
    final bool flipX = direction == WormDirection.left;
    final bool isBackSprite = sprite == _spriteBack || sprite == _helmetBack;
    final bool flipY = !_showCryFace && direction == WormDirection.up && !isBackSprite;
    if (flipX || flipY) {
      canvas.translate(cx, cy);
      if (flipX) canvas.scale(-1.0, 1.0);
      if (flipY) canvas.scale(1.0, -1.0);
      canvas.translate(-cx, -cy);
    }
    final drawSize = size * config.imageScale;
    Vector2 drawCenter = center;
    switch (direction) {
      case WormDirection.left:
      case WormDirection.right:
        drawCenter = center + Vector2(0, -size.y * config.antennaOffsetHorizontal);
        break;
      case WormDirection.up:
        drawCenter = center + Vector2(0, size.y * config.antennaOffsetUp);
        break;
      case WormDirection.down:
        drawCenter = center + Vector2(0, -size.y * config.antennaOffsetDown);
        break;
    }
    sprite.render(canvas, position: drawCenter, size: drawSize, anchor: Anchor.center);
    canvas.restore();
  }

  /// Override nếu cần logic chọn sprite khác (vd. không hiện cry khi đi lên).
  Sprite? get currentSprite {
    final useHelmet = _useHelmet && _helmetVertical != null;
    if (useHelmet) {
      if (_showCryFace && _helmetCry != null && direction != WormDirection.up) return _helmetCry;
      if (direction == WormDirection.up) return _helmetBack;
      if (direction == WormDirection.down) return _helmetVertical;
      return _helmetHorizontal;
    }
    if (_showCryFace && _spriteCry != null && direction != WormDirection.up) return _spriteCry;
    if (direction == WormDirection.up) return _spriteBack;
    if (direction == WormDirection.down) return _spriteVertical;
    return _spriteHorizontal;
  }
}
