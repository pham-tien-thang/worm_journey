import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/debug_grid_coordinates.dart';
import '../../../components/grid_background.dart';
import '../../../components/pink_worm/pink_worm.dart';
import '../../../components/pink_worm/pink_worm_config.dart';
import '../../../components/worm/worm.dart';
import '../../../components/worm/worm_direction.dart';
import '../../../common/debug_apply.dart';
import '../../../components/max_text_effect.dart';
import '../../../config/config.dart';
import '../../../core/services/shared_prefs_service.dart';
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

/// Nguyên nhân game over: hết giờ hoặc mất hết thân (va chạm).
enum _GameOverCause {
  timeUp,
  bodyGone,
}

/// Snapshot khi sâu chết: map, nhiệm vụ, nguyên nhân; nếu timeUp thêm vị trí/hướng sâu; nếu bodyGone thêm thời gian còn lại.
class _DeathSnapshot {
  _DeathSnapshot({
    required this.entries,
    required this.missionCurrents,
    required this.cause,
    this.wormPositions,
    this.wormDirection,
    this.remainingTimeAtDeath,
  });

  final List<({Vector2 grid, String typeId})> entries;
  final List<int> missionCurrents;
  final _GameOverCause cause;
  /// Chỉ có khi [cause] == timeUp: vị trí grid head→tail để hồi sinh tại chỗ.
  final List<Vector2>? wormPositions;
  /// Chỉ có khi [cause] == timeUp.
  final WormDirection? wormDirection;
  /// Chỉ có khi [cause] == bodyGone: thời gian còn lại lúc chết (để set tối thiểu 30s nếu < 30).
  final double? remainingTimeAtDeath;
}

