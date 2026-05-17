import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/buff/buff_config.dart';
import '../../models/item_model.dart';
import '../worm/worm.dart';

/// Một vòng radar: bán kính max theo số ô [baseRadiusTiles], đang thu nhỏ theo [scale] (1 → 0).
class _MagnetRipple {
  _MagnetRipple(this.baseRadiusTiles, this.scale);
  int baseRadiusTiles;
  double scale;
}

/// Vòng radar vàng quanh đầu khi có magnet. x = magnetRangeTiles - 1 vòng (vd. 3 ô → 2 vòng).
/// Mỗi vòng thu về đúng 1 đơn vị (1 ô) thì biến mất.
class MagnetRadarComponent extends PositionComponent {
  MagnetRadarComponent({
    required this.segmentSize,
    super.priority,
  });

  final double segmentSize;

  /// Thời gian để vòng thu về 1 đơn vị (giây) — càng lớn càng chậm.
  static const double _shrinkPeriod = 1.8;
  /// Còn bao nhiêu giây thì radar nhấp nháy vàng/đỏ.
  static const double _blinkWhenSecondsLeft = 3.0;
  /// Chu kỳ nhấp nháy (giây) — mỗi nửa chu kỳ đổi màu (càng nhỏ càng nhanh).
  static const double _blinkInterval = 0.08;
  final List<_MagnetRipple> _ripples = [];
  bool _initialized = false;
  int? _pendingAddBase;

  void _initRipples(int range) {
    _ripples.clear();
    _pendingAddBase = null;
    final circleCount = range - 1;
    for (var i = 0; i < circleCount; i++) {
      final baseRadiusTiles = i + 2;
      _ripples.add(_MagnetRipple(baseRadiusTiles, 1.0));
    }
    _initialized = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worm = parent;
    if (worm is Worm) {
      position.setFrom(worm.headLocalPosition);
      if (!worm.hasItemEffect(ItemType.magnet.effectTypeId)) {
        _initialized = false;
        _pendingAddBase = null;
        return;
      }

      final range = BuffConfig.magnetRangeTiles;
      if (!_initialized) _initRipples(range);

      // Cho phép sinh vòng pending khi: không còn vòng nào, hoặc vòng to nhất (tầng range) đã co 1 ô.
      if (_pendingAddBase != null) {
        final largest = _ripples.isEmpty ? null : _ripples.reduce((a, b) => a.baseRadiusTiles >= b.baseRadiusTiles ? a : b);
        final maySpawn = largest == null ||
            largest.baseRadiusTiles != range ||
            (largest.baseRadiusTiles == range && largest.scale <= (range - 1) / range);
        if (maySpawn) {
          _ripples.add(_MagnetRipple(_pendingAddBase!, 1.0));
          _pendingAddBase = null;
        }
      }

      final baseShrinkPerSecond = 1.0 / _shrinkPeriod;
      for (var i = _ripples.length - 1; i >= 0; i--) {
        final r = _ripples[i];
        final speed = baseShrinkPerSecond * (2.0 - r.scale).clamp(0.5, 2.0);
        r.scale -= dt * speed;
        // Chỉ biến mất khi còn đúng 1 đơn vị (bán kính = 1 ô): scale <= 1/baseRadiusTiles.
        final thresholdScale = 1.0 / r.baseRadiusTiles;
        if (r.scale <= thresholdScale) {
          _ripples.removeAt(i);
          _pendingAddBase = r.baseRadiusTiles;
        }
      }
    }
  }

  /// Thời gian còn lại của effect magnet (giây). Null nếu không có hoặc không hết hạn.
  double? _magnetTimeLeft(Worm worm) {
    if (worm.gameTime == null) return null;
    for (final e in worm.itemEffects) {
      if (e.itemId == ItemType.magnet.effectTypeId && e.endTime != null) {
        return e.endTime! - worm.gameTime!;
      }
    }
    return null;
  }

  @override
  void render(Canvas canvas) {
    final worm = parent;
    if (worm is! Worm || !worm.hasItemEffect(ItemType.magnet.effectTypeId)) {
      return;
    }
    if (_ripples.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final timeLeft = _magnetTimeLeft(worm);
    final isBlinkZone = timeLeft != null && timeLeft > 0 && timeLeft <= _blinkWhenSecondsLeft;
    final showWhite = isBlinkZone && worm.gameTime != null && ((worm.gameTime! / _blinkInterval).floor() % 2 == 1);

    final center = Offset.zero;
    for (final r in _ripples) {
      final radius = r.baseRadiusTiles * segmentSize * r.scale;
      if (radius < segmentSize * 0.5) continue;
      final alpha = (0.45 * r.scale).clamp(0.1, 0.45);
      paint.color = (showWhite ? Colors.white : Colors.orange).withValues(alpha: alpha);
      canvas.drawCircle(center, radius, paint);
    }
  }
}
