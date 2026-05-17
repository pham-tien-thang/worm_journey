import 'dart:ui' as ui;

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

/// Cấu hình vùng ngoài grid (mặc định nâu + 🌱). Sau sẽ load từ JSON.
class OutsideGridConfig {
  const OutsideGridConfig({
    this.color = const Color(0xFF8B7355),
    this.icon = '🌱',
  });

  final Color color;
  final String icon;
}

/// Nền: ngoài vùng chơi [outsideConfig] (mặc định nâu + 🌱); trong vùng chơi vẽ lưới.
class GridBackground extends PositionComponent {
  GridBackground({
    required this.segmentSize,
    required this.gridColumns,
    required this.totalWorldRows,
    required this.playableStartRow,
    required this.playableRowCount,
    GridBackgroundColors colors = GridBackgroundColors.brown,
    OutsideGridConfig outsideConfig = const OutsideGridConfig(),
    Vector2? position,
  }) : colorLight = colors.colorLight,
       colorLighter = colors.colorLighter,
       outsideColor = outsideConfig.color,
       outsideIcon = outsideConfig.icon,
       super(
         position: position ?? Vector2.zero(),
         size: Vector2(segmentSize * gridColumns, segmentSize * totalWorldRows),
       );

  double segmentSize;
  int gridColumns;
  int totalWorldRows;
  int playableStartRow;
  int playableRowCount;
  final Color colorLight;
  final Color colorLighter;
  Color outsideColor;
  String outsideIcon;

  ui.Picture? _cachedPicture;

  void updateGrid(
    double segSize,
    int cols,
    int totalRows,
    int playStart,
    int playCount, {
    Color? outsideColor,
    String? outsideIcon,
  }) {
    segmentSize = segSize;
    gridColumns = cols;
    totalWorldRows = totalRows;
    playableStartRow = playStart;
    playableRowCount = playCount;
    if (outsideColor != null) this.outsideColor = outsideColor;
    if (outsideIcon != null) this.outsideIcon = outsideIcon;
    size.setValues(segSize * cols, segSize * totalRows);
    _invalidateCache();
  }

  @override
  void render(Canvas canvas) {
    _cachedPicture ??= _buildPicture();
    canvas.drawPicture(_cachedPicture!);
  }

  @override
  void onRemove() {
    _invalidateCache();
    super.onRemove();
  }

  void _invalidateCache() {
    _cachedPicture?.dispose();
    _cachedPicture = null;
  }

  ui.Picture _buildPicture() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final lightPaint = Paint()..color = colorLight;
    final lighterPaint = Paint()..color = colorLighter;
    final outsidePaint = Paint()..color = outsideColor;
    final outsidePainter = TextPainter(
      text: TextSpan(
        text: outsideIcon,
        style: TextStyle(fontSize: segmentSize * 0.6),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    for (var row = 0; row < totalWorldRows; row++) {
      final inPlayable =
          row >= playableStartRow && row < playableStartRow + playableRowCount;
      for (var col = 0; col < gridColumns; col++) {
        final left = col * segmentSize;
        final top = row * segmentSize;
        if (inPlayable) {
          final playableRow = row - playableStartRow;
          final isEven = (playableRow + col) % 2 == 0;
          canvas.drawRect(
            Rect.fromLTWH(left, top, segmentSize, segmentSize),
            isEven ? lightPaint : lighterPaint,
          );
        } else {
          canvas.drawRect(
            Rect.fromLTWH(left, top, segmentSize, segmentSize),
            outsidePaint,
          );
          final cx = left + segmentSize / 2 - outsidePainter.width / 2;
          final cy = top + segmentSize / 2 - outsidePainter.height / 2;
          outsidePainter.paint(canvas, Offset(cx, cy));
        }
      }
    }
    return recorder.endRecording();
  }
}
