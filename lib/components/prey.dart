import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Mồi: vẽ [icon] (emoji). Hitbox passive — logic ăn xử lý trong game.
class Prey extends PositionComponent {
  Prey({
    required this.segmentSize,
    required this.icon,
    Vector2? position,
    this.withSpawnEffect = false,
    this.iconScale = 1.0,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  final double segmentSize;
  final String icon;
  final bool withSpawnEffect;
  /// Scale chữ/icon (vd. lá cờ 1.25 để to hơn xíu).
  final double iconScale;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (withSpawnEffect) {
      scale = Vector2.zero();
      add(ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.15),
      ));
    }
    add(RectangleHitbox(
      collisionType: CollisionType.passive,
      isSolid: false,
    ));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final fontSize = size.x * 0.9 * iconScale;

    final painter = TextPainter(
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
    );
    painter.layout(minWidth: 0, maxWidth: size.x);
    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
  }
}
