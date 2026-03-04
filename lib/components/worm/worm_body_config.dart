/// Cấu hình đốt thân sâu: đường dẫn asset, scale (truyền lúc khởi tạo).
class WormBodyConfig {
  const WormBodyConfig({
    required this.assetVertical,
    required this.assetHorizontal,
    this.imageScale = 1.2,
  });

  final String assetVertical;
  final String assetHorizontal;
  final double imageScale;
}
