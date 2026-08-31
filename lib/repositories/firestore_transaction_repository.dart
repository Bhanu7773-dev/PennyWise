import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import 'transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreTransactionRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(userId).collection('transactions');

  @override
  Future<List<Transaction>> getTransactions() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Transaction.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await _collection.doc(transaction.id).set(transaction.toJson());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    await _collection.doc(transaction.id).update(transaction.toJson());
  }

  @override
  Future<void> clear() async {
    final snapshot = await _collection.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
