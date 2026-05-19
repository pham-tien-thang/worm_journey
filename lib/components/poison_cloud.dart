import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Animated poison cloud: event-driven map entity with cached paints.
class PoisonCloud extends PositionComponent {
  PoisonCloud({
    required double segmentSize,
    Vector2? position,
    this.withSpawnEffect = false,
  }) : _segmentSize = segmentSize,
       super(
         position: position ?? Vector2.zero(),
         size: Vector2.all(segmentSize),
         anchor: Anchor.center,
       );

  final double _segmentSize;
  final bool withSpawnEffect;
  double _phase = 0;

  final Paint _corePaint =
      Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _ringPaint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _sparkPaint =
      Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (withSpawnEffect) {
      scale = Vector2.zero();
      add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.18)));
    }
    add(RectangleHitbox(collisionType: CollisionType.passive, isSolid: false));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase = (_phase + dt * 1.8) % (pi * 2);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulse = (sin(_phase) + 1) * 0.5;
    final flicker = (sin(_phase * 4.7) + sin(_phase * 7.9 + 1.2)) * 0.5;
    final baseRadius = _segmentSize * (0.22 + pulse * 0.05 + flicker * 0.012);

    _corePaint.color = const Color(
      0xFF58E56E,
    ).withValues(alpha: 0.25 + pulse * 0.12);
    canvas.drawCircle(center, _segmentSize * (0.38 + pulse * 0.06), _corePaint);

    for (var i = 0; i < 9; i++) {
      final angle =
          _phase * (i.isEven ? 1.0 : -1.45) + i * pi * 2 / 9 + sin(_phase + i);
      final drift =
          _segmentSize *
          (0.08 + 0.08 * sin(_phase * (1.6 + i * 0.07) + i * 0.9).abs());
      final wobble =
          Offset(sin(_phase * 3.1 + i * 1.7), cos(_phase * 2.6 + i * 1.1)) *
          (_segmentSize * 0.025);
      final puffCenter =
          center + Offset(cos(angle), sin(angle)) * drift + wobble;
      final alpha = 0.2 + 0.22 * sin(_phase * 2.3 + i).abs();
      _corePaint.color = const Color(
        0xFF7CFF55,
      ).withValues(alpha: alpha.clamp(0.14, 0.38));
      canvas.drawCircle(
        puffCenter,
        baseRadius * (0.48 + 0.2 * sin(_phase * 2 + i).abs()),
        _corePaint,
      );
    }

    _ringPaint.color = const Color(
      0xFF1F9E3F,
    ).withValues(alpha: 0.28 + (1 - pulse) * 0.24);
    canvas.drawCircle(center, _segmentSize * (0.28 + pulse * 0.14), _ringPaint);
    canvas.drawCircle(
      center +
          Offset(sin(_phase * 1.9), cos(_phase * 2.2)) * _segmentSize * 0.03,
      _segmentSize * (0.17 + (1 - pulse) * 0.08),
      _ringPaint,
    );

    for (var i = 0; i < 12; i++) {
      final angle = -_phase * (1.2 + i * 0.05) + i * pi * 2 / 12;
      final distance =
          _segmentSize * (0.1 + 0.23 * sin(_phase * 1.4 + i * 0.7).abs());
      final alpha = 0.24 + 0.42 * sin(_phase * 5.0 + i).abs();
      _sparkPaint.color = const Color(0xFFC8FF72).withValues(alpha: alpha);
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * distance,
        _segmentSize * (0.018 + 0.026 * sin(_phase * 3 + i).abs()),
        _sparkPaint,
      );
    }
  }
}
