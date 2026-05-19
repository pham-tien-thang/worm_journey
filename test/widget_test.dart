import 'package:flutter_test/flutter_test.dart';
import 'package:worm_journey/components/pink_worm/pink_worm.dart';
import 'package:worm_journey/models/item_model.dart';
import 'package:worm_journey/core/app_constants.dart';

void main() {
  test('formats compact coin values', () {
    expect(AppConstants.formatCoin(999), '999');
    expect(AppConstants.formatCoin(1000), '1k');
    expect(AppConstants.formatCoin(1500), '1.5k');
    expect(AppConstants.formatCoin(1000000), '1m');
  });

  test('speed and snail expiry restores base move interval', () {
    final worm = PinkWorm();
    final baseInterval = worm.config.moveInterval;

    worm.addItemEffect(ItemType.speed.effectTypeId, 1);
    expect(worm.moveInterval, baseInterval * worm.speedMoveIntervalScale);

    worm.removeExpiredItemEffects(1);
    expect(worm.hasItemEffect(ItemType.speed.effectTypeId), isFalse);
    expect(worm.moveInterval, baseInterval);

    worm.addItemEffect(ItemType.snail.effectTypeId, 2);
    expect(worm.moveInterval, baseInterval * worm.snailMoveIntervalScale);

    worm.removeExpiredItemEffects(2);
    expect(worm.hasItemEffect(ItemType.snail.effectTypeId), isFalse);
    expect(worm.moveInterval, baseInterval);
  });

  test('speed and snail mutual removal syncs move interval once removed', () {
    final worm = PinkWorm();
    final baseInterval = worm.config.moveInterval;

    worm.addItemEffect(ItemType.speed.effectTypeId, 8);
    worm.addItemEffect(ItemType.snail.effectTypeId, 8);

    expect(worm.hasItemEffect(ItemType.speed.effectTypeId), isFalse);
    expect(worm.hasItemEffect(ItemType.snail.effectTypeId), isTrue);
    expect(worm.moveInterval, baseInterval * worm.snailMoveIntervalScale);
  });

  test('antidote clears speed and snail move interval changes', () {
    final worm = PinkWorm();
    final baseInterval = worm.config.moveInterval;

    worm.addItemEffect(ItemType.speed.effectTypeId, 8);
    expect(worm.moveInterval, baseInterval * worm.speedMoveIntervalScale);

    worm.addItemEffect(ItemType.antidote.effectTypeId, null);

    expect(worm.hasItemEffect(ItemType.speed.effectTypeId), isFalse);
    expect(worm.hasItemEffect(ItemType.snail.effectTypeId), isFalse);
    expect(worm.hasItemEffect(ItemType.antidote.effectTypeId), isFalse);
    expect(worm.moveInterval, baseInterval);
  });
}
