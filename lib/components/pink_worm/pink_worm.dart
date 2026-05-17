import 'package:flame/components.dart';

import '../../core/buff/buff_config.dart';
import '../../entities/entities.dart';
import '../../models/item_model.dart';
import '../worm/worm.dart';
import 'antidote_burst.dart';
import 'bomb_explosion.dart';
import 'dizzy_stars.dart';
import 'freeze_burst.dart';
import 'magnet_radar.dart';
import 'pink_worm_config.dart';

/// Pink worm: chỉ khởi tạo game object với [PinkWormConfig] (assets, thông số).
/// Extend từ Worm; logic nón (evil) và nhấp nháy sắp hết effect nằm ở đây.
class PinkWorm extends Worm {
  PinkWorm({PinkWormConfig? config, WormInfo? info, Vector2? position, int? gridRowsOverride})
    : super(config: config ?? PinkWormConfig(), info: info, position: position, gridRowsOverride: gridRowsOverride);

  bool _hasHelmet = false;
  double _antidoteBurstRemaining = 0;
  double _bombExplosionRemaining = 0;
  double _freezeBurstRemaining = 0;

  double get antidoteBurstRemaining => _antidoteBurstRemaining;
  double get bombExplosionRemaining => _bombExplosionRemaining;
  double get freezeBurstRemaining => _freezeBurstRemaining;

  void triggerBombExplosion() {
    _bombExplosionRemaining = BombExplosionComponent.explosionDuration;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(MagnetRadarComponent(
      segmentSize: config.segmentSize,
      priority: 5,
    ));
    add(DizzyStarsComponent(
      segmentSize: config.segmentSize,
      priority: 20,
    ));
    add(AntidoteBurstComponent(
      segmentSize: config.segmentSize,
      priority: 20,
    ));
    add(BombExplosionComponent(
      segmentSize: config.segmentSize,
      priority: 20,
    ));
    add(FreezeBurstComponent(
      segmentSize: config.segmentSize,
      priority: 20,
    ));
  }
  double _effectBlinkAccumulator = 0;
  bool _effectBlinkShow = true;
  static const double _effectBlinkLastSeconds = 3.0;
  static const double _effectBlinkInterval = 0.15;

  bool get hasHelmet => _hasHelmet;

  @override
  void setHasHelmet(bool value) {
    _hasHelmet = value;
    setHeadHelmet(value);
  }

  @override
  void onItemEffectAdded(String itemId) {
    if (itemId == ItemType.coconut.effectTypeId) {
      stats.currentHardness = stats.originalBaseHardness + 1;
      setHasHelmet(true);
      _effectBlinkAccumulator = 0;
      _effectBlinkShow = true;
    }
    if (itemId == ItemType.speed.effectTypeId || itemId == ItemType.snail.effectTypeId) {
      _applySpeedSnailMoveInterval(itemId);
    }
    if (itemId == ItemType.antidote.effectTypeId) {
      _antidoteBurstRemaining = AntidoteBurstComponent.burstDuration;
      removeItemEffects(BuffConfig.removableByAntidoteEffectIds);
      removeItemEffects([ItemType.antidote.effectTypeId]);
    }
    if (itemId == ItemType.dizzy.effectTypeId) {
      // Đảo hướng: Worm dùng _effectiveDirection (peekNextHead / step) khi hasItemEffect(dizzy)
    }
    if (itemId == ItemType.freeze.effectTypeId) {
      _freezeBurstRemaining = FreezeBurstComponent.burstDuration;
    }
  }

  @override
  void onItemEffectRemoved(String itemId) {
    if (itemId == ItemType.coconut.effectTypeId) {
      stats.currentHardness = stats.originalBaseHardness;
      setHasHelmet(false);
    }
    if (itemId == ItemType.speed.effectTypeId || itemId == ItemType.snail.effectTypeId) {
      _applySpeedSnailMoveInterval(itemId, speed: config.moveInterval);
    }
  }

  /// Cập nhật moveInterval theo speed/snail còn đang bật; không có thì về base.
  void _applySpeedSnailMoveInterval(String itemId, {double? speed}) {
    if (speed != null) {
      setMoveInterval(speed);
      return;
    }
    final base = config.moveInterval;
    if (itemId == ItemType.speed.effectTypeId) {
      if (hasItemEffect(ItemType.snail.effectTypeId)) {
        removeItemEffects([ItemType.snail.effectTypeId]);
      }
      setMoveInterval(base / 2);

    } else if (itemId == ItemType.snail.effectTypeId) {
      if (hasItemEffect(ItemType.speed.effectTypeId)) {
        removeItemEffects([ItemType.speed.effectTypeId]);
      }
      setMoveInterval(base * 2);
    } else {
      setMoveInterval(base);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_antidoteBurstRemaining > 0) _antidoteBurstRemaining = (_antidoteBurstRemaining - dt).clamp(0.0, 1.0);
    if (_bombExplosionRemaining > 0) _bombExplosionRemaining = (_bombExplosionRemaining - dt).clamp(0.0, 1.0);
    if (_freezeBurstRemaining > 0) _freezeBurstRemaining = (_freezeBurstRemaining - dt).clamp(0.0, 1.0);

    if (hasItemEffect(ItemType.freeze.effectTypeId) && gameTime != null) {
      double? freezeTimeLeft;
      for (final e in itemEffects) {
        if (e.itemId == ItemType.freeze.effectTypeId && e.endTime != null) {
          freezeTimeLeft = e.endTime! - gameTime!;
          break;
        }
      }
      setFreezeEndBlink(freezeTimeLeft != null && freezeTimeLeft > 0 && freezeTimeLeft <= 1.0);
    } else {
      setFreezeEndBlink(false);
    }

    if (!hasItemEffect(ItemType.coconut.effectTypeId) || gameTime == null) return;
    final list = itemEffects.where((e) => e.itemId == ItemType.coconut.effectTypeId).toList();
    if (list.isEmpty) return;
    final entry = list.first;
    if (entry.endTime == null) return;
    final timeLeft = entry.endTime! - gameTime!;
    if (timeLeft > _effectBlinkLastSeconds || timeLeft <= 0) return;
    _effectBlinkAccumulator += dt;
    if (_effectBlinkAccumulator >= _effectBlinkInterval) {
      _effectBlinkAccumulator = 0;
      _effectBlinkShow = !_effectBlinkShow;
      setHasHelmet(_effectBlinkShow);
    }
  }
}
