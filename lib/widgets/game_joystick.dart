import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game.dart';
import '../components/worm/worm_direction.dart';

/// Joystick: kéo đổi hướng, bấm vào từng vùng (có mũi tên) cũng đổi hướng.
class GameJoystick extends StatefulWidget {
  const GameJoystick({
    super.key,
    required this.game,
    this.size = 160,
    this.baseRadius = 64,
    this.stickRadius = 24,
    this.deadZoneRatio = 0.22,
    this.tapDragThreshold = 10,
  });

  final WormJourneyGame game;
  final double size;
  final double baseRadius;
  final double stickRadius;
  final double deadZoneRatio;
  final double tapDragThreshold;

  @override
  State<GameJoystick> createState() => _GameJoystickState();
}

class _GameJoystickState extends State<GameJoystick> {
  Offset _stickOffset = Offset.zero;
  Offset? _panStartPosition;
  bool _isDragging = false;

  double get _deadZone => widget.baseRadius * widget.deadZoneRatio;
  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  WormDirection _directionFromAngle(double angleDeg) {
    if (angleDeg >= -45 && angleDeg < 45) return WormDirection.right;
    if (angleDeg >= 45 && angleDeg < 135) return WormDirection.down;
    if (angleDeg >= 135 || angleDeg < -135) return WormDirection.left;
    return WormDirection.up;
  }

  WormDirection? _directionFromOffset(Offset o) {
    if (o.distance < _deadZone) return null;
    final angleDeg = math.atan2(o.dy, o.dx) * 180 / math.pi;
    return _directionFromAngle(angleDeg);
  }

  /// Ngưỡng kéo (px): khi vượt qua thì ưu tiên hướng theo vector kéo để tránh gửi nhầm hướng lúc mới bắt đầu kéo (vd. tay đặt trái, kéo sang phải thì phải ra right chứ không ra left).
  static const double _dragIntentThreshold = 24.0;

  WormDirection _directionFromPosition(Offset localPosition) {
    final o = localPosition - _center;
    final angleDeg = math.atan2(o.dy, o.dx) * 180 / math.pi;
    return _directionFromAngle(angleDeg);
  }

  Offset _clampOffset(Offset o) {
    final r = widget.baseRadius - widget.stickRadius;
    if (o.distance <= r) return o;
    return Offset.fromDirection(o.direction, r);
  }

