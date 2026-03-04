/// Chỉ số sâu: tốc độ, độ cứng, v.v. Buff dừa: gọi set baseHardness = originalBaseHardness + 1 khi thêm, trả về gốc khi xóa.
class WormStats {
  WormStats({
    double? moveInterval,
    int? baseHardness,
  })  : _moveInterval = moveInterval ?? 0.28,
        _originalBaseHardness = baseHardness ?? 1,
        _baseHardness = baseHardness ?? 1;

  double _moveInterval;
  final int _originalBaseHardness;
  int _baseHardness;

  /// Giây giữa mỗi bước di chuyển.
  double get moveInterval => _moveInterval;
  set moveInterval(double value) {
    if (value > 0) _moveInterval = value;
  }

  /// Độ cứng gốc (không đổi). Dùng để restore khi hết buff dừa.
  int get originalBaseHardness => _originalBaseHardness;

  /// Độ cứng hiện tại (so sánh va chạm). Khi có buff dừa được set = originalBaseHardness + 1 trong onItemEffectAdded.
  int get baseHardness => _baseHardness;
  set baseHardness(int value) {
    _baseHardness = value;
  }

  WormStats copyWith({double? moveInterval, int? baseHardness}) {
    final newBase = baseHardness ?? _baseHardness;
    return WormStats(
      moveInterval: moveInterval ?? _moveInterval,
      baseHardness: newBase,
    );
  }
}
