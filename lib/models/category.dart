import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCode;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final bool isCustom;

  @HiveField(5)
  final String? parentId; // ID of parent category (null if top-level)

  @HiveField(6)
  final List<String> subcategoryIds; // IDs of subcategories

  Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.isCustom = true,
    this.parentId,
    List<String>? subcategoryIds,
  }) : subcategoryIds = subcategoryIds ?? [];

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
  
  bool get isSubcategory => parentId != null;
  bool get hasSubcategories => subcategoryIds.isNotEmpty;

  Category copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    bool? isCustom,
    String? parentId,
    List<String>? subcategoryIds,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
      parentId: parentId ?? this.parentId,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
    );
  }
}
