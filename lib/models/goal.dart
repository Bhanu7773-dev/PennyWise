import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 5)
class Goal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  double savedAmount;

  @HiveField(4)
  final DateTime? deadline;

  @HiveField(5)
  final int iconCode;

  @HiveField(6)
  final int colorValue;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.deadline,
    required this.iconCode,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => savedAmount >= targetAmount;
}
