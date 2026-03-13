// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get entityPreyLeafName => 'Chiếc lá';

  @override
  String get entityPreyCoconutName => 'Quả dừa';

  @override
  String get entityXMarkName => 'Chướng ngại vật';

  @override
  String get entityPreyFlagName => 'Lá cờ';

  @override
  String get entityCoinName => 'Đồng xu';

  @override
  String get appTitle => 'Worm Journey';

  @override
  String levelLabel(int level) {
    return 'Lv$level';
  }

  @override
  String sceneLabel(int n) {
    return 'Cảnh $n';
  }

  @override
  String stageLabel(int n) {
    return 'Chặng $n';
  }

  @override
  String get gameOver => 'Game Over';

  @override
  String get tapToPlayAgain => 'Chạm để chơi lại';

  @override
  String get gameOverPlayAgain => 'Chơi lại';

  @override
  String get gameOverRevive => 'Hồi sinh';

  @override
  String get gameOverEnd => 'Kết thúc';

  @override
  String get view => 'Xem';

  @override
  String quantityShort(int quantity) {
    return 'x$quantity';
  }

  @override
  String buyCoins(int price, String coinIcon) {
    return 'Mua $price $coinIcon';
  }

  @override
  String get receive => 'Nhận';

  @override
  String getCoins(int amount, String coinIcon) {
    return 'Nhận $amount $coinIcon';
  }

  @override
  String get buttonJourney => 'Hành trình';

  @override
  String get buttonChallenge => 'Thử thách';

  @override
  String get buttonShop => 'Cửa hàng';

  @override
  String get buttonSettings => 'Cài đặt';

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
  String get itemSeedDescription => 'Tạo thêm lá cây.';

  @override
  String get itemAntidoteName => 'Thuốc giải';

  @override
  String get itemAntidoteDescription =>
      'Loại bỏ toàn bộ trạng thái hiệu ứng đang có trên sâu.';

  @override
  String get itemSpeedName => 'Tăng tốc';

  @override
  String get itemSpeedDescription =>
      'Sâu di chuyển nhanh hơn trong thời gian ngắn.';

  @override
  String get itemClockName => 'Đồng hồ';

  @override
  String get itemClockDescription =>
      'Cộng thêm 10 giây cho thời gian ván chơi.';

  @override
  String get itemFreezeName => 'Đóng băng';

  @override
  String get itemFreezeDescription => 'Dừng game trong 5 giây.';

  @override
  String get itemDizzyName => 'Chóng mặt';

  @override
  String get itemDizzyDescription => 'Đảo ngược hướng di chuyển của rắn.';

  @override
  String get exitGameWarningMessage => 'Trò chơi sẽ kết thúc ?';

  @override
  String get exitGameConfirm => 'Kết thúc';

  @override
  String get exitGameCancel => 'Huỷ';

  @override
  String get notEnoughCoins => 'Không đủ vàng';

  @override
  String waitCountdown(String time) {
    return 'Chờ $time';
  }

  @override
  String get itemBlockedInLevel => 'Item bị cấm ở màn này';

  @override
  String get understood => 'Đã hiểu';

  @override
  String get gameRulesTitle => 'Luật chơi';

  @override
  String get ready => 'Sẵn sàng';

  @override
  String get victory => 'Chiến thắng';

  @override
  String get victoryContinue => 'Tiếp tục';

  @override
  String victoryClaimReward(int amount) => 'Nhận thưởng $amount xu';

  @override
  String get victoryExit => 'Thoát';

  @override
  String get victoryExitLoseRewardWarning => 'Bạn sẽ mất phần thưởng lớn';

  @override
  String get victoryRewardLevelLabel => 'Level';

  @override
  String get victoryRewardTimeLabel => 'Thời gian';

  @override
  String get victoryRewardCoinsLabel => 'Xu';
}
