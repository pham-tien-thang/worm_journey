import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../core/services/shared_prefs_service.dart' show SharedPrefsService, unlockNotifier;
import '../../models/scene_model.dart';

/// Vòng tròn đứt đoạn (dashed circle) — dùng cho hiệu ứng xoay.
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.radius,
    required this.color,
    this.strokeWidth = 2.5,
    this.dashCount = 12,
    this.dashRatio = 0.6,
  });

  final double radius;
  final Color color;
  final double strokeWidth;
  final int dashCount;
  final double dashRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const twoPi = math.pi * 2;
    final step = twoPi / dashCount;
    final sweep = step * dashRatio;
    for (var i = 0; i < dashCount; i++) {
      final start = i * step;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.radius != radius || old.color != color || old.strokeWidth != strokeWidth;
}

/// Màn chọn level trong một scene: zigzag dọc, mỗi stage là 1 nút, nối bằng gạch đứt.
/// Stage mở có hiệu ứng toả sáng, stage khoá có ổ khoá đè lên.
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key, required this.sceneIndex});

  final int sceneIndex;

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  SceneModel? _scene;
  int _maxLevelIndexUnlock = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScene();
    unlockNotifier.addListener(_onUnlockChanged);
  }

  @override
  void dispose() {
    unlockNotifier.removeListener(_onUnlockChanged);
    super.dispose();
  }

  void _onUnlockChanged() => _loadScene();

  Future<void> _loadScene() async {
    final maxScene = await SharedPrefsService.getMaxSceneIndexUnlock();
    final maxLevel = await SharedPrefsService.getMaxLevelIndexUnlock();
    final scenes = buildSceneList(
      maxSceneIndexUnlock: maxScene,
      maxLevelIndexUnlock: maxLevel,
    );
    final index = (widget.sceneIndex - 1).clamp(0, scenes.length - 1);
    if (!mounted) return;
    setState(() {
      _scene = index < scenes.length ? scenes[index] : null;
      _maxLevelIndexUnlock = maxLevel;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/select_level.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                    weight: 100,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _scene == null
                          ? const Center(child: Text('Scene not found'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _StageZigzagList(
                                scene: _scene!,
                                maxLevelIndexUnlock: _maxLevelIndexUnlock,
                                onLevelTap: (level) =>
                                    context.push(AppRoutes.game(level.id)),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Layout zigzag dọc: stage 0 trái, 1 phải, 2 trái, ...; nối bằng gạch đứt.
class _StageZigzagList extends StatelessWidget {
  const _StageZigzagList({
    required this.scene,
    required this.maxLevelIndexUnlock,
    required this.onLevelTap,
  });

  final SceneModel scene;
  final int maxLevelIndexUnlock;
  final void Function(LevelModel level) onLevelTap;

  static const double _rowHeight = 128.0;
  static const double _leftFraction = 0.20;
  static const double _rightFraction = 0.80;
  static const double _nodeRadius = 14.0;
  static const double _topPadding = 20.0;

  List<Offset> _nodeCenters(int count, double width) {
    final list = <Offset>[];
    for (var i = 0; i < count; i++) {
      final x = (i % 2 == 0)
          ? width * _leftFraction
          : width * _rightFraction;
      final y = _topPadding + i * _rowHeight + _rowHeight / 2;
      list.add(Offset(x, y));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final levels = scene.levels;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final centers = _nodeCenters(levels.length, w);
        final totalHeight = _topPadding + levels.length * _rowHeight + _topPadding;
        return SizedBox(
          width: w,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Đường nối gạch đứt giữa các nút
              Positioned.fill(
                child: CustomPaint(
                  painter: _DashedConnectorPainter(
                    centers: centers,
                    dashLength: 8,
                    gapLength: 6,
                    color: Colors.white.withValues(alpha: 0.7),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              // Các nút stage (zigzag: chẵn trái, lẻ phải); tâm chấm trùng với [centers]
              for (var i = 0; i < levels.length; i++) ...[
                Positioned(
                  left: (i % 2 == 0)
                      ? (w * _leftFraction - _StageNode.width / 2)
                      : (w * _rightFraction - _StageNode.width / 2),
                  top: _topPadding + i * _rowHeight + (_rowHeight / 2) - _StageNode.dotPartHeight / 2,
                  child: _StageNode(
                    level: levels[i],
                    nodeRadius: _nodeRadius,
                    showRadar: levels[i].id == maxLevelIndexUnlock,
                    onTap: () => onLevelTap(levels[i]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Vẽ đường gạch đứt nối các điểm [centers].
class _DashedConnectorPainter extends CustomPainter {
  _DashedConnectorPainter({
    required this.centers,
    required this.dashLength,
    required this.gapLength,
    required this.color,
    this.strokeWidth = 2,
  });

  final List<Offset> centers;
  final double dashLength;
  final double gapLength;
  final Color color;
  final double strokeWidth;

  void _drawDashedSegment(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len <= 0) return;
    final ux = dx / len;
    final uy = dy / len;
    final step = dashLength + gapLength;
    var t = 0.0;
    while (t + dashLength <= len) {
      final a = Offset(p1.dx + ux * t, p1.dy + uy * t);
      final b = Offset(p1.dx + ux * (t + dashLength), p1.dy + uy * (t + dashLength));
      canvas.drawLine(a, b, paint);
      t += step;
    }
    if (t < len && len - t > 1) {
      final a = Offset(p1.dx + ux * t, p1.dy + uy * t);
      canvas.drawLine(a, p2, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < centers.length - 1; i++) {
      _drawDashedSegment(canvas, centers[i], centers[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedConnectorPainter old) =>
      old.centers != centers ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.color != color;
}

/// Một nút stage: chấm đen, vòng transparent, vòng trắng; unlock (theo SharedPrefs) thì hiệu ứng radar toả dần; khoá thì ổ khoá.
class _StageNode extends StatefulWidget {
  const _StageNode({
    required this.level,
    required this.nodeRadius,
    required this.showRadar,
    required this.onTap,
  });

  static const double width = 72.0;
  static const double dotPartHeight = 72.0;

  final LevelModel level;
  final double nodeRadius;
  /// Chỉ stage có id trùng unlock level trong SharedPrefs mới toả.
  final bool showRadar;
  final VoidCallback onTap;

  @override
  State<_StageNode> createState() => _StageNodeState();
}

class _StageNodeState extends State<_StageNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.nodeRadius;
    final unlocked = widget.level.isUnlock;
    final showRadar = widget.showRadar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? widget.onTap : null,
        borderRadius: BorderRadius.circular(r + 12),
        child: SizedBox(
          width: _StageNode.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _StageNode.width,
                height: _StageNode.dotPartHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Vòng tròn cam đứt đoạn xoay tròn (stage trùng unlock level)
                    if (showRadar)
                      Center(
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _glowController.value * 2 * math.pi,
                              child: SizedBox(
                                width: (r + 8) * 2,
                                height: (r + 8) * 2,
                                child: CustomPaint(
                                  painter: _DashedCirclePainter(
                                    radius: r + 8,
                                    color: Colors.orange,
                                    strokeWidth: 4,
                                    dashCount: 12,
                                    dashRatio: 0.4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // Vòng transparent (1 xíu)
                    Container(
                      width: r * 2 + 12,
                      height: r * 2 + 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Vòng trắng (bỏ khi đang toả)
                    if (!showRadar)
                      Container(
                        width: r * 2 + 20,
                        height: r * 2 + 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    // Chấm đen + số
                    Container(
                      width: r * 2,
                      height: r * 2,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.level.id}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: r * 0.85,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Ổ khoá đè lên khi bị khoá (khớp đúng kích thước nút = vòng trắng)
                    if (!unlocked)
                      Center(
                        child: SizedBox(
                          width: r * 2 + 20,
                          height: r * 2 + 20,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black45,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: r * 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stage ${widget.level.id}',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(color: Colors.white, offset: Offset(0, 0), blurRadius: 2),
                    Shadow(color: Colors.white, offset: Offset(1, 0), blurRadius: 1),
                    Shadow(color: Colors.white, offset: Offset(-1, 0), blurRadius: 1),
                    Shadow(color: Colors.white, offset: Offset(0, 1), blurRadius: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
