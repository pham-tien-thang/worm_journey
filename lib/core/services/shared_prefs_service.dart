import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier khi max level/scene unlock thay đổi (chiến thắng cập nhật SharedPrefs).
/// Màn level selection và scene selection lắng nghe để reload ngay.
final UnlockNotifier unlockNotifier = UnlockNotifier();

class UnlockNotifier extends ChangeNotifier {
  void notifyUnlockChanged() => notifyListeners();
}

/// Service lưu/đọc dữ liệu qua SharedPreferences.
class SharedPrefsService {
  SharedPrefsService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const String _coinKey = 'coin';
  static const String _firstTimeBonusKey = 'first_time_bonus_given';
  static const String _freeRandomCoinLastAtKey = 'free_random_coin_last_at';
  static const String _maxSceneIndexUnlockKey = 'max_scene_index_unlock';
  static const String _maxLevelIndexUnlockKey = 'max_level_index_unlock';
  static const String _wormInitLengthKey = 'worm_init_length';
  static const String _wormMaxLengthKey = 'worm_max_length';
  static const String _itemQtyPrefix = 'item_qty_';

  /// Số đốt thân khởi điểm (1 = 1 đầu + 1 thân + 1 đuôi). Mặc định 1.
  static Future<int> getWormInitLength() async {
    await init();
    return _prefs!.getInt(_wormInitLengthKey) ?? 1;
  }

  static Future<void> setWormInitLength(int value) async {
    await init();
    await _prefs!.setInt(_wormInitLengthKey, value.clamp(1, 99));
  }

  /// Độ dài tối đa (số đốt, đầu+thân+đuôi). Mặc định 10.
  static Future<int> getWormMaxLength() async {
    await init();
    return _prefs!.getInt(_wormMaxLengthKey) ?? 10;
  }

  static Future<void> setWormMaxLength(int value) async {
    await init();
    await _prefs!.setInt(_wormMaxLengthKey, value.clamp(2, 999));
  }

  /// Scene index cao nhất đã mở (1-based). Mặc định 1.
  static Future<int> getMaxSceneIndexUnlock() async {
    await init();
    return _prefs!.getInt(_maxSceneIndexUnlockKey) ?? 1;
  }

  static Future<void> setMaxSceneIndexUnlock(int value) async {
    await init();
    await _prefs!.setInt(_maxSceneIndexUnlockKey, value.clamp(1, 999));
    unlockNotifier.notifyUnlockChanged();
  }

  /// Level index (id) cao nhất đã mở (1-based, global). Mặc định 1.
  static Future<int> getMaxLevelIndexUnlock() async {
    await init();
    return _prefs!.getInt(_maxLevelIndexUnlockKey) ?? 1;
  }

  static Future<void> setMaxLevelIndexUnlock(int value) async {
    await init();
    await _prefs!.setInt(_maxLevelIndexUnlockKey, value.clamp(1, 999));
    unlockNotifier.notifyUnlockChanged();
  }

  /// Timestamp (ms since epoch) lần cuối nhận free random coin. Null nếu chưa từng.
  static Future<int?> getFreeRandomCoinLastAt() async {
    await init();
    final v = _prefs!.getInt(_freeRandomCoinLastAtKey);
    return v;
  }

  /// Lưu thời điểm vừa nhận free random coin (sau khi bấm Get XX coin).
  static Future<void> setFreeRandomCoinLastAt(int millisecondsSinceEpoch) async {
    await init();
    await _prefs!.setInt(_freeRandomCoinLastAtKey, millisecondsSinceEpoch);
  }

  /// Đã tặng bonus 100 coin lần đầu chưa (chỉ tặng 1 lần, trừ khi dev mode).
  static Future<bool> hasFirstTimeBonusGiven() async {
    await init();
    return _prefs!.getBool(_firstTimeBonusKey) ?? false;
  }

  static Future<void> setFirstTimeBonusGiven() async {
    await init();
    await _prefs!.setBool(_firstTimeBonusKey, true);
  }

  /// Đọc coin. Null nếu chưa từng set (lần đầu).
  static Future<int?> getCoin() async {
    await init();
    final v = _prefs!.getInt(_coinKey);
    return v;
  }

  /// Lưu coin.
  static Future<void> setCoin(int value) async {
    await init();
    await _prefs!.setInt(_coinKey, value);
  }

  /// Số lượng item (mặc định 0).
  static Future<int> getItemQuantity(String itemId) async {
    await init();
    return _prefs!.getInt(_itemQtyPrefix + itemId) ?? 0;
  }

  /// Lưu số lượng item.
  static Future<void> setItemQuantity(String itemId, int value) async {
    await init();
    if (value <= 0) {
      await _prefs!.remove(_itemQtyPrefix + itemId);
    } else {
      await _prefs!.setInt(_itemQtyPrefix + itemId, value);
    }
  }

  /// Kiểm tra đã từng lưu số lượng item chưa (để biết lần đầu vào game).
  static Future<bool> hasItemQuantityKey(String itemId) async {
    await init();
    return _prefs!.containsKey(_itemQtyPrefix + itemId);
  }

  /// Load số lượng tất cả item (key = itemId).
  static Future<Map<String, int>> getItemQuantities(Iterable<String> itemIds) async {
    await init();
    final map = <String, int>{};
    for (final id in itemIds) {
      map[id] = _prefs!.getInt(_itemQtyPrefix + id) ?? 0;
    }
    return map;
  }
}