/// Game rắn săn mồi. Full màn hình. Đâm tường/đuôi trừ 1 đốt; còn đầu+đuôi thì thua.
class WormJourneyGame extends FlameGame
    with KeyboardEvents, TapCallbacks, HasCollisionDetection {
  WormJourneyGame({this.level = 1, this.onGuideLoaded});

  final int level;
  /// Gọi khi load xong màn và guide không rỗng. UI show dialog; khi đóng dialog gọi [dismissGuide].
  final void Function(String guideVi, String guideEn)? onGuideLoaded;

  @override
  Color backgroundColor() => const Color(0xFF1B3D2E);

  late WormAgent _playerAgent;
  /// Con sâu được điều khiển và lấy thông tin lên HUD.
  Worm get mainWorm => _playerAgent.worm;

  late WormGameContext _wormContext;
  late TypeObjConfig _typeObjConfig;
  late MapEntityManager _mapEntityManager;

  /// Accumulator theo typeId cho spawn theo chu kỳ (từ _levelConfig.spawnCycle).
  final Map<String, double> _spawnCycleAccumulators = {};

  /// Thời gian đã chơi (giây), tăng mỗi frame. Dùng cho buff expiry, HUD còn lại = [ _timeLimit ] - [_gameTime].
  double _gameTime = 0;

  double _moveAccumulator = 0;
  bool _gameOver = false;
  bool _victoryTriggered = false;
  bool _flagSpawned = false;
  bool _paused = false;
  bool _loaded = false;

  /// Delay khi mới vào (sâu nhấp nháy). Hiện chưa đưa vào config; mặc định 1s.
  static const double startDelaySeconds = 1.0;
  double _startDelayRemaining = startDelaySeconds;

  /// Thời gian chơi tối đa (giây), từ [ _levelConfig.timeLimitSeconds ]. Ghi đè trong onLoad và _restart.
  double _timeLimit = 120.0;
  /// Tổng thời gian màn (để overlay Victory tính thưởng thời gian).
  double get timeLimitSeconds => _timeLimit;

  /// Config màn load từ JSON (level_1.json, level_2.json, ...). Mặc định trống, gán lại trong onLoad.
  LevelJsonConfig _levelConfig = const LevelJsonConfig();

  /// Danh sách effectTypeId item bị cấm trong màn (từ config itemBlock). Scaffold dùng để hiển thị cấm + báo khi bấm.
  List<String> get blockedItemIds => _levelConfig.itemBlock;
  /// Nhiệm vụ từ config; [ _missionCurrents[i] ] = tiến độ của [ _missionConfigs[i] ].
  List<MissionConfig> _missionConfigs = const [MissionConfig.defaultLeaves];
  List<int> _missionCurrents = [0];
  /// Ghi đè target theo id (vd. setMission2Target gọi khi load level).
  final Map<String, int> _missionTargetOverrides = {};

  /// Snapshot khi game over: map + tiến trình nhiệm vụ (không có thời gian). Dùng khi bấm "Hồi sinh".
  _DeathSnapshot? _deathSnapshot;

  /// Đã hồi sinh một lần trong ván này; chết lần hai không hiện nút Hồi sinh (trừ debug mode).
  bool _hasRevivedOnce = false;

  /// Số đồng xu đã ăn trong ván (để cộng thưởng victory: +1 per coin).
  int _coinsCollectedThisRun = 0;
  /// Thời điểm game (giây) khi đồng xu gần nhất bị ăn; âm = chưa ăn lần nào.
  double _lastCoinEatenGameTime = -999.0;
  /// Đã spawn đồng xu đầu tiên chưa (để dùng firstSpawnDelay vs delayAfterEaten).
  bool _firstCoinSpawned = false;

  /// Số xu ăn được trong ván (overlay Victory cộng thưởng = coinsCollectedThisRun * 1).
  int get coinsCollectedThisRun => _coinsCollectedThisRun;

  double _segmentSize = 28.0;
  int _gridRows = GameConfig.gridRows;
  late GridBackground _gridBackground;

  /// Overlay tọa độ ô (A1, B1...) chỉ khi shouldApplyDebug (nút Debug ON ở HUD).
  DebugGridCoordinates? _debugGridCoordinates;

  /// Camera Y đang lerp (làm mượt, tránh giật).
  double? _cameraY;

  /// Factory đặt entity tại ô: typeId (từ JSON) → hàm (grid). Mọi loại dùng chung [MapEntityManager.placeAt].
  final Map<String, void Function(Vector2 grid)> _placeEntityAt = {};

  /// Magnet pull: mồi đang bay về đầu rắn (position + scale animation).
  final List<_MagnetPull> _magnetPulls = [];
  /// Thời điểm lần hút magnet gần nhất (để hút liên tục trong lúc effect còn).
  double? _magnetLastPullTime;

  /// Pause / resume (vd. khi mở/đóng dialog).
  void setPaused(bool value) {
    _paused = value;
  }

  /// Gọi sau khi user bấm Đã hiểu ở dialog hướng dẫn → bắt đầu chơi.
  void dismissGuide() {
    setPaused(false);
  }

  /// Dùng item: effect có duration → thêm vào list effect; instant (bomb, clock, seed) → xử lý ngay; antidote → add để PinkWorm.onItemEffectAdded xóa list.
  void useEffect(ItemType type) {
    if (_gameOver || !_loaded) return;
    final id = type.effectTypeId;
    if (BuffConfig.isInstantEffect(id)) {
      _applyInstantEffect(type);
      return;
    }
    if (id == ItemType.antidote.effectTypeId) {
      mainWorm.addItemEffect(id, null);
      return;
    }
    final duration = BuffConfig.durationSecondsFor(id);
    if (duration > 0) {
      mainWorm.addItemEffect(id, _gameTime + duration);
      if (id == ItemType.magnet.effectTypeId) _triggerMagnetPull();
    }
  }

  /// Instant effect: dùng 1 lần, không lưu vào list. Scale: thêm case theo [ItemType].
  void _applyInstantEffect(ItemType type) {
    switch (type) {
      case ItemType.bomb:
        _instantEffectBomb();
        break;
      case ItemType.clock:
        _timeLimit += BuffConfig.clockAddSeconds;
        break;
      case ItemType.seed:
        _spawnPrey();
        _spawnPrey();
        break;
      default:
        break;
    }
  }

  /// Bom: phá entity trong bán kính [BuffConfig.bombRadiusTiles] ô quanh đầu rắn.
  void _instantEffectBomb() {
    final head = mainWorm.headGridPosition;
    final r = BuffConfig.bombRadiusTiles;
    for (var dy = -r; dy <= r; dy++) {
      for (var dx = -r; dx <= r; dx++) {
        if (dx == 0 && dy == 0) continue;
        if (dx.abs() + dy.abs() > r) continue;
        final grid = Vector2(head.x + dx, head.y + dy);
        if (_mapEntityManager.hasBlockingEntityAt(grid)) {
          _destroyEntityAt(grid);
        }
      }
    }
    if (mainWorm is PinkWorm) (mainWorm as PinkWorm).triggerBombExplosion();
  }

  /// Magnet: hút mồi trong phạm vi [BuffConfig.magnetRangeTiles] ô (Chebyshev) từ đầu rắn, thuộc [magnetAttractTypeIds].
  void _triggerMagnetPull() {
    final head = mainWorm.headGridPosition;
    final range = BuffConfig.magnetRangeTiles;
    final toPull = _mapEntityManager.entries.where((e) {
      if (!BuffConfig.magnetAttractTypeIds.contains(e.typeId)) return false;
      final dx = (e.grid.x - head.x).abs();
      final dy = (e.grid.y - head.y).abs();
      return dx <= range && dy <= range;
    }).toList();
    for (final entry in toPull) {
      final removed = _mapEntityManager.removeAt(entry.grid);
      if (removed != null) {
        _magnetPulls.add(_MagnetPull(
          entry: removed,
          startPos: removed.component.position.clone(),
          startTime: _gameTime,
        ));
      }
    }
  }

  void _updateMagnetPulls(double dt) {
    if (_magnetPulls.isEmpty) return;
    final headWorld = _gridToWorld(mainWorm.headGridPosition);
    const duration = BuffConfig.magnetPullDurationSeconds;
    final toRemove = <_MagnetPull>[];
    for (final pull in _magnetPulls) {
      final t = ((_gameTime - pull.startTime) / duration).clamp(0.0, 1.0);
      final comp = pull.entry.component;
      comp.position.setFrom(pull.startPos + (headWorld - pull.startPos) * t);
      comp.scale.setValues(1 - t, 1 - t);
      if (t >= 1) {
        comp.removeFromParent();
        _applyEatEntity(pull.entry.typeId);
        toRemove.add(pull);
      }
    }
    for (final p in toRemove) _magnetPulls.remove(p);
  }

  /// Áp dụng logic ăn entity (grow, mission, buff) theo typeId — dùng khi magnet hút xong hoặc ăn trực tiếp.
  void _applyEatEntity(String typeId) {
    final view = EntityModels.view(typeId);
    if (view != null) {
      _playerAgent.behavior.onEatEntity(_playerAgent, view, _wormContext);
    }
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
  static const int _extraRowsAboveBelow = 8;
  static const int playableStartRow = _extraRowsAboveBelow; // 8
  static const int playableRowCount = 37;
  static const int totalWorldRows = _extraRowsAboveBelow + playableRowCount + _extraRowsAboveBelow;

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

  int _wormInitLength = 1;
  int _wormMaxLength = 10;

  @override
  Future<void> onLoad() async {
    _deathSnapshot = null;
    _hasRevivedOnce = false;
    _coinsCollectedThisRun = 0;
    _lastCoinEatenGameTime = -999.0;
    _firstCoinSpawned = false;
    _gridRows = playableRowCount;
    camera.viewport = MaxViewport();

    _wormInitLength = await SharedPrefsService.getWormInitLength();
    _wormMaxLength = await SharedPrefsService.getWormMaxLength();

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
      addMissionProgressByTypeIdCallback: (typeId, n) {
        final i = _missionConfigs.indexWhere((m) => m.typeId == typeId);
        if (i >= 0 && i < _missionCurrents.length) {
          final m = _missionConfigs[i];
          final target = _missionTargetOverrides[m.id] ?? m.target;
          _missionCurrents[i] = (_missionCurrents[i] + n).clamp(0, target);
        }
      },
      destroyObstacleAtCallback: _destroyEntityAt,
      loseSegmentCallback: _loseSegment,
      triggerMagnetPullCallback: _triggerMagnetPull,
      preyLeafCountOnMapGetter: () => _mapEntityManager.entries
          .where((e) => e.typeId == ProjectType.preyLeaf.typeId)
          .length,
    );

    final initLen = shouldApplyDebug ? 10 : (_wormInitLength + 2);
    final maxLen = shouldApplyDebug ? null : _wormMaxLength;
    final worm = PinkWorm(
      config: PinkWormConfig(
        segmentSize: _segmentSize,
        moveInterval: GameConfig.moveInterval,
        initialLength: initLen,
        maxLength: maxLen,
        gridRows: _gridRows,
      ),
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * _segmentSize),
      gridRowsOverride: _gridRows,
    );
    world.add(worm);
    worm.setOnGrowAtMax(_onWormGrowAtMax);
    _playerAgent = WormAgent(
      worm: worm,
      behavior: PlayerWormBehavior(),
    );

    _registerMapEntityPlacers();
    _placeAllMapEntitiesFromConfig();
    if (!_mapEntityManager.entries.any((e) => _typeObjConfig.isEatable(e.typeId))) _spawnPrey();

    if (shouldApplyDebug) {
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
    if (_levelConfig.guideVi.isNotEmpty || _levelConfig.guideEn.isNotEmpty) {
      _paused = true;
      onGuideLoaded?.call(_levelConfig.guideVi, _levelConfig.guideEn);
    }
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

  /// Sinh một entity eatable theo [typeId] (từ config spawnCycle). Điều kiện đặc thù từng loại (vd. dừa: tối đa 1 quả, không sinh khi sâu đang buff dừa).
  void _spawnByTypeId(String typeId) {
    if (typeId == ProjectType.preyCoconut.typeId) {
      if (mainWorm.hasItemEffect(ProjectType.preyCoconut.typeId)) return;
      if (_mapEntityManager.entries.any((e) => e.typeId == typeId)) return;
    }
    final occupied = _occupiedGridKeys();
    final entry = _mapEntityManager.spawn(
      typeId,
      occupied,
      isCellVisible: _isGridInCameraView,
    );
    if (entry != null) world.add(entry.component);
  }

  static const String _preyCoinTypeId = 'prey_coin';

  /// Spawn đồng xu nếu config bật và chưa có xu trên map; đồng xu đầu sau firstSpawnDelay, các lần sau sau spawnDelayAfterEaten kể từ khi xu trước bị ăn.
  void _trySpawnCoin() {
    final config = _levelConfig.coinSpawnConfig;
    if (config == null) return;
    if (_mapEntityManager.entries.any((e) => e.typeId == _preyCoinTypeId)) return;

    final canSpawn = !_firstCoinSpawned
        ? (_gameTime >= config.firstSpawnDelaySeconds)
        : (_gameTime - _lastCoinEatenGameTime >= config.spawnDelayAfterEatenSeconds);

    if (!canSpawn) return;

    _firstCoinSpawned = true;
    final occupied = _occupiedGridKeys();
    final entry = _mapEntityManager.spawn(
      _preyCoinTypeId,
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

  /// Duyệt config map: typeId (string) → placeAt cho từng ô. Bỏ qua prey_flag — cờ chỉ spawn khi hoàn thành nhiệm vụ.
  /// Không đặt entity lên ô đang bị thân sâu hoặc entity khác chiếm.
  void _placeAllMapEntitiesFromConfig() {
    Set<String> occupied = _occupiedGridKeys();
    for (final entry in _levelConfig.mapConfig.placements.entries) {
      if (entry.key == 'prey_flag') continue;
      final place = _placeEntityAt[entry.key];
      if (place == null) continue;
      for (final grid in entry.value) {
        final key = '${grid.x.toInt()},${grid.y.toInt()}';
        if (occupied.contains(key)) continue;
        place(grid);
        occupied.add(key);
      }
    }
  }

  void _onWormGrowAtMax() {
    world.add(MaxTextEffectComponent(
      position: mainWorm.headWorldPosition,
      segmentSize: _segmentSize,
    ));
  }

  /// Spawn lá cờ tại ô ưu tiên từ config, hoặc ô trống bất kỳ trong view nếu ô config bị sâu/entity chiếm. Có hiệu ứng nhấp nháy 1 nhịp.
  void _spawnFlag() {
    final occupied = _occupiedGridKeys();
    final preferred = _levelConfig.mapConfig.placements['prey_flag'];
    Vector2? targetGrid;
    if (preferred != null && preferred.isNotEmpty) {
      final freePreferred = preferred.where(
        (g) => !occupied.contains('${g.x.toInt()},${g.y.toInt()}'),
      );
      if (freePreferred.isNotEmpty) targetGrid = freePreferred.first;
    }
    if (targetGrid == null) {
      final candidates = <Vector2>[];
      for (var row = 0; row < _gridRows; row++) {
        for (var col = 0; col < GameConfig.gridColumns; col++) {
          final pos = Vector2(col.toDouble(), row.toDouble());
          if (occupied.contains('$col,$row')) continue;
          if (!_isGridInCameraView(pos)) continue;
          candidates.add(pos);
        }
      }
      if (candidates.isEmpty) return;
      targetGrid = candidates[Random().nextInt(candidates.length)];
    }
    final comp = _mapEntityManager.placeAt(targetGrid, 'prey_flag', withSpawnEffect: true);
    world.add(comp);
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

  /// Di chuyển camera theo đầu rắn (trục Y), lerp mượt.
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

  void _setGameOver(_GameOverCause cause) {
    if (_gameOver) return;
    _gameOver = true;
    _deathSnapshot = _DeathSnapshot(
      entries: _mapEntityManager.entries
          .map((e) => (grid: e.grid.clone(), typeId: e.typeId))
          .toList(),
      missionCurrents: List.from(_missionCurrents),
      cause: cause,
      wormPositions: cause == _GameOverCause.timeUp
          ? mainWorm.allGridPositions.map((v) => v.clone()).toList()
          : null,
      wormDirection: cause == _GameOverCause.timeUp ? mainWorm.currentDirection : null,
      remainingTimeAtDeath: cause == _GameOverCause.bodyGone
          ? (_timeLimit - _gameTime).clamp(0.0, double.infinity)
          : null,
    );
    if (_hasRevivedOnce && !shouldApplyDebug) {
      overlays.add('GameOverNoRevive');
    } else {
      overlays.add('GameOver');
    }
  }

  /// True khi mọi nhiệm vụ (có target > 0) đều đạt current >= target.
  bool _allMissionsComplete() {
    for (var i = 0; i < _missionConfigs.length && i < _missionCurrents.length; i++) {
      final m = _missionConfigs[i];
      final target = _missionTargetOverrides[m.id] ?? m.target;
      if (target <= 0) continue;
      if (_missionCurrents[i] < target) return false;
    }
    return true;
  }

  /// Phần thưởng thoát victory (overlay set khi build). GameScreen dùng để thoát khi bấm back + xác nhận, không show thêm dialog end game.
  int? _victoryExitReward;
  int? get victoryExitReward => _victoryExitReward;
  void setVictoryExitReward(int r) => _victoryExitReward = r;

  /// Unlock level/scene và gỡ overlay Victory. Gọi sau khi user xác nhận thoát victory (từ overlay hoặc từ GameScreen khi bấm back).
  Future<void> performVictoryUnlockAndDismiss() async {
    final currentMaxLevel = await SharedPrefsService.getMaxLevelIndexUnlock();
    final newLevel = currentMaxLevel < level + 1 ? level + 1 : currentMaxLevel;
    await SharedPrefsService.setMaxLevelIndexUnlock(newLevel);
    final newSceneFromLevel = ((newLevel - 1) ~/ 5) + 1;
    final currentMaxScene = await SharedPrefsService.getMaxSceneIndexUnlock();
    if (newSceneFromLevel > currentMaxScene) {
      await SharedPrefsService.setMaxSceneIndexUnlock(newSceneFromLevel);
    }
    overlays.remove('Victory');
  }

  void _setVictory() {
    if (_gameOver || _victoryTriggered) return;
    _victoryTriggered = true;
    _gameOver = true;
    overlays.add('Victory');
  }

  /// Gọi từ overlay Flutter "Hồi sinh" hoặc nội bộ.
  void restart() {
    overlays.remove('GameOver');
    overlays.remove('GameOverNoRevive');
    if (_deathSnapshot != null) {
      _hasRevivedOnce = true;
      _restartFromDeath();
    } else {
      _restart();
    }
  }

  /// Ô trong lưới và hoàn toàn trống (không có entity).
  bool _isCellEmpty(Vector2 grid) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    if (grid.x < 0 || grid.x >= cols || grid.y < 0 || grid.y >= rows) return false;
    return _mapEntityManager.getAt(grid) == null;
  }

  /// Ô trong lưới và trống, hoặc có vật cản độ cứng 1 (chỉ dùng khi không còn vùng an toàn).
  bool _isCellUsableForSpawn(Vector2 grid) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    if (grid.x < 0 || grid.x >= cols || grid.y < 0 || grid.y >= rows) return false;
    final entry = _mapEntityManager.getAt(grid);
    if (entry == null) return true;
    return _typeObjConfig.isBlocking(entry.typeId) &&
        EntityModels.hardness(entry.typeId) == 1;
  }

  /// Số ô liên tiếp theo [dir] từ [head] (không tính head) hoàn toàn trống.
  int _countStrictEmptyAhead(Vector2 head, WormDirection dir) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    final step = dir.toVector();
    var pos = head + step;
    var count = 0;
    while (pos.x >= 0 && pos.x < cols && pos.y >= 0 && pos.y < rows) {
      if (_mapEntityManager.getAt(pos) != null) break;
      count++;
      pos += step;
    }
    return count;
  }

  /// Số ô liên tiếp theo [dir] từ [head] là trống hoặc vật cản độ cứng 1 (dùng khi đã phải phá chỗ).
  int _countEmptyOrClearableAhead(Vector2 head, WormDirection dir) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    final step = dir.toVector();
    var pos = head + step;
    var count = 0;
    while (pos.x >= 0 && pos.x < cols && pos.y >= 0 && pos.y < rows) {
      final entry = _mapEntityManager.getAt(pos);
      if (entry == null) {
        count++;
      } else if (_typeObjConfig.isBlocking(entry.typeId) &&
          EntityModels.hardness(entry.typeId) == 1) {
        count++;
      } else {
        break;
      }
      pos += step;
    }
    return count;
  }

  /// Độ dài sâu khi hồi sinh (3 + 2 đơn vị).
  static const int _respawnWormLength = 5;

  static const List<WormDirection> _allDirections = [
    WormDirection.right,
    WormDirection.left,
    WormDirection.down,
    WormDirection.up,
  ];

  WormDirection? _respawnHeadDirectionFromConfig() {
    final s = _levelConfig.respawnHeadDirection;
    if (s == 'none' || s.isEmpty) return null;
    switch (s) {
      case 'top':
        return WormDirection.up;
      case 'r':
        return WormDirection.right;
      case 'l':
        return WormDirection.left;
      case 'b':
        return WormDirection.down;
      default:
        return null;
    }
  }

  /// Tìm **vị trí an toàn** để hồi sinh sâu (độ dài 5).
  /// - Config "none": sâu xếp thẳng hàng, hướng đầu chọn theo nhiều ô trống phía trước nhất (logic hiện tại).
  /// - Config "top"/"r"/"l"/"b": sâu có thể ngoằn nghoèo (path 5 ô nối tiếp), hướng đầu cố định từ config.
  /// Trả về (positions: head→tail, direction, needDestroy).
  ({List<Vector2> positions, WormDirection direction, bool needDestroy})? _findSafeSpawn() {
    final configDir = _respawnHeadDirectionFromConfig();
    if (configDir == null) return _findSafeSpawnLinear();
    return _findSafeSpawnWinding(configDir);
  }

  /// Sâu xếp thẳng hàng; hướng đầu chọn theo nhiều ô trống phía trước nhất (config "none").
  ({List<Vector2> positions, WormDirection direction, bool needDestroy})? _findSafeSpawnLinear() {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    const bodyCount = _respawnWormLength - 1;

    ({Vector2 head, WormDirection direction, int ahead})? bestEmpty;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final head = Vector2(col.toDouble(), row.toDouble());
        for (final dir in _allDirections) {
          final step = dir.toVector();
          final body1 = head - step;
          var ok = _isCellEmpty(head) && _isCellEmpty(body1);
          var pos = body1;
          for (var i = 0; i < bodyCount - 1 && ok; i++) {
            pos = pos - step;
            if (pos.x < 0 || pos.x >= cols || pos.y < 0 || pos.y >= rows) {
              ok = false;
              break;
            }
            if (!_isCellEmpty(pos)) ok = false;
          }
          if (!ok) continue;
          final front = head + step;
          if (front.x < 0 || front.x >= cols || front.y < 0 || front.y >= rows) continue;
          if (!_isCellEmpty(front)) continue;

          final ahead = _countStrictEmptyAhead(head, dir);
          if (bestEmpty == null || ahead > bestEmpty.ahead) {
            bestEmpty = (head: head, direction: dir, ahead: ahead);
          }
        }
      }
    }
    if (bestEmpty != null) {
      final step = bestEmpty.direction.toVector();
      final positions = [
        bestEmpty.head,
        bestEmpty.head - step,
        bestEmpty.head - step * 2,
        bestEmpty.head - step * 3,
        bestEmpty.head - step * 4,
      ];
      return (positions: positions, direction: bestEmpty.direction, needDestroy: false);
    }

    ({Vector2 head, WormDirection direction, int ahead})? bestUsable;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final head = Vector2(col.toDouble(), row.toDouble());
        for (final dir in _allDirections) {
          final step = dir.toVector();
          var pos = head;
          var ok = _isCellUsableForSpawn(pos);
          for (var i = 0; i < bodyCount && ok; i++) {
            pos = pos - step;
            if (pos.x < 0 || pos.x >= cols || pos.y < 0 || pos.y >= rows) {
              ok = false;
              break;
            }
            if (!_isCellUsableForSpawn(pos)) ok = false;
          }
          if (!ok) continue;

          final ahead = _countEmptyOrClearableAhead(head, dir);
          if (bestUsable == null || ahead > bestUsable.ahead) {
            bestUsable = (head: head, direction: dir, ahead: ahead);
          }
        }
      }
    }
    if (bestUsable != null) {
      final step = bestUsable.direction.toVector();
      final positions = [
        bestUsable.head,
        bestUsable.head - step,
        bestUsable.head - step * 2,
        bestUsable.head - step * 3,
        bestUsable.head - step * 4,
      ];
      return (positions: positions, direction: bestUsable.direction, needDestroy: true);
    }
    return null;
  }

  /// Sâu có thể ngoằn nghoèo (path 5 ô nối tiếp); hướng đầu cố định [headDirection] từ config.
  ({List<Vector2> positions, WormDirection direction, bool needDestroy})? _findSafeSpawnWinding(WormDirection headDirection) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    final frontStep = headDirection.toVector();

    bool inBounds(Vector2 p) =>
        p.x >= 0 && p.x < cols && p.y >= 0 && p.y < rows;

    ({List<Vector2> path, bool useHeadAtStart})? bestEmpty;
    ({List<Vector2> path, bool useHeadAtStart})? bestUsable;
    var bestEmptyAhead = -1;
    var bestUsableAhead = -1;

    void tryPath(List<Vector2> path, bool headAtStart) {
      final head = headAtStart ? path.first : path.last;
      final front = head + frontStep;
      if (!inBounds(front)) return;

      final emptyOk = path.every(_isCellEmpty) && _isCellEmpty(front);
      final usableOk = path.every(_isCellUsableForSpawn) && _isCellUsableForSpawn(front);
      if (!emptyOk && !usableOk) return;

      final ahead = emptyOk
          ? _countStrictEmptyAhead(head, headDirection)
          : _countEmptyOrClearableAhead(head, headDirection);

      if (emptyOk && (bestEmpty == null || ahead > bestEmptyAhead)) {
        bestEmpty = (path: List.from(path), useHeadAtStart: headAtStart);
        bestEmptyAhead = ahead;
      }
      if (usableOk && (bestUsable == null || ahead > bestUsableAhead)) {
        bestUsable = (path: List.from(path), useHeadAtStart: headAtStart);
        bestUsableAhead = ahead;
      }
    }

    void dfs(List<Vector2> path, Set<String> used) {
      if (path.length == _respawnWormLength) {
        tryPath(path, true);
        tryPath(path, false);
        return;
      }
      final last = path.last;
      for (final d in _allDirections) {
        final next = last + d.toVector();
        if (!inBounds(next)) continue;
        final key = '${next.x.toInt()},${next.y.toInt()}';
        if (used.contains(key)) continue;
        used.add(key);
        path.add(next);
        dfs(path, used);
        path.removeLast();
        used.remove(key);
      }
    }

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final start = Vector2(col.toDouble(), row.toDouble());
        final key = '${col},$row';
        dfs([start], {key});
      }
    }

    if (bestEmpty != null) {
      final b = bestEmpty!;
      final path = b.useHeadAtStart ? b.path : b.path.reversed.toList();
      return (positions: path, direction: headDirection, needDestroy: false);
    }
    if (bestUsable != null) {
      final b = bestUsable!;
      final path = b.useHeadAtStart ? b.path : b.path.reversed.toList();
      return (positions: path, direction: headDirection, needDestroy: true);
    }
    return null;
  }

  /// Vị trí mặc định khi không tìm được spawn (giữa lưới, thẳng hàng theo [dir]).
  List<Vector2> _defaultRespawnPositions(WormDirection dir) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    final step = dir.toVector();
    final head = Vector2((cols / 2).floorToDouble(), (rows / 2).floorToDouble());
    return [
      head,
      head - step,
      head - step * 2,
      head - step * 3,
      head - step * 4,
    ];
  }

  /// Phá entity tại [grid] nếu là vật cản độ cứng 1 (để giải chỗ cho sâu hồi sinh).
  void _destroyObstacleIfHardness1(Vector2 grid) {
    final entry = _mapEntityManager.getAt(grid);
    if (entry == null) return;
    if (!_typeObjConfig.isBlocking(entry.typeId)) return;
    if (EntityModels.hardness(entry.typeId) != 1) return;
    _destroyEntityAt(grid);
  }

  void _restartFromDeath() {
    final snapshot = _deathSnapshot!;
    mainWorm.removeFromParent();
    for (final e in _mapEntityManager.entries) e.component.removeFromParent();
    _mapEntityManager.clear();
    for (final p in _magnetPulls) p.entry.component.removeFromParent();
    _magnetPulls.clear();
    _magnetLastPullTime = null;

    for (final e in snapshot.entries) {
      final place = _placeEntityAt[e.typeId];
      if (place != null) place(e.grid);
    }
    _missionCurrents = List.from(snapshot.missionCurrents);

    final List<Vector2> initialPositions;
    final WormDirection dir;
    final int wormLength;

    if (snapshot.cause == _GameOverCause.timeUp &&
        snapshot.wormPositions != null &&
        snapshot.wormPositions!.length >= 2 &&
        snapshot.wormDirection != null) {
      initialPositions = snapshot.wormPositions!;
      dir = snapshot.wormDirection!;
      wormLength = initialPositions.length;
      _timeLimit += 30;
    } else {
      final safe = _findSafeSpawn();
      initialPositions = safe?.positions ??
          _defaultRespawnPositions(WormDirection.right);
      dir = safe?.direction ?? WormDirection.right;
      wormLength = _respawnWormLength;

      if (safe?.needDestroy == true) {
        final headGrid = initialPositions.first;
        final front = headGrid + dir.toVector();
        for (final grid in [...initialPositions, front]) {
          _destroyObstacleIfHardness1(grid);
        }
      }

      final remaining = snapshot.remainingTimeAtDeath ?? 0;
      _timeLimit = remaining < 30 ? 30 : remaining;
      _gameTime = 0;
    }

    final worm = PinkWorm(
      config: PinkWormConfig(
        segmentSize: _segmentSize,
        moveInterval: GameConfig.moveInterval,
        initialLength: wormLength,
        maxLength: _wormMaxLength,
        gridRows: _gridRows,
        initialGridPositions: initialPositions,
        initialDirection: dir,
      ),
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * _segmentSize),
      gridRowsOverride: _gridRows,
    );
    world.add(worm);
    worm.setOnGrowAtMax(_onWormGrowAtMax);
    _playerAgent = WormAgent(
      worm: worm,
      behavior: PlayerWormBehavior(),
    );

    final headWorld = _gridToWorld(initialPositions.first);
    final worldWidth = GameConfig.gridColumns * _segmentSize;
    final halfViewY = camera.viewport.size.y / 2;
    final bottomOfPlayable = (playableStartRow + playableRowCount) * _segmentSize;
    final maxCameraY = bottomOfPlayable - halfViewY;
    _cameraY = headWorld.y.clamp(halfViewY, maxCameraY.clamp(halfViewY, double.infinity));
    camera.viewfinder.position = Vector2(worldWidth / 2, _cameraY!);

    _spawnCycleAccumulators.clear();
    for (final item in _levelConfig.spawnCycle.items) {
      _spawnCycleAccumulators[item.objType] = 0;
    }
    _coinsCollectedThisRun = 0;
    _lastCoinEatenGameTime = -999.0;
    _firstCoinSpawned = false;
    if (snapshot.cause != _GameOverCause.timeUp) {
      _gameTime = 0;
    }
    _startDelayRemaining = startDelaySeconds;
    _gameOver = false;
    _victoryTriggered = false;
    _flagSpawned = false;
    _paused = false;
    _moveAccumulator = 0;
  }

  void _restart() {
    mainWorm.removeFromParent();
    for (final e in _mapEntityManager.entries) e.component.removeFromParent();
    _mapEntityManager.clear();
    for (final p in _magnetPulls) p.entry.component.removeFromParent();
    _magnetPulls.clear();
    _magnetLastPullTime = null;

    final initLen = shouldApplyDebug ? 10 : (_wormInitLength + 2);
    final maxLen = shouldApplyDebug ? null : _wormMaxLength;
    final worm = PinkWorm(
      config: PinkWormConfig(
        segmentSize: _segmentSize,
        moveInterval: GameConfig.moveInterval,
        initialLength: initLen,
        maxLength: maxLen,
        gridRows: _gridRows,
      ),
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * _segmentSize),
      gridRowsOverride: _gridRows,
    );
    world.add(worm);
    worm.setOnGrowAtMax(_onWormGrowAtMax);
    _playerAgent = WormAgent(
      worm: worm,
      behavior: PlayerWormBehavior(),
    );

    _placeAllMapEntitiesFromConfig();
    if (!_mapEntityManager.entries.any((e) => _typeObjConfig.isEatable(e.typeId))) _spawnPrey();

    _spawnCycleAccumulators.clear();
    for (final item in _levelConfig.spawnCycle.items) {
      _spawnCycleAccumulators[item.objType] = 0;
    }
    _coinsCollectedThisRun = 0;
    _lastCoinEatenGameTime = -999.0;
    _firstCoinSpawned = false;
    _gameTime = 0;
    _startDelayRemaining = startDelaySeconds;
    _timeLimit = _levelConfig.timeLimitSeconds;
    _missionCurrents = List.filled(_missionConfigs.length, 0);

    _gameOver = false;
    _victoryTriggered = false;
    _flagSpawned = false;
    _paused = false;
    _moveAccumulator = 0;
    _cameraY = null;
    _hasRevivedOnce = false;
  }

  /// Trừ 1 đốt đuôi và để lại dấu X tại vị trí đuôi.
  void _loseSegment() {
    mainWorm.showCryFace();
    final tailGrid = mainWorm.tailGridPosition;
    mainWorm.removeTail();
    final comp = _mapEntityManager.placeAt(tailGrid, 'x_mark');
    world.add(comp);
    if (mainWorm.segmentCount <= 2) _setGameOver(_GameOverCause.bodyGone);
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
        final view = EntityModels.view(entry.typeId);
        if (view == null) return true;
        final wormHardness = _getWormHardness();
        final result = _playerAgent.behavior.onHitEntity(
          _playerAgent,
          view,
          wormHardness,
          _wormContext,
        );
        switch (result) {
          case HitResult.loseSegment:
            _loseSegment();
            break;
          case HitResult.destroyAndStep:
            _wormContext.addMissionProgressByTypeId(entry.typeId, 1);
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
        timeUrgentThresholdSeconds: 30.0,
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
      timeUrgentThresholdSeconds: _levelConfig.timeUrgentThresholdSeconds,
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
      _setGameOver(_GameOverCause.timeUp);
      return;
    }

    mainWorm.setGameTime(_gameTime);
    mainWorm.removeExpiredItemEffects(_gameTime);

    if (mainWorm.hasItemEffect(ItemType.freeze.effectTypeId)) return;

    _updateMagnetPulls(dt);

    if (mainWorm.hasItemEffect(ItemType.magnet.effectTypeId)) {
      final now = _gameTime;
      if (_magnetLastPullTime == null ||
          (now - _magnetLastPullTime!) >= BuffConfig.magnetPullDurationSeconds) {
        _triggerMagnetPull();
        _magnetLastPullTime = now;
      }
    } else {
      _magnetLastPullTime = null;
    }

    for (final item in _levelConfig.spawnCycle.items) {
      if (!_typeObjConfig.isEatable(item.objType)) continue;
      final acc = _spawnCycleAccumulators[item.objType] ?? 0;
      final next = acc + dt;
      _spawnCycleAccumulators[item.objType] = next;
      if (next >= item.intervalSeconds) {
        _spawnCycleAccumulators[item.objType] = next - item.intervalSeconds;
        _spawnByTypeId(item.objType);
      }
    }

    _trySpawnCoin();

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
      final entry = _mapEntityManager.getAt(nextHead);
      if (entry != null) {
        final view = EntityModels.view(entry.typeId);
        if (view != null && view.wormCanPassThrough) {
          mainWorm.step();
          return;
        }
      }
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
      if (consumed.typeId == _preyCoinTypeId) {
        _coinsCollectedThisRun++;
        _lastCoinEatenGameTime = _gameTime;
      }
      if (consumed.typeId == 'prey_flag') {
        final view = EntityModels.view(consumed.typeId);
        if (view != null) {
          _playerAgent.behavior.onEatEntity(_playerAgent, view, _wormContext);
        }
        _setVictory();
        return;
      }
      final view = EntityModels.view(consumed.typeId);
      if (view != null) {
        _playerAgent.behavior.onEatEntity(_playerAgent, view, _wormContext);
      }
      if (_allMissionsComplete() && !_flagSpawned) {
        _spawnFlag();
        _flagSpawned = true;
      }
      return;
    }

    if (_allMissionsComplete() && !_flagSpawned) {
      _spawnFlag();
      _flagSpawned = true;
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

class _MagnetPull {
  _MagnetPull({required this.entry, required this.startPos, required this.startTime});
  final MapEntityEntry entry;
  final Vector2 startPos;
  final double startTime;
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
    this.timeUrgentThresholdSeconds = 30.0,
  });

  final double timeRemainingSeconds;
  /// Còn <= X giây thì cảnh báo đỏ nháy. Từ level config.
  final double timeUrgentThresholdSeconds;
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
