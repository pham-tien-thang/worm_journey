import 'package:shared_preferences/shared_preferences.dart';

/// Service lưu/đọc dữ liệu qua SharedPreferences.
class SharedPrefsService {
  SharedPrefsService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const String _itemQtyPrefix = 'item_qty_';

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
