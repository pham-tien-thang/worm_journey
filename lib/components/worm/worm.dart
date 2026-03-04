import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../entities/entities.dart';
import 'worm_body_segment.dart';
import 'worm_config.dart';
import 'worm_direction.dart';
import 'worm_head.dart';
import 'worm_tail.dart';

/// Sâu (class tổng): đầu + thân + đuôi, mọi thông số lấy từ [WormConfig] lúc khởi tạo.
/// Các loại worm (agent, hệ thống, người chơi) extend hoặc tạo từ config khác nhau.
class Worm extends PositionComponent {
  Worm({
    required this.config,
    this.info,
    WormStats? stats,
    Vector2? position,
    int? gridRowsOverride,
  })  : _segmentSize = config.segmentSize,
        _gridRows = gridRowsOverride ?? config.gridRows ?? GameConfig.gridRows,
        stats = stats ?? WormStats(moveInterval: config.moveInterval),
        super(position: position ?? Vector2.zero());

  final WormConfig config;
  final WormInfo? info;

  /// Chỉ số (tốc độ, ...). Cập nhật trong ván: [stats.moveInterval = 0.2].
  final WormStats stats;

  double _segmentSize;
  final int _gridRows;

  double get moveInterval => stats.moveInterval;

  /// Đổi tốc độ ngay trong ván (vd. buff ốc, skill).
  void setMoveInterval(double value) {
    stats.moveInterval = value;
  }
  final List<Vector2> _gridPositions = [];
  List<Vector2> _previousGridPositions = [];
  double _visualProgress = 1.0;

  WormDirection _direction = WormDirection.right;
  WormDirection? _nextDirection;
  int _pendingGrow = 0;

  // --- Nhấp nháy khi đợi ready (mới vào màn) ---
  /// Game set true khi _startDelayRemaining > 0; khi false thì không nhấp nháy.
  bool _waitingToStart = false;
  /// Thời gian tích lũy (giây) để tính chu kỳ ẩn/hiện.
  double _blinkPhase = 0;
  /// True = đang nửa chu kỳ “hiện”, false = nửa chu kỳ “ẩn”. Head/body/tail check qua [isBlinkVisible].
  bool _blinkVisible = true;

  late WormHead _head;
  final List<WormBodySegment> _bodySegments = [];
  late WormTail _tail;

  double? _cryEndTimeRemaining;

  // --- Item effects (buff/item đều là effect; [endTime] null = không hết hạn) ---
  final List<ItemEffectEntry> _itemEffects = [];
  double? _gameTime;

  List<ItemEffectEntry> get itemEffects => List.unmodifiable(_itemEffects);

  /// Có đang có effect [itemId] không.
  bool hasItemEffect(String itemId) =>
      _itemEffects.any((e) => e.itemId == itemId);

  /// Game gọi mỗi frame để worm có thể dùng (countdown, blink sắp hết, ...).
  void setGameTime(double t) => _gameTime = t;
  double? get gameTime => _gameTime;

  /// Thêm hoặc ghi đè effect [itemId]. [endTime] null = không hết hạn; có giá trị = hết hạn tại game time đó.
  void addItemEffect(String itemId, double? endTime) {
    final had = hasItemEffect(itemId);
    _itemEffects.removeWhere((e) => e.itemId == itemId);
    _itemEffects.add(ItemEffectEntry(itemId: itemId, endTime: endTime));
    if (!had) onItemEffectAdded(itemId);
  }

  /// Xóa các effect có [endTime] != null và endTime <= currentTime; gọi [onItemEffectRemoved] trước khi xóa.
  void removeExpiredItemEffects(double currentTime) {
    final toRemove = _itemEffects
        .where((e) => e.endTime != null && e.endTime! <= currentTime)
        .toList();
    for (final e in toRemove) {
      onItemEffectRemoved(e.itemId);
      _itemEffects.remove(e);
    }
  }

  /// Override (vd. PinkWorm): khi thêm effect, áp dụng visual/state (nón, ...).
  void onItemEffectAdded(String itemId) {}

  /// Override (vd. PinkWorm): khi effect hết hạn hoặc bị xóa.
  void onItemEffectRemoved(String itemId) {}

  /// Bật mặt khóc trên đầu trong 0.5s (khi trừ đốt).
  void showCryFace() {
    _cryEndTimeRemaining = 0.5;
    _syncVisuals();
  }

