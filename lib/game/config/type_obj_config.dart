import 'dart:convert';

import 'package:flutter/services.dart';

/// Config từ jsonTypeObj.json: chỉ định nghĩa type thuộc category nào (obtain/grey).
/// Không chứa icon hay hardness — lấy từ [EntityModels] (model cha/con).
class TypeObjConfig {
  TypeObjConfig._({required this.categories});

  /// typeId → category: "obtain" (vật cản), "grey" (mồi), ...
  final Map<String, String> categories;

  static Future<TypeObjConfig> load({String path = 'assets/jsonTypeObj.json'}) async {
    try {
      final s = await rootBundle.loadString(path);
      final json = jsonDecode(s) as Map<String, dynamic>?;
      return fromJson(json ?? {});
    } catch (_) {
      return fromJson({});
    }
  }

  static TypeObjConfig fromJson(Map<String, dynamic> json) {
    final categories = <String, String>{};
    for (final entry in (json['obtain'] as List<dynamic>?) ?? []) {
      categories[entry.toString()] = 'obtain';
    }
    for (final entry in (json['grey'] as List<dynamic>?) ?? []) {
      categories[entry.toString()] = 'grey';
    }
    for (final entry in (json['x'] as List<dynamic>?) ?? []) {
      categories[entry.toString()] = 'x';
    }
    return TypeObjConfig._(categories: categories);
  }

  String? getCategory(String typeId) => categories[typeId];

  bool isEatable(String typeId) => getCategory(typeId) == 'grey';

  /// Có chặn đường không (đâm vào phải so độ cứng).
  bool isBlocking(String typeId) =>
      getCategory(typeId) != null && getCategory(typeId) != 'grey';

  Set<String> get allTypeIds => categories.keys.toSet();
}
