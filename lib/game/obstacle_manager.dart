import 'package:flame/components.dart';

import '../components/x_obstacle.dart';

/// Loại chướng ngại. Thêm type mới: enum + component tương ứng trong [ObstacleManager.createComponent].
enum ObstacleType {
  /// Dấu X (🪦) để lại khi mất đuôi. Có buff dừa thì phá được.
  xMark,
  // Sau này: spike, mud, ...
}

/// Cấu hình hành vi khi sâu đâm vào chướng ngại (game dùng để quyết định lose segment hay phá).
class ObstacleBehavior {
  const ObstacleBehavior({
    this.buffIdToDestroy,
    this.loseSegmentIfNotDestroyed = true,
  });

  /// Nếu sâu có buff này thì có thể phá chướng (không mất đuôi). Null = không phá được bằng buff.
  final String? buffIdToDestroy;

  /// Khi không phá được: có trừ 1 đốt đuôi không.
  final bool loseSegmentIfNotDestroyed;

  static const ObstacleBehavior xMark = ObstacleBehavior(
    buffIdToDestroy: 'coconut',
    loseSegmentIfNotDestroyed: true,
  );
}

/// Một chướng ngại trên map: vị trí lưới + loại + component.
class ObstacleEntry {
  ObstacleEntry({
    required this.grid,
    required this.type,
    required this.component,
  });

  final Vector2 grid;
  final ObstacleType type;
  final PositionComponent component;
}

/// Quản lý danh sách chướng ngại (nhiều loại). Game dùng để thêm khi mất đuôi, kiểm tra đâm, phá khi có buff.
class ObstacleManager {
  ObstacleManager({
    required this.segmentSize,
    required this.gridToWorld,
  });

  final double segmentSize;
  final Vector2 Function(Vector2 grid) gridToWorld;

  final List<ObstacleEntry> _entries = [];

  List<ObstacleEntry> get entries => List.unmodifiable(_entries);

  /// Hành vi theo từng loại (game dùng khi xử lý va chạm).
  static ObstacleBehavior behaviorFor(ObstacleType type) {
    switch (type) {
      case ObstacleType.xMark:
        return ObstacleBehavior.xMark;
    }
  }

  /// Tạo component tương ứng loại. Thêm type mới: thêm case và import component.
  PositionComponent createComponent(ObstacleType type, Vector2 grid) {
    switch (type) {
      case ObstacleType.xMark:
        return XObstacle(
          segmentSize: segmentSize,
          position: gridToWorld(grid),
        );
    }
  }

  void add(Vector2 grid, ObstacleType type, PositionComponent component) {
    _entries.add(ObstacleEntry(grid: grid, type: type, component: component));
  }

  /// Có chướng ngại tại ô [grid] không.
  bool hasObstacleAt(Vector2 grid) {
    final gx = grid.x.toInt();
    final gy = grid.y.toInt();
    return _entries.any((e) => e.grid.x.toInt() == gx && e.grid.y.toInt() == gy);
  }

  /// Lấy entry tại ô [grid]. Dùng khi cần biết type để áp behavior.
  ObstacleEntry? getAt(Vector2 grid) {
    final gx = grid.x.toInt();
    final gy = grid.y.toInt();
    for (final e in _entries) {
      if (e.grid.x.toInt() == gx && e.grid.y.toInt() == gy) return e;
    }
    return null;
  }

  /// Xóa chướng ngại tại ô [grid]. Game gọi removeFromParent(entry.component) sau khi remove.
  ObstacleEntry? removeAt(Vector2 grid) {
    final gx = grid.x.toInt();
    final gy = grid.y.toInt();
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].grid.x.toInt() == gx && _entries[i].grid.y.toInt() == gy) {
        return _entries.removeAt(i);
      }
    }
    return null;
  }

  /// Danh sách vị trí lưới (để đưa vào occupied / kiểm tra nhanh).
  Iterable<Vector2> get gridPositions => _entries.map((e) => e.grid);

  void clear() {
    _entries.clear();
  }
}
