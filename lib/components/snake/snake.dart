import 'package:flame/components.dart';

import '../../config/config.dart';
import 'snake_body_segment.dart';
import 'snake_direction.dart';
import 'snake_head.dart';
import 'snake_tail.dart';

/// Rắn: đầu + các đốt thân + đuôi (ô trắng X). Game gọi [step] mỗi tick.
/// Tốc độ cố định gắn vào rắn khi khởi tạo ([moveInterval] giây / 1 bước).
class Snake extends PositionComponent {
  Snake({
    Vector2? position,
    double segmentSize = 28.0,
    double moveInterval = 0.28,
    int? gridRows,
  })  : _segmentSize = segmentSize,
        _moveInterval = moveInterval,
        _gridRows = gridRows ?? GameConfig.gridRows,
        super(position: position ?? Vector2.zero());

  double _segmentSize;
  final int _gridRows;
  final double _moveInterval;

  /// Thời gian (giây) giữa mỗi bước di chuyển — cố định từ lúc tạo rắn.
  double get moveInterval => _moveInterval;
  final List<Vector2> _gridPositions = [];
  List<Vector2> _previousGridPositions = [];
  double _visualProgress = 1.0;

  SnakeDirection _direction = SnakeDirection.right;
  SnakeDirection? _nextDirection;
  int _pendingGrow = 0;

  late SnakeHead _head;
  final List<SnakeBodySegment> _bodySegments = [];
  late SnakeTail _tail;

  /// Hướng đang di chuyển (đã áp dụng next nếu có).
  SnakeDirection get currentDirection => _nextDirection ?? _direction;

  int get segmentCount => _gridPositions.length;
  Vector2 get tailGridPosition =>
      _gridPositions.isNotEmpty ? _gridPositions.last : Vector2.zero();

  Vector2 get headGridPosition =>
      _gridPositions.isNotEmpty ? _gridPositions.first : Vector2.zero();

  /// Vị trí ô đầu sẽ tới nếu bước tiếp (chưa gọi step). Để game kiểm tra trước khi cho di chuyển.
  Vector2 peekNextHead() {
    if (_gridPositions.isEmpty) return Vector2.zero();
    final dir = _nextDirection ?? _direction;
    return _gridPositions.first + dir.toVector();
  }

  List<Vector2> get allGridPositions => List.from(_gridPositions);

  void setSegmentSize(double s) {
    if (s <= 0) return;
    _segmentSize = s;
    _head.size.setValues(s, s);
    _tail.size.setValues(s, s);
    for (final seg in _bodySegments) seg.size.setValues(s, s);
  }

  static const int _initialLength = 10;

  @override
  Future<void> onLoad() async {
    final startX = (GameConfig.gridColumns / 2).floor() - _initialLength ~/ 2;
    final startY = (_gridRows / 2).floor();
    for (var i = _initialLength - 1; i >= 0; i--) {
      _gridPositions.add(Vector2((startX + i).toDouble(), startY.toDouble()));
    }
    _direction = SnakeDirection.right;
    _previousGridPositions = List.from(_gridPositions);

    _head = SnakeHead(
      direction: _direction,
      segmentSize: _segmentSize,
      emoji: '🙂',
      position: _gridToWorld(_gridPositions[0]),
    );
    add(_head);

    _tail = SnakeTail(
      direction: SnakeDirection.right,
      segmentSize: _segmentSize,
      position: _gridToWorld(_gridPositions[_gridPositions.length - 1]),
    );
    add(_tail);

    _syncVisuals();
  }

  Vector2 _gridToWorld(Vector2 grid) {
    final half = _segmentSize / 2;
    return Vector2(
      grid.x * _segmentSize + half,
      grid.y * _segmentSize + half,
    );
  }

  void setNextDirection(SnakeDirection d) {
    if (_direction == SnakeDirection.up && d == SnakeDirection.down) return;
    if (_direction == SnakeDirection.down && d == SnakeDirection.up) return;
    if (_direction == SnakeDirection.left && d == SnakeDirection.right) return;
    if (_direction == SnakeDirection.right && d == SnakeDirection.left) return;
    _nextDirection = d;
  }

  void grow() {
    _pendingGrow++;
  }

  /// Bật/ tắt chế độ 😈 (sau khi ăn táo, tồn tại 10s rồi tự tắt).
  void setHasHelmet(bool value) {
    _head.emoji = value ? '😈' : '🙂';
  }

  /// Bỏ 1 đốt đuôi (khi đâm tường hoặc đâm đuôi). Trả về true nếu còn đủ đốt.
  void removeTail() {
    if (_gridPositions.length <= 1) return;
    _gridPositions.removeLast();
    if (_previousGridPositions.length > _gridPositions.length) {
      _previousGridPositions.removeLast();
    }
    _syncVisuals();
  }

  /// Tiến độ nội suy 0→1 giữa ô cũ và ô mới (game gọi mỗi frame).
  void setVisualProgress(double t) {
    _visualProgress = t.clamp(0.0, 1.0);
  }

  Vector2 _lerpWorld(Vector2 gridFrom, Vector2 gridTo) {
    final from = _gridToWorld(gridFrom);
    final to = _gridToWorld(gridTo);
    return from + (to - from) * _visualProgress;
  }

  void _syncVisuals() {
    if (_gridPositions.isEmpty) return;

    final headPrev = _previousGridPositions.isNotEmpty
        ? _previousGridPositions.first
        : _gridPositions.first;
    _head.position = _lerpWorld(headPrev, _gridPositions.first);
    _head.direction = _direction;
    _head.angle = _direction.rotationRadians;

    final tailGrid = _gridPositions.last;
    final tailPrev = _previousGridPositions.length >= _gridPositions.length
        ? _previousGridPositions.last
        : tailGrid;
    _tail.position = _lerpWorld(tailPrev, tailGrid);
    if (_gridPositions.length >= 2) {
      final prev = _gridPositions[_gridPositions.length - 2];
      final diff = tailGrid - prev;
      if (diff.x > 0) {
        _tail.direction = SnakeDirection.right;
      } else if (diff.x < 0) {
        _tail.direction = SnakeDirection.left;
      } else if (diff.y > 0) {
        _tail.direction = SnakeDirection.down;
      } else {
        _tail.direction = SnakeDirection.up;
      }
    }

    while (_bodySegments.length > _gridPositions.length - 2) {
      final seg = _bodySegments.removeLast();
      seg.removeFromParent();
    }
    for (var i = 1; i < _gridPositions.length - 1; i++) {
      final prev = i < _previousGridPositions.length
          ? _previousGridPositions[i]
          : _gridPositions[i];
      final pos = _lerpWorld(prev, _gridPositions[i]);
      if (i - 1 < _bodySegments.length) {
        _bodySegments[i - 1].position = pos;
      } else {
        final seg = SnakeBodySegment(
          segmentSize: _segmentSize,
          position: pos,
        );
        _bodySegments.add(seg);
        add(seg);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncVisuals();
  }

  /// Game gọi mỗi tick. Trả về vị trí lưới của đầu mới (sau khi đã di chuyển).
  Vector2? step() {
    if (_gridPositions.isEmpty) return null;

    _previousGridPositions = List.from(_gridPositions);
    _visualProgress = 0.0;

    if (_nextDirection != null) {
      _direction = _nextDirection!;
      _nextDirection = null;
    }

    final move = _direction.toVector();
    final newHead = _gridPositions.first + move;

    _gridPositions.insert(0, newHead);
    if (_pendingGrow > 0) {
      _pendingGrow--;
    } else {
      _gridPositions.removeLast();
    }

    _syncVisuals();
    return newHead;
  }
}
