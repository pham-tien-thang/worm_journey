import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bánh xe may mắn: hình quạt (nửa đường tròn) 5 ô với x1.5, x2, x3.
/// [size]: width = đường kính cung, height = bán kính R (chỉ từ tâm tới cạnh, không x2).
/// Vòng đứng im; marker ở tâm (bottom center) quay qua lại.
class LuckyWheel extends StatefulWidget {
  final Size size;
  /// 5 màu cho 5 ô (trái → phải). Null = dùng mặc định [green, orange, red, orange, green].
  final List<Color>? segmentColors;
  /// Scale kích thước các ô (1.0 = bình thường).
  final double segmentScale;
  /// Màu chữ multiplier (x1.5, x2, x3). Null = vàng có viền.
  final Color? textColor;
  /// Scale cỡ chữ.
  final double textScale;
  /// Màu marker mũi tên. Null = vàng/cam.
  final Color? markerColor;
  /// Tốc độ quay (radian/giây) — quay càng nhanh khi giá trị lớn.
  final double rotationSpeed;

  static const List<Color> _defaultSegmentColors = [
    Color(0xFF4CAF50), // green
    Color(0xFFFF9800), // orange
    Color(0xFFE53935), // red
    Color(0xFFFF9800), // orange
    Color(0xFF4CAF50), // green
  ];

  static const List<String> _labels = ['x1.5', 'x2', 'x3', 'x2', 'x1.5'];
  /// Multiplier cho từng ô: xanh x1.5, cam x2, đỏ x3, cam x2, xanh x1.5.
  static const List<double> segmentMultipliers = [1.5, 2.0, 3.0, 2.0, 1.5];

  /// Nhãn hiển thị cho ô (x1.5, x2, x3).
  static String labelForSegmentIndex(int index) {
    if (index < 0 || index >= _labels.length) return 'x1.5';
    return _labels[index];
  }

  /// Góc kim (radian) → index ô 0..4. Dùng để tính claim = total * segmentMultipliers[index].
  static int segmentIndexFromAngle(double pointerAngle) {
    const segmentCount = 5;
    const sweepSegment = -math.pi / segmentCount;
    final pointingAngle = -math.pi / 2 + pointerAngle;
    var i = (pointingAngle / sweepSegment).floor();
    if (i < 0) i = 0;
    if (i >= segmentCount) i = segmentCount - 1;
    return i;
  }

  /// Gọi mỗi khi góc kim thay đổi (để overlay cập nhật claim amount).
  final ValueChanged<double>? onPointerAngle;
  /// Khi true: dừng kim (dùng lúc đang chạy hiệu ứng claim).
  final bool pausePointer;

  const LuckyWheel({
    super.key,
    this.size = const Size(280, 140),
    this.segmentColors,
    this.segmentScale = 1.0,
    this.textColor,
    this.textScale = 1.0,
    this.markerColor,
    this.rotationSpeed = 2.5,
    this.onPointerAngle,
    this.pausePointer = false,
  });

  @override
  State<LuckyWheel> createState() => _LuckyWheelState();
}

