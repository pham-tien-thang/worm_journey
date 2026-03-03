import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Loại mồi: lá (thường) hoặc dừa (đặc biệt, mỗi 10s).
enum PreyType {
  leaf,
  apple,
}

/// Con mồi: icon lá 🍃 hoặc dừa 🥥 (ký tự đặc biệt).
/// Hitbox passive, không chặn (trigger/xuyên) — logic ăn mồi xử lý trong game.
class Prey extends PositionComponent {
  Prey({
    required double segmentSize,
    required PreyType type,
    Vector2? position,
  })  : _type = type,
        _emoji = _emojiForType(type),
        super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(segmentSize),
          anchor: Anchor.center,
        );

  final PreyType _type;
  final String _emoji;

  static String _emojiForType(PreyType type) {
    switch (type) {
      case PreyType.leaf:
        return '🍃';
      case PreyType.apple:
        return '🥥';
    }
  }

  PreyType get type => _type;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      collisionType: CollisionType.passive,
      isSolid: false,
    ));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final fontSize = size.x * 0.9;

    final painter = TextPainter(
      text: TextSpan(
        text: _emoji,
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
