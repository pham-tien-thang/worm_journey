/// Config màn chơi từ JSON: load từng phần hoặc toàn bộ.
///
/// Mỗi màn có một file trong `assets/levels/` (vd. `level_1.json`).
/// Xem [loadLevelJsonConfig], [LevelJsonConfig] và `assets/levels/README.md` cho định dạng JSON.
library;

import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/grid_background.dart';

/// Quy tắc chơi màn. Scale thêm: cấm xài item, v.v.
enum EnumRule {
  none,
  // noItems, noApple, ...
}

/// Một nhiệm vụ trong config. Icon và label lấy từ [EntityModels] + l10n theo [typeId].
class MissionConfig {
  const MissionConfig({
    required this.id,
    required this.typeId,
    required this.target,
  });

  final String id;
  /// typeId entity (vd. prey_leaf). HUD lấy icon từ EntityModels, name từ ARB (l10n.entityDisplayName).
  final String typeId;
  final int target;

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeId': typeId,
        'target': target,
      };

  static MissionConfig fromJson(Map<String, dynamic> json) {
    return MissionConfig(
      id: json['id'] as String? ?? 'leaves',
      typeId: json['typeId'] as String? ?? 'prey_leaf',
      target: (json['target'] as num?)?.toInt() ?? 10,
    );
  }

  /// Mặc định: 1 nhiệm vụ ăn 10 lá.
  static const MissionConfig defaultLeaves = MissionConfig(
    id: 'leaves',
    typeId: 'prey_leaf',
    target: 10,
  );
}

/// Màu ô lưới (cell) trong vùng chơi. Từ JSON: colorLight, colorLighter (hex).
class GridColorsConfig {
  const GridColorsConfig({
    this.colorLight = const Color(0xFFE8DED5),
    this.colorLighter = const Color(0xFFD7CCC8),
  });

  final Color colorLight;
  final Color colorLighter;

  GridBackgroundColors toGridBackgroundColors() =>
      GridBackgroundColors(colorLight: colorLight, colorLighter: colorLighter);

  static GridColorsConfig fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const GridColorsConfig();
    return GridColorsConfig(
      colorLight: _parseColorFromJson(json['colorLight']) ?? const Color(0xFFE8DED5),
      colorLighter: _parseColorFromJson(json['colorLighter']) ?? const Color(0xFFD7CCC8),
    );
  }
}

/// Vùng ngoài grid (outside): màu + icon. Từ JSON: color (hex), icon.
class OutsideConfig {
  const OutsideConfig({
    this.color = const Color(0xFF8B7355),
    this.icon = '🌱',
  });

  final Color color;
  final String icon;

  OutsideGridConfig toOutsideGridConfig() =>
      OutsideGridConfig(color: color, icon: icon);

  static OutsideConfig fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const OutsideConfig();
    return OutsideConfig(
      color: _parseColorFromJson(json['color']) ?? const Color(0xFF8B7355),
      icon: json['icon'] as String? ?? '🌱',
    );
  }
}

Color? _parseColorFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return Color(value);
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  var hex = s.startsWith('#') ? s.substring(1) : s;
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.length == 6) hex = 'FF$hex';
  final parsed = int.tryParse(hex, radix: 16);
  return parsed != null ? Color(parsed) : null;
}

/// Map chơi: mỗi key = loại entity (x_mark, prey_leaf, rock, water, small_bot...), value = danh sách ô [[col, row]].
/// Game dùng factory đăng ký từng typeId → hàm "tạo + đặt tại ô"; không gom hết vào ObstacleManager.
class MapConfig {
  const MapConfig({this.placements = const {}});

  /// typeId → danh sách vị trí grid. VD: "x_mark": [[1,2]], "prey_leaf": [[0,1],[2,3]], "rock": [[5,6]].
  final Map<String, List<Vector2>> placements;

  static MapConfig fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const MapConfig();
    final placements = <String, List<Vector2>>{};
    for (final entry in json.entries) {
      final list = _parseGridList(entry.value);
      if (list.isEmpty) continue;
      final key = entry.key;
      // Tương thích cũ: obstacles → x_mark, prey → prey_leaf.
      final typeId = key == 'obstacles' ? 'x_mark' : (key == 'prey' ? 'prey_leaf' : key);
      placements[typeId] = [...(placements[typeId] ?? []), ...list];
    }
    return MapConfig(placements: placements);
  }

  static List<Vector2> _parseGridList(dynamic value) {
    if (value is! List) return [];
    final list = <Vector2>[];
    for (final e in value) {
      if (e is List && e.length >= 2) {
        final col = (e[0] as num).toDouble();
        final row = (e[1] as num).toDouble();
        list.add(Vector2(col, row));
      }
    }
    return list;
  }
}

/// Loại boss màn. "none" = không hiện boss; các giá trị khác do game/scene xử lý (vd. "snake_boss", "dragon").
const String levelBossTypeNone = 'none';

/// Config đầy đủ một màn (từ JSON). Mỗi màn có file JSON riêng.
class LevelJsonConfig {
  const LevelJsonConfig({
    this.missions = const [MissionConfig.defaultLeaves],
    this.timeLimitSeconds = 120.0,
    this.rule = EnumRule.none,
    this.mapConfig = const MapConfig(),
    this.gridColors = const GridColorsConfig(),
    this.outsideConfig = const OutsideConfig(),
    this.bossType = levelBossTypeNone,
  });

