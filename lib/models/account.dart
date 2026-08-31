import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 6)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  int iconCode;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  bool isDefault;

  @HiveField(6)
  bool showSmsTransactions;

  Account({
    required this.id,
    required this.name,
    this.colorValue = 0xFF6C5CE7, // Default purple
    this.iconCode = 0xe04b, // account_balance_wallet icon code
    DateTime? createdAt,
    this.isDefault = false,
    this.showSmsTransactions = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
      'showSmsTransactions': showSmsTransactions,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      colorValue: json['colorValue'] ?? 0xFF6C5CE7,
      iconCode: json['iconCode'] ?? 0xe04b,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isDefault: json['isDefault'] ?? false,
      showSmsTransactions: json['showSmsTransactions'] ?? false,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCode,
    DateTime? createdAt,
    bool? isDefault,
    bool? showSmsTransactions,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      showSmsTransactions: showSmsTransactions ?? this.showSmsTransactions,
    );
  }
}
