/// Chỉ số sâu: tốc độ, v.v. Có thể cập nhật trong ván (vd. buff ốc làm chậm).
class WormStats {
  WormStats({
    double? moveInterval,
  }) : _moveInterval = moveInterval ?? 0.28;

  double _moveInterval;

  /// Giây giữa mỗi bước di chuyển. Cập nhật trong ván: [moveInterval = 0.2].
  double get moveInterval => _moveInterval;
  set moveInterval(double value) {
    if (value > 0) _moveInterval = value;
  }

  WormStats copyWith({double? moveInterval}) {
    return WormStats(moveInterval: moveInterval ?? _moveInterval);
  }
}
