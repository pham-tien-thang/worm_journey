/// Hằng số dùng chung trong app (icon, số, v.v.).
abstract final class AppConstants {
  AppConstants._();

  /// Ký tự đồng tiền vàng (🪙). Dùng cho HUD, l10n, mô tả giá item.
  static const String coinIcon = '🪙';

  /// Ký tự item bị cấm. Dùng stack lên ô item khi màn chơi cấm item đó.
  static const String itemBlockedIcon = '🚫';
}
