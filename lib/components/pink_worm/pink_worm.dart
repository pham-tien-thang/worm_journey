import 'package:flame/components.dart';

import '../../entities/entities.dart';
import '../../models/item_model.dart';
import '../worm/worm.dart';
import 'pink_worm_config.dart';

/// Pink worm: chỉ khởi tạo game object với [PinkWormConfig] (assets, thông số).
/// Extend từ Worm; logic nón (evil) và nhấp nháy sắp hết effect nằm ở đây.
class PinkWorm extends Worm {
  PinkWorm({
    PinkWormConfig? config,
    WormInfo? info,
    Vector2? position,
    int? gridRowsOverride,
  }) : super(
          config: config ?? PinkWormConfig(),
          info: info,
          position: position,
          gridRowsOverride: gridRowsOverride,
        );

  bool _hasHelmet = false;
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
  }

  @override
  void onItemEffectRemoved(String itemId) {
    if (itemId == ItemType.coconut.effectTypeId) {
      stats.currentHardness = stats.originalBaseHardness;
      setHasHelmet(false);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
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