  /// Hướng hiện tại (đã áp next nếu có).
  WormDirection get currentDirection => _nextDirection ?? _direction;

  /// Số đốt (đầu + thân + đuôi).
  int get segmentCount => _gridPositions.length;
  /// Ô grid đuôi.
  Vector2 get tailGridPosition =>
      _gridPositions.isNotEmpty ? _gridPositions.last : Vector2.zero();
  /// Ô grid đầu.
  Vector2 get headGridPosition =>
      _gridPositions.isNotEmpty ? _gridPositions.first : Vector2.zero();

  /// Ô grid đầu sẽ tới sau bước di chuyển tiếp theo (để game check va chạm trước khi step).
  Vector2 peekNextHead() {
    if (_gridPositions.isEmpty) return Vector2.zero();
    final dir = _nextDirection ?? _direction;
    return _gridPositions.first + dir.toVector();
  }

  /// Danh sách tất cả ô grid (đầu → đuôi).
  List<Vector2> get allGridPositions => List.from(_gridPositions);

  /// Đổi kích thước mỗi đốt (gọi khi resize màn).
  void setSegmentSize(double s) {
    if (s <= 0) return;
    _segmentSize = s;
    _head.size.setValues(s, s);
    _tail.size.setValues(s, s);
    for (final seg in _bodySegments) seg.size.setValues(s, s);
  }

  @override
  /// Khởi tạo vị trí grid, tạo head + tail, chưa có body (body sinh khi step).
  Future<void> onLoad() async {
    final n = config.initialLength;
    final startX = (GameConfig.gridColumns / 2).floor() - n ~/ 2;
    final startY = (_gridRows / 2).floor();
    for (var i = n - 1; i >= 0; i--) {
      _gridPositions.add(Vector2((startX + i).toDouble(), startY.toDouble()));
    }
    _direction = WormDirection.right;
    _previousGridPositions = List.from(_gridPositions);

    _head = WormHead(
      config: config.headConfig,
      direction: _direction,
      segmentSize: _segmentSize,
      position: _gridToWorld(_gridPositions[0]),
    );
    add(_head);

    _tail = WormTail(
      config: config.tailConfig,
      direction: WormDirection.right,
      segmentSize: _segmentSize,
      position: _gridToWorld(_gridPositions[_gridPositions.length - 1]),
    );
    add(_tail);

    _syncVisuals();
  }

  /// Đổi tọa độ ô grid (0..cột, 0..hàng) sang tọa độ world trong component.
  Vector2 _gridToWorld(Vector2 grid) {
    final half = _segmentSize / 2;
    return Vector2(
      grid.x * _segmentSize + half,
      grid.y * _segmentSize + half,
    );
  }

  /// Đặt hướng cho bước tiếp theo; không cho quay ngược 180°.
  void setNextDirection(WormDirection d) {
    if (_direction == WormDirection.up && d == WormDirection.down) return;
    if (_direction == WormDirection.down && d == WormDirection.up) return;
    if (_direction == WormDirection.left && d == WormDirection.right) return;
    if (_direction == WormDirection.right && d == WormDirection.left) return;
    _nextDirection = d;
  }

  /// Đánh dấu thêm 1 đốt ở bước step tiếp theo (gọi khi ăn mồi).
  void grow() => _pendingGrow++;

  /// Bật/tắt nón (evil mode); [PinkWorm] override để đổi sprite.
  void setHasHelmet(bool value) {}

  /// Cắt 1 đốt ở đuôi (khi đâm tường/chướng ngại/đuôi).
  void removeTail() {
    if (_gridPositions.length <= 1) return;
    _gridPositions.removeLast();
    if (_previousGridPositions.length > _gridPositions.length) {
      _previousGridPositions.removeLast();
    }
    _syncVisuals();
  }

  /// Game gọi khi bắt đầu màn (true) hoặc hết delay (false). Khi false thì tắt nhấp nháy.
  void setWaitingToStart(bool value) {
    _waitingToStart = value;
    if (!value) {
      _blinkPhase = 0;
      _blinkVisible = true;
    }
  }

  /// Head/body/tail check trước khi vẽ: false = đang nửa chu kỳ ẩn → không vẽ.
  bool get isBlinkVisible => !_waitingToStart || _blinkVisible;

