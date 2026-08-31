import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  double monthlyLimit;

  @HiveField(1)
  int month; // 1-12

  @HiveField(2)
  int year;

  @HiveField(3)
  String accountId;

  @HiveField(4)
  Map<String, double> categoryLimits;

  Budget({
    required this.monthlyLimit,
    required this.month,
    required this.year,
    this.accountId = 'default',
    Map<String, double>? categoryLimits,
  }) : categoryLimits = categoryLimits ?? {};

  Map<String, dynamic> toJson() {
    return {
      'monthlyLimit': monthlyLimit,
      'month': month,
      'year': year,
      'accountId': accountId,
      'categoryLimits': categoryLimits,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      monthlyLimit: json['monthlyLimit'],
      month: json['month'],
      year: json['year'],
      accountId: json['accountId'] ?? 'default',
      categoryLimits:
          (json['categoryLimits'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
    );
  }
}
