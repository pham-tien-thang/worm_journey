import '../../game/entities/entity_model.dart';

/// Cấu hình buff dùng chung: thời gian (giây) theo typeId (ProjectType.typeId).
abstract class BuffConfig {
  BuffConfig._();

  /// Thời gian buff (giây). Key = ProjectType.typeId.
  static final Map<String, double> durationSeconds = {
    ProjectType.preyCoconut.typeId: 10.0,
    // Thêm typeId khác khi có buff: 'snail': 5.0, ...
  };

  /// Lấy thời gian buff (giây) cho [itemId]. Mặc định 0.
  static double durationSecondsFor(String itemId) {
    return durationSeconds[itemId] ?? 0;
  }

  /// Có phải buff có thời gian (dùng để add vào list buff).
  static bool hasDuration(String itemId) {
    return (durationSeconds[itemId] ?? 0) > 0;
  }
}
