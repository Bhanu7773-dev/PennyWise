import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final bool isExpense;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String accountId;

  @HiveField(7)
  final String? userId;

  @HiveField(8)
  final String? smsBody;

  @HiveField(9)
  final String? referenceNumber;

  @HiveField(10)
  final String? bankName;

  @HiveField(11)
  final String? accountLast4;

  @HiveField(12)
  final bool isExcluded;

  @HiveField(13)
  final String? notes;

  @HiveField(14)
  final String? receiptPath;

  @HiveField(15)
  final String? receiptBase64;

  @HiveField(16)
  final String? subcategory;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
    this.accountId = 'default',
    this.userId,
    this.smsBody,
    this.referenceNumber,
    this.bankName,
    this.accountLast4,
    this.isExcluded = false,
    this.notes,
    this.receiptPath,
    this.receiptBase64,
    this.subcategory,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
      'category': category,
      'accountId': accountId,
      'userId': userId,
      'smsBody': smsBody,
      'referenceNumber': referenceNumber,
      'bankName': bankName,
      'accountLast4': accountLast4,
      'isExcluded': isExcluded,
      'notes': notes,
      'receiptPath': receiptPath,
      'receiptBase64': receiptBase64,
      'subcategory': subcategory,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      isExpense: json['isExpense'],
      category: json['category'],
      accountId: json['accountId'] ?? 'default',
      userId: json['userId'],
      smsBody: json['smsBody'],
      referenceNumber: json['referenceNumber'],
      bankName: json['bankName'],
      accountLast4: json['accountLast4'],
      isExcluded: json['isExcluded'] ?? false,
      notes: json['notes'],
      receiptPath: json['receiptPath'],
      receiptBase64: json['receiptBase64'],
      subcategory: json['subcategory'],
    );
  }
}
