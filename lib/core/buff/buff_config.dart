import '../../game/entities/entity_model.dart';
import '../../models/item_model.dart';

/// Cấu hình buff/effect dùng chung: thời gian, nhóm mutual, antidote xóa những gì, item dùng 1 lần (instant).
abstract class BuffConfig {
  BuffConfig._();

  // --- Thời gian (giây) cho effect có duration ---
  static final Map<String, double> durationSeconds = {
    ItemType.coconut.effectTypeId: 10.0,
    ItemType.speed.effectTypeId: 8.0,
    ItemType.snail.effectTypeId: 8.0,
    ItemType.freeze.effectTypeId: 5.0,
    ItemType.dizzy.effectTypeId: 8.0,
    ItemType.magnet.effectTypeId: 8.0,
  };

  /// Effect nào không cùng tồn tại: thêm cái này thì xóa hết các cái trong cùng nhóm.
  /// VD: [speed, snail] — thêm speed thì xóa snail, thêm snail thì xóa speed.
  static final List<List<String>> mutuallyExclusiveEffectGroups = [
    [ItemType.speed.effectTypeId, ItemType.snail.effectTypeId],
  ];

  /// Antidote xóa toàn bộ effect có id trong danh sách này. Scale: thêm typeId vào list.
  static final List<String> removableByAntidoteEffectIds = [
    ItemType.speed.effectTypeId,
    ItemType.snail.effectTypeId,
    ItemType.freeze.effectTypeId,
    ItemType.dizzy.effectTypeId,
  ];

  /// Item dùng 1 lần, không có duration, không vào list effect. Scale: thêm typeId vào list.
  static final List<String> instantEffectIds = [
    ItemType.bomb.effectTypeId,
    ItemType.clock.effectTypeId,
    ItemType.seed.effectTypeId,
  ];

  /// Tham số cho instant effect (scale: thêm key mới). VD: clock + bao nhiêu giây, bomb bán kính ô.
  static const int clockAddSeconds = 10;
  /// Số ô bán kính nổ của bom (tính từ đầu rắn; khoảng cách Chebyshev: max(|dx|,|dy|) <= giá trị này).
  static const int bombRadiusTiles = 3;

  /// Magnet: số ô bán kính hút (khoảng cách Chebyshev từ đầu rắn; chỉ mồi trong phạm vi này bị hút).
  static const int magnetRangeTiles = 3;
  /// Magnet hút các ProjectType có typeId trong list này về đầu worm. Scale: thêm typeId.
  static final List<String> magnetAttractTypeIds = [
    ProjectType.preyLeaf.typeId,
    ProjectType.preyCoconut.typeId,
  ];

  static const double magnetPullDurationSeconds = 0.5;

  static double durationSecondsFor(String itemId) {
    return durationSeconds[itemId] ?? 0;
  }

  static bool hasDuration(String itemId) {
    return (durationSeconds[itemId] ?? 0) > 0;
  }

  static bool isInstantEffect(String itemId) => instantEffectIds.contains(itemId);

  /// Nhóm chứa [itemId] (nếu có). Trả về các id khác trong nhóm (để xóa khi thêm itemId).
  static List<String>? getMutuallyExclusiveIdsToRemove(String itemId) {
    for (final group in mutuallyExclusiveEffectGroups) {
      if (group.contains(itemId)) {
        return group.where((id) => id != itemId).toList();
      }
    }
    return null;
  }
}
