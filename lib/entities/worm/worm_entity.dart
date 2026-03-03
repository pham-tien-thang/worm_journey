import 'worm_team.dart';
import 'worm_type.dart';

/// Thông tin chung của một con rắn (player hoặc bot).
/// Thiết kế dễ mở rộng: sau có thể thêm chiêu thức, kỹ năng, v.v.
class WormEntity {
  const WormEntity({
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

  /// Rắn player mặc định (điều khiển bằng joystick).
  static WormEntity get playerDefault => WormEntity(
        id: 'player_1',
        name: 'Player',
        description: 'Rắn điều khiển bởi joystick',
        wormType: WormType.playerControlled,
        team: WormTeam.player,
        skin: 'default',
      );
}
