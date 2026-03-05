import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/debug_grid_coordinates.dart';
import '../../../components/grid_background.dart';
import '../../../components/pink_worm/pink_worm.dart';
import '../../../components/pink_worm/pink_worm_config.dart';
import '../../../components/worm/worm.dart';
import '../../../components/worm/worm_direction.dart';
import '../../../common/debug_apply.dart';
import '../../../config/config.dart';
import '../../../models/item_model.dart';
import '../../../entities/entities.dart';
import '../../../core/buff/buff_config.dart';
import '../../config/level_json_config.dart';
import '../../config/type_obj_config.dart';
import '../../entities/entity_models.dart';
import '../../managers/map_entity_manager.dart';
import '../../behavior/player_worm_behavior.dart';
import '../../behavior/worm_agents.dart';
import '../../behavior/worm_behavior.dart';
import '../../context/worm_game_context.dart';

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
  WormJourneyGame({this.level = 1});

  final int level;

  @override
  Color backgroundColor() => const Color(0xFF1B3D2E);

  late WormAgent _playerAgent;
  /// Con sâu được điều khiển và lấy thông tin lên HUD.
  Worm get mainWorm => _playerAgent.worm;

  late WormGameContext _wormContext;
  late TypeObjConfig _typeObjConfig;
  late MapEntityManager _mapEntityManager;

  double _appleSpawnAccumulator = 0;
  static const double _appleSpawnInterval = 10.0;

  /// Thời gian đã chơi (giây), tăng mỗi frame. Dùng cho buff expiry, HUD còn lại = [ _timeLimit ] - [_gameTime].
  double _gameTime = 0;

  double _moveAccumulator = 0;
  bool _gameOver = false;
  bool _paused = false;
  bool _loaded = false;

  /// Delay khi mới vào (sâu nhấp nháy). Hiện chưa đưa vào config; mặc định 1s.
  static const double startDelaySeconds = 1.0;
  double _startDelayRemaining = startDelaySeconds;

  /// Thời gian chơi tối đa (giây), từ [ _levelConfig.timeLimitSeconds ]. Ghi đè trong onLoad và _restart.
  double _timeLimit = 120.0;

  /// Config màn load từ JSON (level_1.json, level_2.json, ...).
  late LevelJsonConfig _levelConfig;
  /// Nhiệm vụ từ config; [ _missionCurrents[i] ] = tiến độ của [ _missionConfigs[i] ].
  List<MissionConfig> _missionConfigs = const [MissionConfig.defaultLeaves];
  List<int> _missionCurrents = [0];
  /// Ghi đè target theo id (vd. setMission2Target gọi khi load level).
  final Map<String, int> _missionTargetOverrides = {};

  double _segmentSize = 28.0;
  int _gridRows = GameConfig.gridRows;
  late GridBackground _gridBackground;

  /// Overlay tọa độ ô (A1, B1...) chỉ khi kDebugMode.
  DebugGridCoordinates? _debugGridCoordinates;

  /// Camera Y đang lerp (làm mượt, tránh giật).
  double? _cameraY;

  /// Factory đặt entity tại ô: typeId (từ JSON) → hàm (grid). Mọi loại dùng chung [MapEntityManager.placeAt].
  final Map<String, void Function(Vector2 grid)> _placeEntityAt = {};

  /// Pause / resume (vd. khi mở/đóng dialog).
  void setPaused(bool value) {
    _paused = value;
  }

  /// Dùng item dừa: thêm buff (ProjectType.preyCoconut) +1 độ cứng. Hết thời gian buff thì độ cứng về base.
  void useEffect(ItemType type) {
    if (_gameOver || !_loaded) return;
    final duration = BuffConfig.durationSecondsFor(type.effectTypeId);
    if (duration <= 0) return;
    mainWorm.addItemEffect(type.effectTypeId, _gameTime + duration);
  }

  /// Tăng tiến độ nhiệm vụ có [id] (mặc định 'mission2').
  void addMission2Progress() {
    final i = _missionConfigs.indexWhere((m) => m.id == 'mission2');
    if (i >= 0 && i < _missionCurrents.length) {
      final target = _missionTargetOverrides['mission2'] ?? _missionConfigs[i].target;
      _missionCurrents[i] = (_missionCurrents[i] + 1).clamp(0, target);
    }
  }

  /// Ghi đè mục tiêu nhiệm vụ theo id (vd. 'mission2'). > 0 thì hiện trên HUD; nếu chưa có mission đó thì thêm vào.
  void setMission2Target(int target) {
    final t = target.clamp(0, 9999);
    if (t <= 0) return;
    _missionTargetOverrides['mission2'] = t;
    if (_missionConfigs.every((m) => m.id != 'mission2')) {
      _missionConfigs = [..._missionConfigs, const MissionConfig(id: 'mission2', typeId: 'prey_leaf', target: 0)];
      _missionCurrents = [..._missionCurrents, 0];
    }
  }

  /// Gọi từ nút/joystick — chỉ đổi hướng cho bước tiếp theo, không ép step ngay.
  /// Rắn sẽ quay khi tới đúng thời điểm step (tránh nhảy ô vì step sớm).
  void setDirection(WormDirection d) {
    if (_gameOver || !_loaded) return;
    final current = mainWorm.currentDirection;
    if (d == current || d.isOppositeOf(current)) return;
    mainWorm.setNextDirection(d);
  }

  /// Vùng chơi: A13–X49 (cột A–X, hàng 13–49). Chỉ vùng này là grid; ngoài ra trắng + 🟫.
  /// Camera chỉ hở thêm ~6 ô trên/dưới (outside), không hở nhiều bên ngoài.
  static const int _extraRowsAboveBelow = 6;
  static const int playableStartRow = _extraRowsAboveBelow; // 6
  static const int playableRowCount = 37;  // 13..49
  static const int totalWorldRows = _extraRowsAboveBelow + playableRowCount + _extraRowsAboveBelow; // 49

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    final byWidth = size.x / GameConfig.gridColumns;
    _segmentSize = byWidth;
    _gridRows = playableRowCount;
    camera.viewport = FixedResolutionViewport(resolution: size);
    if (_loaded) {
      mainWorm.setSegmentSize(_segmentSize);
      mainWorm.position = Vector2(0, playableStartRow * _segmentSize);
      _gridBackground.updateGrid(
        _segmentSize,
        GameConfig.gridColumns,
        totalWorldRows,
        playableStartRow,
        playableRowCount,
        outsideColor: _levelConfig.outsideConfig.color,
        outsideIcon: _levelConfig.outsideConfig.icon,
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

    _levelConfig = await loadLevelJsonConfig(level);
    _typeObjConfig = await TypeObjConfig.load();
    _missionConfigs = _levelConfig.missions;
    _missionCurrents = List.filled(_missionConfigs.length, 0);
    _timeLimit = _levelConfig.timeLimitSeconds;

    final gridColors = _levelConfig.gridColors.toGridBackgroundColors();
    final outsideConfig = _levelConfig.outsideConfig.toOutsideGridConfig();
    _gridBackground = GridBackground(
      segmentSize: _segmentSize,
      gridColumns: GameConfig.gridColumns,
      totalWorldRows: totalWorldRows,
      playableStartRow: playableStartRow,
      playableRowCount: playableRowCount,
      colors: gridColors,
      outsideConfig: outsideConfig,
    );
    world.add(_gridBackground);

    _mapEntityManager = MapEntityManager(
      typeObjConfig: _typeObjConfig,
      segmentSize: _segmentSize,
      gridColumns: GameConfig.gridColumns,
      gridRows: _gridRows,
      gridToWorld: _gridToWorld,
    );

    _wormContext = WormGameContextImpl(
      gameTimeGetter: () => _gameTime,
      spawnPreyCallback: _spawnPrey,
      addMissionLeavesCallback: (n) {
        final i = _missionConfigs.indexWhere((m) => m.id == 'leaves');
        if (i >= 0 && i < _missionCurrents.length) {
          final m = _missionConfigs[i];
          final target = _missionTargetOverrides[m.id] ?? m.target;
          _missionCurrents[i] = (_missionCurrents[i] + n).clamp(0, target);
        }
      },
      destroyObstacleAtCallback: _destroyEntityAt,
      loseSegmentCallback: _loseSegment,
    );

    final worm = PinkWorm(
      config: PinkWormConfig(
        segmentSize: _segmentSize,
        moveInterval: GameConfig.moveInterval,
        initialLength: 10,
        gridRows: _gridRows,
      ),
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * _segmentSize),
      gridRowsOverride: _gridRows,
    );
    world.add(worm);
    _playerAgent = WormAgent(
      worm: worm,
      behavior: PlayerWormBehavior(),
    );

    _registerMapEntityPlacers();
    _placeAllMapEntitiesFromConfig();
    if (!_mapEntityManager.entries.any((e) => _typeObjConfig.isEatable(e.typeId))) _spawnPrey();

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

  Set<String> _occupiedGridKeys() =>
      _mapEntityManager.occupiedGridKeys(mainWorm.allGridPositions);

  bool _isGridInCameraView(Vector2 grid) {
    if (_cameraY == null || !_loaded) return true;
    final halfViewY = camera.viewport.size.y / 2;
    final cellCenterY = (grid.y + playableStartRow + 0.5) * _segmentSize;
    return cellCenterY >= _cameraY! - halfViewY &&
        cellCenterY <= _cameraY! + halfViewY;
  }

  void _spawnPrey() {
    final occupied = _occupiedGridKeys();
    final entry = _mapEntityManager.spawn(
      ProjectType.preyLeaf.typeId,
      occupied,
      isCellVisible: _isGridInCameraView,
    );
    if (entry != null) world.add(entry.component);
  }

  void _spawnApple() {
    if (_mapEntityManager.entries.any((e) => e.typeId == ProjectType.preyCoconut.typeId)) return;
    final occupied = _occupiedGridKeys();
    final entry = _mapEntityManager.spawn(
      ProjectType.preyCoconut.typeId,
      occupied,
      isCellVisible: _isGridInCameraView,
    );
    if (entry != null) world.add(entry.component);
  }

  /// Đăng ký typeId từ typeObjConfig → placeAt(grid, typeId) + world.add.
  void _registerMapEntityPlacers() {
    for (final typeId in _typeObjConfig.allTypeIds) {
      _placeEntityAt[typeId] = (Vector2 grid) {
        final comp = _mapEntityManager.placeAt(grid, typeId);
        world.add(comp);
      };
    }
  }

  /// Duyệt config map: typeId (string) → placeAt cho từng ô. TypeId không có trong typeObjConfig thì bỏ qua.
  void _placeAllMapEntitiesFromConfig() {
    for (final entry in _levelConfig.mapConfig.placements.entries) {
      final place = _placeEntityAt[entry.key];
      if (place == null) continue;
      for (final grid in entry.value) {
        place(grid);
      }
    }
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

    final headWorld = _gridToWorld(mainWorm.headGridPosition);
    final targetY = headWorld.y.clamp(halfViewY, maxCameraY.clamp(halfViewY, double.infinity));

    final current = _cameraY ?? targetY;
    final smoothFactor = 1.0 - exp(-_cameraSmoothSpeed * dt);
    _cameraY = current + (targetY - current) * smoothFactor;

    camera.viewfinder.position = Vector2(worldWidth / 2, _cameraY!);
  }

  void _setGameOver() {
    if (_gameOver) return;
    _gameOver = true;
    overlays.add('GameOver');
  }

  /// Gọi từ overlay Flutter "Chơi lại" hoặc nội bộ.
  void restart() {
    overlays.remove('GameOver');
    _restart();
  }

  void _restart() {
    mainWorm.removeFromParent();
    for (final e in _mapEntityManager.entries) e.component.removeFromParent();
    _mapEntityManager.clear();

    final worm = PinkWorm(
      config: PinkWormConfig(
        segmentSize: _segmentSize,
        moveInterval: GameConfig.moveInterval,
        initialLength: 10,
        gridRows: _gridRows,
      ),
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * _segmentSize),
      gridRowsOverride: _gridRows,
    );
    world.add(worm);
    _playerAgent = WormAgent(
      worm: worm,
      behavior: PlayerWormBehavior(),
    );

    _placeAllMapEntitiesFromConfig();
    if (!_mapEntityManager.entries.any((e) => _typeObjConfig.isEatable(e.typeId))) _spawnPrey();

    _appleSpawnAccumulator = 0;
    _gameTime = 0;
    _startDelayRemaining = startDelaySeconds;
    _timeLimit = _levelConfig.timeLimitSeconds;
    _missionCurrents = List.filled(_missionConfigs.length, 0);

    _gameOver = false;
    _paused = false;
    _moveAccumulator = 0;
    _cameraY = null;
  }

  /// Trừ 1 đốt đuôi và để lại dấu X tại vị trí đuôi.
  void _loseSegment() {
    mainWorm.showCryFace();
    final tailGrid = mainWorm.tailGridPosition;
    mainWorm.removeTail();
    final comp = _mapEntityManager.placeAt(tailGrid, 'x_mark');
    world.add(comp);
    if (mainWorm.segmentCount <= 2) _setGameOver();
  }

  /// Phá entity tại ô [grid] (khi độ cứng sâu > độ cứng vật cản).
  void _destroyEntityAt(Vector2 grid) {
    final entry = _mapEntityManager.removeAt(grid);
    if (entry != null) entry.component.removeFromParent();
  }

  /// Độ cứng hiện tại của sâu (currentHardness, set trong onItemEffectAdded/Removed khi buff dừa).
  int _getWormHardness() => mainWorm.stats.currentHardness;

  /// Xử lý khi đầu chạm vùng nguy hiểm. Wall/tail/body → trừ đuôi. Vật cản → gọi behavior.onHitEntity.
  bool _onHitHazard(HazardType type, Vector2 nextHead) {
    mainWorm.applyNextDirectionAndSyncVisuals();
    switch (type) {
      case HazardType.wall:
      case HazardType.tail:
      case HazardType.body:
        _loseSegment();
        return true;
      case HazardType.obstacle: {
        final entry = _mapEntityManager.getAt(nextHead);
        if (entry == null) return true;
        final projectType = EntityModels.projectType(entry.typeId) ?? ProjectType.xMark;
        final entityHardness = EntityModels.hardness(entry.typeId);
        final wormHardness = _getWormHardness();
        final result = _playerAgent.behavior.onHitEntity(
          _playerAgent,
          projectType,
          entityHardness,
          wormHardness,
          _wormContext,
        );
        switch (result) {
          case HitResult.loseSegment:
            _loseSegment();
            break;
          case HitResult.destroyAndStep:
            _destroyEntityAt(nextHead);
            mainWorm.step();
            break;
          case HitResult.none:
            break;
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
        diamonds: 0,
        missions: const [GameHudMission(id: 'leaves', typeId: 'prey_leaf', current: 0, target: 10)],
        bossHp: 0,
        bossHpMax: 0,
        itemBuffs: const [],
        startDelayRemaining: _startDelayRemaining,
      );
    }
    final missions = <GameHudMission>[];
    for (var i = 0; i < _missionConfigs.length && i < _missionCurrents.length; i++) {
      final m = _missionConfigs[i];
      if (m.target <= 0) continue;
      final target = _missionTargetOverrides[m.id] ?? m.target;
      if (target <= 0) continue;
      missions.add(GameHudMission(
        id: m.id,
        typeId: m.typeId,
        current: _missionCurrents[i],
        target: target,
      ));
    }
    final hasBoss = _levelConfig.hasBoss;
    final int bossHp = hasBoss ? 0 : 0; // TODO: cập nhật từ boss entity khi có
    final int bossHpMax = hasBoss ? 100 : 0; // TODO: từ level JSON khi có boss
    final itemBuffs = mainWorm.itemEffects
        .where((e) => e.endTime != null)
        .map((e) => GameHudItemBuff(
              itemId: e.itemId,
              remainingSeconds: (e.endTime! - _gameTime).clamp(0.0, double.infinity),
            ))
        .toList();
    return GameHudData(
      timeRemainingSeconds: (_timeLimit - _gameTime).clamp(0.0, _timeLimit),
      diamonds: 0,
      missions: missions,
      bossHp: bossHp,
      bossHpMax: bossHpMax,
      itemBuffs: itemBuffs,
      startDelayRemaining: _startDelayRemaining,
    );
  }

  @override
  void update(double dt) {
    mainWorm.setWaitingToStart(_startDelayRemaining > 0);
    super.update(dt);
    if (_loaded) _updateCameraFollowSnake(dt);
    if (_gameOver) return;
    if (_paused) return;

    if (_startDelayRemaining > 0) {
      _startDelayRemaining -= dt;
      return;
    }

    _gameTime += dt;

    if (_gameTime >= _timeLimit) {
      _setGameOver();
      return;
    }

    mainWorm.setGameTime(_gameTime);
    mainWorm.removeExpiredItemEffects(_gameTime);

    if (!mainWorm.hasItemEffect(ProjectType.preyCoconut.typeId)) {
      _appleSpawnAccumulator += dt;
      if (_appleSpawnAccumulator >= _appleSpawnInterval) {
        _appleSpawnAccumulator -= _appleSpawnInterval;
        _spawnApple();
      }
    }

    final interval = mainWorm.moveInterval;
    final raw = (_moveAccumulator / interval).clamp(0.0, 1.0);
    final progress = Curves.linear.transform(raw);
    mainWorm.setVisualProgress(progress);

    _moveAccumulator += dt;
    if (_moveAccumulator < interval) return;
    _moveAccumulator -= interval;

    final nextHead = mainWorm.peekNextHead();

    final outOfBounds = nextHead.x < 0 ||
        nextHead.x >= GameConfig.gridColumns ||
        nextHead.y < 0 ||
        nextHead.y >= _gridRows;

    if (outOfBounds) {
      _onHitHazard(HazardType.wall, nextHead);
      return;
    }

    if (_mapEntityManager.hasBlockingEntityAt(nextHead)) {
      _onHitHazard(HazardType.obstacle, nextHead);
      return;
    }

    final tailGrid = mainWorm.tailGridPosition;
    final hitTail =
        nextHead.x == tailGrid.x && nextHead.y == tailGrid.y;
    if (hitTail) {
      _onHitHazard(HazardType.tail, nextHead);
      return;
    }

    final body = mainWorm.allGridPositions;
    for (var i = 1; i < body.length - 1; i++) {
      if (body[i].x == nextHead.x && body[i].y == nextHead.y) {
        _onHitHazard(HazardType.body, nextHead);
        return;
      }
    }

    mainWorm.step();

    final newHead = mainWorm.headGridPosition;
    final consumed = _mapEntityManager.consumeAt(newHead);
    if (consumed != null) {
      consumed.component.removeFromParent();
      _playerAgent.behavior.onEatEntity(_playerAgent, consumed.typeId, _wormContext);
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
      mainWorm.setNextDirection(WormDirection.up);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      mainWorm.setNextDirection(WormDirection.down);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      mainWorm.setNextDirection(WormDirection.left);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      mainWorm.setNextDirection(WormDirection.right);
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

/// Một nhiệm vụ trên HUD (x/xx). Target = 0 thì không hiển thị. Icon và label lấy từ EntityModels + l10n theo [typeId].
class GameHudMission {
  const GameHudMission({
    required this.id,
    required this.typeId,
    required this.current,
    required this.target,
  });

  final String id;
  final String typeId;
  final int current;
  final int target;
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
