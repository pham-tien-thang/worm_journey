/// Cấu hình buff dùng chung: thời gian (giây) theo [itemId].
/// Các màn (game, shop, ...) dùng chung để apply buff và hiển thị.
abstract class BuffConfig {
  BuffConfig._();

  /// Thời gian buff (giây). Null hoặc 0 = không có buff theo thời gian.
  static const Map<String, double> durationSeconds = {
    'coconut': 10.0,
    // Thêm itemId khác khi có buff: 'snail': 5.0, 'shield': 1.0, ...
  };

  /// Lấy thời gian buff (giây) cho [itemId]. Mặc định 0.
  static double durationSecondsFor(String itemId) {
    return durationSeconds[itemId] ?? 0;
  }

  /// Có phải buff có thời gian (dùng để add vào list buff).
  static bool hasDuration(String itemId) {
    return (durationSeconds[itemId] ?? 0) > 0;
  }
}
