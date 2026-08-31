import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

class HiveTransactionRepository implements TransactionRepository {
  final Box<Transaction> _box;

  HiveTransactionRepository(this._box);

  @override
  Future<List<Transaction>> getTransactions() async {
    return _box.values.toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    // Use the transaction ID as the key for direct access
    await _box.put(transaction.id, transaction);
    await _box.flush(); // Ensure data is written to disk
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (_box.containsKey(id)) {
      await _box.delete(id);
      await _box.flush();
    } else {
      // Fallback for legacy data where key might be an integer
      try {
        final transaction = _box.values.firstWhere((t) => t.id == id);
        await transaction.delete();
        await _box.flush();
      } catch (e) {
        // Transaction not found
      }
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    debugPrint('HiveRepo: Updating transaction ${transaction.id}');
    debugPrint('HiveRepo: receiptPath = ${transaction.receiptPath}');
    debugPrint('HiveRepo: notes = ${transaction.notes}');
    await _box.put(transaction.id, transaction);
    await _box.flush(); // Ensure data is written to disk immediately
    
    // Verify the save
    final saved = _box.get(transaction.id);
    debugPrint('HiveRepo: Verified saved receiptPath = ${saved?.receiptPath}');
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
