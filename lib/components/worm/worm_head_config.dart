/// Cấu hình đầu sâu: đường dẫn asset, scale, offset vẽ (truyền lúc khởi tạo).
/// [assetHelmet*] optional: khi có thì head có thể bật helmet (vd. buff dừa).
class WormHeadConfig {
  const WormHeadConfig({
    required this.assetVertical,
    required this.assetHorizontal,
    required this.assetBack,
    required this.assetCry,
    this.assetHelmetVertical,
    this.assetHelmetHorizontal,
    this.assetHelmetBack,
    this.assetHelmetCry,
    this.imageScale = 1.32,
    this.antennaOffsetHorizontal = 0.18,
    this.antennaOffsetUp = 0.1,
    this.antennaOffsetDown = 0.18,
  });

  final String assetVertical;
  final String assetHorizontal;
  final String assetBack;
  final String assetCry;
  final String? assetHelmetVertical;
  final String? assetHelmetHorizontal;
  final String? assetHelmetBack;
  final String? assetHelmetCry;
  final double imageScale;
  final double antennaOffsetHorizontal;
  final double antennaOffsetUp;
  final double antennaOffsetDown;

  bool get hasHelmetAssets =>
      assetHelmetVertical != null &&
      assetHelmetHorizontal != null &&
      assetHelmetBack != null &&
      assetHelmetCry != null;
}
