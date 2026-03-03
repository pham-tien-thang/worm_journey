import 'app_localizations.dart';

class AppLocalizationsVi extends AppLocalizations {
  @override
  String get appTitle => 'Worm Journey';

  @override
  String levelLabel(int level) => 'Lv$level';

  @override
  String get gameOver => 'Game Over';

  @override
  String get tapToPlayAgain => 'Chạm để chơi lại';

  @override
  String get view => 'Xem';

  @override
  String quantityShort(int quantity) => 'x$quantity';

  @override
  String buyDiamonds(int price) => 'Mua $price💎';

  @override
  String get receive => 'Nhận';

  @override
  String get buttonJourney => 'Hành trình';

  @override
  String get buttonChallenge => 'Thử thách';

  @override
  String get itemCoconutName => 'Quả dừa';

  @override
  String get itemCoconutDescription =>
      'Ăn vào sâu vào chế độ cứng đầu, phá được chướng ngại vật.';

  @override
  String get itemSnailName => 'Ốc sên';

  @override
  String get itemSnailDescription =>
      'Sâu vào chế độ đi chậm, dễ dàng điều khiển.';

  @override
  String get itemMagnetName => 'Nam châm';

  @override
  String get itemMagnetDescription =>
      'Hút tất cả các lá cây trong khoảng cách 2 ô.';

  @override
  String get itemShieldName => 'Khiên';

  @override
  String get itemShieldDescription =>
      '1 Khiên sẽ bảo vệ 1 lần khi đâm vào chướng ngại vật hoặc nhận sát thương.';

  @override
  String get itemBombName => 'Bom';

  @override
  String get itemBombDescription =>
      'Phá huỷ chướng ngại vật và gây sát thương lên kẻ địch trong 3 ô.';

  @override
  String get itemSeedName => 'Hạt giống';

  @override
  String get itemSeedDescription => 'Tạo thêm 3 lá cây.';
}
