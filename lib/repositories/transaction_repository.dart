import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<void> addTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> clear();
}
