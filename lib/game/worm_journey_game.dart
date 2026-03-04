import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/debug_grid_coordinates.dart';
import '../components/game_over_overlay.dart';
import '../components/grid_background.dart';
import '../components/prey.dart' show PreyType;
import '../components/pink_worm/snake_direction.dart';
import '../components/pink_worm/worm.dart';
import '../common/debug_apply.dart';
import '../config/config.dart';
import '../entities/entities.dart';
import '../core/buff/buff_config.dart';
import 'level_config.dart';
import 'obstacle_manager.dart';
import 'prey_manager.dart';
import 'worm_agents.dart';

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

  late WormAgent _playerAgent;
  Worm get _worm => _playerAgent.worm;

  late PreyManager _preyManager;
  late ObstacleManager _obstacleManager;

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

  /// Delay 1 giây khi mới vào: sâu không di chuyển, tránh nhấp nháy.
  static const double startDelaySeconds = 1.0;
  double _startDelayRemaining = startDelaySeconds;

  /// Thời gian chơi mặc định (giây). Đếm ngược từ 2 phút.
  static const double defaultTimeLimitSeconds = 120.0;
  double _timeLimit = defaultTimeLimitSeconds;

  /// Kim cương (sẽ load từ config sau).
  int _diamonds = 0;

  /// Nhiệm vụ: lá cây (hiện tại / mục tiêu). Sẽ load từ config sau.
  int _leavesCurrent = 0;
  int _leavesTarget = 10;

  /// Nhiệm vụ 2 (chưa dùng thì target = 0 → ẩn trên HUD). Sau load từ config / xử lý tương ứng.
  int _mission2Current = 0;
  int _mission2Target = 0;

  /// HP boss (sẽ load từ config sau). Hiển thị dạng icon x4.
  int _bossHp = 4;
  static const int _bossHpMax = 4;

  /// Chướng ngại: quản lý qua [ObstacleManager] (nhiều loại, dễ mở rộng).

  double _segmentSize = 28.0;
  int _gridRows = GameConfig.gridRows;
  late GridBackground _gridBackground;

  /// Overlay tọa độ ô (A1, B1...) chỉ khi kDebugMode.
  DebugGridCoordinates? _debugGridCoordinates;

  /// Camera Y đang lerp (làm mượt, tránh giật).
  double? _cameraY;

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
    _worm.setHasHelmet(true);
    _devilBlinkAccumulator = 0;
    _devilBlinkShowEvil = true;
    _worm.addBuff(itemId, _gameTime + duration);
  }

  /// Tăng tiến độ nhiệm vụ 2 (gọi khi player thực hiện hành động tương ứng). Sau load config có thể có thêm mission 3, 4...
  void addMission2Progress() {
    _mission2Current = (_mission2Current + 1).clamp(0, _mission2Target);
  }

  /// Gán mục tiêu nhiệm vụ 2 (từ config / level). > 0 thì mới hiện trên HUD.
  void setMission2Target(int target) {
    _mission2Target = target.clamp(0, 9999);
    _mission2Current = _mission2Current.clamp(0, _mission2Target);
  }

  /// Gọi từ nút/joystick — chỉ đổi hướng cho bước tiếp theo, không ép step ngay.
  /// Rắn sẽ quay khi tới đúng thời điểm step (tránh nhảy ô vì step sớm).
  void setDirection(SnakeDirection d) {
    if (_gameOver || !_loaded) return;
    final current = _worm.currentDirection;
    if (d == current || d.isOppositeOf(current)) return;
    _worm.setNextDirection(d);
  }

  /// Vùng chơi: A13–X49 (cột A–X, hàng 13–49). Chỉ vùng này là grid; ngoài ra trắng + 🟫.
  /// Camera chỉ hở thêm ~5 ô trên/dưới, không hở nhiều bên ngoài.
  static const int _extraRowsAboveBelow = 5;
  static const int playableStartRow = _extraRowsAboveBelow; // 5
  static const int playableRowCount = 37;  // 13..49
  static const int totalWorldRows = _extraRowsAboveBelow + playableRowCount + _extraRowsAboveBelow; // 47

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    final byWidth = size.x / GameConfig.gridColumns;
    _segmentSize = byWidth;
    _gridRows = playableRowCount;
    camera.viewport = FixedResolutionViewport(resolution: size);
    if (_loaded) {
      _worm.setSegmentSize(_segmentSize);
      _worm.position = Vector2(0, playableStartRow * _segmentSize);
      _gridBackground.updateGrid(
        _segmentSize,
        GameConfig.gridColumns,
        totalWorldRows,
        playableStartRow,
        playableRowCount,
      );
      _debugGridCoordinates?.updateGrid(
        _segmentSize,
        GameConfig.gridColumns,
        playableRowCount,
      );
      _debugGridCoordinates?.position = Vector2(0, playableStartRow * _segmentSize);
    }
  }

  @override
  Future<void> onLoad() async {
    _gridRows = playableRowCount;
    camera.viewport = MaxViewport();
    final gridColors = LevelConfig.colorsFor(level);
    _gridBackground = GridBackground(
      segmentSize: _segmentSize,
      gridColumns: GameConfig.gridColumns,
      totalWorldRows: totalWorldRows,
      playableStartRow: playableStartRow,
      playableRowCount: playableRowCount,
      colors: gridColors,
    );
    world.add(_gridBackground);

    _obstacleManager = ObstacleManager(
      segmentSize: _segmentSize,
      gridToWorld: _gridToWorld,
    );
    _preyManager = PreyManager(
      segmentSize: _segmentSize,
      gridColumns: GameConfig.gridColumns,
      gridRows: _gridRows,
      gridToWorld: _gridToWorld,
    );

    final worm = Worm(
      segmentSize: _segmentSize,
      moveInterval: GameConfig.moveInterval,
      gridRows: _gridRows,
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * _segmentSize),
    );
    world.add(worm);
    _playerAgent = WormAgent(worm: worm, info: WormInfo.playerDefault);

    _spawnPrey();

    if (kDebugMode) {
      _debugGridCoordinates = DebugGridCoordinates(
        segmentSize: _segmentSize,
        gridColumns: GameConfig.gridColumns,
        gridRows: playableRowCount,
      );
      _debugGridCoordinates!.position = Vector2(0, playableStartRow * _segmentSize);
      _debugGridCoordinates!.size = Vector2(
        GameConfig.gridColumns * _segmentSize,
        playableRowCount * _segmentSize,
      );
      world.add(_debugGridCoordinates!);
    }

    _loaded = true;
  }

  Set<String> _occupiedGridKeys() {
    return _preyManager.occupiedGridKeys(
      snakePositions: _worm.allGridPositions,
      obstaclePositions: _obstacleManager.gridPositions,
    );
  }

  void _spawnPrey() {
    final occupied = _occupiedGridKeys();
    final entry = _preyManager.spawn(PreyType.leaf, occupied);
    if (entry != null) world.add(entry.component);
  }

  void _spawnApple() {
    if (_preyManager.entries.any((e) => e.type == PreyType.apple)) return;
    final occupied = _occupiedGridKeys();
    final entry = _preyManager.spawn(PreyType.apple, occupied);
    if (entry != null) world.add(entry.component);
  }

  /// Chuyển ô logic (0..23, 0..36) sang tọa độ world. A1 = vị trí cũ A13.
  Vector2 _gridToWorld(Vector2 grid) {
    final half = _segmentSize / 2;
    return Vector2(
      grid.x * _segmentSize + half,
      (grid.y + playableStartRow) * _segmentSize + half,
    );
  }

  /// Tốc độ làm mượt camera (càng lớn càng bám nhanh). ~6 = mượt, ~15 = bám gần ngay.
  static const double _cameraSmoothSpeed = 8.0;

  /// Di chuyển camera theo đầu rắn (trục Y), lerp mượt. Không cho camera xuống quá hàng 37 (cuối vùng chơi).
  void _updateCameraFollowSnake(double dt) {
    if (!_loaded) return;
    final viewportSize = camera.viewport.size;
    final worldWidth = GameConfig.gridColumns * _segmentSize;
    final halfViewY = viewportSize.y / 2;
    final bottomOfPlayable = (playableStartRow + playableRowCount) * _segmentSize;
    final maxCameraY = bottomOfPlayable - halfViewY;

    final headWorld = _gridToWorld(_worm.headGridPosition);
    final targetY = headWorld.y.clamp(halfViewY, maxCameraY.clamp(halfViewY, double.infinity));

    final current = _cameraY ?? targetY;
    final smoothFactor = 1.0 - exp(-_cameraSmoothSpeed * dt);
    _cameraY = current + (targetY - current) * smoothFactor;

    camera.viewfinder.position = Vector2(worldWidth / 2, _cameraY!);
  }

  void _setGameOver() {
    if (_gameOver) return;
    _gameOver = true;
    final sz = camera.viewport.size;
    // Thêm vào viewport → tọa độ đúng viewport, vẽ đè lên; có onTap để chạm tắt và chơi lại.
    camera.viewport.add(GameOverOverlay(
      size: Vector2(sz.x, sz.y),
      locale: ui.PlatformDispatcher.instance.locale,
      onTap: _restart,
    ));
  }

  void _restart() {
    for (final c in camera.viewport.children.whereType<GameOverOverlay>().toList()) {
      c.removeFromParent();
    }
    _worm.removeFromParent();
    for (final e in _preyManager.entries) e.component.removeFromParent();
    _preyManager.clear();
    for (final e in _obstacleManager.entries) e.component.removeFromParent();
    _obstacleManager.clear();

    final worm = Worm(
      segmentSize: _segmentSize,
      moveInterval: GameConfig.moveInterval,
      gridRows: _gridRows,
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * _segmentSize),
    );
    world.add(worm);
    _playerAgent = WormAgent(worm: worm, info: WormInfo.playerDefault);

    _spawnPrey();

    _appleSpawnAccumulator = 0;
    _gameTime = 0;
    _wasInDevilMode = false;
    _startDelayRemaining = startDelaySeconds;
    _timeLimit = defaultTimeLimitSeconds;
    _leavesCurrent = 0;
    _mission2Current = 0;

    _gameOver = false;
    _paused = false;
    _moveAccumulator = 0;
    _cameraY = null;
  }

  /// Trừ 1 đốt đuôi và để lại chướng ngại tại vị trí đuôi (type X, sau có thể config).
  void _loseSegment() {
    _worm.showCryFace();
    final tailGrid = _worm.tailGridPosition;
    _worm.removeTail();
    final comp = _obstacleManager.createComponent(ObstacleType.xMark, tailGrid);
    _obstacleManager.add(tailGrid, ObstacleType.xMark, comp);
    world.add(comp);
    if (_worm.segmentCount <= 2) _setGameOver();
  }

  /// Phá chướng ngại tại ô [grid] (vd. khi đang 😈 có buff phá được).
  void _destroyObstacleAt(Vector2 grid) {
    final entry = _obstacleManager.removeAt(grid);
    if (entry != null) entry.component.removeFromParent();
  }

  /// Buff coconut đang bật (sau khi đã removeExpiredBuffs). Dùng cho evil mode + phá vật cản.
  WormBuffEntry? _coconutBuff() {
    final list = _worm.buffEffects.where((b) => b.itemId == 'coconut').toList();
    return list.isEmpty ? null : list.first;
  }

  /// Có buff [itemId] đang bật không (dùng chung cho obstacle behavior).
  bool _hasBuff(String itemId) =>
      _worm.buffEffects.any((b) => b.itemId == itemId);

  /// Xử lý chung khi đầu chạm vùng nguy hiểm: tường, chướng ngại, đuôi hoặc thân.
  /// Thân và đuôi/tường/X: trừ 1 đốt + để lại dấu X. Chỉ game over khi còn ≤ 2 đốt.
  /// Gọi applyNextDirectionAndSyncVisuals trước để đầu quay đúng hướng đâm.
  bool _onHitHazard(HazardType type, Vector2 nextHead) {
    _worm.applyNextDirectionAndSyncVisuals();
    switch (type) {
      case HazardType.wall:
      case HazardType.tail:
      case HazardType.body:
        _loseSegment();
        return true;
      case HazardType.obstacle: {
        final entry = _obstacleManager.getAt(nextHead);
        if (entry == null) return true;
        final behavior = ObstacleManager.behaviorFor(entry.type);
        if (behavior.buffIdToDestroy != null && _hasBuff(behavior.buffIdToDestroy!)) {
          _destroyObstacleAt(nextHead);
          _worm.step();
        } else if (behavior.loseSegmentIfNotDestroyed) {
          _loseSegment();
        }
        return true;
      }
    }
  }

  /// Dữ liệu HUD (cập nhật trong lúc chơi). Cấu trúc sẵn để sau load từ JSON.
  /// Chỉ đưa nhiệm vụ có target > 0 vào [missions] (chưa có thì ẩn).
  /// Trả về giá trị mặc định khi game chưa load (tránh LateInitializationError khi GameHud build trước onLoad).
  GameHudData get hudData {
    if (!_loaded) {
      return GameHudData(
        timeRemainingSeconds: _timeLimit,
        diamonds: _diamonds,
        missions: [
          GameHudMission(id: 'leaves', label: 'Lá cây', current: 0, target: _leavesTarget, icon: '🍃'),
        ],
        bossHp: _bossHp,
        bossHpMax: _bossHpMax,
        itemBuffs: const [],
        startDelayRemaining: _startDelayRemaining,
      );
    }
    final missions = <GameHudMission>[
      GameHudMission(
        id: 'leaves',
        label: 'Lá cây',
        current: _leavesCurrent,
        target: _leavesTarget,
        icon: '🍃',
      ),
    ];
    if (_mission2Target > 0) {
      missions.add(GameHudMission(
        id: 'mission2',
        label: 'Nhiệm vụ 2',
        current: _mission2Current,
        target: _mission2Target,
        icon: null,
      ));
    }
    return GameHudData(
      timeRemainingSeconds: (_timeLimit - _gameTime).clamp(0.0, _timeLimit),
      diamonds: _diamonds,
      missions: missions,
      bossHp: _bossHp,
      bossHpMax: _bossHpMax,
      itemBuffs: _worm.buffEffects
          .map((e) => GameHudItemBuff(
                itemId: e.itemId,
                remainingSeconds: (e.endTime - _gameTime).clamp(0.0, double.infinity),
              ))
          .toList(),
      startDelayRemaining: _startDelayRemaining,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_loaded) _updateCameraFollowSnake(dt);
    if (_gameOver) return;
    if (_paused) return;

    _worm.setWaitingToStart(_startDelayRemaining > 0);
    if (_startDelayRemaining > 0) {
      _startDelayRemaining -= dt;
      return;
    }

    _gameTime += dt;

    _worm.removeExpiredBuffs(_gameTime);

    final coconut = _coconutBuff();
    if (coconut == null) {
      _worm.setHasHelmet(false);
      if (_wasInDevilMode) _appleSpawnAccumulator = 0;
      _devilBlinkAccumulator = 0;
    } else {
      final timeLeft = coconut.endTime - _gameTime;
      if (timeLeft <= _devilBlinkLastSeconds && timeLeft > 0) {
        _devilBlinkAccumulator += dt;
        if (_devilBlinkAccumulator >= 0.15) {
          _devilBlinkAccumulator = 0;
          _devilBlinkShowEvil = !_devilBlinkShowEvil;
          _worm.setHasHelmet(_devilBlinkShowEvil);
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

    final interval = _worm.moveInterval;
    final progress = (_moveAccumulator / interval).clamp(0.0, 1.0);
    _worm.setVisualProgress(progress);

    _moveAccumulator += dt;
    if (_moveAccumulator < interval) return;
    _moveAccumulator -= interval;

    final nextHead = _worm.peekNextHead();

    final outOfBounds = nextHead.x < 0 ||
        nextHead.x >= GameConfig.gridColumns ||
        nextHead.y < 0 ||
        nextHead.y >= _gridRows;

    if (outOfBounds) {
      _onHitHazard(HazardType.wall, nextHead);
      return;
    }

    if (_obstacleManager.hasObstacleAt(nextHead)) {
      _onHitHazard(HazardType.obstacle, nextHead);
      return;
    }

    final tailGrid = _worm.tailGridPosition;
    final hitTail =
        nextHead.x == tailGrid.x && nextHead.y == tailGrid.y;
    if (hitTail) {
      _onHitHazard(HazardType.tail, nextHead);
      return;
    }

    final body = _worm.allGridPositions;
    for (var i = 1; i < body.length - 1; i++) {
      if (body[i].x == nextHead.x && body[i].y == nextHead.y) {
        _onHitHazard(HazardType.body, nextHead);
        return;
      }
    }

    _worm.step();

    final newHead = _worm.headGridPosition;
    final consumed = _preyManager.consumeAt(newHead);
    if (consumed != null) {
      consumed.component.removeFromParent();
      _worm.grow();
      switch (consumed.type) {
        case PreyType.leaf:
          _leavesCurrent = (_leavesCurrent + 1).clamp(0, _leavesTarget);
          _spawnPrey();
          break;
        case PreyType.apple:
          const itemId = 'coconut';
          final duration = BuffConfig.durationSecondsFor(itemId);
          if (duration > 0) {
            _worm.setHasHelmet(true);
            _worm.addBuff(itemId, _gameTime + duration);
          }
          break;
      }
      return;
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
      _worm.setNextDirection(SnakeDirection.up);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _worm.setNextDirection(SnakeDirection.down);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _worm.setNextDirection(SnakeDirection.left);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _worm.setNextDirection(SnakeDirection.right);
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
    if (shouldApplyDebug) {
      _paused = !_paused;
    }
  }
}

/// Một nhiệm vụ trên HUD (x/xx). Target = 0 thì không hiển thị.
class GameHudMission {
  const GameHudMission({
    required this.id,
    required this.label,
    required this.current,
    required this.target,
    this.icon,
  });

  final String id;
  final String label;
  final int current;
  final int target;
  /// Icon optional (emoji hoặc asset), null thì chỉ hiện label.
  final String? icon;
}

/// Dữ liệu HUD (sẽ load từ JSON config sau). Cập nhật trong lúc chơi.
class GameHudData {
  const GameHudData({
    required this.timeRemainingSeconds,
    required this.diamonds,
    required this.missions,
    required this.bossHp,
    required this.bossHpMax,
    required this.itemBuffs,
    required this.startDelayRemaining,
  });

  final double timeRemainingSeconds;
  final int diamonds;
  /// Nhiệm vụ (lá cây, nhiệm vụ 2, ...). Chỉ chứa mission có target > 0.
  final List<GameHudMission> missions;
  final int bossHp;
  final int bossHpMax;
  final List<GameHudItemBuff> itemBuffs;
  final double startDelayRemaining;
}

class GameHudItemBuff {
  const GameHudItemBuff({
    required this.itemId,
    required this.remainingSeconds,
  });

  final String itemId;
  final double remainingSeconds;
}
