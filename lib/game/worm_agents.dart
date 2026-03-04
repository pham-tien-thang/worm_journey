import 'package:flame/components.dart';

import '../components/snake/snake_direction.dart';
import '../components/snake/worm.dart';
import '../entities/entities.dart';

/// Một “con sâu” trong game: component Worm + thông tin entity (player / bot).
/// Game giữ [List<WormAgent>]; index 0 = player, sau này thêm bot.
class WormAgent {
  WormAgent({
    required this.worm,
    required this.entity,
  });

  final Worm worm;
  final WormEntity entity;

  bool get isPlayer => entity.isPlayerControlled;
  bool get isBot => entity.isBot;

  Vector2 get headGridPosition => worm.headGridPosition;
  Vector2 get tailGridPosition => worm.tailGridPosition;
  List<Vector2> get allGridPositions => worm.allGridPositions;
  Vector2 peekNextHead() => worm.peekNextHead();
  int get segmentCount => worm.segmentCount;

  void setNextDirection(SnakeDirection d) => worm.setNextDirection(d);
  Vector2? step() => worm.step();
  void removeTail() => worm.removeTail();
  void grow() => worm.grow();
  void applyNextDirectionAndSyncVisuals() => worm.applyNextDirectionAndSyncVisuals();
  void showCryFace() => worm.showCryFace();
  void addBuff(String itemId, double endTime) => worm.addBuff(itemId, endTime);
  void setHasHelmet(bool value) => worm.setHasHelmet(value);
  void removeExpiredBuffs(double currentTime) => worm.removeExpiredBuffs(currentTime);
  List<WormBuffEntry> get buffEffects => worm.buffEffects;
  void setWaitingToStart(bool value) => worm.setWaitingToStart(value);
  void setVisualProgress(double progress) => worm.setVisualProgress(progress);
  double get moveInterval => worm.moveInterval;
}
