import 'package:flutter/material.dart';

/// Cấu hình chung của game rắn săn mồi.
abstract class GameConfig {
  GameConfig._();

  // Kích thước 1 ô lưới (đầu/đốt/mồi)
  static const double segmentSize = 28.0;

  // Màu rắn
  static const Color snakePink = Color(0xFFFF69B4);
  static const Color snakeInnerOrange = Color(0xFFFF8C00);

  // Màu mồi (hình tròn xanh lá)
  static const Color preyGreen = Color(0xFF2E7D32);

  // Tốc độ: giây giữa mỗi lần rắn di chuyển (càng lớn càng chậm)
  static const double moveInterval = 0.28;

  // Số cột / hàng — lưới lớn hơn để vùng chơi to
  static const int gridColumns = 24;
  static const int gridRows = 19;
}
