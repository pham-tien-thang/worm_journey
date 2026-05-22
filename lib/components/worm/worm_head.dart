import 'dart:math' as math;
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
  }) : _segmentSize = segmentSize,
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
  double _helmetEffectTime = 0;
  final Paint _helmetArcGlowPaint =
      Paint()
        ..color = const Color(0x55FF6A00)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
  final Paint _helmetArcPaint =
      Paint()
        ..color = const Color(0xFFFFB000)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
  final Paint _helmetBladeGlowPaint =
      Paint()
        ..color = const Color(0x77FF7A00)
        ..style = PaintingStyle.fill;
  final Paint _helmetBladePaint =
      Paint()
        ..color = const Color(0xFFFFD23A)
        ..style = PaintingStyle.fill;
  final Paint _helmetBladeCorePaint =
      Paint()
        ..color = const Color(0xFFFFFFC4)
        ..style = PaintingStyle.fill;
  final Paint _helmetArcCorePaint =
      Paint()
        ..color = const Color(0xFFFFF4A8)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
  final Paint _helmetSparkPaint =
      Paint()
        ..color = const Color(0xFFFFF2A0)
        ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    priority = _showCryFace ? 10 : (direction == WormDirection.up ? -1 : 10);
    if (_useHelmet && config.drawHelmetEffect) {
      _helmetEffectTime += dt;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.active, isSolid: false));

    final game = findParent<FlameGame>();
    if (game == null) return;
    _spriteVertical = await Sprite.load(
      config.assetVertical,
      images: game.images,
    );
    _spriteHorizontal = await Sprite.load(
      config.assetHorizontal,
      images: game.images,
    );
    _spriteBack = await Sprite.load(config.assetBack, images: game.images);
    _spriteCry = await Sprite.load(config.assetCry, images: game.images);

    if (config.hasHelmetAssets) {
      _helmetVertical = await Sprite.load(
        config.assetHelmetVertical!,
        images: game.images,
      );
      _helmetHorizontal = await Sprite.load(
        config.assetHelmetHorizontal!,
        images: game.images,
      );
      _helmetBack = await Sprite.load(
        config.assetHelmetBack!,
        images: game.images,
      );
      _helmetCry = await Sprite.load(
        config.assetHelmetCry!,
        images: game.images,
      );
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

    final circleColor = config.circleColor;
    if (circleColor != null) {
      final radius = size.x * 0.42;
      final fillPaint = Paint()..color = circleColor;
      final borderPaint =
          Paint()
            ..color = config.circleBorderColor ?? const Color(0xFFFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.x * 0.08;
      canvas.drawCircle(Offset(cx, cy), radius, fillPaint);
      canvas.drawCircle(Offset(cx, cy), radius, borderPaint);
      return;
    }

    canvas.save();
    final bool flipX = direction == WormDirection.left;
    final bool isBackSprite = sprite == _spriteBack || sprite == _helmetBack;
    final bool flipY =
        !_showCryFace && direction == WormDirection.up && !isBackSprite;
    final downRotation =
        direction == WormDirection.down ? config.downRotationRadians : 0.0;
    final downSkew = direction == WormDirection.down ? config.downSkewX : 0.0;
    if (flipX || flipY || downRotation != 0 || downSkew != 0) {
      canvas.translate(cx, cy);
      if (flipX) canvas.scale(-1.0, 1.0);
      if (flipY) canvas.scale(1.0, -1.0);
      if (downRotation != 0) canvas.rotate(downRotation);
      if (downSkew != 0) canvas.skew(downSkew, 0);
      canvas.translate(-cx, -cy);
    }
    final drawSize = size * config.imageScale;
    Vector2 drawCenter = center;
    switch (direction) {
      case WormDirection.left:
      case WormDirection.right:
        drawCenter =
            center + Vector2(0, -size.y * config.antennaOffsetHorizontal);
        break;
      case WormDirection.up:
        drawCenter = center + Vector2(0, size.y * config.antennaOffsetUp);
        break;
      case WormDirection.down:
        drawCenter = center + Vector2(0, -size.y * config.antennaOffsetDown);
        break;
    }
    sprite.render(
      canvas,
      position: drawCenter,
      size: drawSize,
      anchor: Anchor.center,
    );
    canvas.restore();

    if (_useHelmet && config.drawHelmetEffect) {
      _renderHelmetEffect(canvas, cx, cy);
    }
  }

  void _renderHelmetEffect(Canvas canvas, double cx, double cy) {
    final phase = _helmetEffectTime * 4.4 % 1.0;
    final pulse = 0.5 + 0.5 * math.sin(_helmetEffectTime * 13.0);
    final arcCenterOffset = size.x * 0.34;
    final baseWidth = size.x * (1.18 + pulse * 0.08);
    final baseHeight = size.y * (1.02 + pulse * 0.06);
    final angle = _helmetEffectAngle;

    _helmetArcGlowPaint.strokeWidth = size.x * (0.09 + pulse * 0.02);
    _helmetArcPaint.strokeWidth = size.x * 0.072;
    _helmetArcCorePaint.strokeWidth = size.x * 0.028;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(arcCenterOffset, 0);

    final outerRect = Rect.fromCenter(
      center: Offset.zero,
      width: baseWidth,
      height: baseHeight,
    );
    final innerRect = Rect.fromCenter(
      center: Offset.zero,
      width: baseWidth * 0.78,
      height: baseHeight * 0.76,
    );
    const startAngle = -1.18;
    const sweepAngle = 2.36;
    canvas.drawArc(
      outerRect,
      startAngle,
      sweepAngle,
      false,
      _helmetArcGlowPaint,
    );
    _drawEnergyArcSegments(canvas, outerRect, startAngle, _helmetArcPaint);
    _drawEnergyArcSegments(
      canvas,
      innerRect,
      startAngle + 0.16 + phase * 0.2,
      _helmetArcCorePaint,
    );
    canvas.drawArc(
      outerRect,
      startAngle + 0.2 + phase * 1.05,
      0.32,
      false,
      _helmetArcCorePaint,
    );

    _drawEnergyBlades(canvas, baseWidth, baseHeight, phase);

    final sparkRadius = size.x * 0.035;
    final sparkLead = size.x * (0.62 + phase * 0.18);
    canvas.drawCircle(
      Offset(sparkLead, size.y * (phase - 0.5) * 0.12),
      sparkRadius,
      _helmetSparkPaint,
    );
    canvas.drawCircle(
      Offset(sparkLead * 0.82, -size.y * (0.22 + pulse * 0.08)),
      sparkRadius * 0.7,
      _helmetSparkPaint,
    );
    canvas.drawCircle(
      Offset(sparkLead * 0.78, size.y * (0.24 - pulse * 0.05)),
      sparkRadius * 0.58,
      _helmetSparkPaint,
    );
    canvas.restore();
  }

  void _drawEnergyArcSegments(
    Canvas canvas,
    Rect rect,
    double startAngle,
    Paint paint,
  ) {
    canvas.drawArc(rect, startAngle, 0.56, false, paint);
    canvas.drawArc(rect, startAngle + 0.78, 0.42, false, paint);
    canvas.drawArc(rect, startAngle + 1.38, 0.64, false, paint);
  }

  void _drawEnergyBlades(
    Canvas canvas,
    double width,
    double height,
    double phase,
  ) {
    const bladeAngles = [-0.88, -0.44, 0.0, 0.44, 0.88];
    final halfW = width * 0.5;
    final halfH = height * 0.5;
    for (var i = 0; i < bladeAngles.length; i++) {
      final a = bladeAngles[i];
      final flicker = 0.55 + 0.45 * math.sin((phase + i * 0.23) * math.pi * 2);
      final baseX = math.cos(a) * halfW;
      final baseY = math.sin(a) * halfH;
      final outwardX = math.cos(a);
      final outwardY = math.sin(a);
      final tangentX = -math.sin(a);
      final tangentY = math.cos(a);
      final bladeLength = size.x * (0.22 + flicker * 0.1);
      final halfBase = size.x * (i == 2 ? 0.09 : 0.065);
      final tip = Offset(
        baseX + outwardX * bladeLength,
        baseY + outwardY * bladeLength,
      );
      final left = Offset(
        baseX + tangentX * halfBase,
        baseY + tangentY * halfBase,
      );
      final right = Offset(
        baseX - tangentX * halfBase,
        baseY - tangentY * halfBase,
      );
      final glowTip = Offset(
        baseX + outwardX * (bladeLength + size.x * 0.08),
        baseY + outwardY * (bladeLength + size.x * 0.08),
      );
      final glowLeft = Offset(
        baseX + tangentX * halfBase * 1.55,
        baseY + tangentY * halfBase * 1.55,
      );
      final glowRight = Offset(
        baseX - tangentX * halfBase * 1.55,
        baseY - tangentY * halfBase * 1.55,
      );
      final glowPath =
          Path()
            ..moveTo(glowTip.dx, glowTip.dy)
            ..lineTo(glowLeft.dx, glowLeft.dy)
            ..lineTo(glowRight.dx, glowRight.dy)
            ..close();
      final bladePath =
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
      final coreTip = Offset(
        baseX + outwardX * bladeLength * 0.72,
        baseY + outwardY * bladeLength * 0.72,
      );
      final coreLeft = Offset(
        baseX + tangentX * halfBase * 0.35,
        baseY + tangentY * halfBase * 0.35,
      );
      final coreRight = Offset(
        baseX - tangentX * halfBase * 0.35,
        baseY - tangentY * halfBase * 0.35,
      );
      final corePath =
          Path()
            ..moveTo(coreTip.dx, coreTip.dy)
            ..lineTo(coreLeft.dx, coreLeft.dy)
            ..lineTo(coreRight.dx, coreRight.dy)
            ..close();
      canvas.drawPath(glowPath, _helmetBladeGlowPaint);
      canvas.drawPath(bladePath, _helmetBladePaint);
      canvas.drawPath(corePath, _helmetBladeCorePaint);
    }
  }

  double get _helmetEffectAngle {
    switch (direction) {
      case WormDirection.right:
        return 0;
      case WormDirection.down:
        return 1.5708;
      case WormDirection.left:
        return 3.1416;
      case WormDirection.up:
        return -1.5708;
    }
  }

  /// Override nếu cần logic chọn sprite khác (vd. không hiện cry khi đi lên).
  Sprite? get currentSprite {
    final useHelmet = _useHelmet && _helmetVertical != null;
    if (useHelmet) {
      if (_showCryFace && _helmetCry != null && direction != WormDirection.up)
        return _helmetCry;
      if (direction == WormDirection.up) return _helmetBack;
      if (direction == WormDirection.down) return _helmetVertical;
      return _helmetHorizontal;
    }
    if (_showCryFace && _spriteCry != null && direction != WormDirection.up)
      return _spriteCry;
    if (direction == WormDirection.up) return _spriteBack;
    if (direction == WormDirection.down) return _spriteVertical;
    return _spriteHorizontal;
  }
}
