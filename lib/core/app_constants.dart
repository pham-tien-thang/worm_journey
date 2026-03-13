/// Hằng số dùng chung trong app (icon, số, v.v.).
abstract final class AppConstants {
  AppConstants._();

  /// Ký tự đồng tiền vàng (🪙). Dùng cho HUD, l10n, mô tả giá item.
  static const String coinIcon = '🪙';

  /// Ký tự item bị cấm. Dùng stack lên ô item khi màn chơi cấm item đó.
  static const String itemBlockedIcon = '🚫';

  /// Format số xu: 1000 → "1k", 1_000_000 → "1m", 1_000_000_000 → "1b". Dưới 1000 giữ nguyên.
  static String formatCoin(int value) {
    if (value >= 1000000000) {
      final v = value / 1000000000;
      return v == v.truncateToDouble() ? '${v.toInt()}b' : '${v.toStringAsFixed(1)}b';
    }
    if (value >= 1000000) {
      final v = value / 1000000;
      return v == v.truncateToDouble() ? '${v.toInt()}m' : '${v.toStringAsFixed(1)}m';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return v == v.truncateToDouble() ? '${v.toInt()}k' : '${v.toStringAsFixed(1)}k';
    }
    return '$value';
  }
}
