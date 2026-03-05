import 'package:flutter/material.dart';

/// Màu dùng chung trong app (game over, HUD, nút, v.v.).
abstract final class AppColors {
  AppColors._();

  /// Cam đậm dùng cho chữ Game Over, Kết thúc, badge quảng cáo.
  static const Color gameOverOrange = Color(0xFFFF9800);

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