  void _onPanStart(DragStartDetails details) {
    _panStartPosition = details.localPosition;
    _isDragging = false;
    _stickOffset = Offset.zero;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final start = _panStartPosition ?? details.localPosition;
    final current = details.localPosition;
    final delta = current - start;

    if (!_isDragging && delta.distance > widget.tapDragThreshold) {
      _isDragging = true;
    }

    if (_isDragging) {
      final o = _clampOffset(current - _center);
      setState(() => _stickOffset = o);
      WormDirection? dir = _directionFromOffset(o);
      // Khi kéo xa (qua vùng giữa): ưu tiên hướng theo vector kéo, tránh gửi hướng điểm bấm (vd. tay đặt trái kéo sang phải → right, không bị left).
      if (delta.distance >= _dragIntentThreshold) {
        final dragDir = _directionFromOffset(delta);
        if (dragDir != null && dragDir != dir) {
          dir = dragDir;
        }
      }
      if (dir != null) {
        widget.game.setDirection(dir);
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging && _panStartPosition != null) {
      final dir = _directionFromPosition(_panStartPosition!);
      if ((_panStartPosition! - _center).distance > _deadZone) {
        widget.game.setDirection(dir);
      }
    }
    _panStartPosition = null;
    _isDragging = false;
    setState(() => _stickOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [

          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _JoystickPainter(
                baseRadius: widget.baseRadius,
                stickRadius: widget.stickRadius,
                stickOffset: _stickOffset,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({
    required this.baseRadius,
    required this.stickRadius,
    required this.stickOffset,
  });

  final double baseRadius;
  final double stickRadius;
  final Offset stickOffset;

  /// Màu hồng chung cho nút / vòng tròn.
  static const Color _stickColor = Color(0xFFE91E8C);
  static const Color _stickStroke = Color(0xFFC2185B);
  /// Màu trắng nhạt cho vòng tròn to (bớt chói).
  static const Color _baseWhiteSoft = Color(0xFFF0E6EC);
  static const Color _baseHighlightSoft = Color(0x88FFFFFF);

  /// Vẽ hình tròn hồng bóng (gradient + vệt sáng) + tùy chọn viền.
  /// [baseStyle]: true = dùng cho vòng to: trắng nhạt, không viền.
  void _drawGlossyPinkCircle(Canvas canvas, Offset center, double radius,
      {double strokeWidth = 1.5, Color? strokeColor, bool baseStyle = false}) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final colors = baseStyle
        ? const [_baseWhiteSoft, Color(0xFFF8BBD9), _stickColor]
        : const [Color(0xFFFFFFFF), Color(0xFFF8BBD9), _stickColor];
    final highlightColors = baseStyle
        ? const [_baseHighlightSoft, Color(0x30FFFFFF), Color(0x00FFFFFF)]
        : const [Color(0xE8FFFFFF), Color(0x50FFFFFF), Color(0x00FFFFFF)];

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 1.2,
          colors: colors,
          stops: const [0.0, 0.35, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.fill,
    );
    if (!baseStyle && strokeWidth > 0) {
      final borderColor = strokeColor ?? _stickStroke;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
    final highlightCenter = center + Offset(-radius * 0.32, -radius * 0.32);
    final highlightRadius = radius * 0.38;
    canvas.drawCircle(
      highlightCenter,
      highlightRadius,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: highlightColors,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: highlightCenter, radius: highlightRadius))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Hình tròn tổng thể (base) — trắng nhạt, không viền
    _drawGlossyPinkCircle(canvas, center, baseRadius, baseStyle: true);

    // Bốn nút mũi tên — chỉ vẽ icon mũi tên trắng (không vòng tròn hồng)
    _drawArrow(canvas, center, 0, -1);
    _drawArrow(canvas, center, 0, 1);
    _drawArrow(canvas, center, -1, 0);
    _drawArrow(canvas, center, 1, 0);

    // Nút giữa (kéo di chuyển)
    final stickCenter = center + stickOffset;
    _drawGlossyPinkCircle(canvas, stickCenter, stickRadius);
  }

  static const double _arrowDist = 0.58;
  static const double _arrowSize = 10;

  void _drawArrow(Canvas canvas, Offset center, double dx, double dy) {
    final pos = center + Offset(dx * baseRadius * _arrowDist, dy * baseRadius * _arrowDist);
    final path = Path();
    final s = _arrowSize;
    if (dy != 0) {
      if (dy < 0) {
        path.moveTo(pos.dx, pos.dy - s);
        path.lineTo(pos.dx + s * 0.6, pos.dy + s * 0.5);
        path.lineTo(pos.dx, pos.dy + s * 0.2);
        path.lineTo(pos.dx - s * 0.6, pos.dy + s * 0.5);
      } else {
        path.moveTo(pos.dx, pos.dy + s);
        path.lineTo(pos.dx + s * 0.6, pos.dy - s * 0.5);
        path.lineTo(pos.dx, pos.dy - s * 0.2);
        path.lineTo(pos.dx - s * 0.6, pos.dy - s * 0.5);
      }
    } else {
      if (dx < 0) {
        path.moveTo(pos.dx - s, pos.dy);
        path.lineTo(pos.dx + s * 0.5, pos.dy - s * 0.6);
        path.lineTo(pos.dx + s * 0.2, pos.dy);
        path.lineTo(pos.dx + s * 0.5, pos.dy + s * 0.6);
      } else {
        path.moveTo(pos.dx + s, pos.dy);
        path.lineTo(pos.dx - s * 0.5, pos.dy - s * 0.6);
        path.lineTo(pos.dx - s * 0.2, pos.dy);
        path.lineTo(pos.dx - s * 0.5, pos.dy + s * 0.6);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter old) =>
      old.stickOffset != stickOffset;
}
