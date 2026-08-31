import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<List<Transaction>> syncMessages(String userId) async {
    try {
      debugPrint('Querying SMS...');
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 100, // Limit to last 100 messages for performance
      );
      debugPrint('Found ${messages.length} messages');

      final List<Transaction> transactions = [];

      for (final message in messages) {
        // debugPrint('SmsService: Checking message: ${message.body}');
        final transaction = _parseMessage(message, userId);
        if (transaction != null) {
          debugPrint(
            'Parsed transaction: ${transaction.title} - ${transaction.amount}',
          );
          transactions.add(transaction);
        }
      }

      return transactions;
    } catch (e) {
      debugPrint('Error reading SMS: $e');
      return [];
    }
  }

  Transaction? _parseMessage(SmsMessage message, String userId) {
    final body = message.body;
    if (body == null) return null;

    // debugPrint('Parsing: $body');

    // Regex for the provided format:
    // Rs.50.00 debited A/cXX5150 and credited to Vodafone Idea Rajasthan via UPI Ref No 541214146676 on 26Nov25.

    // 1. Extract Amount
    // Matches Rs.50.00, Rs. 50.00, INR 50.00, etc.
    final amountMatch = RegExp(
      r'(?:Rs\.?|INR)\s*(\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(body);
    if (amountMatch == null) {
      // debugPrint('Failed to match amount');
      return null;
    }
    final amount = double.tryParse(amountMatch.group(1) ?? '') ?? 0.0;

    // 2. Extract Type (debited/credited)
    final isExpense = body.toLowerCase().contains('debited');
    if (!isExpense && !body.toLowerCase().contains('credited')) {
      // debugPrint('Failed to match type (debited/credited)');
      return null;
    }

    // 3. Extract Payee/Payer
    String title = 'Unknown Transaction';
    if (isExpense) {
      final toMatch = RegExp(
        r'credited to (.+?) via',
        caseSensitive: false,
      ).firstMatch(body);
      if (toMatch != null) {
        title = toMatch.group(1)?.trim() ?? 'Unknown';
      } else {
        // debugPrint('Failed to match payee');
      }
    } else {
      // Handle credited (income) logic if needed, for now focusing on the provided example
      final fromMatch = RegExp(
        r'from (.+?) via',
        caseSensitive: false,
      ).firstMatch(body);
      if (fromMatch != null) {
        title = fromMatch.group(1)?.trim() ?? 'Unknown';
      }
    }

    // 4. Extract Date
    DateTime date = message.date ?? DateTime.now();
    final dateMatch = RegExp(
      r'on (\d{2}[A-Za-z]{3}\d{2})',
      caseSensitive: false,
    ).firstMatch(body);
    if (dateMatch != null) {
      try {
        final dateStr = dateMatch.group(1)!;
        // Parse format like 26Nov25
        final parser = DateFormat('ddMMMyy');
        final parsedDate = parser.parse(dateStr);

        // Combine parsed date with time from message.date if available to preserve order
        if (message.date != null) {
          date = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            message.date!.hour,
            message.date!.minute,
            message.date!.second,
          );
        } else {
          date = parsedDate;
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    // 5. Extract Ref No for uniqueness
    final refMatch = RegExp(
      r'Ref No (\d+)',
      caseSensitive: false,
    ).firstMatch(body);
    final refNo = refMatch?.group(1);

    // 6. Extract Bank Name
    // Check for "BankName- Message" at start OR "Message -BankName" at end
    // Allow alphanumeric and spaces, relying on the hyphen as separator
    final bankMatchStart = RegExp(
      r'^([a-zA-Z0-9\s]+)-',
    ).firstMatch(body.trim());
    final bankMatchEnd = RegExp(r'-([a-zA-Z0-9\s]+)$').firstMatch(body.trim());
    final bankName =
        bankMatchStart?.group(1)?.trim() ?? bankMatchEnd?.group(1)?.trim();

    // 7. Extract Account Last 4 (e.g., A/cXX5150)
    final accMatch = RegExp(r'A/cXX(\d+)').firstMatch(body);
    final accLast4 = accMatch?.group(1);

    // Use Ref No as ID if available, otherwise fallback to hash
    final id = refNo ?? 'sms_${message.date?.millisecondsSinceEpoch}_$amount';

    return Transaction(
      id: id,
      title: title,
      amount: amount,
      date: date,
      isExpense: isExpense,
      category: isExpense ? 'Utilities' : 'Income',
      accountId: userId,
      userId: userId,
      smsBody: body,
      referenceNumber: refNo,
      bankName: bankName,
      accountLast4: accLast4,
    );
  }
}
