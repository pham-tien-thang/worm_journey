import 'package:flame/components.dart';

import '../../components/worm/worm.dart' show Worm, ItemEffectEntry;
import '../../components/worm/worm_direction.dart';
import '../../entities/entities.dart';
import 'worm_behavior.dart';

/// Một "con sâu" trong game: Worm (có [Worm.info]) + WormBehavior.
/// Game giữ [List<WormAgent>]; index 0 = player, sau này thêm bot với behavior khác.
/// [worm] phải có [Worm.info] != null.
class WormAgent {
  WormAgent({
    required this.worm,
    required this.behavior,
  }) : assert(worm.info != null, 'WormAgent cần worm có info');

  final Worm worm;
  final WormBehavior behavior;

  /// Lấy từ [worm.info]; không lưu trùng.
  WormInfo get info => worm.info!;

  bool get isPlayer => info.isPlayerControlled;
  bool get isBot => info.isBot;

  Vector2 get headGridPosition => worm.headGridPosition;
  Vector2 get tailGridPosition => worm.tailGridPosition;
  List<Vector2> get allGridPositions => worm.allGridPositions;
  Vector2 peekNextHead() => worm.peekNextHead();
  int get segmentCount => worm.segmentCount;

  void setNextDirection(WormDirection d) => worm.setNextDirection(d);
  Vector2? step() => worm.step();
  void removeTail() => worm.removeTail();
  void grow() => worm.grow();
  void applyNextDirectionAndSyncVisuals() => worm.applyNextDirectionAndSyncVisuals();
  void showCryFace() => worm.showCryFace();
  void addItemEffect(String itemId, double? endTime) => worm.addItemEffect(itemId, endTime);
  void setGameTime(double t) => worm.setGameTime(t);
  void removeExpiredItemEffects(double currentTime) => worm.removeExpiredItemEffects(currentTime);
  bool hasItemEffect(String itemId) => worm.hasItemEffect(itemId);
  List<ItemEffectEntry> get itemEffects => worm.itemEffects;
  void setHasHelmet(bool value) => worm.setHasHelmet(value);
  void setWaitingToStart(bool value) => worm.setWaitingToStart(value);
  void setVisualProgress(double progress) => worm.setVisualProgress(progress);
  double get moveInterval => worm.moveInterval;
}
