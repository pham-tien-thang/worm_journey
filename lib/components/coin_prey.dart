import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Đồng xu: mồi có hiệu ứng lật theo trục dọc (trái → phải), không xoay như bánh xe.
class CoinPrey extends PositionComponent {
  CoinPrey({
    required this.segmentSize,
    required this.icon,
    Vector2? position,
    this.withSpawnEffect = false,
    this.iconScale = 1.0,
    this.rotateSpeed = 5.0,
  }) : super(
         position: position ?? Vector2.zero(),
         size: Vector2.all(segmentSize),
         anchor: Anchor.center,
       );

  final double segmentSize;
  final String icon;
  final bool withSpawnEffect;
  final double iconScale;

  /// Tốc độ lật (radian/giây). Dương = lật từ trái qua phải.
  final double rotateSpeed;

  double _angle = 0;
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
    add(RectangleHitbox(collisionType: CollisionType.passive, isSolid: false));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _angle += rotateSpeed * dt;
    if (_angle > math.pi * 2) _angle -= math.pi * 2;
  }

  void _layoutIcon() {
    final center = Offset(size.x / 2, size.y / 2);
    final fontSize = size.x * 0.9 * iconScale;
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
    final center = Offset(size.x / 2, size.y / 2);
    // Lật theo trục dọc (Y): scale X từ 1 → 0 → 1 tạo hiệu ứng đồng xu lật trái qua phải.
    final flipScaleX = (1 + math.cos(_angle)) * 0.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(flipScaleX, 1.0);
    canvas.translate(-center.dx, -center.dy);

    _iconPainter.paint(canvas, _iconOffset);

    canvas.restore();
  }
}
