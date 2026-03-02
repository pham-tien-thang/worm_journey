import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game.dart';
import '../components/snake/snake_direction.dart';

/// Control tích hợp: vừa 4 nút (bấm) vừa joystick (giữ + kéo). Bấm hoặc di đều đổi hướng.
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
  SnakeDirection? _lastDirection;

  double get _deadZone => widget.baseRadius * widget.deadZoneRatio;
  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  SnakeDirection _directionFromAngle(double angleDeg) {
    if (angleDeg >= -45 && angleDeg < 45) return SnakeDirection.right;
    if (angleDeg >= 45 && angleDeg < 135) return SnakeDirection.down;
    if (angleDeg >= 135 || angleDeg < -135) return SnakeDirection.left;
    return SnakeDirection.up;
  }

  SnakeDirection? _directionFromOffset(Offset o) {
    if (o.distance < _deadZone) return null;
    final angleDeg = math.atan2(o.dy, o.dx) * 180 / math.pi;
    return _directionFromAngle(angleDeg);
  }

  SnakeDirection _directionFromPosition(Offset localPosition) {
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
      final dir = _directionFromOffset(o);
      if (dir != null && dir != _lastDirection) {
        _lastDirection = dir;
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
    _lastDirection = null;
    setState(() => _stickOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final stickCenter = center + stickOffset;
    canvas.drawCircle(
      stickCenter,
      stickRadius,
      Paint()
        ..color = Colors.grey.shade700
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      stickCenter,
      stickRadius,
      Paint()
        ..color = Colors.grey.shade900
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter old) =>
      old.stickOffset != stickOffset;
}