  /// Tiến độ di chuyển 0..1 giữa hai ô (để lerp vị trí đầu/đuôi mượt).
  void setVisualProgress(double t) {
    _visualProgress = t.clamp(0.0, 1.0);
  }

  /// Nội suy vị trí world giữa hai ô theo [_visualProgress].
  Vector2 _lerpWorld(Vector2 gridFrom, Vector2 gridTo) {
    final from = _gridToWorld(gridFrom);
    final to = _gridToWorld(gridTo);
    return from + (to - from) * _visualProgress;
  }

  /// Đổi vector (hướng) sang [WormDirection] (ưu tiên trục ngang nếu bằng).
  WormDirection _vectorToDirection(Vector2 v) {
    if (v.x.abs() >= v.y.abs()) {
      return v.x > 0 ? WormDirection.right : WormDirection.left;
    }
    return v.y > 0 ? WormDirection.down : WormDirection.up;
  }

  /// Cập nhật vị trí và hướng head/body/tail theo [_gridPositions] và [_visualProgress].
  void _syncVisuals() {
    if (_gridPositions.isEmpty) return;

    final headPrev = _previousGridPositions.isNotEmpty
        ? _previousGridPositions.first
        : _gridPositions.first;
    _head.position = _lerpWorld(headPrev, _gridPositions.first);
    _head.direction = _direction;
    _head.setShowCryFace(_cryEndTimeRemaining != null && _cryEndTimeRemaining! > 0);
    _head.angle = 0;

    final tailGrid = _gridPositions.last;
    final tailPrev = _previousGridPositions.length >= _gridPositions.length
        ? _previousGridPositions.last
        : tailGrid;
    _tail.position = _lerpWorld(tailPrev, tailGrid);
    if (_gridPositions.length >= 2) {
      final prev = _gridPositions[_gridPositions.length - 2];
      final diff = tailGrid - prev;
      if (diff.x > 0) {
        _tail.direction = WormDirection.right;
      } else if (diff.x < 0) {
        _tail.direction = WormDirection.left;
      } else if (diff.y > 0) {
        _tail.direction = WormDirection.down;
      } else {
        _tail.direction = WormDirection.up;
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
      final towardHead = _gridPositions[i - 1] - _gridPositions[i];
      final bodyDir = _vectorToDirection(towardHead);
      if (i - 1 < _bodySegments.length) {
        _bodySegments[i - 1].position = pos;
        _bodySegments[i - 1].setDirection(bodyDir);
      } else {
        final seg = WormBodySegment(
          config: config.bodyConfig,
          direction: bodyDir,
          segmentSize: _segmentSize,
          position: pos,
        );
        _bodySegments.add(seg);
        add(seg);
      }
    }
  }

  @override
  /// Cập nhật cry face, nhấp nháy (nếu đợi ready), và đồng bộ vị trí head/body/tail.
  void update(double dt) {
    super.update(dt);
    if (_cryEndTimeRemaining != null) {
      _cryEndTimeRemaining = _cryEndTimeRemaining! - dt;
      if (_cryEndTimeRemaining! <= 0) _cryEndTimeRemaining = null;
    }
    if (_waitingToStart) {
      _blinkPhase += dt;
      const period = 0.12; // ~0.06s hiện, ~0.06s ẩn — nháy rất nhanh
      _blinkVisible = (_blinkPhase % period) < period * 0.5;
    } else {
      _blinkVisible = true;
    }
    _syncVisuals();
  }

  @override
  void render(Canvas canvas) {
    // Đang nửa chu kỳ ẩn thì không vẽ (con head/body/tail cũng check [isBlinkVisible] nên cả giun ẩn).
    if (!isBlinkVisible) return;
    super.render(canvas);
  }

  /// Áp dụng [_nextDirection] thành [_direction] và đồng bộ vị trí (gọi trước khi xử lý va chạm).
  void applyNextDirectionAndSyncVisuals() {
    if (_nextDirection != null) {
      _direction = _nextDirection!;
      _nextDirection = null;
    }
    _syncVisuals();
  }

  /// Di chuyển 1 ô theo [_direction]: thêm đầu mới, bỏ đuôi (trừ khi [_pendingGrow] > 0). Trả về ô đầu mới.
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

/// Một item effect đang bật trên sâu. [endTime] null = không hết hạn.
class ItemEffectEntry {
  const ItemEffectEntry({required this.itemId, this.endTime});

  final String itemId;
  final double? endTime;
}