class _LuckyWheelState extends State<LuckyWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final durationMs = (800 / widget.rotationSpeed).round().clamp(200, 1200);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _animation = Tween<double>(begin: -math.pi / 2, end: math.pi / 2)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    if (widget.onPointerAngle != null) {
      _animation.addListener(_onAnimationTick);
    }
    if (!widget.pausePointer) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LuckyWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pausePointer && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.pausePointer && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  void _onAnimationTick() {
    widget.onPointerAngle?.call(_animation.value);
  }

  @override
  void dispose() {
    if (widget.onPointerAngle != null) {
      _animation.removeListener(_onAnimationTick);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segmentColors =
        widget.segmentColors ?? LuckyWheel._defaultSegmentColors;
    final textColor = widget.textColor ?? const Color(0xFFFFEB3B);
    final markerColor = widget.markerColor ?? Colors.black;

    final w = widget.size.width;
    final h = widget.size.height;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => CustomPaint(
                size: widget.size,
                painter: _WheelPainter(
                  segmentColors: segmentColors.length >= 5
                      ? segmentColors
                      : LuckyWheel._defaultSegmentColors,
                  segmentScale: widget.segmentScale,
                  textColor: textColor,
                  textScale: widget.textScale,
                  labels: LuckyWheel._labels,
                  pointerAngle: _animation.value,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => Transform.rotate(
                  angle: _animation.value,
                  alignment: Alignment.bottomCenter,
                  child: CustomPaint(
                    size: const Size(14, 40),
                    painter: _MarkerArrowPainter(color: markerColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.segmentColors,
    required this.segmentScale,
    required this.textColor,
    required this.textScale,
    required this.labels,
    required this.pointerAngle,
  });

  final List<Color> segmentColors;
  final double segmentScale;
  final Color textColor;
  final double textScale;
  final List<String> labels;
  final double pointerAngle;

  static const _highlightScale = 1.06;
  static const _darkenAmount = 0.25;

  int _segmentAtPointer() {
    const segmentCount = 5;
    const sweepSegment = -math.pi / segmentCount;
    final pointingAngle = -math.pi / 2 + pointerAngle;
    final t = pointingAngle / sweepSegment;
    var i = t.floor();
    if (i < 0) i = 0;
    if (i >= segmentCount) i = segmentCount - 1;
    return i;
  }

  Color _darken(Color c, double amount) {
    return Color.lerp(c, Colors.black, amount.clamp(0.0, 1.0)) ?? c;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final R = size.height * segmentScale;
    final activeIndex = _segmentAtPointer();

    canvas.save();
    canvas.translate(cx, R);

    const startAngle = 0.0;
    const sweepTotal = -math.pi;
    const segmentCount = 5;
    final sweepSegment = sweepTotal / segmentCount;
    final R_inner = R * 0.35;
    final outerRect = Rect.fromCircle(center: Offset.zero, radius: R);
    final innerRect = Rect.fromCircle(center: Offset.zero, radius: R_inner);

    for (var i = 0; i < segmentCount; i++) {
      var color = i < segmentColors.length ? segmentColors[i] : Colors.grey;
      final isActive = i == activeIndex;
      if (isActive) color = _darken(color, _darkenAmount);

      final a1 = startAngle + i * sweepSegment;
      final a2 = startAngle + (i + 1) * sweepSegment;

      final path = Path()
        ..moveTo(R * math.cos(a1), R * math.sin(a1))
        ..arcTo(outerRect, a1, sweepSegment, false)
        ..lineTo(
          R_inner * math.cos(a2),
          R_inner * math.sin(a2),
        )
        ..arcTo(innerRect, a2, -sweepSegment, false)
        ..close();

      if (isActive) {
        canvas.save();
        final midAngle = startAngle + (i + 0.5) * sweepSegment;
        final scaleCenterX = (R + R_inner) / 2 * math.cos(midAngle);
        final scaleCenterY = (R + R_inner) / 2 * math.sin(midAngle);
        canvas.translate(scaleCenterX, scaleCenterY);
        canvas.scale(_highlightScale, _highlightScale);
        canvas.translate(-scaleCenterX, -scaleCenterY);
      }
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      if (isActive) canvas.restore();
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    for (var i = 0; i < segmentCount && i < labels.length; i++) {
      final midAngle = startAngle + (i + 0.5) * sweepSegment;
      final dist = R * 0.68;
      final tx = dist * math.cos(midAngle);
      final ty = dist * math.sin(midAngle);
      final isActive = i == activeIndex;
      canvas.save();
      canvas.translate(tx, ty);
      if (isActive) canvas.scale(_highlightScale, _highlightScale);
      final label = labels[i];
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: isActive ? _darken(textColor, _darkenAmount) : textColor,
          fontSize: 14 * textScale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0xFF5D4037), offset: Offset(1, 1), blurRadius: 1),
            Shadow(color: Colors.black54, offset: Offset(0, 0), blurRadius: 2),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.segmentScale != segmentScale ||
      old.textScale != textScale ||
      old.textColor != textColor ||
      old.segmentColors != segmentColors ||
      old.pointerAngle != pointerAngle;
}

class _MarkerArrowPainter extends CustomPainter {
  _MarkerArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h * 0.75)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkerArrowPainter old) => old.color != color;
}
