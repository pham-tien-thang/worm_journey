import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/debug_grid_coordinates.dart';
import '../../../components/green_boss_worm/green_boss_worm.dart';
import '../../../components/green_boss_worm/green_boss_worm_config.dart';
import '../../../components/grid_background.dart';
import '../../../components/heart_burst_effect.dart';
import '../../../components/pineapple_worm/pineapple_worm.dart';
import '../../../components/pineapple_worm/pineapple_worm_config.dart';
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

/// Nguyên nhân game over: hết giờ hoặc mất hết thân (va chạm).
enum _GameOverCause { timeUp, bodyGone }

/// Snapshot khi sâu chết: map, nhiệm vụ, nguyên nhân; nếu timeUp thêm vị trí/hướng sâu; nếu bodyGone thêm thời gian còn lại.
class _DeathSnapshot {
  _DeathSnapshot({
    required this.entries,
    required this.missionCurrents,
    required this.cause,
    this.wormPositions,
    this.wormDirection,
    this.remainingTimeAtDeath,
    this.greenBossSegmentCount,
    this.greenBossLeavesEaten = 0,
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

  /// Độ dài boss xanh tại thời điểm chết để revive giữ damage đã gây ra.
  final int? greenBossSegmentCount;
  final int greenBossLeavesEaten;
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

  /// Bot/mini-bot active trong màn. Mọi bot đăng ký ở đây sẽ tự được tính vào
  /// occupied grid, spawn avoidance, buff expiry, và worm-vs-worm collision.
  final List<WormAgent> _botAgents = [];
  WormAgent? _pineappleAgent;
  WormAgent? _greenBossAgent;
  bool get _isLevel2 => level == 2;
  bool get _isLevel3 => level == 3;
  bool get _isLevel4GreenBoss =>
      level == 4 || _levelConfig.bossType == 'green_worm_boss';
  bool get _isLevel5GreenBoss =>
      level == 5 && _levelConfig.bossType == 'green_worm_boss';
  int _pineappleLeavesEaten = 0;
  static const int _pineappleLeavesLoseTarget = 10;
  int _greenBossLeavesEaten = 0;
  static const int _greenBossLeavesLoseTarget = 100;
  static const double _pineappleMoveIntervalScale = 1.10;
  static const double _level3PlayerMoveIntervalScale = 1.15;
  static const int _greenBossLength = 8;
  static const double _greenBossSpeedUnitIntervalScale = 0.1;
  static const double _greenBossBaseSpeedUnits = 0.5;
  static const int _level5GreenBossSpeedLagUnits = 7;
  static const int _pineappleBaseHardness = 25;
  static const int _greenBossHitSlowUnits = 3;
  static const double _greenBossHitSlowDurationSeconds = 1.5;
  static const int _level5GreenBossDamageSpeedUnits = 8;
  static const double _level5GreenBossDamageSpeedDurationSeconds = 1.0;
  static const double _greenBossMoveIntervalScale =
      1.0 - _greenBossBaseSpeedUnits * _greenBossSpeedUnitIntervalScale;
  static const double _greenBossEscapeMoveIntervalScale = 0.45;
  static const int _greenBossPoisonStepInterval = 3;
  static const int _greenBossMaxPoisonClouds = 48;
  static const double _poisonDurationSeconds = 20.0;
  static const double _poisonImmunitySeconds = 3.0;
  static const int _level5GreenBossMaxBodySegments = 10;
  static const int _level5GreenBossMaxLength =
      _level5GreenBossMaxBodySegments + 2;
  static const int _greenBossMinPlayerSpawnDistance = 8;
  static final Set<String> _greenBossAvoidedItemTypeIds = {
    ProjectType.snail.typeId,
    ProjectType.bomb.typeId,
  };
  double _pineappleMoveAccumulator = 0;
  double _greenBossMoveAccumulator = 0;
  double _greenBossHitSlowRemaining = 0;
  double _level5GreenBossDamageSpeedUntil = -1.0;
  int _greenBossCellsSincePoison = 0;
  bool _greenBossEscaping = false;
  double _poisonImmunityUntil = -1.0;

  /// Con sâu được điều khiển và lấy thông tin lên HUD.
  Worm get mainWorm => _playerAgent.worm;

  double get _playerMoveInterval =>
      level == 3
          ? GameConfig.moveInterval * _level3PlayerMoveIntervalScale
          : GameConfig.moveInterval;

  double get _greenBossBaseMoveInterval =>
      _isLevel5GreenBoss
          ? GameConfig.moveInterval *
              (1.0 +
                  _level5GreenBossSpeedLagUnits *
                      _greenBossSpeedUnitIntervalScale)
          : GameConfig.moveInterval * _greenBossMoveIntervalScale;

  double get _greenBossSpeedUnitMoveInterval =>
      GameConfig.moveInterval * _greenBossSpeedUnitIntervalScale;

  int get _greenBossMaxLengthForCurrentLevel =>
      _isLevel5GreenBoss ? _level5GreenBossMaxLength : _greenBossLength;

  int get _greenBossMaxBodySegmentsForHud =>
      _isLevel5GreenBoss
          ? _level5GreenBossMaxBodySegments
          : _greenBossLength - 2;

  int get _greenBossBodySegmentsForHud {
    final bodySegments = (_greenBossAgent?.segmentCount ?? 2) - 2;
    return max(0, min(bodySegments, _greenBossMaxBodySegmentsForHud));
  }

  late WormGameContext _wormContext;
  late TypeObjConfig _typeObjConfig;
  late MapEntityManager _mapEntityManager;

  /// Accumulator theo typeId cho spawn theo chu kỳ (từ _levelConfig.spawnCycle).
  final Map<String, double> _spawnCycleAccumulators = {};
  final Map<String, int> _spawnCyclePositionIndexes = {};
  final Map<String, double> _poisonExpireTimes = {};
  int _nextPreyLeafSequenceIndex = 0;
  bool _missionCompleteSpawnsPlaced = false;

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

  /// Các x_mark sinh khi sâu hồng mất đốt. Khi chơi lại từ death snapshot,
  /// xoá các ô này để không giữ lại vật cản do lượt chơi trước tạo ra.
  final Set<String> _runtimeDeathXMarkKeys = {};

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
  double _cameraShakeRemaining = 0;
  double _cameraShakeDuration = 0;
  double _cameraShakeAmplitude = 0;
  double _cameraShakePhase = 0;

  static const double _damageShakeDurationSeconds = 0.12;
  static const double _damageShakeAmplitudePixels = 4.0;
  static const double _bombShakeDurationSeconds = 0.24;
  static const double _bombShakeAmplitudePixels = 10.0;

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
      _grantPoisonImmunity();
      return;
    }
    if (id == ItemType.dizzy.effectTypeId &&
        mainWorm.hasItemEffect(ItemType.dizzy.effectTypeId)) {
      mainWorm.removeItemEffects([ItemType.dizzy.effectTypeId]);
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
  void _instantEffectBomb({WormAgent? source, bool damageGreenBoss = true}) {
    _triggerCameraShake(
      duration: _bombShakeDurationSeconds,
      amplitude: _bombShakeAmplitudePixels,
    );
    _triggerBombHaptic();
    final sourceAgent = source ?? _playerAgent;
    final head = sourceAgent.worm.headGridPosition;
    final r = BuffConfig.bombRadiusTiles;
    var hitGreenBoss = false;
    for (var dy = -r; dy <= r; dy++) {
      for (var dx = -r; dx <= r; dx++) {
        if (dx == 0 && dy == 0) continue;
        if (max(dx.abs(), dy.abs()) > r) continue;
        final grid = Vector2(head.x + dx, head.y + dy);
        if (_mapEntityManager.hasBlockingEntityAt(grid)) {
          _destroyEntityAt(grid);
        }
        if (!hitGreenBoss && _greenBossOccupiesGrid(grid)) {
          hitGreenBoss = true;
        }
      }
    }
    if (damageGreenBoss && hitGreenBoss) {
      _damageGreenBossFromBomb();
    }
    if (sourceAgent.worm is PinkWorm) {
      (sourceAgent.worm as PinkWorm).triggerBombExplosion();
    }
  }

  bool _greenBossOccupiesGrid(Vector2 grid) {
    final agent = _greenBossAgent;
    if (agent == null || _greenBossEscaping) return false;
    return _wormContainsGrid(agent, grid);
  }

  void _damageGreenBossFromBomb() {
    final agent = _greenBossAgent;
    if (agent == null || _greenBossEscaping) return;
    for (var i = 0; i < 2; i++) {
      final currentAgent = _greenBossAgent;
      if (currentAgent == null || _greenBossEscaping) return;
      _loseSegmentFor(currentAgent);
      if (currentAgent.segmentCount <= 2) {
        _startGreenBossEscape();
        return;
      }
    }
  }

  /// Magnet: hút mồi trong phạm vi [BuffConfig.magnetRangeTiles] ô (Chebyshev) từ đầu rắn, thuộc [magnetAttractTypeIds].
  void _triggerMagnetPull() {
    final head = mainWorm.headGridPosition;
    final range = BuffConfig.magnetRangeTiles;
    final toPull =
        _mapEntityManager.entries.where((e) {
          if (!BuffConfig.magnetAttractTypeIds.contains(e.typeId)) return false;
          final dx = (e.grid.x - head.x).abs();
          final dy = (e.grid.y - head.y).abs();
          return dx <= range && dy <= range;
        }).toList();
    for (final entry in toPull) {
      final removed = _mapEntityManager.removeAt(entry.grid);
      if (removed != null) {
        _magnetPulls.add(
          _MagnetPull(
            entry: removed,
            startPos: removed.component.position.clone(),
            startTime: _gameTime,
          ),
        );
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

  void _applyPoisonToPlayer() {
    if (_isPlayerPoisonProtected) return;
    final duration = BuffConfig.durationSecondsFor(ItemType.dizzy.effectTypeId);
    if (duration > 0) {
      mainWorm.addItemEffect(ItemType.dizzy.effectTypeId, _gameTime + duration);
      if (mainWorm is PinkWorm) {
        (mainWorm as PinkWorm).applyPoisonReverse();
      } else {
        mainWorm.setPoisonedReverse(true);
      }
    }
    _loseSegmentFor(_playerAgent, triggerFeedback: false);
  }

  bool get _isPlayerPoisonProtected =>
      mainWorm.isPoisonedReverse || _gameTime < _poisonImmunityUntil;

  void _grantPoisonImmunity() {
    _poisonImmunityUntil = _gameTime + _poisonImmunitySeconds;
  }

  /// Tăng tiến độ nhiệm vụ có [id] (mặc định 'mission2').
  void addMission2Progress() {
    final i = _missionConfigs.indexWhere((m) => m.id == 'mission2');
    if (i >= 0 && i < _missionCurrents.length) {
      final target =
          _missionTargetOverrides['mission2'] ?? _missionConfigs[i].target;
      _missionCurrents[i] = (_missionCurrents[i] + 1).clamp(0, target);
    }
  }

  /// Ghi đè mục tiêu nhiệm vụ theo id (vd. 'mission2'). > 0 thì hiện trên HUD; nếu chưa có mission đó thì thêm vào.
  void setMission2Target(int target) {
    final t = target.clamp(0, 9999);
    if (t <= 0) return;
    _missionTargetOverrides['mission2'] = t;
    if (_missionConfigs.every((m) => m.id != 'mission2')) {
      _missionConfigs = [
        ..._missionConfigs,
        MissionConfig(
          id: 'mission2',
          typeId: ProjectType.preyLeaf.typeId,
          target: 0,
        ),
      ];
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
  static const int totalWorldRows =
      _extraRowsAboveBelow + playableRowCount + _extraRowsAboveBelow;

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
      _debugGridCoordinates?.position = Vector2(
        0,
        playableStartRow * _segmentSize,
      );
    }
  }

  int _wormInitLength = 1;
  int _wormMaxLength = 10;

  WormInfo get _pineappleInfo => const WormInfo(
    id: 'bot_pineapple',
    name: 'Sâu dứa',
    description: 'Bot tự tìm lá và né chướng ngại',
    wormType: WormType.bot,
    team: WormTeam.bot,
    skin: 'pineapple',
  );

  WormInfo get _pineapplePlayerInfo => const WormInfo(
    id: 'player_pineapple',
    name: 'Sâu dứa',
    description: 'Sâu điều khiển bởi joystick',
    wormType: WormType.playerControlled,
    team: WormTeam.player,
    skin: 'pineapple',
  );

  WormInfo get _greenBossInfo => const WormInfo(
    id: 'boss_green_worm',
    name: 'Sâu xanh',
    description: 'Boss sâu xanh',
    wormType: WormType.bot,
    team: WormTeam.bot,
    skin: 'green_boss',
  );

  @override
  Future<void> onLoad() async {
    _deathSnapshot = null;
    _hasRevivedOnce = false;
    _coinsCollectedThisRun = 0;
    _lastCoinEatenGameTime = -999.0;
    _greenBossMoveAccumulator = 0;
    _greenBossHitSlowRemaining = 0;
    _level5GreenBossDamageSpeedUntil = -1.0;
    _greenBossCellsSincePoison = 0;
    _greenBossLeavesEaten = 0;
    _greenBossEscaping = false;
    _poisonExpireTimes.clear();
    _poisonImmunityUntil = -1.0;
    _firstCoinSpawned = false;
    _gridRows = playableRowCount;
    camera.viewport = MaxViewport();

    _wormInitLength = await SharedPrefsService.getWormInitLength();
    _wormMaxLength = await SharedPrefsService.getWormMaxLength();

    _levelConfig = await loadLevelJsonConfig(level);
    _typeObjConfig = await TypeObjConfig.load();
    await _claimLevelEntryItemRewards();
    _missionConfigs = _levelConfig.missions;
    _missionCurrents = List.filled(_missionConfigs.length, 0);
    _timeLimit = _levelConfig.timeLimitSeconds;
    _nextPreyLeafSequenceIndex = 0;
    _missionCompleteSpawnsPlaced =
        _levelConfig.missionCompleteSpawns.placements.isEmpty;

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
      preyLeafCountOnMapGetter:
          () =>
              _mapEntityManager.entries
                  .where((e) => e.typeId == ProjectType.preyLeaf.typeId)
                  .length,
    );

    final initLen = shouldApplyDebug ? 10 : (_wormInitLength + 2);
    final maxLen = shouldApplyDebug ? null : _wormMaxLength;
    final playerInitialPositions = _initialPlayerPositions(initLen);
    final playerInitialLength = playerInitialPositions?.length ?? initLen;
    final worm = _createPlayerWorm(
      segmentSize: _segmentSize,
      moveInterval: _playerMoveInterval,
      initialLength: playerInitialLength,
      maxLength: maxLen,
      gridRows: _gridRows,
      initialGridPositions: playerInitialPositions,
      initialDirection:
          playerInitialPositions != null ? WormDirection.right : null,
    );
    world.add(worm);
    worm.setOnGrowAtMax(_onWormGrowAtMax);
    _playerAgent = WormAgent(worm: worm, behavior: PlayerWormBehavior());
    if (_isLevel2) {
      final pineapple = PineappleWorm(
        config: PineappleWormConfig(
          segmentSize: _segmentSize,
          moveInterval: GameConfig.moveInterval * _pineappleMoveIntervalScale,
          initialLength: initLen,
          maxLength: maxLen,
          gridRows: _gridRows,
          initialGridPositions: _level2PineappleStartPositions(
            initLen,
            avoid: mainWorm.allGridPositions,
          ),
          initialDirection: WormDirection.left,
        ),
        info: _pineappleInfo,
        position: Vector2(0, playableStartRow * _segmentSize),
        gridRowsOverride: _gridRows,
      );
      world.add(pineapple);
      _pineappleAgent = _registerBotAgent(
        WormAgent(worm: pineapple, behavior: PlayerWormBehavior()),
      );
    }
    _spawnGreenBoss(avoid: mainWorm.allGridPositions);

    _registerMapEntityPlacers();
    _placeAllMapEntitiesFromConfig();
    _flagSpawned = _hasEntityOnMap(ProjectType.preyFlag.typeId);
    _ensureLeafOnMap();

    if (shouldApplyDebug) {
      _debugGridCoordinates = DebugGridCoordinates(
        segmentSize: _segmentSize,
        gridColumns: GameConfig.gridColumns,
        gridRows: playableRowCount,
      );
      _debugGridCoordinates!.position = Vector2(
        0,
        playableStartRow * _segmentSize,
      );
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

  WormAgent _registerBotAgent(WormAgent agent) {
    _botAgents.add(agent);
    return agent;
  }

  Future<void> _claimLevelEntryItemRewards() async {
    for (final reward in _levelConfig.entryItemRewards.entries) {
      await SharedPrefsService.claimLevelEntryItemReward(
        level,
        reward.key,
        reward.value,
      );
    }
  }

  Worm _createPlayerWorm({
    required double segmentSize,
    required double moveInterval,
    required int initialLength,
    required int? maxLength,
    required int gridRows,
    required List<Vector2>? initialGridPositions,
    required WormDirection? initialDirection,
  }) {
    if (_isLevel5GreenBoss) {
      return PineappleWorm(
        config: PineappleWormConfig(
          segmentSize: segmentSize,
          moveInterval: moveInterval,
          initialLength: initialLength,
          maxLength: maxLength,
          gridRows: gridRows,
          initialGridPositions: initialGridPositions,
          initialDirection: initialDirection,
        ),
        info: _pineapplePlayerInfo,
        position: Vector2(0, playableStartRow * segmentSize),
        gridRowsOverride: gridRows,
      );
    }
    return PinkWorm(
      config: PinkWormConfig(
        segmentSize: segmentSize,
        moveInterval: moveInterval,
        initialLength: initialLength,
        maxLength: maxLength,
        gridRows: gridRows,
        initialGridPositions: initialGridPositions,
        initialDirection: initialDirection,
      ),
      info: WormInfo.playerDefault,
      position: Vector2(0, playableStartRow * segmentSize),
      gridRowsOverride: gridRows,
    );
  }

  void _removeBotAgents() {
    for (final agent in _botAgents) {
      agent.worm.removeFromParent();
    }
    _botAgents.clear();
    _pineappleAgent = null;
    _greenBossAgent = null;
    _greenBossEscaping = false;
    _greenBossHitSlowRemaining = 0;
    _level5GreenBossDamageSpeedUntil = -1.0;
    _greenBossCellsSincePoison = 0;
  }

  Iterable<WormAgent> _activeWormAgents() sync* {
    yield _playerAgent;
    yield* _botAgents;
  }

  Iterable<Vector2> _allWormGridPositions() sync* {
    for (final agent in _activeWormAgents()) {
      yield* agent.allGridPositions;
    }
  }

  void _spawnGreenBoss({
    Iterable<Vector2> avoid = const [],
    int length = _greenBossLength,
  }) {
    if (!_isLevel4GreenBoss) return;
    final bossLength = length.clamp(2, _greenBossMaxLengthForCurrentLevel);
    final positions = _greenBossStartPositions(
      avoid: avoid,
      length: bossLength,
    );
    final boss = GreenBossWorm(
      config: GreenBossWormConfig(
        segmentSize: _segmentSize,
        moveInterval: _greenBossBaseMoveInterval,
        initialLength: bossLength,
        maxLength: _isLevel5GreenBoss ? _level5GreenBossMaxLength : bossLength,
        gridRows: _gridRows,
        initialGridPositions: positions,
        initialDirection: WormDirection.left,
      ),
      info: _greenBossInfo,
      position: Vector2(0, playableStartRow * _segmentSize),
      gridRowsOverride: _gridRows,
    );
    world.add(boss);
    _greenBossAgent = _registerBotAgent(
      WormAgent(worm: boss, behavior: PlayerWormBehavior()),
    );
    _greenBossEscaping = bossLength <= 2;
    _greenBossHitSlowRemaining = 0;
    _level5GreenBossDamageSpeedUntil = -1.0;
    _greenBossCellsSincePoison = 0;
    if (_greenBossEscaping) _startGreenBossEscape();
  }

  Set<String> _occupiedGridKeys() =>
      _mapEntityManager.occupiedGridKeys(_allWormGridPositions());

  bool _isGridInCameraView(Vector2 grid) {
    if (_cameraY == null || !_loaded) return true;
    final halfViewY = camera.viewport.size.y / 2;
    final cellCenterY = (grid.y + playableStartRow + 0.5) * _segmentSize;
    return cellCenterY >= _cameraY! - halfViewY &&
        cellCenterY <= _cameraY! + halfViewY;
  }

  /// Hàng 6 trở đi (grid row >= 5) cho lá đầu; các lá sau spawn bình thường.
  static const int _firstLeafMinRow = 5;

  void _spawnPrey() {
    if (_levelConfig.preyLeafSequence.isNotEmpty) {
      _spawnNextConfiguredLeaf();
      return;
    }
    final occupied = _occupiedGridKeys();
    final isFirstLeaf =
        !_mapEntityManager.entries.any(
          (e) => e.typeId == ProjectType.preyLeaf.typeId,
        );
    final entry = _mapEntityManager.spawn(
      ProjectType.preyLeaf.typeId,
      occupied,
      isCellVisible: _isGridInCameraView,
      minRow: isFirstLeaf ? _firstLeafMinRow : null,
    );
    if (entry != null) world.add(entry.component);
  }

  void _spawnNextConfiguredLeaf() {
    while (_nextPreyLeafSequenceIndex < _levelConfig.preyLeafSequence.length) {
      final grid = _levelConfig.preyLeafSequence[_nextPreyLeafSequenceIndex++];
      if (_spawnAtGridIfFree(ProjectType.preyLeaf.typeId, grid)) {
        _spawnPreyLeafCompanions(grid);
        return;
      }
    }
  }

  String _gridCoordinateLabel(Vector2 grid) {
    var col = grid.x.toInt() + 1;
    var label = '';
    while (col > 0) {
      col--;
      label = String.fromCharCode(0x41 + col % 26) + label;
      col ~/= 26;
    }
    return '$label${grid.y.toInt() + 1}';
  }

  void _spawnPreyLeafCompanions(Vector2 leafGrid) {
    final config =
        _levelConfig.preyLeafCompanionSpawns[_gridCoordinateLabel(leafGrid)];
    if (config == null) return;
    for (final entry in config.placements.entries) {
      for (final grid in entry.value) {
        _spawnAtGridIfFree(entry.key, grid);
      }
    }
  }

  bool _spawnAtGridIfFree(String typeId, Vector2 grid) {
    final key = _gridKey(grid);
    if (_occupiedGridKeys().contains(key)) return false;
    final comp = _mapEntityManager.placeAt(grid, typeId);
    world.add(comp);
    return true;
  }

  bool _hasEntityOnMap(String typeId) =>
      _mapEntityManager.entries.any((e) => e.typeId == typeId);

  bool _hasLeafOnMap() => _hasEntityOnMap(ProjectType.preyLeaf.typeId);

  void _ensureLeafOnMap() {
    if (!_hasLeafOnMap()) _spawnPrey();
  }

  void _syncLeafSequenceIndexFromState() {
    if (_levelConfig.preyLeafSequence.isEmpty) return;
    final leafMissionIndex = _missionConfigs.indexWhere(
      (m) => m.id == 'leaves',
    );
    final eatenCount =
        leafMissionIndex >= 0 && leafMissionIndex < _missionCurrents.length
            ? _missionCurrents[leafMissionIndex]
            : 0;
    final leavesOnMap =
        _mapEntityManager.entries
            .where((e) => e.typeId == ProjectType.preyLeaf.typeId)
            .length;
    _nextPreyLeafSequenceIndex = (eatenCount + leavesOnMap).clamp(
      0,
      _levelConfig.preyLeafSequence.length,
    );
  }

  void _reducePineappleScoreOnRevive() {
    if (!_isLevel2) return;
    _pineappleLeavesEaten = (_pineappleLeavesEaten - 5).clamp(
      0,
      _pineappleLeavesLoseTarget,
    );
  }

  /// Sinh một entity eatable theo [typeId] (từ config spawnCycle). Điều kiện đặc thù từng loại (vd. dừa: tối đa 1 quả, không sinh khi sâu đang buff dừa).
  void _spawnByTypeId(
    String typeId, {
    List<Vector2> preferredPositions = const [],
    bool preferredPositionsOnly = false,
  }) {
    if (typeId == ProjectType.preyCoconut.typeId) {
      if (mainWorm.hasItemEffect(ProjectType.preyCoconut.typeId)) return;
      if (_mapEntityManager.entries.any((e) => e.typeId == typeId)) return;
    }
    if (preferredPositions.isNotEmpty) {
      final start = _spawnCyclePositionIndexes[typeId] ?? 0;
      for (var i = 0; i < preferredPositions.length; i++) {
        final index = (start + i) % preferredPositions.length;
        if (_spawnAtGridIfFree(typeId, preferredPositions[index])) {
          _spawnCyclePositionIndexes[typeId] = index + 1;
          return;
        }
      }
      if (preferredPositionsOnly) return;
    }
    final occupied = _occupiedGridKeys();
    final entry = _mapEntityManager.spawn(
      typeId,
      occupied,
      isCellVisible: _isGridInCameraView,
    );
    if (entry != null) world.add(entry.component);
  }

  bool get _greenBossObjectiveComplete =>
      !_isLevel5GreenBoss || _greenBossAgent == null || _greenBossEscaping;

  bool get _levelObjectivesReadyForFlag =>
      _allMissionsComplete() && _greenBossObjectiveComplete;

  void _placeMissionCompleteSpawnsIfNeeded() {
    if (_missionCompleteSpawnsPlaced || !_levelObjectivesReadyForFlag) return;
    var placedAny = false;
    for (final entry in _levelConfig.missionCompleteSpawns.placements.entries) {
      for (final grid in entry.value) {
        final placed = _spawnAtGridIfFree(entry.key, grid);
        placedAny = placed || placedAny;
        if (placed && entry.key == ProjectType.preyFlag.typeId) {
          _flagSpawned = true;
        }
      }
    }
    _missionCompleteSpawnsPlaced =
        placedAny || _levelConfig.missionCompleteSpawns.placements.isEmpty;
  }

  void _trySpawnFlagForObjectives() {
    if (_gameOver) return;
    _placeMissionCompleteSpawnsIfNeeded();
    if (!_levelObjectivesReadyForFlag || _flagSpawned) return;
    if (_isLevel2) {
      _setVictory();
      return;
    }
    _spawnFlag();
    _flagSpawned = true;
  }

  Vector2? _nearestLeafGridFrom(Vector2 from) {
    Vector2? nearest;
    var best = 1 << 30;
    for (final entry in _mapEntityManager.entries) {
      if (entry.typeId != ProjectType.preyLeaf.typeId) continue;
      final d =
          (entry.grid.x - from.x).abs().toInt() +
          (entry.grid.y - from.y).abs().toInt();
      if (d < best) {
        best = d;
        nearest = entry.grid;
      }
    }
    return nearest;
  }

  String _gridKey(Vector2 grid) => '${grid.x.toInt()},${grid.y.toInt()}';

  List<Vector2> _linearWormPositions(
    WormDirection direction,
    int length, {
    int rowOffset = 0,
  }) {
    final safeLength = length.clamp(2, GameConfig.gridColumns);
    final centerRow = (_gridRows / 2).floor();
    final row = (centerRow + rowOffset).clamp(0, _gridRows - 1);
    final startCol = ((GameConfig.gridColumns - safeLength) / 2).floor().clamp(
      0,
      GameConfig.gridColumns - safeLength,
    );
    final headCol =
        direction == WormDirection.left ? startCol : startCol + safeLength - 1;
    final head = Vector2(headCol.toDouble(), row.toDouble());
    final step = direction.toVector();
    return List<Vector2>.generate(
      safeLength,
      (i) => head - step * i.toDouble(),
    );
  }

  bool _positionsOverlap(List<Vector2> positions, Iterable<Vector2> avoid) {
    final occupied = avoid.map(_gridKey).toSet();
    for (final position in positions) {
      if (occupied.contains(_gridKey(position))) return true;
    }
    return false;
  }

  List<Vector2> _level2PlayerStartPositions(int length) =>
      _linearWormPositions(WormDirection.right, length, rowOffset: 4);

  List<Vector2>? _initialPlayerPositions(int length) {
    final configured = _levelConfig.initialWormPositions;
    if (configured.length >= 2) return configured;
    if (_isLevel2) return _level2PlayerStartPositions(length);
    if (_isLevel4GreenBoss) return _level4PlayerStartPositions(length);
    return null;
  }

  List<Vector2> _level4PlayerStartPositions(int length) {
    final bossPositions = _greenBossStartPositions();
    const rowOffsets = [14, 12, 10, 8, 6, 4, 0, -4, -8];
    for (final offset in rowOffsets) {
      final positions = _linearWormPositions(
        WormDirection.right,
        length,
        rowOffset: offset,
      );
      if (_isPlayerSpawnFarFromGreenBoss(positions, bossPositions)) {
        return positions;
      }
    }
    return _linearWormPositions(WormDirection.right, length, rowOffset: 10);
  }

  List<Vector2> _level2PineappleStartPositions(
    int length, {
    Iterable<Vector2> avoid = const [],
  }) {
    const rowOffsets = [-4, -6, 6, -8, 8, 0, -10, 10];
    for (final offset in rowOffsets) {
      final positions = _linearWormPositions(
        WormDirection.left,
        length,
        rowOffset: offset,
      );
      if (!_positionsOverlap(positions, avoid)) return positions;
    }
    return _linearWormPositions(WormDirection.left, length, rowOffset: -4);
  }

  bool _isPlayerSpawnFarFromGreenBoss(
    List<Vector2> playerPositions,
    Iterable<Vector2> bossPositions,
  ) {
    return _minGridDistanceBetween(playerPositions, bossPositions) >=
        _greenBossMinPlayerSpawnDistance;
  }

  int _minGridDistanceBetween(Iterable<Vector2> a, Iterable<Vector2> b) {
    var best = 1 << 30;
    for (final left in a) {
      for (final right in b) {
        final d =
            (left.x - right.x).abs().toInt() + (left.y - right.y).abs().toInt();
        if (d < best) best = d;
      }
    }
    return best;
  }

  List<Vector2> _greenBossStartPositions({
    Iterable<Vector2> avoid = const [],
    int length = _greenBossLength,
  }) {
    final bossLength = length.clamp(2, _greenBossMaxLengthForCurrentLevel);
    const rowsFromTop = [2, 4, 6, 8, 10];
    final occupied = avoid.map(_gridKey).toSet();
    for (final row in rowsFromTop) {
      final head = Vector2(
        (GameConfig.gridColumns - bossLength).toDouble(),
        row.toDouble(),
      );
      final positions = List<Vector2>.generate(
        bossLength,
        (i) => Vector2(head.x + i, head.y),
      );
      final inBounds = positions.every(
        (p) =>
            p.x >= 0 &&
            p.x < GameConfig.gridColumns &&
            p.y >= 0 &&
            p.y < _gridRows,
      );
      if (!inBounds) continue;
      if (positions.any((p) => occupied.contains(_gridKey(p)))) continue;
      return positions;
    }
    return List<Vector2>.generate(
      bossLength,
      (i) => Vector2((GameConfig.gridColumns - 1 - i).toDouble(), 2),
    );
  }

  bool _isBlockedForAgentPath(Vector2 grid, WormAgent agent) {
    if (grid.x < 0 ||
        grid.x >= GameConfig.gridColumns ||
        grid.y < 0 ||
        grid.y >= _gridRows)
      return true;
    if (_mapEntityManager.hasBlockingEntityAt(grid)) return true;
    for (final part in agent.allGridPositions) {
      if (part.x == grid.x && part.y == grid.y) return true;
    }
    return _wormAtGrid(grid, except: agent) != null;
  }

  WormDirection _choosePineappleDirection(WormAgent agent) {
    final worm = agent.worm;
    final target = _nearestLeafGridFrom(worm.headGridPosition);
    final current = worm.currentDirection;
    final candidates = <WormDirection>[
      current,
      WormDirection.up,
      WormDirection.down,
      WormDirection.left,
      WormDirection.right,
    ];
    WormDirection best = current;
    var bestScore = 1 << 30;
    for (final dir in candidates) {
      if (dir.isOppositeOf(current)) continue;
      final next = worm.headGridPosition + dir.toVector();
      if (_isBlockedForAgentPath(next, agent)) continue;
      final score =
          target == null
              ? 0
              : (target.x - next.x).abs().toInt() +
                  (target.y - next.y).abs().toInt();
      if (score < bestScore) {
        bestScore = score;
        best = dir;
      }
    }
    // Nếu không có hướng né an toàn, giữ hướng hiện tại để movement gateway
    // xử lý va chạm bằng hardness thay vì đứng giật tại chỗ.
    return best;
  }

  int _gridDistance(Vector2 a, Vector2 b) =>
      (a.x - b.x).abs().toInt() + (a.y - b.y).abs().toInt();

  int _gridRadiusDistance(Vector2 a, Vector2 b) =>
      max((a.x - b.x).abs().toInt(), (a.y - b.y).abs().toInt());

  ({Vector2 target, int distance})? _nearestReachablePlayerPartForGreenBoss(
    WormAgent agent,
  ) {
    ({Vector2 target, int distance})? best;
    for (final part in mainWorm.allGridPositions) {
      final distance = _greenBossPathDistance(agent, part);
      if (distance == null) continue;
      if (best == null || distance < best.distance) {
        best = (target: part, distance: distance);
      }
    }
    return best;
  }

  int? _greenBossPathDistance(WormAgent agent, Vector2 target) {
    final head = agent.worm.headGridPosition;
    if (head.x == target.x && head.y == target.y) return 0;

    final current = agent.worm.currentDirection;
    final queue = <Vector2>[head];
    final distances = <String, int>{_gridKey(head): 0};

    for (var index = 0; index < queue.length; index++) {
      final currentGrid = queue[index];
      final currentDistance = distances[_gridKey(currentGrid)]!;
      for (final direction in _allDirections) {
        if (currentGrid.x == head.x &&
            currentGrid.y == head.y &&
            direction.isOppositeOf(current)) {
          continue;
        }
        final next = currentGrid + direction.toVector();
        final key = _gridKey(next);
        if (distances.containsKey(key)) continue;
        if (_isBlockedForGreenBossPath(next, agent, target)) continue;
        final nextDistance = currentDistance + 1;
        if (next.x == target.x && next.y == target.y) return nextDistance;
        distances[key] = nextDistance;
        queue.add(next);
      }
    }
    return null;
  }

  Vector2? _nearbyPriorityFoodForGreenBoss(
    WormAgent agent,
    int? playerPathDistance,
  ) {
    final head = agent.worm.headGridPosition;
    Vector2? target;
    var best = 1 << 30;

    for (final entry in _mapEntityManager.entries) {
      if (entry.typeId != ProjectType.preyLeaf.typeId &&
          entry.typeId != ProjectType.speed.typeId) {
        continue;
      }
      final radiusDistance = _gridRadiusDistance(head, entry.grid);
      if (radiusDistance > 2) continue;

      final pathDistance = _greenBossPathDistance(agent, entry.grid);
      if (pathDistance == null) continue;

      // Nếu item ở gần theo toạ độ nhưng bị thân chắn làm đường vòng xa,
      // và sâu hồng gần đầu hơn theo đường đi thực tế, bỏ item để lao vào sâu hồng.
      if (playerPathDistance != null && playerPathDistance <= pathDistance) {
        continue;
      }

      final score =
          pathDistance + (entry.typeId == ProjectType.speed.typeId ? 0 : 4);
      if (score < best) {
        best = score;
        target = entry.grid;
      }
    }
    return target;
  }

  Vector2? _nearestReachableLeafForGreenBoss(WormAgent agent) {
    Vector2? target;
    var best = 1 << 30;
    for (final entry in _mapEntityManager.entries) {
      if (entry.typeId != ProjectType.preyLeaf.typeId) continue;
      final distance = _greenBossPathDistance(agent, entry.grid);
      if (distance == null) continue;
      if (distance < best) {
        best = distance;
        target = entry.grid;
      }
    }
    return target;
  }

  bool _isBlockedForGreenBossPath(
    Vector2 grid,
    WormAgent agent,
    Vector2 target,
  ) {
    if (grid.x < 0 ||
        grid.x >= GameConfig.gridColumns ||
        grid.y < 0 ||
        grid.y >= _gridRows) {
      return true;
    }
    if (!(grid.x == target.x && grid.y == target.y)) {
      final entry = _mapEntityManager.getAt(grid);
      if (entry != null &&
          _greenBossAvoidedItemTypeIds.contains(entry.typeId)) {
        return true;
      }
    }
    if (_mapEntityManager.hasBlockingEntityAt(grid)) return true;
    for (final part in agent.allGridPositions) {
      if (part.x == grid.x && part.y == grid.y) return true;
    }
    final other = _wormAtGrid(grid, except: agent);
    return other != null && !(grid.x == target.x && grid.y == target.y);
  }

  WormDirection? _firstGreenBossPathDirection(WormAgent agent, Vector2 target) {
    final head = agent.worm.headGridPosition;
    final current = agent.worm.currentDirection;
    if (head.x == target.x && head.y == target.y) return null;

    final queue = <Vector2>[head];
    final cameFrom = <String, ({String previous, WormDirection direction})>{};
    final seen = <String>{_gridKey(head)};
    var foundKey = '';

    for (var index = 0; index < queue.length; index++) {
      final currentGrid = queue[index];
      if (currentGrid.x == target.x && currentGrid.y == target.y) {
        foundKey = _gridKey(currentGrid);
        break;
      }
      for (final direction in _allDirections) {
        if (currentGrid.x == head.x &&
            currentGrid.y == head.y &&
            direction.isOppositeOf(current)) {
          continue;
        }
        final next = currentGrid + direction.toVector();
        final key = _gridKey(next);
        if (seen.contains(key)) continue;
        if (_isBlockedForGreenBossPath(next, agent, target)) continue;
        seen.add(key);
        cameFrom[key] = (previous: _gridKey(currentGrid), direction: direction);
        queue.add(next);
      }
    }

    if (foundKey.isEmpty) return null;
    var key = foundKey;
    var step = cameFrom[key];
    while (step != null && step.previous != _gridKey(head)) {
      key = step.previous;
      step = cameFrom[key];
    }
    return step?.direction;
  }

  WormDirection _chooseGreenBossDirection(WormAgent agent) {
    final current = agent.worm.currentDirection;
    if (_isLevel5GreenBoss) {
      final leafTarget = _nearestReachableLeafForGreenBoss(agent);
      if (leafTarget != null) {
        final pathDirection = _firstGreenBossPathDirection(agent, leafTarget);
        if (pathDirection != null) return pathDirection;
      }
    }
    final playerTarget = _nearestReachablePlayerPartForGreenBoss(agent);
    final itemTarget = _nearbyPriorityFoodForGreenBoss(
      agent,
      playerTarget?.distance,
    );
    final target = itemTarget ?? playerTarget?.target;
    if (target == null) return current;

    final pathDirection = _firstGreenBossPathDirection(agent, target);
    if (pathDirection != null) return pathDirection;

    final head = agent.worm.headGridPosition;
    WormDirection? best;
    var bestScore = 1 << 30;
    for (final direction in [current, ..._allDirections]) {
      if (direction.isOppositeOf(current)) continue;
      final next = head + direction.toVector();
      if (_isBlockedForGreenBossPath(next, agent, target)) continue;
      final score = _gridDistance(next, target);
      if (score < bestScore) {
        bestScore = score;
        best = direction;
      }
    }

    // Không tự đâm thân nếu còn bất kỳ hướng hợp lệ nào. Nếu không có hướng hợp lệ,
    // trả current để movement gateway xử lý va chạm như các bot khác.
    return best ?? current;
  }

  void _startGreenBossEscape() {
    final agent = _greenBossAgent;
    if (agent == null) return;
    _greenBossEscaping = true;
    _greenBossHitSlowRemaining = 0;
    _level5GreenBossDamageSpeedUntil = -1.0;
    _greenBossCellsSincePoison = 0;
    agent.worm.setMoveInterval(
      GameConfig.moveInterval * _greenBossEscapeMoveIntervalScale,
    );
    _trySpawnFlagForObjectives();
  }

  void _triggerGreenBossHitSlow() {
    final agent = _greenBossAgent;
    if (agent == null || _greenBossEscaping) return;
    _greenBossHitSlowRemaining = _greenBossHitSlowDurationSeconds;
    _syncGreenBossMoveInterval(agent);
  }

  void _updateGreenBossHitSlow(double dt) {
    final agent = _greenBossAgent;
    if (agent == null || _greenBossEscaping) return;
    final hasDamageSpeedTimer = _level5GreenBossDamageSpeedUntil >= 0;
    if (_greenBossHitSlowRemaining <= 0 && !hasDamageSpeedTimer) return;

    if (_greenBossHitSlowRemaining > 0) {
      _greenBossHitSlowRemaining -= dt;
      if (_greenBossHitSlowRemaining <= 0) {
        _greenBossHitSlowRemaining = 0;
      }
    }
    if (_level5GreenBossDamageSpeedUntil >= 0 &&
        _gameTime >= _level5GreenBossDamageSpeedUntil) {
      _level5GreenBossDamageSpeedUntil = -1.0;
    }
    _syncGreenBossMoveInterval(agent);
  }

  void _triggerLevel5GreenBossDamageSpeed() {
    final agent = _greenBossAgent;
    if (!_isLevel5GreenBoss || agent == null || _greenBossEscaping) return;
    _level5GreenBossDamageSpeedUntil =
        _gameTime + _level5GreenBossDamageSpeedDurationSeconds;
    _syncGreenBossMoveInterval(agent);
  }

  void _syncGreenBossMoveInterval(WormAgent agent) {
    agent.worm.setMoveInterval(
      _isLevel5GreenBossDamageSpeedActive
          ? _greenBossDamageSpeedMoveInterval(agent)
          : _greenBossHitSlowRemaining > 0
          ? _greenBossSlowedMoveInterval(agent)
          : _greenBossUnslowedMoveInterval(agent),
    );
  }

  double _greenBossUnslowedMoveInterval(WormAgent agent) {
    final worm = agent.worm;
    if (agent.hasItemEffect(ItemType.speed.effectTypeId) && worm is PinkWorm) {
      return _greenBossBaseMoveInterval * worm.speedMoveIntervalScale;
    }
    if (agent.hasItemEffect(ItemType.snail.effectTypeId) && worm is PinkWorm) {
      return _greenBossBaseMoveInterval * worm.snailMoveIntervalScale;
    }
    return _greenBossBaseMoveInterval;
  }

  bool get _isLevel5GreenBossDamageSpeedActive =>
      _isLevel5GreenBoss &&
      _level5GreenBossDamageSpeedUntil >= 0 &&
      _gameTime < _level5GreenBossDamageSpeedUntil;

  double _greenBossDamageSpeedMoveInterval(WormAgent agent) {
    final interval =
        _greenBossUnslowedMoveInterval(agent) -
        _level5GreenBossDamageSpeedUnits * _greenBossSpeedUnitMoveInterval;
    return max(_greenBossSpeedUnitMoveInterval, interval);
  }

  double _greenBossSlowedMoveInterval(WormAgent agent) {
    return _greenBossUnslowedMoveInterval(agent) +
        _greenBossHitSlowUnits * _greenBossSpeedUnitMoveInterval;
  }

  bool _isGreenBossGoneOutsideMap(WormAgent agent) {
    final head = agent.worm.headGridPosition;
    return head.x < -3 ||
        head.x >= GameConfig.gridColumns + 3 ||
        head.y < -3 ||
        head.y >= _gridRows + 3;
  }

  bool _isBlockedForGreenBossEscape(Vector2 grid, WormAgent agent) {
    if (!_isGridInBounds(grid)) return false;
    if (_mapEntityManager.hasEntityAt(grid)) return true;
    for (final part in agent.allGridPositions) {
      if (part.x == grid.x && part.y == grid.y) return true;
    }
    return _wormAtGrid(grid, except: agent) != null;
  }

  int _greenBossEscapeScore(Vector2 grid) {
    final left = grid.x.toInt() + 4;
    final right = GameConfig.gridColumns - grid.x.toInt() + 2;
    final top = grid.y.toInt() + 4;
    final bottom = _gridRows - grid.y.toInt() + 2;
    return [left, right, top, bottom].reduce(min);
  }

  WormDirection _chooseGreenBossEscapeDirection(WormAgent agent) {
    final head = agent.worm.headGridPosition;
    WormDirection? best;
    var bestScore = 1 << 30;
    for (final direction in _allDirections) {
      final next = head + direction.toVector();
      if (_isBlockedForGreenBossEscape(next, agent)) continue;
      final score = _greenBossEscapeScore(next);
      if (score < bestScore) {
        bestScore = score;
        best = direction;
      }
    }
    return best ?? agent.worm.currentDirection;
  }

  void _advanceEscapingGreenBoss(WormAgent agent) {
    final direction = _chooseGreenBossEscapeDirection(agent);
    agent.worm.forceDirection(direction);
    agent.step();
    if (_isGreenBossGoneOutsideMap(agent)) {
      agent.worm.removeFromParent();
      _botAgents.remove(agent);
      _greenBossAgent = null;
      _greenBossEscaping = false;
      _greenBossHitSlowRemaining = 0;
      _level5GreenBossDamageSpeedUntil = -1.0;
      _greenBossCellsSincePoison = 0;
      _trySpawnFlagForObjectives();
    }
  }

  void _consumeEntityForBot(WormAgent agent, MapEntityEntry consumed) {
    consumed.component.removeFromParent();
    if (consumed.typeId == ProjectType.preyLeaf.typeId) {
      if (!identical(agent, _greenBossAgent) || _isLevel5GreenBoss) {
        agent.grow();
      }
      agent.worm.playSwallowPreyEffect();
      if (identical(agent, _greenBossAgent)) {
        _greenBossLeavesEaten = (_greenBossLeavesEaten + 1).clamp(
          0,
          _greenBossLeavesLoseTarget,
        );
        if (_greenBossLeavesEaten >= _greenBossLeavesLoseTarget) {
          _setGameOver(_GameOverCause.bodyGone);
          return;
        }
      }
      if (identical(agent, _pineappleAgent)) {
        _pineappleLeavesEaten = (_pineappleLeavesEaten + 1).clamp(
          0,
          _pineappleLeavesLoseTarget,
        );
        if (_pineappleLeavesEaten >= _pineappleLeavesLoseTarget) {
          _setGameOver(_GameOverCause.bodyGone);
          return;
        }
      }
      if (!_hasLeafOnMap()) _spawnPrey();
      return;
    }
    if (identical(agent, _greenBossAgent) &&
        consumed.typeId == ProjectType.bomb.typeId) {
      _instantEffectBomb(source: agent, damageGreenBoss: false);
      return;
    }

    final view = EntityModels.view(consumed.typeId);
    final effectId = view?.effectTypeId;
    if (effectId == null) return;
    final duration = BuffConfig.durationSecondsFor(effectId);
    if (duration > 0) {
      agent.addItemEffect(effectId, _gameTime + duration);
      if (identical(agent, _greenBossAgent)) {
        _syncGreenBossMoveInterval(agent);
      }
    }
  }

  void _dropGreenBossPoisonAt(Vector2 grid) {
    if (!_isLevel5GreenBoss) return;
    if (!_isGridInBounds(grid)) return;
    if (_mapEntityManager.getAt(grid) != null) return;
    if (_wormAtGrid(grid) != null) return;
    final poisonEntries =
        _mapEntityManager.entries
            .where((e) => e.typeId == ProjectType.poison.typeId)
            .toList();
    if (poisonEntries.length >= _greenBossMaxPoisonClouds) {
      final removed = _mapEntityManager.removeAt(poisonEntries.first.grid);
      removed?.component.removeFromParent();
      _poisonExpireTimes.remove(_gridKey(poisonEntries.first.grid));
    }
    final comp = _mapEntityManager.placeAt(
      grid,
      ProjectType.poison.typeId,
      withSpawnEffect: true,
    );
    _poisonExpireTimes[_gridKey(grid)] = _gameTime + _poisonDurationSeconds;
    world.add(comp);
  }

  void _updatePoisonCloudLifetimes() {
    if (_poisonExpireTimes.isEmpty) return;
    final expiredKeys =
        _poisonExpireTimes.entries
            .where((entry) => entry.value <= _gameTime)
            .map((entry) => entry.key)
            .toList();
    if (expiredKeys.isEmpty) return;
    for (final key in expiredKeys) {
      _poisonExpireTimes.remove(key);
      for (final entry in _mapEntityManager.entries) {
        if (_gridKey(entry.grid) != key) continue;
        if (entry.typeId != ProjectType.poison.typeId) continue;
        final removed = _mapEntityManager.removeAt(entry.grid);
        removed?.component.removeFromParent();
        break;
      }
    }
  }

  void _onGreenBossAdvanced(Vector2 tailBeforeStep) {
    if (!_isLevel5GreenBoss || _greenBossEscaping) return;
    _greenBossCellsSincePoison++;
    if (_greenBossCellsSincePoison < _greenBossPoisonStepInterval) return;
    _greenBossCellsSincePoison = 0;
    _dropGreenBossPoisonAt(tailBeforeStep);
  }

  void _updatePineappleWorm(double dt) {
    final agent = _pineappleAgent;
    if (agent == null) return;
    final worm = agent.worm;
    _pineappleMoveAccumulator += dt;
    final interval = worm.moveInterval;
    final raw = (_pineappleMoveAccumulator / interval).clamp(0.0, 1.0);
    worm.setVisualProgress(Curves.linear.transform(raw));
    while (_pineappleMoveAccumulator >= interval) {
      _pineappleMoveAccumulator -= interval;
      final nextDir = _choosePineappleDirection(agent);
      if (!_advanceAgentOneStep(agent, nextDirection: nextDir)) return;
      final entryAtHead = _mapEntityManager.getAt(worm.headGridPosition);
      if (entryAtHead?.typeId == ProjectType.poison.typeId) continue;
      final consumed = _mapEntityManager.consumeAt(worm.headGridPosition);
      if (consumed == null) continue;
      _consumeEntityForBot(agent, consumed);
    }
  }

  void _updateGreenBossWorm(double dt) {
    final agent = _greenBossAgent;
    if (agent == null) return;
    _updateGreenBossHitSlow(dt);
    final worm = agent.worm;
    _greenBossMoveAccumulator += dt;
    final interval = worm.moveInterval;
    worm.setVisualProgress(
      Curves.linear.transform(
        (_greenBossMoveAccumulator / interval).clamp(0.0, 1.0),
      ),
    );
    while (_greenBossMoveAccumulator >= interval) {
      _greenBossMoveAccumulator -= interval;
      if (_greenBossEscaping) {
        _advanceEscapingGreenBoss(agent);
        if (_greenBossAgent == null) return;
        continue;
      }
      final nextDir = _chooseGreenBossDirection(agent);
      final tailBeforeStep = worm.tailGridPosition.clone();
      if (!_advanceAgentOneStep(agent, nextDirection: nextDir)) return;
      _onGreenBossAdvanced(tailBeforeStep);
      final entryAtHead = _mapEntityManager.getAt(worm.headGridPosition);
      if (entryAtHead?.typeId == ProjectType.poison.typeId) continue;
      final consumed = _mapEntityManager.consumeAt(worm.headGridPosition);
      if (consumed == null) continue;
      _consumeEntityForBot(agent, consumed);
    }
  }

  /// Spawn đồng xu nếu config bật và chưa có xu trên map; đồng xu đầu sau firstSpawnDelay, các lần sau sau spawnDelayAfterEaten kể từ khi xu trước bị ăn.
  void _trySpawnCoin() {
    final config = _levelConfig.coinSpawnConfig;
    if (config == null) return;
    if (_mapEntityManager.entries.any(
      (e) => e.typeId == ProjectType.preyCoin.typeId,
    ))
      return;

    final canSpawn =
        !_firstCoinSpawned
            ? (_gameTime >= config.firstSpawnDelaySeconds)
            : (_gameTime - _lastCoinEatenGameTime >=
                config.spawnDelayAfterEatenSeconds);

    if (!canSpawn) return;

    _firstCoinSpawned = true;
    final occupied = _occupiedGridKeys();
    final entry = _mapEntityManager.spawn(
      ProjectType.preyCoin.typeId,
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

  /// Duyệt config map: typeId (string) → placeAt cho từng ô.
  /// Không đặt entity lên ô đang bị thân sâu hoặc entity khác chiếm.
  void _placeAllMapEntitiesFromConfig() {
    Set<String> occupied = _occupiedGridKeys();
    for (final entry in _levelConfig.mapConfig.placements.entries) {
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
    world.add(
      MaxTextEffectComponent(
        position: mainWorm.headWorldPosition,
        segmentSize: _segmentSize,
      ),
    );
  }

  /// Spawn lá cờ tại ô ưu tiên từ config, hoặc ô trống bất kỳ trong view nếu ô config bị sâu/entity chiếm. Có hiệu ứng nhấp nháy 1 nhịp.
  void _spawnFlag() {
    final occupied = _occupiedGridKeys();
    final preferred =
        _levelConfig.mapConfig.placements[ProjectType.preyFlag.typeId];
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
    final comp = _mapEntityManager.placeAt(
      targetGrid,
      ProjectType.preyFlag.typeId,
      withSpawnEffect: true,
    );
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
  static const double _cameraShakeFrequency = 88.0;

  void _triggerCameraShake({
    required double duration,
    required double amplitude,
  }) {
    if (duration <= 0 || amplitude <= 0) return;
    _cameraShakeDuration = max(_cameraShakeDuration, duration);
    _cameraShakeRemaining = max(_cameraShakeRemaining, duration);
    _cameraShakeAmplitude = max(_cameraShakeAmplitude, amplitude);
  }

  void _triggerDamageHaptic() {
    if (!appSettingsNotifier.hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  void _triggerBombHaptic() {
    if (!appSettingsNotifier.hapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void _resetCameraShake() {
    _cameraShakeRemaining = 0;
    _cameraShakeDuration = 0;
    _cameraShakeAmplitude = 0;
    _cameraShakePhase = 0;
  }

  /// Di chuyển camera theo đầu rắn (trục Y), lerp mượt.
  void _updateCameraFollowSnake(double dt) {
    if (!_loaded) return;
    final viewportSize = camera.viewport.size;
    final worldWidth = GameConfig.gridColumns * _segmentSize;
    final halfViewY = viewportSize.y / 2;
    final bottomOfPlayable =
        (playableStartRow + playableRowCount) * _segmentSize;
    final maxCameraY = bottomOfPlayable - halfViewY;

    final headWorld = _gridToWorld(mainWorm.headGridPosition);
    final targetY = headWorld.y.clamp(
      halfViewY,
      maxCameraY.clamp(halfViewY, double.infinity),
    );

    final current = _cameraY ?? targetY;
    final smoothFactor = 1.0 - exp(-_cameraSmoothSpeed * dt);
    _cameraY = current + (targetY - current) * smoothFactor;

    var shakeX = 0.0;
    var shakeY = 0.0;
    if (_cameraShakeRemaining > 0 && _cameraShakeDuration > 0) {
      _cameraShakePhase += dt * _cameraShakeFrequency;
      _cameraShakeRemaining = max(0.0, _cameraShakeRemaining - dt);
      final fade = _cameraShakeRemaining / _cameraShakeDuration;
      final amplitude = _cameraShakeAmplitude * fade * fade;
      shakeX = sin(_cameraShakePhase) * amplitude;
      shakeY = cos(_cameraShakePhase * 1.37) * amplitude * 0.55;
      if (_cameraShakeRemaining <= 0) {
        _cameraShakeDuration = 0;
        _cameraShakeAmplitude = 0;
      }
    }

    camera.viewfinder.position = Vector2(
      worldWidth / 2 + shakeX,
      _cameraY! + shakeY,
    );
  }

  void _setGameOver(_GameOverCause cause) {
    if (_gameOver) return;
    _gameOver = true;
    _deathSnapshot = _DeathSnapshot(
      entries:
          _mapEntityManager.entries
              .map((e) => (grid: e.grid.clone(), typeId: e.typeId))
              .toList(),
      missionCurrents: List.from(_missionCurrents),
      cause: cause,
      wormPositions:
          cause == _GameOverCause.timeUp
              ? mainWorm.allGridPositions.map((v) => v.clone()).toList()
              : null,
      wormDirection:
          cause == _GameOverCause.timeUp ? mainWorm.currentDirection : null,
      remainingTimeAtDeath:
          cause == _GameOverCause.bodyGone
              ? (_timeLimit - _gameTime).clamp(0.0, double.infinity)
              : null,
      greenBossSegmentCount:
          _isLevel4GreenBoss
              ? min(
                _greenBossAgent?.segmentCount ?? 0,
                _greenBossMaxLengthForCurrentLevel,
              )
              : null,
      greenBossLeavesEaten: _greenBossLeavesEaten,
    );
    if (_hasRevivedOnce && !shouldApplyDebug) {
      overlays.add('GameOverNoRevive');
    } else {
      overlays.add('GameOver');
    }
  }

  /// True khi mọi nhiệm vụ (có target > 0) đều đạt current >= target.
  bool _allMissionsComplete() {
    for (
      var i = 0;
      i < _missionConfigs.length && i < _missionCurrents.length;
      i++
    ) {
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
    if (grid.x < 0 || grid.x >= cols || grid.y < 0 || grid.y >= rows)
      return false;
    return _mapEntityManager.getAt(grid) == null;
  }

  /// Ô trong lưới và trống, hoặc có vật cản độ cứng 10 (chỉ dùng khi không còn vùng an toàn).
  bool _isCellUsableForSpawn(Vector2 grid) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    if (grid.x < 0 || grid.x >= cols || grid.y < 0 || grid.y >= rows)
      return false;
    final entry = _mapEntityManager.getAt(grid);
    if (entry == null) return true;
    return _typeObjConfig.isBlocking(entry.typeId) &&
        EntityModels.hardness(entry.typeId) == 10;
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

  /// Số ô liên tiếp theo [dir] từ [head] là trống hoặc vật cản độ cứng 10 (dùng khi đã phải phá chỗ).
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
          EntityModels.hardness(entry.typeId) == 10) {
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
  ({List<Vector2> positions, WormDirection direction, bool needDestroy})?
  _findSafeSpawn({
    Iterable<Vector2> avoid = const [],
    int? minDistanceFromAvoid,
  }) {
    final configDir = _respawnHeadDirectionFromConfig();
    if (configDir == null) {
      return _findSafeSpawnLinear(
        avoid: avoid,
        minDistanceFromAvoid: minDistanceFromAvoid,
      );
    }
    return _findSafeSpawnWinding(
      configDir,
      avoid: avoid,
      minDistanceFromAvoid: minDistanceFromAvoid,
    );
  }

  /// Sâu xếp thẳng hàng; hướng đầu chọn theo nhiều ô trống phía trước nhất (config "none").
  ({List<Vector2> positions, WormDirection direction, bool needDestroy})?
  _findSafeSpawnLinear({
    Iterable<Vector2> avoid = const [],
    int? minDistanceFromAvoid,
  }) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    const bodyCount = _respawnWormLength - 1;
    final avoidList = avoid.toList();
    final avoidKeys = avoidList.map(_gridKey).toSet();

    bool avoids(Vector2 grid) => !avoidKeys.contains(_gridKey(grid));

    bool farEnough(List<Vector2> positions) {
      if (minDistanceFromAvoid == null || avoidList.isEmpty) return true;
      return _minGridDistanceBetween(positions, avoidList) >=
          minDistanceFromAvoid;
    }

    ({Vector2 head, WormDirection direction, int ahead})? bestEmpty;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final head = Vector2(col.toDouble(), row.toDouble());
        for (final dir in _allDirections) {
          final step = dir.toVector();
          final body1 = head - step;
          var ok =
              _isCellEmpty(head) &&
              avoids(head) &&
              _isCellEmpty(body1) &&
              avoids(body1);
          var pos = body1;
          for (var i = 0; i < bodyCount - 1 && ok; i++) {
            pos = pos - step;
            if (pos.x < 0 || pos.x >= cols || pos.y < 0 || pos.y >= rows) {
              ok = false;
              break;
            }
            if (!_isCellEmpty(pos) || !avoids(pos)) ok = false;
          }
          if (!ok) continue;
          final positions = List<Vector2>.generate(
            _respawnWormLength,
            (i) => head - step * i.toDouble(),
          );
          if (!farEnough(positions)) continue;
          final front = head + step;
          if (front.x < 0 || front.x >= cols || front.y < 0 || front.y >= rows)
            continue;
          if (!_isCellEmpty(front) || !avoids(front)) continue;

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
      return (
        positions: positions,
        direction: bestEmpty.direction,
        needDestroy: false,
      );
    }

    ({Vector2 head, WormDirection direction, int ahead})? bestUsable;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final head = Vector2(col.toDouble(), row.toDouble());
        for (final dir in _allDirections) {
          final step = dir.toVector();
          var pos = head;
          var ok = _isCellUsableForSpawn(pos) && avoids(pos);
          for (var i = 0; i < bodyCount && ok; i++) {
            pos = pos - step;
            if (pos.x < 0 || pos.x >= cols || pos.y < 0 || pos.y >= rows) {
              ok = false;
              break;
            }
            if (!_isCellUsableForSpawn(pos) || !avoids(pos)) ok = false;
          }
          if (!ok) continue;
          final positions = List<Vector2>.generate(
            _respawnWormLength,
            (i) => head - step * i.toDouble(),
          );
          if (!farEnough(positions)) continue;

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
      return (
        positions: positions,
        direction: bestUsable.direction,
        needDestroy: true,
      );
    }
    return null;
  }

  /// Sâu có thể ngoằn nghoèo (path 5 ô nối tiếp); hướng đầu cố định [headDirection] từ config.
  ({List<Vector2> positions, WormDirection direction, bool needDestroy})?
  _findSafeSpawnWinding(
    WormDirection headDirection, {
    Iterable<Vector2> avoid = const [],
    int? minDistanceFromAvoid,
  }) {
    const cols = GameConfig.gridColumns;
    final rows = _gridRows;
    final frontStep = headDirection.toVector();
    final avoidList = avoid.toList();
    final avoidKeys = avoidList.map(_gridKey).toSet();

    bool inBounds(Vector2 p) =>
        p.x >= 0 && p.x < cols && p.y >= 0 && p.y < rows;

    bool avoids(Vector2 grid) => !avoidKeys.contains(_gridKey(grid));

    bool farEnough(List<Vector2> positions) {
      if (minDistanceFromAvoid == null || avoidList.isEmpty) return true;
      return _minGridDistanceBetween(positions, avoidList) >=
          minDistanceFromAvoid;
    }

    ({List<Vector2> path, bool useHeadAtStart})? bestEmpty;
    ({List<Vector2> path, bool useHeadAtStart})? bestUsable;
    var bestEmptyAhead = -1;
    var bestUsableAhead = -1;

    void tryPath(List<Vector2> path, bool headAtStart) {
      final head = headAtStart ? path.first : path.last;
      final front = head + frontStep;
      if (!inBounds(front)) return;

      if (!path.every(avoids) || !avoids(front)) return;
      if (!farEnough(path)) return;

      final emptyOk = path.every(_isCellEmpty) && _isCellEmpty(front);
      final usableOk =
          path.every(_isCellUsableForSpawn) && _isCellUsableForSpawn(front);
      if (!emptyOk && !usableOk) return;

      final ahead =
          emptyOk
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
    final head = Vector2(
      (cols / 2).floorToDouble(),
      (rows / 2).floorToDouble(),
    );
    return [
      head,
      head - step,
      head - step * 2,
      head - step * 3,
      head - step * 4,
    ];
  }

  /// Phá entity tại [grid] nếu là vật cản độ cứng 10 (để giải chỗ cho sâu hồi sinh).
  void _destroyObstacleIfHardness1(Vector2 grid) {
    final entry = _mapEntityManager.getAt(grid);
    if (entry == null) return;
    if (!_typeObjConfig.isBlocking(entry.typeId)) return;
    if (EntityModels.hardness(entry.typeId) != 10) return;
    _destroyEntityAt(grid);
  }

  bool _isGridInBounds(Vector2 grid) {
    return grid.x >= 0 &&
        grid.x < GameConfig.gridColumns &&
        grid.y >= 0 &&
        grid.y < _gridRows;
  }

  WormDirection _inferDirectionFromPositions(List<Vector2> positions) {
    if (positions.length < 2) return WormDirection.right;
    final delta = positions.first - positions[1];
    if (delta.x > 0) return WormDirection.right;
    if (delta.x < 0) return WormDirection.left;
    if (delta.y > 0) return WormDirection.down;
    if (delta.y < 0) return WormDirection.up;
    return WormDirection.right;
  }

  bool _canClearForConfiguredSpawn(
    Vector2 grid, {
    required bool clearNonBlocking,
  }) {
    if (!_isGridInBounds(grid)) return false;
    final entry = _mapEntityManager.getAt(grid);
    if (entry == null) return true;
    if (!_typeObjConfig.isBlocking(entry.typeId)) return clearNonBlocking;
    return EntityModels.hardness(entry.typeId) == 10;
  }

  void _clearForConfiguredSpawn(
    Vector2 grid, {
    required bool clearNonBlocking,
  }) {
    final entry = _mapEntityManager.getAt(grid);
    if (entry == null) return;
    final isBlocking = _typeObjConfig.isBlocking(entry.typeId);
    if (!isBlocking && clearNonBlocking) {
      _destroyEntityAt(grid);
      return;
    }
    if (isBlocking && EntityModels.hardness(entry.typeId) == 10) {
      _destroyEntityAt(grid);
    }
  }

  void _removeRuntimeDeathXMarksFromMap() {
    if (_runtimeDeathXMarkKeys.isEmpty) return;
    for (final key in _runtimeDeathXMarkKeys.toList()) {
      for (final entry in _mapEntityManager.entries) {
        if (_gridKey(entry.grid) != key) continue;
        if (entry.typeId != ProjectType.xMark.typeId) continue;
        final removed = _mapEntityManager.removeAt(entry.grid);
        removed?.component.removeFromParent();
        break;
      }
    }
    _runtimeDeathXMarkKeys.clear();
  }

  void _removePoisonCloudsFromMap() {
    for (final entry in _mapEntityManager.entries.toList()) {
      if (entry.typeId != ProjectType.poison.typeId) continue;
      final removed = _mapEntityManager.removeAt(entry.grid);
      removed?.component.removeFromParent();
    }
    _poisonExpireTimes.clear();
  }

  ({List<Vector2> positions, WormDirection direction})?
  _configuredInitialSpawnForRestart() {
    final configured = _levelConfig.initialWormPositions;
    if (configured.length < 2) return null;

    final positions = [for (final p in configured) p.clone()];
    final direction = _inferDirectionFromPositions(positions);
    final front = positions.first + direction.toVector();

    for (final grid in positions) {
      if (!_canClearForConfiguredSpawn(grid, clearNonBlocking: true)) {
        return null;
      }
    }
    if (!_canClearForConfiguredSpawn(front, clearNonBlocking: true)) {
      return null;
    }

    for (final grid in positions) {
      _clearForConfiguredSpawn(grid, clearNonBlocking: true);
    }
    _clearForConfiguredSpawn(front, clearNonBlocking: true);
    return (positions: positions, direction: direction);
  }

  void _restartFromDeath() {
    final snapshot = _deathSnapshot!;
    mainWorm.removeFromParent();
    _removeBotAgents();
    for (final e in _mapEntityManager.entries) e.component.removeFromParent();
    _mapEntityManager.clear();
    for (final p in _magnetPulls) p.entry.component.removeFromParent();
    _magnetPulls.clear();
    _magnetLastPullTime = null;
    _poisonExpireTimes.clear();

    for (final e in snapshot.entries) {
      final place = _placeEntityAt[e.typeId];
      if (place != null) place(e.grid);
    }
    _removeRuntimeDeathXMarksFromMap();
    _removePoisonCloudsFromMap();
    _missionCurrents = List.from(snapshot.missionCurrents);
    _greenBossLeavesEaten = snapshot.greenBossLeavesEaten;
    _syncLeafSequenceIndexFromState();

    final List<Vector2> initialPositions;
    final WormDirection dir;
    final int wormLength;
    final greenBossSpawnPreview =
        _isLevel4GreenBoss ? _greenBossStartPositions() : const <Vector2>[];

    final configuredRestart =
        _isLevel3 ? _configuredInitialSpawnForRestart() : null;

    if (configuredRestart != null) {
      initialPositions = configuredRestart.positions;
      dir = configuredRestart.direction;
      wormLength = initialPositions.length;

      if (snapshot.cause == _GameOverCause.timeUp) {
        _timeLimit += 30;
      } else {
        final remaining = snapshot.remainingTimeAtDeath ?? 0;
        _timeLimit = remaining < 30 ? 30 : remaining;
        _gameTime = 0;
      }
    } else if (!_isLevel4GreenBoss &&
        snapshot.cause == _GameOverCause.timeUp &&
        snapshot.wormPositions != null &&
        snapshot.wormPositions!.length >= 2 &&
        snapshot.wormDirection != null) {
      initialPositions = snapshot.wormPositions!;
      dir = snapshot.wormDirection!;
      wormLength = initialPositions.length;
      _timeLimit += 30;
    } else {
      final safe =
          _isLevel4GreenBoss
              ? _findSafeSpawn(
                avoid: greenBossSpawnPreview,
                minDistanceFromAvoid: _greenBossMinPlayerSpawnDistance,
              )
              : _findSafeSpawn();
      initialPositions =
          safe?.positions ??
          (_isLevel4GreenBoss
              ? _level4PlayerStartPositions(_respawnWormLength)
              : _defaultRespawnPositions(WormDirection.right));
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

    final worm = _createPlayerWorm(
      segmentSize: _segmentSize,
      moveInterval: _playerMoveInterval,
      initialLength: wormLength,
      maxLength: _wormMaxLength,
      gridRows: _gridRows,
      initialGridPositions: initialPositions,
      initialDirection: dir,
    );
    world.add(worm);
    worm.setOnGrowAtMax(_onWormGrowAtMax);
    _playerAgent = WormAgent(worm: worm, behavior: PlayerWormBehavior());
    if (_isLevel2) {
      final pineapple = PineappleWorm(
        config: PineappleWormConfig(
          segmentSize: _segmentSize,
          moveInterval: GameConfig.moveInterval * _pineappleMoveIntervalScale,
          initialLength: _respawnWormLength,
          maxLength: _wormMaxLength,
          gridRows: _gridRows,
          initialGridPositions: _level2PineappleStartPositions(
            _respawnWormLength,
            avoid: initialPositions,
          ),
          initialDirection: WormDirection.left,
        ),
        info: _pineappleInfo,
        position: Vector2(0, playableStartRow * _segmentSize),
        gridRowsOverride: _gridRows,
      );
      world.add(pineapple);
      _pineappleAgent = _registerBotAgent(
        WormAgent(worm: pineapple, behavior: PlayerWormBehavior()),
      );
    }
    final greenBossRestartLength =
        snapshot.greenBossSegmentCount == null
            ? _greenBossLength
            : min(snapshot.greenBossSegmentCount!, _greenBossLength);
    if (greenBossRestartLength > 0) {
      _spawnGreenBoss(avoid: initialPositions, length: greenBossRestartLength);
    }

    final headWorld = _gridToWorld(initialPositions.first);
    final worldWidth = GameConfig.gridColumns * _segmentSize;
    final halfViewY = camera.viewport.size.y / 2;
    final bottomOfPlayable =
        (playableStartRow + playableRowCount) * _segmentSize;
    final maxCameraY = bottomOfPlayable - halfViewY;
    _cameraY = headWorld.y.clamp(
      halfViewY,
      maxCameraY.clamp(halfViewY, double.infinity),
    );
    camera.viewfinder.position = Vector2(worldWidth / 2, _cameraY!);
    _ensureLeafOnMap();

    _spawnCycleAccumulators.clear();
    _spawnCyclePositionIndexes.clear();
    for (final item in _levelConfig.spawnCycle.items) {
      _spawnCycleAccumulators[item.objType] = 0;
    }
    _coinsCollectedThisRun = 0;
    _reducePineappleScoreOnRevive();
    _pineappleMoveAccumulator = 0;
    _greenBossMoveAccumulator = 0;
    _greenBossHitSlowRemaining = 0;
    _level5GreenBossDamageSpeedUntil = -1.0;
    _greenBossCellsSincePoison = 0;
    _poisonImmunityUntil = -1.0;
    _lastCoinEatenGameTime = -999.0;
    _firstCoinSpawned = false;
    if (snapshot.cause != _GameOverCause.timeUp) {
      _gameTime = 0;
    }
    _poisonExpireTimes.clear();
    _startDelayRemaining = startDelaySeconds;
    _gameOver = false;
    _victoryTriggered = false;
    // Giữ đúng trạng thái lá cờ từ snapshot: nếu snapshot đã có prey_flag thì không spawn thêm.
    _flagSpawned = snapshot.entries.any(
      (e) => e.typeId == ProjectType.preyFlag.typeId,
    );
    _paused = false;
    _moveAccumulator = 0;
    _resetCameraShake();
    _missionCompleteSpawnsPlaced =
        _levelConfig.missionCompleteSpawns.placements.isEmpty;
  }

  void _restart() {
    _reducePineappleScoreOnRevive();
    mainWorm.removeFromParent();
    _removeBotAgents();
    for (final e in _mapEntityManager.entries) e.component.removeFromParent();
    _mapEntityManager.clear();
    for (final p in _magnetPulls) p.entry.component.removeFromParent();
    _magnetPulls.clear();
    _magnetLastPullTime = null;
    _runtimeDeathXMarkKeys.clear();
    _poisonExpireTimes.clear();

    final initLen = shouldApplyDebug ? 10 : (_wormInitLength + 2);
    final maxLen = shouldApplyDebug ? null : _wormMaxLength;
    final playerInitialPositions = _initialPlayerPositions(initLen);
    final playerInitialLength = playerInitialPositions?.length ?? initLen;
    final worm = _createPlayerWorm(
      segmentSize: _segmentSize,
      moveInterval: _playerMoveInterval,
      initialLength: playerInitialLength,
      maxLength: maxLen,
      gridRows: _gridRows,
      initialGridPositions: playerInitialPositions,
      initialDirection:
          playerInitialPositions != null ? WormDirection.right : null,
    );
    world.add(worm);
    worm.setOnGrowAtMax(_onWormGrowAtMax);
    _playerAgent = WormAgent(worm: worm, behavior: PlayerWormBehavior());
    if (_isLevel2) {
      final pineapple = PineappleWorm(
        config: PineappleWormConfig(
          segmentSize: _segmentSize,
          moveInterval: GameConfig.moveInterval * _pineappleMoveIntervalScale,
          initialLength: initLen,
          maxLength: maxLen,
          gridRows: _gridRows,
          initialGridPositions: _level2PineappleStartPositions(
            initLen,
            avoid: mainWorm.allGridPositions,
          ),
          initialDirection: WormDirection.left,
        ),
        info: _pineappleInfo,
        position: Vector2(0, playableStartRow * _segmentSize),
        gridRowsOverride: _gridRows,
      );
      world.add(pineapple);
      _pineappleAgent = _registerBotAgent(
        WormAgent(worm: pineapple, behavior: PlayerWormBehavior()),
      );
    }
    _spawnGreenBoss(avoid: mainWorm.allGridPositions);

    _placeAllMapEntitiesFromConfig();
    _ensureLeafOnMap();

    _spawnCycleAccumulators.clear();
    _spawnCyclePositionIndexes.clear();
    for (final item in _levelConfig.spawnCycle.items) {
      _spawnCycleAccumulators[item.objType] = 0;
    }
    _coinsCollectedThisRun = 0;
    if (!_isLevel2) _pineappleLeavesEaten = 0;
    _greenBossLeavesEaten = 0;
    _pineappleMoveAccumulator = 0;
    _greenBossMoveAccumulator = 0;
    _greenBossHitSlowRemaining = 0;
    _level5GreenBossDamageSpeedUntil = -1.0;
    _greenBossCellsSincePoison = 0;
    _poisonImmunityUntil = -1.0;
    _lastCoinEatenGameTime = -999.0;
    _firstCoinSpawned = false;
    _gameTime = 0;
    _startDelayRemaining = startDelaySeconds;
    _timeLimit = _levelConfig.timeLimitSeconds;
    _missionCurrents = List.filled(_missionConfigs.length, 0);

    _gameOver = false;
    _victoryTriggered = false;
    _flagSpawned = _hasEntityOnMap(ProjectType.preyFlag.typeId);
    _paused = false;
    _moveAccumulator = 0;
    _cameraY = null;
    _resetCameraShake();
    _hasRevivedOnce = false;
    _nextPreyLeafSequenceIndex = 0;
    _missionCompleteSpawnsPlaced =
        _levelConfig.missionCompleteSpawns.placements.isEmpty;
  }

  /// Trừ 1 đốt đuôi và để lại dấu X tại vị trí đuôi.
  void _loseSegmentFor(WormAgent agent, {bool triggerFeedback = true}) {
    if (triggerFeedback) {
      _triggerCameraShake(
        duration: _damageShakeDurationSeconds,
        amplitude: _damageShakeAmplitudePixels,
      );
      _triggerDamageHaptic();
    }
    agent.showCryFace();
    final tailGrid = agent.tailGridPosition.clone();
    agent.removeTail();
    final isGreenBoss = identical(agent, _greenBossAgent);
    if (isGreenBoss) {
      _triggerLevel5GreenBossDamageSpeed();
    }
    if (_mapEntityManager.getAt(tailGrid) == null) {
      final comp = _mapEntityManager.placeAt(
        tailGrid,
        ProjectType.xMark.typeId,
      );
      _runtimeDeathXMarkKeys.add(_gridKey(tailGrid));
      world.add(comp);
    }
    if (identical(agent, _pineappleAgent) && agent.segmentCount <= 2) {
      _setVictory();
      return;
    }
    if (isGreenBoss && agent.segmentCount <= 2) {
      _startGreenBossEscape();
      return;
    }
    if (agent.isPlayer && agent.segmentCount <= 2) {
      _setGameOver(_GameOverCause.bodyGone);
    }
  }

  void _loseSegment() {
    _loseSegmentFor(_playerAgent);
  }

  /// Phá entity tại ô [grid] (khi độ cứng sâu > độ cứng vật cản).
  void _destroyEntityAt(Vector2 grid) {
    final entry = _mapEntityManager.removeAt(grid);
    if (entry != null) {
      if (entry.typeId == ProjectType.xMark.typeId) {
        _runtimeDeathXMarkKeys.remove(_gridKey(entry.grid));
      }
      if (entry.typeId == ProjectType.poison.typeId) {
        _poisonExpireTimes.remove(_gridKey(entry.grid));
      }
      entry.component.removeFromParent();
    }
  }

  /// Độ cứng hiện tại của sâu (currentHardness, set trong onItemEffectAdded/Removed khi buff dừa).
  int _getWormHardness(WormAgent agent) => agent.worm.stats.currentHardness;

  int _getEntityHardnessForCollision(String typeId) {
    if (_isLevel5GreenBoss && typeId == ProjectType.xMark.typeId) {
      return _pineappleBaseHardness;
    }
    return EntityModels.hardness(typeId);
  }

  bool _wormContainsGrid(WormAgent agent, Vector2 grid) {
    for (final part in agent.allGridPositions) {
      if (part.x == grid.x && part.y == grid.y) return true;
    }
    return false;
  }

  WormAgent? _wormAtGrid(Vector2 grid, {WormAgent? except}) {
    for (final agent in _activeWormAgents()) {
      if (identical(agent, except)) continue;
      if (_wormContainsGrid(agent, grid)) return agent;
    }
    return null;
  }

  bool _onHitWorm(WormAgent attacker, WormAgent defender) {
    attacker.applyNextDirectionAndSyncVisuals();
    if (identical(attacker, _greenBossAgent) && defender.isPlayer) {
      world.add(
        HeartBurstEffect(
          position: attacker.worm.headWorldPosition,
          segmentSize: _segmentSize,
        ),
      );
      _triggerGreenBossHitSlow();
    }
    final attackerHardness = _getWormHardness(attacker);
    final defenderHardness = _getWormHardness(defender);
    if (attackerHardness <= defenderHardness) {
      _loseSegmentFor(attacker);
    } else {
      _loseSegmentFor(defender);
    }
    return true;
  }

  bool _resolveWormCollisionAt(WormAgent attacker, Vector2 nextHead) {
    final defender = _wormAtGrid(nextHead, except: attacker);
    if (defender == null) return false;
    return _onHitWorm(attacker, defender);
  }

  bool _isOutOfBounds(Vector2 grid) =>
      grid.x < 0 ||
      grid.x >= GameConfig.gridColumns ||
      grid.y < 0 ||
      grid.y >= _gridRows;

  bool _resolveSelfCollisionAt(WormAgent agent, Vector2 nextHead) {
    final body = agent.allGridPositions;
    for (var i = 1; i < body.length; i++) {
      if (body[i].x == nextHead.x && body[i].y == nextHead.y) {
        agent.applyNextDirectionAndSyncVisuals();
        _loseSegmentFor(agent);
        return true;
      }
    }
    return false;
  }

  /// Returns null when there is no blocking entity, true when the agent moved,
  /// and false when collision was resolved without movement.
  bool? _resolveBlockingEntityAt(WormAgent agent, Vector2 nextHead) {
    if (!_mapEntityManager.hasBlockingEntityAt(nextHead)) return null;
    final entry = _mapEntityManager.getAt(nextHead);
    if (entry == null) return false;
    final view = EntityModels.view(entry.typeId);
    if (view == null) return false;
    if (view.wormCanPassThrough) {
      agent.step();
      return true;
    }

    final entityHardness = _getEntityHardnessForCollision(entry.typeId);
    final result =
        _getWormHardness(agent) <= entityHardness
            ? HitResult.loseSegment
            : HitResult.destroyAndStep;
    switch (result) {
      case HitResult.loseSegment:
        agent.applyNextDirectionAndSyncVisuals();
        _loseSegmentFor(agent);
        return false;
      case HitResult.destroyAndStep:
        if (agent.isPlayer) {
          _wormContext.addMissionProgressByTypeId(entry.typeId, 1);
        }
        _destroyEntityAt(nextHead);
        agent.step();
        return true;
      case HitResult.none:
        return false;
    }
  }

  /// Shared movement/collision gateway for player, boss, bot, and future mini-bots.
  /// Returns true only when the agent actually advanced into the next cell.
  bool _advanceAgentOneStep(WormAgent agent, {WormDirection? nextDirection}) {
    if (nextDirection != null) agent.setNextDirection(nextDirection);
    final nextHead = agent.peekNextHead();

    if (_isOutOfBounds(nextHead)) {
      agent.applyNextDirectionAndSyncVisuals();
      _loseSegmentFor(agent);
      return false;
    }

    if (_resolveWormCollisionAt(agent, nextHead)) return false;

    final entityResult = _resolveBlockingEntityAt(agent, nextHead);
    if (entityResult != null) return entityResult;

    if (_resolveSelfCollisionAt(agent, nextHead)) return false;

    agent.step();
    return true;
  }

  /// Dữ liệu HUD (cập nhật trong lúc chơi). Cấu trúc sẵn để sau load từ JSON.
  /// Chỉ đưa nhiệm vụ có target > 0 vào [missions] (chưa có thì ẩn).
  /// Trả về giá trị mặc định khi game chưa load (tránh LateInitializationError khi GameHud build trước onLoad).
  GameHudData get hudData {
    if (!_loaded) {
      return GameHudData(
        timeRemainingSeconds: _timeLimit,
        diamonds: 0,
        missions: [
          GameHudMission(
            id: 'leaves',
            typeId: ProjectType.preyLeaf.typeId,
            current: 0,
            target: 10,
          ),
        ],
        bossHp: 0,
        bossHpMax: 0,
        itemBuffs: const [],
        startDelayRemaining: _startDelayRemaining,
        timeUrgentThresholdSeconds: 30.0,
        pineappleScore: _isLevel2 ? _pineappleLeavesEaten : -1,
      );
    }
    final missions = <GameHudMission>[];
    for (
      var i = 0;
      i < _missionConfigs.length && i < _missionCurrents.length;
      i++
    ) {
      final m = _missionConfigs[i];
      if (m.target <= 0) continue;
      final target = _missionTargetOverrides[m.id] ?? m.target;
      if (target <= 0) continue;
      missions.add(
        GameHudMission(
          id: m.id,
          typeId: m.typeId,
          current: _missionCurrents[i],
          target: target,
        ),
      );
    }
    final hasBoss = _levelConfig.hasBoss;
    final isGreenBossHud = hasBoss && _isLevel4GreenBoss;
    final int bossHp = isGreenBossHud ? _greenBossBodySegmentsForHud : 0;
    final int bossHpMax =
        isGreenBossHud
            ? _greenBossMaxBodySegmentsForHud
            : hasBoss
            ? 100
            : 0;
    final itemBuffs =
        mainWorm.itemEffects
            .where((e) => e.endTime != null)
            .map(
              (e) => GameHudItemBuff(
                itemId: e.itemId,
                remainingSeconds: (e.endTime! - _gameTime).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
            )
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
      pineappleScore: _isLevel2 ? _pineappleLeavesEaten : -1,
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
    _updatePoisonCloudLifetimes();

    if (_gameTime >= _timeLimit) {
      _setGameOver(_GameOverCause.timeUp);
      return;
    }

    mainWorm.setGameTime(_gameTime);
    mainWorm.removeExpiredItemEffects(_gameTime);
    for (final agent in _botAgents) {
      agent.setGameTime(_gameTime);
      agent.removeExpiredItemEffects(_gameTime);
    }

    if (mainWorm.hasItemEffect(ItemType.freeze.effectTypeId)) return;

    _updateMagnetPulls(dt);
    _updatePineappleWorm(dt);
    _updateGreenBossWorm(dt);
    if (_gameOver) return;

    if (mainWorm.hasItemEffect(ItemType.magnet.effectTypeId)) {
      final now = _gameTime;
      if (_magnetLastPullTime == null ||
          (now - _magnetLastPullTime!) >=
              BuffConfig.magnetPullDurationSeconds) {
        _triggerMagnetPull();
        _magnetLastPullTime = now;
      }
    } else {
      _magnetLastPullTime = null;
    }

    for (final item in _levelConfig.spawnCycle.items) {
      if (!_typeObjConfig.isEatable(item.objType)) continue;
      final maxOnMap = item.maxOnMap;
      if (maxOnMap != null &&
          _mapEntityManager.entries
                  .where((e) => e.typeId == item.objType)
                  .length >=
              maxOnMap) {
        if (item.pauseWhenPresent) {
          _spawnCycleAccumulators[item.objType] = 0;
        }
        continue;
      }
      final acc = _spawnCycleAccumulators[item.objType] ?? 0;
      final next = acc + dt;
      _spawnCycleAccumulators[item.objType] = next;
      if (next >= item.intervalSeconds) {
        _spawnCycleAccumulators[item.objType] = next - item.intervalSeconds;
        _spawnByTypeId(
          item.objType,
          preferredPositions: item.preferredPositions,
          preferredPositionsOnly: item.preferredPositionsOnly,
        );
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

    if (!_advanceAgentOneStep(_playerAgent)) return;

    final newHead = mainWorm.headGridPosition;
    final entryAtHead = _mapEntityManager.getAt(newHead);
    if (entryAtHead?.typeId == ProjectType.poison.typeId) {
      _applyPoisonToPlayer();
      _trySpawnFlagForObjectives();
      return;
    }
    final consumed = _mapEntityManager.consumeAt(newHead);
    if (consumed != null) {
      consumed.component.removeFromParent();
      if (consumed.typeId == ProjectType.preyCoin.typeId) {
        _coinsCollectedThisRun++;
        _lastCoinEatenGameTime = _gameTime;
      }
      if (consumed.typeId == ProjectType.preyFlag.typeId) {
        final view = EntityModels.view(consumed.typeId);
        if (view != null) {
          _playerAgent.behavior.onEatEntity(_playerAgent, view, _wormContext);
        }
        if (_allMissionsComplete()) _setVictory();
        return;
      }
      if (consumed.typeId == ProjectType.bomb.typeId) {
        _instantEffectBomb();
        return;
      }
      if (consumed.typeId == ProjectType.antidote.typeId) {
        _grantPoisonImmunity();
      }
      final view = EntityModels.view(consumed.typeId);
      if (view != null) {
        _playerAgent.behavior.onEatEntity(_playerAgent, view, _wormContext);
      }
      _trySpawnFlagForObjectives();
      return;
    }

    _trySpawnFlagForObjectives();
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
  _MagnetPull({
    required this.entry,
    required this.startPos,
    required this.startTime,
  });
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
    required this.pineappleScore,
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
  final int pineappleScore;
}

class GameHudItemBuff {
  const GameHudItemBuff({required this.itemId, required this.remainingSeconds});

  final String itemId;
  final double remainingSeconds;
}
