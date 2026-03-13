import 'entity_model.dart';

/// Model cha cho mồi (grey). Mặc định độ cứng 0.
abstract class GreyModel extends EntityModel {
  @override
  int get hardness => 0;
}

/// Lá 🌿
class PreyLeafModel extends GreyModel {
  @override
  String get icon => '🌿';
  @override
  ProjectType get type => ProjectType.preyLeaf;
}

/// Quả dừa 🥥
class PreyCoconutModel extends GreyModel {
  @override
  String get icon => '🥥';
  @override
  ProjectType get type => ProjectType.preyCoconut;
}

/// Lá cờ tam giác 🚩 (ăn để chiến thắng, không tính vào nhiệm vụ).
class PreyFlagModel extends GreyModel {
  @override
  String get icon => '🚩';
  @override
  ProjectType get type => ProjectType.preyFlag;
}

/// Đồng xu 🪙 (ăn để cộng thưởng victory).
class PreyCoinModel extends GreyModel {
  @override
  String get icon => '🪙';
  @override
  ProjectType get type => ProjectType.preyCoin;
}
