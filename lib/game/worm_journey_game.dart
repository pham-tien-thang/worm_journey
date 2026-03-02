import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/game_over_overlay.dart';
import '../components/grid_background.dart';
import '../components/prey.dart' show Prey, PreyType;
import '../components/snake/snake.dart';
import '../components/snake/snake_direction.dart';
import '../components/x_obstacle.dart';
import '../config/config.dart';
import '../core/buff/buff_config.dart';
import 'level_config.dart';

/// Loại va chạm nguy hiểm: tường, chướng ngại X, đuôi rắn, thân rắn.
enum HazardType {
  wall,
  obstacle,
  tail,
  body,
}

/// Game rắn săn mồi. Full màn hình. Đâm tường/đuôi trừ 1 đốt; còn đầu+đuôi thì thua.
class WormJourneyGame extends FlameGame
    with KeyboardEvents, TapCallbacks, HasCollisionDetection {
  WormJourneyGame({this.level = 1}) : super();

  final int level;

  @override
  Color backgroundColor() => const Color(0xFF1B3D2E);

  late Snake _snake;
  late Prey _prey;
  Vector2 _preyGrid = Vector2.zero();
  Prey? _applePrey;
  Vector2? _applePreyGrid;
  double _appleSpawnAccumulator = 0;
  static const double _appleSpawnInterval = 10.0;

  double _gameTime = 0;
  static const double _devilBlinkLastSeconds = 3.0;
  double _devilBlinkAccumulator = 0;
  bool _devilBlinkShowEvil = true;
  bool _wasInDevilMode = false;

  double _moveAccumulator = 0;
  bool _gameOver = false;
  bool _paused = false;
  bool _loaded = false;

  /// Chướng ngại X để lại khi mất đuôi (vị trí lưới).
  final List<Vector2> _obstacles = [];
  final List<XObstacle> _obstacleComponents = [];

  double _segmentSize = 28.0;
  int _gridRows = GameConfig.gridRows;
  late GridBackground _gridBackground;

  /// Pause / resume (vd. khi mở/đóng dialog).
  void setPaused(bool value) {
    _paused = value;
  }

  /// Gọi khi dùng item (vd. quả dừa) — bật evil mode theo BuffConfig, lưu buff vào sâu.
  void triggerDevilModeByItem() {
    if (_gameOver || !_loaded) return;
    const itemId = 'coconut';
    final duration = BuffConfig.durationSecondsFor(itemId);
    if (duration <= 0) return;
    _snake.setHasHelmet(true);
    _devilBlinkAccumulator = 0;
    _devilBlinkShowEvil = true;
    _snake.addBuff(itemId, _gameTime + duration);
  }

  /// Gọi từ nút/joystick — đổi hướng và kích hoạt bước ngay (không delay).
  /// Nếu đang đi đúng hướng đó rồi thì không làm gì.
  void setDirection(SnakeDirection d) {
    if (_gameOver || !_loaded) return;
    if (d == _snake.currentDirection) return;
    _snake.setNextDirection(d);
    _moveAccumulator = _snake.moveInterval;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    final byWidth = size.x / GameConfig.gridColumns;
    _segmentSize = byWidth;
    _gridRows = (size.y / _segmentSize).floor();
    if (_gridRows < GameConfig.gridRows) _gridRows = GameConfig.gridRows;
    camera.viewport = FixedResolutionViewport(resolution: size);
    if (_loaded) {
      _snake.setSegmentSize(_segmentSize);
      _gridBackground.updateGrid(
        _segmentSize,
        GameConfig.gridColumns,
        _gridRows,
      );
    }
  }

  @override
  Future<void> onLoad() async {
    camera.viewport = MaxViewport();
    final gridColors = LevelConfig.colorsFor(level);
    _gridBackground = GridBackground(
      segmentSize: _segmentSize,
      gridColumns: GameConfig.gridColumns,
      gridRows: _gridRows,
      colors: gridColors,
    );
    add(_gridBackground);

    _snake = Snake(
      segmentSize: _segmentSize,
      moveInterval: GameConfig.moveInterval,
      gridRows: _gridRows,
    );
    add(_snake);

    _prey = Prey(
      segmentSize: _segmentSize,
      type: PreyType.leaf,
      position: Vector2.zero(),
    );
    _spawnPrey();

    _loaded = true;
  }

  Set<String> _occupiedGridKeys() {
    final occupied = _snake.allGridPositions
        .map((v) => '${v.x.toInt()},${v.y.toInt()}')
        .toSet();
    occupied.add('${_preyGrid.x.toInt()},${_preyGrid.y.toInt()}');
    if (_applePreyGrid != null) {
      occupied.add('${_applePreyGrid!.x.toInt()},${_applePreyGrid!.y.toInt()}');
    }
    for (final o in _obstacles) {
      occupied.add('${o.x.toInt()},${o.y.toInt()}');
    }
    return occupied;
  }

  void _spawnPrey() {
    if (_prey.parent != null) _prey.removeFromParent();
    final occupied = _occupiedGridKeys();
    var pos = Vector2(
      Random().nextInt(GameConfig.gridColumns).toDouble(),
      Random().nextInt(_gridRows).toDouble(),
    );
    for (var i = 0; i < 100; i++) {
      if (!occupied.contains('${pos.x.toInt()},${pos.y.toInt()}')) break;
      pos = Vector2(
        Random().nextInt(GameConfig.gridColumns).toDouble(),
        Random().nextInt(_gridRows).toDouble(),
      );
    }
    _preyGrid = pos;
    _prey = Prey(
      segmentSize: _segmentSize,
      type: PreyType.leaf,
      position: _gridToWorld(pos),
    );
    add(_prey);
  }

  void _spawnApple() {
    if (_applePreyGrid != null) return;
    final occupied = _occupiedGridKeys();
    var pos = Vector2(
      Random().nextInt(GameConfig.gridColumns).toDouble(),
      Random().nextInt(_gridRows).toDouble(),
    );
    for (var i = 0; i < 100; i++) {
      if (!occupied.contains('${pos.x.toInt()},${pos.y.toInt()}')) break;
      pos = Vector2(
        Random().nextInt(GameConfig.gridColumns).toDouble(),
        Random().nextInt(_gridRows).toDouble(),
      );
    }
    _applePreyGrid = pos;
    _applePrey = Prey(
      segmentSize: _segmentSize,
      type: PreyType.apple,
      position: _gridToWorld(pos),
    );
    add(_applePrey!);
  }

  Vector2 _gridToWorld(Vector2 grid) {
    final half = _segmentSize / 2;
    return Vector2(
      grid.x * _segmentSize + half,
      grid.y * _segmentSize + half,
    );
  }

  void _setGameOver() {
    if (_gameOver) return;
    _gameOver = true;
    final sz = camera.viewport.size;
    add(GameOverOverlay(size: Vector2(sz.x, sz.y)));
  }

  void _restart() {
    for (final c in children.whereType<GameOverOverlay>().toList()) {
      c.removeFromParent();
    }
    _snake.removeFromParent();
    _prey.removeFromParent();
    for (final c in _obstacleComponents) {
      c.removeFromParent();
    }
    _obstacles.clear();
    _obstacleComponents.clear();

    _snake = Snake(
      segmentSize: _segmentSize,
      moveInterval: GameConfig.moveInterval,
      gridRows: _gridRows,
    );
    add(_snake);

    _prey = Prey(
      segmentSize: _segmentSize,
      type: PreyType.leaf,
      position: Vector2.zero(),
    );
    _spawnPrey();

    if (_applePrey != null) {
      _applePrey!.removeFromParent();
      _applePrey = null;
      _applePreyGrid = null;
    }
    _appleSpawnAccumulator = 0;
    _gameTime = 0;
    _wasInDevilMode = false;

    _gameOver = false;
    _paused = false;
    _moveAccumulator = 0;
  }

  /// Trừ 1 đốt đuôi và để lại chướng ngại X tại vị trí đuôi.
  void _loseSegment() {
    final tailGrid = _snake.tailGridPosition;
    _snake.removeTail();
    final comp = XObstacle(
      segmentSize: _segmentSize,
      position: _gridToWorld(tailGrid),
    );
    _obstacles.add(Vector2(tailGrid.x, tailGrid.y));
    _obstacleComponents.add(comp);
    add(comp);
    if (_snake.segmentCount <= 2) _setGameOver();
  }

  /// Phá dấu X tại ô [grid] (khi đang 😈).
  void _destroyObstacleAt(Vector2 grid) {
    for (var i = 0; i < _obstacles.length; i++) {
      if (_obstacles[i].x == grid.x && _obstacles[i].y == grid.y) {
        _obstacles.removeAt(i);
        _obstacleComponents[i].removeFromParent();
        _obstacleComponents.removeAt(i);
        return;
      }
    }
  }

  /// Buff coconut đang bật (sau khi đã removeExpiredBuffs). Dùng cho evil mode + phá vật cản.
  SnakeBuffEntry? _coconutBuff() {
    final list = _snake.buffEffects.where((b) => b.itemId == 'coconut').toList();
    return list.isEmpty ? null : list.first;
  }

  /// Xử lý chung khi đầu chạm vùng nguy hiểm: tường, chướng ngại, đuôi hoặc thân.
  /// Thân và đuôi/tường/X: trừ 1 đốt + để lại dấu X. Chỉ game over khi còn ≤ 2 đốt.
  bool _onHitHazard(HazardType type, Vector2 nextHead) {
    switch (type) {
      case HazardType.wall:
      case HazardType.tail:
      case HazardType.body:
        _loseSegment();
        return true;
      case HazardType.obstacle:
        if (_coconutBuff() != null) {
          _destroyObstacleAt(nextHead);
          _snake.step();
        } else {
          _loseSegment();
        }
        return true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) return;
    if (_paused) return;

    _gameTime += dt;

    _snake.removeExpiredBuffs(_gameTime);

    final coconut = _coconutBuff();
    if (coconut == null) {
      _snake.setHasHelmet(false);
      if (_wasInDevilMode) _appleSpawnAccumulator = 0;
      _devilBlinkAccumulator = 0;
    } else {
      final timeLeft = coconut.endTime - _gameTime;
      if (timeLeft <= _devilBlinkLastSeconds && timeLeft > 0) {
        _devilBlinkAccumulator += dt;
        if (_devilBlinkAccumulator >= 0.15) {
          _devilBlinkAccumulator = 0;
          _devilBlinkShowEvil = !_devilBlinkShowEvil;
          _snake.setHasHelmet(_devilBlinkShowEvil);
        }
      }
    }

    if (coconut == null) {
      _appleSpawnAccumulator += dt;
      if (_appleSpawnAccumulator >= _appleSpawnInterval) {
        _appleSpawnAccumulator -= _appleSpawnInterval;
        _spawnApple();
      }
    }
    _wasInDevilMode = coconut != null;

    final interval = _snake.moveInterval;
    final progress = (_moveAccumulator / interval).clamp(0.0, 1.0);
    _snake.setVisualProgress(progress);

    _moveAccumulator += dt;
    if (_moveAccumulator < interval) return;
    _moveAccumulator -= interval;

    final nextHead = _snake.peekNextHead();

    final outOfBounds = nextHead.x < 0 ||
        nextHead.x >= GameConfig.gridColumns ||
        nextHead.y < 0 ||
        nextHead.y >= _gridRows;

    if (outOfBounds) {
      _onHitHazard(HazardType.wall, nextHead);
      return;
    }

    final hitObstacle = _obstacles.any(
        (o) => o.x == nextHead.x && o.y == nextHead.y);
    if (hitObstacle) {
      _onHitHazard(HazardType.obstacle, nextHead);
      return;
    }

    final tailGrid = _snake.tailGridPosition;
    final hitTail =
        nextHead.x == tailGrid.x && nextHead.y == tailGrid.y;
    if (hitTail) {
      _onHitHazard(HazardType.tail, nextHead);
      return;
    }

    final body = _snake.allGridPositions;
    for (var i = 1; i < body.length - 1; i++) {
      if (body[i].x == nextHead.x && body[i].y == nextHead.y) {
        _onHitHazard(HazardType.body, nextHead);
        return;
      }
    }

    _snake.step();

    final newHead = _snake.headGridPosition;

    if (newHead.x == _preyGrid.x && newHead.y == _preyGrid.y) {
      _snake.grow();
      _spawnPrey();
      return;
    }

    if (_applePreyGrid != null &&
        newHead.x == _applePreyGrid!.x &&
        newHead.y == _applePreyGrid!.y) {
      _snake.grow();
      const itemId = 'coconut';
      final duration = BuffConfig.durationSecondsFor(itemId);
      if (duration > 0) {
        _snake.setHasHelmet(true);
        _snake.addBuff(itemId, _gameTime + duration);
      }
      _applePrey?.removeFromParent();
      _applePrey = null;
      _applePreyGrid = null;
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_gameOver) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _snake.setNextDirection(SnakeDirection.up);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _snake.setNextDirection(SnakeDirection.down);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _snake.setNextDirection(SnakeDirection.left);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _snake.setNextDirection(SnakeDirection.right);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_gameOver) {
      _restart();
      return;
    }
    if (kDebugMode) {
      _paused = !_paused;
    }
  }

}
