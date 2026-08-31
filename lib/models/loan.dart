import 'package:hive/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 3)
enum LoanType {
  @HiveField(0)
  given, // Money I gave to someone (Lent)
  @HiveField(1)
  taken, // Money I took from someone (Borrowed)
}

@HiveType(typeId: 4)
class Loan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title; // Person name or purpose

  @HiveField(2)
  final double totalAmount;

  @HiveField(3)
  double paidAmount;

  @HiveField(4)
  final LoanType type;

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final String? notes;

  Loan({
    required this.id,
    required this.title,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.type,
    required this.startDate,
    this.dueDate,
    this.notes,
  });

  double get remainingAmount => totalAmount - paidAmount;
  double get progress =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => paidAmount >= totalAmount;
}