  final List<MissionConfig> missions;
  final double timeLimitSeconds;
  final EnumRule rule;
  final MapConfig mapConfig;
  final GridColorsConfig gridColors;
  final OutsideConfig outsideConfig;
  /// Loại boss: [levelBossTypeNone] = không hiện; khác thì scene load theo type.
  final String bossType;

  /// Có hiện boss hay không (theo config).
  bool get hasBoss => bossType != levelBossTypeNone && bossType.isNotEmpty;

  /// Load toàn bộ từ [jsonConfig] (map, rule, missions, stats, grid, outside, boss).
  static LevelJsonConfig loadAllConfig(Map<String, dynamic> jsonConfig) {
    return LevelJsonConfig(
      missions: loadMissionsConfig(jsonConfig),
      timeLimitSeconds: loadStatsConfig(jsonConfig).timeLimitSeconds,
      rule: loadRuleConfig(jsonConfig),
      mapConfig: loadMapConfig(jsonConfig),
      gridColors: loadGridConfig(jsonConfig),
      outsideConfig: loadOutsideConfig(jsonConfig),
      bossType: loadBossConfig(jsonConfig),
    );
  }

  /// Chỉ load boss. Key `boss` (string) trong JSON; null/empty/unknown → [levelBossTypeNone].
  static String loadBossConfig(Map<String, dynamic> jsonConfig) {
    final s = jsonConfig['boss'] as String? ?? jsonConfig['bossType'] as String?;
    if (s == null || s.toString().trim().isEmpty) return levelBossTypeNone;
    return s.toString().trim();
  }

  /// Chỉ load màu ô lưới (cell). Key `grid` trong JSON; null/empty → mặc định.
  static GridColorsConfig loadGridConfig(Map<String, dynamic> jsonConfig) {
    final grid = jsonConfig['grid'] as Map<String, dynamic>?;
    return GridColorsConfig.fromJson(grid);
  }

  /// Chỉ load vùng ngoài grid (outside). Key `outside` trong JSON; null/empty → mặc định.
  static OutsideConfig loadOutsideConfig(Map<String, dynamic> jsonConfig) {
    final outside = jsonConfig['outside'] as Map<String, dynamic>?;
    return OutsideConfig.fromJson(outside);
  }

  /// Chỉ load phần map. Key `map` trong JSON; bên trong mỗi key = typeId, value = list [[col, row]]. VD: "x_mark", "prey_leaf", "rock".
  static MapConfig loadMapConfig(Map<String, dynamic> jsonConfig) {
    final map = jsonConfig['map'] as Map<String, dynamic>?;
    return MapConfig.fromJson(map ?? {});
  }

  /// Chỉ load quy tắc chơi. Key `rule` (string, vd. `"none"`). Null/unknown → [EnumRule.none].
  static EnumRule loadRuleConfig(Map<String, dynamic> jsonConfig) {
    final s = jsonConfig['rule'] as String?;
    if (s == null) return EnumRule.none;
    return EnumRule.values.firstWhere(
      (e) => e.name == s,
      orElse: () => EnumRule.none,
    );
  }

  /// Chỉ load danh sách nhiệm vụ. Key `missions` (list object); null/empty → 1 nhiệm vụ mặc định [MissionConfig.defaultLeaves].
  static List<MissionConfig> loadMissionsConfig(Map<String, dynamic> jsonConfig) {
    final list = jsonConfig['missions'] as List<dynamic>?;
    if (list == null || list.isEmpty) {
      return const [MissionConfig.defaultLeaves];
    }
    return list
        .map((e) => MissionConfig.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Chỉ load thông số màn. Key `timeLimitSeconds` (number). Null → 120.
  static StatsConfig loadStatsConfig(Map<String, dynamic> jsonConfig) {
    final time = jsonConfig['timeLimitSeconds'] as num?;
    return StatsConfig(
      timeLimitSeconds: time?.toDouble() ?? 120.0,
    );
  }
}

/// Thông số màn (thời gian, ...). Dùng từ [LevelJsonConfig.loadStatsConfig].
class StatsConfig {
  const StatsConfig({this.timeLimitSeconds = 120.0});

  final double timeLimitSeconds;
}

/// Load config màn từ assets.
///
/// Đọc file `[assetsPath]/level_[level].json` (vd. `assets/levels/level_1.json`).
/// Nếu lỗi đọc, file không tồn tại hoặc parse thất bại thì trả về [LevelJsonConfig] mặc định.
///
/// [assetsPath] mặc định `assets/levels` (phải đã khai báo trong `pubspec.yaml`).
Future<LevelJsonConfig> loadLevelJsonConfig(int level, {String assetsPath = 'assets/levels'}) async {
  try {
    final path = '$assetsPath/level_$level.json';
    final json = await _loadJsonAsset(path);
    if (json != null) return LevelJsonConfig.loadAllConfig(json);
  } catch (_) {}
  return const LevelJsonConfig();
}

Future<Map<String, dynamic>?> _loadJsonAsset(String path) async {
  final str = await _loadString(path);
  if (str == null || str.isEmpty) return null;
  return _convertJson(jsonDecode(str)) as Map<String, dynamic>?;
}

Future<String?> _loadString(String path) async {
  try {
    return await rootBundle.loadString(path);
  } catch (_) {
    return null;
  }
}

dynamic _convertJson(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _convertJson(v)));
  }
  if (value is List) return value.map(_convertJson).toList();
  return value;
}
