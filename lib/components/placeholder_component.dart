import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/config.dart';

/// Component mẫu — sau này thay bằng Worm, Food, Obstacle...
class PlaceholderComponent extends RectangleComponent {
  PlaceholderComponent({
    Vector2? position,
    Vector2? size,
  }) : super(
          position: position ?? Vector2.zero(),
          size: size ?? Vector2.all(GameConfig.segmentSize),
          paint: Paint()..color = GameConfig.snakePink,
        );
}
