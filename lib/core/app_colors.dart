import 'package:flutter/material.dart';

/// Màu dùng chung trong app (game over, HUD, nút, v.v.).
abstract final class AppColors {
  AppColors._();

  /// Cam đậm dùng cho chữ Game Over, Kết thúc, badge quảng cáo.
  static const Color gameOverOrange = Color(0xFFFF9800);

  /// Nâu dùng cho chữ HUD, title dialog, v.v.
  static const Color hudTextBrown = Color(0xFF5D4037);

  /// Nền kem của HUD.
  static const Color hudBackground = Color(0xFFFEE7C4);

  /// Viền cam/vàng của HUD.
  static const Color hudBorder = Color(0xFFF1A64B);

  /// Nền ô thời gian HUD (tương phản, dễ nhìn).
  static const Color timeDisplayBackground = Color(0xFF2E3D49);

  /// Chữ ô thời gian HUD (sáng trên nền tối).
  static const Color timeDisplayText = Color(0xFFF5F0E8);

  /// Màu khi gấp gáp (<= 15s).
  static const Color timeUrgent = Color(0xFFE53935);

  /// Viền trắng mỏng cho chữ (dùng làm [TextStyle.shadows] để tạo viền).
  static const List<Shadow> textOutlineWhite = [
    Shadow(color: Colors.white, offset: Offset(-0.5, -0.5), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(0.5, -0.5), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(-0.5, 0.5), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(0.5, 0.5), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(0, -0.5), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(0, 0.5), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(-0.5, 0), blurRadius: 0),
    Shadow(color: Colors.white, offset: Offset(0.5, 0), blurRadius: 0),
  ];
}
