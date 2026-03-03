import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../common/debug_apply.dart';

/// Chỉ hiển thị khi [shouldApplyDebug]: vẽ tọa độ ô dạng A1, B1, ... (cột chữ, hàng số).
class DebugGridCoordinates extends PositionComponent {
  DebugGridCoordinates({
    required this.segmentSize,
    required this.gridColumns,
    required this.gridRows,
  }) : super(
          position: Vector2.zero(),
          size: Vector2(
            segmentSize * gridColumns,
            segmentSize * gridRows,
          ),
          priority: 100,
        );

  double segmentSize;
  int gridColumns;
  int gridRows;

  void updateGrid(double segSize, int cols, int rows) {
    segmentSize = segSize;
    gridColumns = cols;
    gridRows = rows;
    size.setValues(segSize * cols, segSize * rows);
  }

  static String _columnLabel(int col) {
    String s = '';
    int c = col;
    while (c >= 0) {
      s = String.fromCharCode(0x41 + c % 26) + s;
      c = c ~/ 26 - 1;
    }
    return s;
  }

  static String _cellLabel(int col, int row) {
    return '${_columnLabel(col)}${row + 1}';
  }

  @override
  void render(Canvas canvas) {
    if (!shouldApplyDebug) return;

    const textStyle = TextStyle(
      color: Colors.black54,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final half = segmentSize / 2;
    for (var row = 0; row < gridRows; row++) {
      for (var col = 0; col < gridColumns; col++) {
        final label = _cellLabel(col, row);
        final painter = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        final x = col * segmentSize + half - painter.width / 2;
        final y = row * segmentSize + half - painter.height / 2;
        painter.paint(canvas, Offset(x, y));
      }
    }
  }
}
