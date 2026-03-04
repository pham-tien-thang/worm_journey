import 'dart:math';

import 'package:flame/components.dart';

import '../components/prey.dart' show Prey, PreyType;

/// Một mồi trên map: vị trí lưới + loại + component để vẽ và remove.
class PreyEntry {
  PreyEntry({
    required this.grid,
    required this.type,
    required this.component,
  });

  final Vector2 grid;
  final PreyType type;
  final Prey component;
}

/// Quản lý danh sách mồi (nhiều mồi, nhiều loại). Game dùng để spawn, kiểm tra ô trống, và xử lý ăn mồi.
/// Thêm loại mồi mới: bổ sung [PreyType] trong prey.dart và xử lý effect trong game (grow, buff, mission).
class PreyManager {
  PreyManager({
    required this.segmentSize,
    required this.gridColumns,
    required this.gridRows,
    required this.gridToWorld,
    Random? random,
  }) : _random = random ?? Random();

  final double segmentSize;
  final int gridColumns;
  final int gridRows;
  final Vector2 Function(Vector2 grid) gridToWorld;
  final Random _random;

  final List<PreyEntry> _entries = [];

  List<PreyEntry> get entries => List.unmodifiable(_entries);

  /// Tạo set key ô đã bị chiếm (snake + mồi + chướng ngại) để spawn không trùng.
  Set<String> occupiedGridKeys({
    required Iterable<Vector2> snakePositions,
    required Iterable<Vector2> obstaclePositions,
  }) {
    final keys = <String>{};
    for (final v in snakePositions) {
      keys.add('${v.x.toInt()},${v.y.toInt()}');
    }
    for (final e in _entries) {
      keys.add('${e.grid.x.toInt()},${e.grid.y.toInt()}');
    }
    for (final o in obstaclePositions) {
      keys.add('${o.x.toInt()},${o.y.toInt()}');
    }
    return keys;
  }

  /// Spawn một mồi loại [type] tại ô trống (random). Trả về entry đã tạo; game cần [world.add(entry.component)].
  /// Trả về null nếu không tìm được ô trống sau 100 lần thử.
  PreyEntry? spawn(PreyType type, Set<String> occupied) {
    for (var i = 0; i < 100; i++) {
      final pos = Vector2(
        _random.nextInt(gridColumns).toDouble(),
        _random.nextInt(gridRows).toDouble(),
      );
      final key = '${pos.x.toInt()},${pos.y.toInt()}';
      if (occupied.contains(key)) continue;
      occupied.add(key);
      final component = Prey(
        segmentSize: segmentSize,
        type: type,
        position: gridToWorld(pos),
      );
      final entry = PreyEntry(grid: pos, type: type, component: component);
      _entries.add(entry);
      return entry;
    }
    return null;
  }

  /// Ăn mồi tại ô [grid]: xóa khỏi list và trả về entry (game gọi removeFromParent + xử lý effect theo type).
  /// Trả về null nếu không có mồi tại ô đó.
  PreyEntry? consumeAt(Vector2 grid) {
    final gx = grid.x.toInt();
    final gy = grid.y.toInt();
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].grid.x.toInt() == gx && _entries[i].grid.y.toInt() == gy) {
        return _entries.removeAt(i);
      }
    }
    return null;
  }

  /// Có mồi tại ô [grid] không.
  bool hasPreyAt(Vector2 grid) {
    final gx = grid.x.toInt();
    final gy = grid.y.toInt();
    return _entries.any((e) => e.grid.x.toInt() == gx && e.grid.y.toInt() == gy);
  }

  void clear() {
    _entries.clear();
  }
}
