import 'package:flutter/material.dart';

import '../components/grid_background.dart';

/// Ô lưới (col, row) cho preset chướng ngại.
class GridPoint {
  const GridPoint(this.col, this.row);
  final int col;
  final int row;
}

/// Cấu hình từng level. Về sau thêm preset chướng ngại vật khác nhau.
class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.gridColors,
    this.presetObstacles,
  });

  final int level;
  final GridBackgroundColors gridColors;
  /// Chướng ngại đặt sẵn (col, row). Null = không đặt sẵn (để sau scale).
  final List<GridPoint>? presetObstacles;

  static const _lv1Colors = GridBackgroundColors.brown;

  static const _lv2Colors = GridBackgroundColors(
    colorLight: Color(0xFFE8EAF6),
    colorLighter: Color(0xFFC5CAE9),
  );

  static const _lv3Colors = GridBackgroundColors(
    colorLight: Color(0xFFE8F5E9),
    colorLighter: Color(0xFFC8E6C9),
  );

  static GridBackgroundColors colorsFor(int level) {
    switch (level) {
      case 1:
        return _lv1Colors;
      case 2:
        return _lv2Colors;
      case 3:
        return _lv3Colors;
      default:
        return _lv1Colors;
    }
  }

  static LevelConfig forLevel(int level) {
    return LevelConfig(
      level: level,
      gridColors: colorsFor(level),
      presetObstacles: null,
    );
  }
}
