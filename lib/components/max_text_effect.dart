import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Hiệu ứng chữ "Max" khi ăn lá nhưng đã đạt độ dài tối đa: trắng, viền đen, bold, từ nhỏ tới to và mờ dần.
class MaxTextEffectComponent extends PositionComponent {
  MaxTextEffectComponent({
    required Vector2 position,
    required this.segmentSize,
    this.duration = 0.75,
  }) : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2(segmentSize * 2, segmentSize * 1.5),
          priority: 200,
        );

  final double segmentSize;
  final double duration;
  double _elapsed = 0;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final scale = 0.3 + t * 0.9;
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scale);
    canvas.translate(-size.x / 2, -size.y / 2);

    final baseFontSize = segmentSize * 0.7;
    const text = 'Max';

    TextStyle strokeStyle() => TextStyle(
      fontSize: baseFontSize,
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.black.withOpacity(opacity),
    );
    TextStyle fillStyle() => TextStyle(
      fontSize: baseFontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white.withOpacity(opacity),
    );

    final strokePainter = TextPainter(
      text: TextSpan(text: text, style: strokeStyle()),
      textDirection: TextDirection.ltr,
    );
    strokePainter.layout(minWidth: 0, maxWidth: size.x);
    final paintOffset = Offset(
      (size.x - strokePainter.width) / 2,
      (size.y - strokePainter.height) / 2,
    );
    strokePainter.paint(canvas, paintOffset);

    final fillPainter = TextPainter(
      text: TextSpan(text: text, style: fillStyle()),
      textDirection: TextDirection.ltr,
    );
    fillPainter.layout(minWidth: 0, maxWidth: size.x);
    fillPainter.paint(canvas, paintOffset);
    canvas.restore();
  }
}
