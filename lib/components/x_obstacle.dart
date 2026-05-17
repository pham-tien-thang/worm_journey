import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Vật cản: vẽ [icon] (emoji). Hitbox isSolid — va chạm so độ cứng trong game.
class XObstacle extends PositionComponent {
  XObstacle({
    required double segmentSize,
    required this.icon,
    Vector2? position,
    this.withSpawnEffect = false,
  }) : super(
         position: position ?? Vector2.zero(),
         size: Vector2.all(segmentSize),
         anchor: Anchor.center,
       );

  final String icon;
  final bool withSpawnEffect;

  late TextPainter _iconPainter;
  Offset _iconOffset = Offset.zero;
  double _layoutWidth = -1;
  double _layoutHeight = -1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layoutIcon();
    if (withSpawnEffect) {
      scale = Vector2.zero();
      add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.15)));
    }
    add(RectangleHitbox(collisionType: CollisionType.passive, isSolid: true));
  }

  void _layoutIcon() {
    final center = Offset(size.x / 2, size.y / 2);
    final fontSize = size.x * 0.9;
    _iconPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Apple Color Emoji',
          fontFamilyFallback: const ['Noto Color Emoji', 'Segoe UI Emoji'],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(minWidth: 0, maxWidth: size.x);
    _iconOffset = Offset(
      center.dx - _iconPainter.width / 2,
      center.dy - _iconPainter.height / 2,
    );
    _layoutWidth = size.x;
    _layoutHeight = size.y;
  }

  @override
  void render(Canvas canvas) {
    if (_layoutWidth != size.x || _layoutHeight != size.y) {
      _layoutIcon();
    }
    _iconPainter.paint(canvas, _iconOffset);
  }
}
