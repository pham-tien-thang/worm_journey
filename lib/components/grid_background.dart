import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Nền lưới ô vuông, xen kẽ hai màu nâu nhạt cho dễ nhìn.
class GridBackground extends PositionComponent {
  GridBackground({
    required this.segmentSize,
    required this.gridColumns,
    required this.gridRows,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2(
            segmentSize * gridColumns,
            segmentSize * gridRows,
          ),
        );

  double segmentSize;
  int gridColumns;
  int gridRows;

  /// Màu nâu nhạt xen kẽ (dễ nhìn).
  static const Color _brownLight = Color(0xFFE8DED5);
  static const Color _brownLighter = Color(0xFFD7CCC8);

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
        final color = isEven ? _brownLight : _brownLighter;
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
