import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Màu mặc định cho lưới (nâu nhạt xen kẽ).
class GridBackgroundColors {
  const GridBackgroundColors({
    this.colorLight = const Color(0xFFE8DED5),
    this.colorLighter = const Color(0xFFD7CCC8),
  });

  final Color colorLight;
  final Color colorLighter;

  static const brown = GridBackgroundColors(
    colorLight: Color(0xFFE8DED5),
    colorLighter: Color(0xFFD7CCC8),
  );
}

/// Nền lưới ô vuông, xen kẽ hai màu cho dễ nhìn. Các màn truyền [colors] khác nhau.
class GridBackground extends PositionComponent {
  GridBackground({
    required this.segmentSize,
    required this.gridColumns,
    required this.gridRows,
    GridBackgroundColors colors = GridBackgroundColors.brown,
    Vector2? position,
  })  : colorLight = colors.colorLight,
        colorLighter = colors.colorLighter,
        super(
          position: position ?? Vector2.zero(),
          size: Vector2(
            segmentSize * gridColumns,
            segmentSize * gridRows,
          ),
        );

  double segmentSize;
  int gridColumns;
  int gridRows;
  final Color colorLight;
  final Color colorLighter;

  void updateGrid(double segSize, int cols, int rows) {
    segmentSize = segSize;
    gridColumns = cols;
    gridRows = rows;
    size.setValues(segSize * cols, segSize * rows);
  }

  @override
  void render(Canvas canvas) {
    for (var row = 0; row < gridRows; row++) {
      for (var col = 0; col < gridColumns; col++) {
        final isEven = (row + col) % 2 == 0;
        final color = isEven ? colorLight : colorLighter;
        final left = col * segmentSize;
        final top = row * segmentSize;
        canvas.drawRect(
          Rect.fromLTWH(left, top, segmentSize, segmentSize),
          Paint()..color = color,
        );
      }
    }
  }
}
