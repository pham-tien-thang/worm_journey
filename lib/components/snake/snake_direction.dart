import 'package:flame/components.dart';

/// Hướng di chuyển của rắn.
enum SnakeDirection {
  up,
  down,
  left,
  right;

  Vector2 toVector() {
    switch (this) {
      case SnakeDirection.up:
        return Vector2(0, -1);
      case SnakeDirection.down:
        return Vector2(0, 1);
      case SnakeDirection.left:
        return Vector2(-1, 0);
      case SnakeDirection.right:
        return Vector2(1, 0);
    }
  }

  /// Góc (radian) để xoay đầu rắn cho mặt hướng đúng.
  double get rotationRadians {
    switch (this) {
      case SnakeDirection.up:
        return 0;
      case SnakeDirection.down:
        return 3.141592653589793; // pi
      case SnakeDirection.left:
        return 1.5707963267948966; // pi/2
      case SnakeDirection.right:
        return -1.5707963267948966; // -pi/2
    }
  }
}
