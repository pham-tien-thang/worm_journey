import 'package:flutter/foundation.dart';

import 'shared_prefs_service.dart';

/// Service cộng/trừ vàng: coinPlus(n), coinMinus(n). Lưu SharedPreferences.
/// Init: first-time bonus 100 coin (chỉ 1 lần, lưu flag). Dev mode: mỗi lần mở app đều cộng 100.
class CoinService extends ChangeNotifier {
  CoinService._();
  static final CoinService _instance = CoinService._();
  static CoinService get instance => _instance;

  static const int _firstTimeBonusAmount = 100;
  int _coin = 0;
  bool _initialized = false;

  int get coin => _coin;

  /// Khởi tạo: first-time bonus 100 coin (1 lần). Dev mode: mỗi lần mở app cộng 100.
  Future<void> init() async {
    if (_initialized) return;
    await SharedPrefsService.init();
    final existing = await SharedPrefsService.getCoin();
    final bonusGiven = await SharedPrefsService.hasFirstTimeBonusGiven();

    if (kDebugMode) {
      _coin = (existing ?? 0) + _firstTimeBonusAmount;
      await SharedPrefsService.setCoin(_coin);
    } else {
      if (!bonusGiven) {
        _coin = _firstTimeBonusAmount;
        await SharedPrefsService.setCoin(_coin);
        await SharedPrefsService.setFirstTimeBonusGiven();
      } else {
        _coin = existing ?? 0;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  /// Cộng vàng.
  Future<void> coinPlus(int amount) async {
    if (amount <= 0) return;
    _coin += amount;
    await SharedPrefsService.setCoin(_coin);
    notifyListeners();
  }

  /// Trừ vàng. Trả về true nếu đủ và đã trừ, false nếu không đủ.
  Future<bool> coinMinus(int amount) async {
    if (amount <= 0) return true;
    if (_coin < amount) return false;
    _coin -= amount;
    await SharedPrefsService.setCoin(_coin);
    notifyListeners();
    return true;
  }

  /// Đọc coin hiện tại (sync sau khi init).
  Future<int> getCoinAsync() async {
    if (!_initialized) await init();
    return _coin;
  }
}
