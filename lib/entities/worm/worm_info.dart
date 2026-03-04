import 'worm_team.dart';
import 'worm_type.dart';

/// Thông tin của một con sâu (player hoặc bot): id, tên, loại điều khiển, team, skin, skill...
/// Thiết kế dễ mở rộng: sau có thể thêm chiêu thức, kỹ năng, v.v.
class WormInfo {
  const WormInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.wormType,
    required this.team,
    required this.skin,
    List<String>? skillIds,
  }) : skillIds = skillIds ?? const [];

  /// Id duy nhất (vd. "player_1", "bot_easy_1").
  final String id;

  /// Tên hiển thị.
  final String name;

  /// Mô tả (tooltip, profile).
  final String description;

  /// Loại: điều khiển bởi joystick hay bot.
  final WormType wormType;

  /// Phe: người chơi hoặc team bot.
  final WormTeam team;

  /// Trang phục / skin (id hoặc path, dễ map tới asset sau).
  final String skin;

  /// Id các chiêu thức / kỹ năng (để mở rộng sau).
  final List<String> skillIds;

  bool get isPlayerControlled => wormType == WormType.playerControlled;
  bool get isBot => wormType == WormType.bot;

  /// Sâu player mặc định (điều khiển bằng joystick).
  static WormInfo get playerDefault => WormInfo(
        id: 'player_1',
        name: 'Player',
        description: 'Sâu điều khiển bởi joystick',
        wormType: WormType.playerControlled,
        team: WormTeam.player,
        skin: 'default',
      );
}
