/// Cấu hình đầu sâu: đường dẫn asset, scale, offset vẽ (truyền lúc khởi tạo).
class WormHeadConfig {
  const WormHeadConfig({
    required this.assetVertical,
    required this.assetHorizontal,
    required this.assetBack,
    required this.assetCry,
    this.imageScale = 1.32,
    this.antennaOffsetHorizontal = 0.18,
    this.antennaOffsetUp = 0.1,
    this.antennaOffsetDown = 0.18,
  });

  final String assetVertical;
  final String assetHorizontal;
  final String assetBack;
  final String assetCry;
  final double imageScale;
  final double antennaOffsetHorizontal;
  final double antennaOffsetUp;
  final double antennaOffsetDown;
}
