import 'package:flutter_test/flutter_test.dart';
import 'package:worm_journey/components/pineapple_worm/pineapple_worm.dart';
import 'package:worm_journey/components/pineapple_worm/pineapple_worm_config.dart';
import 'package:worm_journey/components/pink_worm/pink_worm.dart';
import 'package:worm_journey/components/pink_worm/pink_worm_config.dart';
import 'package:worm_journey/core/app_constants.dart';
import 'package:worm_journey/models/item_model.dart';

void main() {
  test('formats compact coin values', () {
    expect(AppConstants.formatCoin(999), '999');
    expect(AppConstants.formatCoin(1000), '1k');
    expect(AppConstants.formatCoin(1500), '1.5k');
    expect(AppConstants.formatCoin(1000000), '1m');
  });

  test('speed and snail expiry restores base move interval', () {
    final worm = PinkWorm(config: PinkWormConfig(moveInterval: 1.0));

    worm.addItemEffect(ItemType.speed.effectTypeId, 5.0);
    expect(worm.moveInterval, 0.65);
    worm.removeExpiredItemEffects(5.0);
    expect(worm.moveInterval, 1.0);

    worm.addItemEffect(ItemType.snail.effectTypeId, 10.0);
    expect(worm.moveInterval, 2.0);
    worm.removeExpiredItemEffects(10.0);
    expect(worm.moveInterval, 1.0);
  });

  test('antidote clears speed and snail move interval changes', () {
    final worm = PinkWorm(config: PinkWormConfig(moveInterval: 1.0));

    worm.addItemEffect(ItemType.speed.effectTypeId, 5.0);
    expect(worm.moveInterval, 0.65);
    worm.addItemEffect(ItemType.antidote.effectTypeId, null);
    expect(worm.hasItemEffect(ItemType.speed.effectTypeId), isFalse);
    expect(worm.moveInterval, 1.0);

    worm.addItemEffect(ItemType.snail.effectTypeId, 10.0);
    expect(worm.moveInterval, 2.0);
    worm.addItemEffect(ItemType.antidote.effectTypeId, null);
    expect(worm.hasItemEffect(ItemType.snail.effectTypeId), isFalse);
    expect(worm.moveInterval, 1.0);
  });

  test('pineapple worm preserves configured base move interval', () {
    final worm = PineappleWorm(config: PineappleWormConfig(moveInterval: 1.23));

    expect(worm.moveInterval, 1.23);
  });
}
