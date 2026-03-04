import 'package:flame/components.dart';

/// Hướng di chuyển của sâu (class cha / enum dùng chung).
enum WormDirection {
  up,
  down,
  left,
  right;

  Vector2 toVector() {
    switch (this) {
      case WormDirection.up:
        return Vector2(0, -1);
      case WormDirection.down:
        return Vector2(0, 1);
      case WormDirection.left:
        return Vector2(-1, 0);
      case WormDirection.right:
        return Vector2(1, 0);
    }
  }

  bool isOppositeOf(WormDirection other) {
    return (this == WormDirection.up && other == WormDirection.down) ||
        (this == WormDirection.down && other == WormDirection.up) ||
        (this == WormDirection.left && other == WormDirection.right) ||
        (this == WormDirection.right && other == WormDirection.left);
  }

  double get rotationRadians {
    switch (this) {
      case WormDirection.up:
        return 0;
      case WormDirection.down:
        return 3.141592653589793;
      case WormDirection.left:
        return 1.5707963267948966;
      case WormDirection.right:
        return -1.5707963267948966;
    }
  }
}
