import 'dart:math';

import 'package:flame/components.dart';

import '../../components/prey.dart';
import '../../components/x_obstacle.dart';
import '../config/type_obj_config.dart';
import '../entities/entity_models.dart';

/// Một vật thể trên map: ô + typeId (string) + component. Category/icon/hardness từ [TypeObjConfig].
class MapEntityEntry {
  MapEntityEntry({
    required this.grid,
    required this.typeId,
    required this.component,
  });

  final Vector2 grid;
  final String typeId;
  final PositionComponent component;
}

/// Một manager cho mọi vật thể: load từ config hay tạo trong ván đều qua [placeAt(grid, typeId)].
/// Tạo component theo category (obtain → XObstacle, grey → Prey) từ [TypeObjConfig].
class MapEntityManager {
  MapEntityManager({
    required this.typeObjConfig,
    required this.segmentSize,
    required this.gridColumns,
    required this.gridRows,
    required this.gridToWorld,
    Random? random,
  }) : _random = random ?? Random();

  final TypeObjConfig typeObjConfig;
  final double segmentSize;
  final int gridColumns;
  final int gridRows;
  final Vector2 Function(Vector2 grid) gridToWorld;
  final Random _random;

  final List<MapEntityEntry> _entries = [];

  List<MapEntityEntry> get entries => List.unmodifiable(_entries);

  /// Đặt entity tại ô [grid]. [typeId] phải có trong typeObjConfig. Trả về component để game [world.add].
  PositionComponent placeAt(Vector2 grid, String typeId) {
    final comp = _createComponent(typeId, grid);
    _entries.add(MapEntityEntry(grid: grid, typeId: typeId, component: comp));
    return comp;
  }

  PositionComponent _createComponent(String typeId, Vector2 grid,
      {bool withSpawnEffect = false}) {
    final position = gridToWorld(grid);
    final icon = EntityModels.icon(typeId);
    final category = typeObjConfig.getCategory(typeId);
    if (category == 'grey') {
      return Prey(
        segmentSize: segmentSize,
        icon: icon,
        position: position,
        withSpawnEffect: withSpawnEffect,
      );
    }
    return XObstacle(
      segmentSize: segmentSize,
      icon: icon,
      position: position,
      withSpawnEffect: withSpawnEffect,
    );
  }

  MapEntityEntry? getAt(Vector2 grid) {
    final gx = grid.x.toInt();
    final gy = grid.y.toInt();
    for (final e in _entries) {
      if (e.grid.x.toInt() == gx && e.grid.y.toInt() == gy) return e;
    }
    return null;
  }

  bool hasEntityAt(Vector2 grid) => getAt(grid) != null;

  bool hasBlockingEntityAt(Vector2 grid) {
    final e = getAt(grid);
    return e != null && typeObjConfig.isBlocking(e.typeId);
  }

  MapEntityEntry? removeAt(Vector2 grid) {
    final gx = grid.x.toInt();
    final gy = grid.y.toInt();
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].grid.x.toInt() == gx && _entries[i].grid.y.toInt() == gy) {
        return _entries.removeAt(i);
      }
    }
    return null;
  }

  MapEntityEntry? consumeAt(Vector2 grid) {
    final entry = getAt(grid);
    if (entry == null || !typeObjConfig.isEatable(entry.typeId)) return null;
    _entries.remove(entry);
    return entry;
  }

  /// [isCellVisible] nếu có: chỉ spawn ở ô trong tầm camera. Null = bỏ qua check.
  MapEntityEntry? spawn(String typeId, Set<String> occupied,
      {bool Function(Vector2 grid)? isCellVisible}) {
    if (!typeObjConfig.isEatable(typeId)) return null;
    for (var i = 0; i < 100; i++) {
      final pos = Vector2(
        _random.nextInt(gridColumns).toDouble(),
        _random.nextInt(gridRows).toDouble(),
      );
      final key = '${pos.x.toInt()},${pos.y.toInt()}';
      if (occupied.contains(key)) continue;
      if (isCellVisible != null && !isCellVisible(pos)) continue;
      occupied.add(key);
      final comp = _createComponent(typeId, pos, withSpawnEffect: true);
      final entry = MapEntityEntry(grid: pos, typeId: typeId, component: comp);
      _entries.add(entry);
      return entry;
    }
    return null;
  }

  Set<String> occupiedGridKeys(Iterable<Vector2> snakePositions) {
    final keys = <String>{};
    for (final v in snakePositions) {
      keys.add('${v.x.toInt()},${v.y.toInt()}');
    }
    for (final e in _entries) {
      keys.add('${e.grid.x.toInt()},${e.grid.y.toInt()}');
    }
    return keys;
  }

  Iterable<Vector2> get gridPositions => _entries.map((e) => e.grid);

  void clear() => _entries.clear();
}
