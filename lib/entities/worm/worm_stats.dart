/// Chỉ số sâu: tốc độ, độ cứng, v.v. Buff dừa: set currentHardness = originalBaseHardness + 1 khi thêm, trả về gốc khi xóa.
class WormStats {
  WormStats({double? moveInterval, int? baseHardness})
    : _moveInterval = moveInterval ?? 0.28,
      _originalBaseHardness = baseHardness ?? 1,
      currentHardness = baseHardness ?? 1;

  double _moveInterval;
  final int _originalBaseHardness;

  /// Độ cứng hiện tại (dùng so va chạm). Set trong onItemEffectAdded/Removed khi buff dừa.
  int currentHardness;

  /// Giây giữa mỗi bước di chuyển.
  double get moveInterval => _moveInterval;
  set moveInterval(double value) {
    if (value > 0) _moveInterval = value;
  }

  /// Độ cứng gốc (không đổi). Dùng để restore khi hết buff dừa.
  int get originalBaseHardness => _originalBaseHardness;

  WormStats copyWith({double? moveInterval, int? baseHardness}) {
    final newBase = baseHardness ?? currentHardness;
    return WormStats(
      moveInterval: moveInterval ?? _moveInterval,
      baseHardness: newBase,
    );
  }
}
