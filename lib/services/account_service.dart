import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/goal.dart';

/// Service for managing multi-account Firebase operations
class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  // Stream subscriptions for real-time sync
  StreamSubscription? _accountsSubscription;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _budgetsSubscription;
  StreamSubscription? _loansSubscription;
  StreamSubscription? _goalsSubscription;

  // Callbacks for real-time updates
  Function(List<Account>)? onAccountsChanged;
  Function(List<Transaction>)? onTransactionsChanged;
  Function(List<Budget>)? onBudgetsChanged;
  Function(List<Loan>)? onLoansChanged;
  Function(List<Goal>)? onGoalsChanged;

  AccountService(this.userId);

  /// Get reference to user document
  DocumentReference get _userDoc => _firestore.collection('users').doc(userId);

  /// Get reference to accounts collection
  CollectionReference<Map<String, dynamic>> get _accountsCollection =>
      _userDoc.collection('accounts');

  /// Get reference to a specific account's subcollection
  CollectionReference<Map<String, dynamic>> _getAccountSubcollection(
    String accountId,
    String subcollection,
  ) => _accountsCollection.doc(accountId).collection(subcollection);

  // ============== ACCOUNT CRUD ==============

  /// Create a new account with initialized empty subcollections
  Future<Account> createAccount({
    required String name,
    int? colorValue,
    bool isDefault = false,
    bool showSmsTransactions = false,
  }) async {
    final accountId = DateTime.now().millisecondsSinceEpoch.toString();

    final account = Account(
      id: accountId,
      name: name,
      colorValue: colorValue ?? _getAccountColor(_getColorIndex()),
      isDefault: isDefault,
      showSmsTransactions: showSmsTransactions,
    );

    // Create the account document
    await _accountsCollection.doc(accountId).set(account.toJson());

    // Initialize empty subcollections with a placeholder document
    // (Firestore doesn't create empty collections, but we don't need to add placeholders)
    // The subcollections will be created when first document is added

    debugPrint(
      'Account "$name" created: $accountId (SMS: $showSmsTransactions)',
    );
    return account;
  }

  int _colorIndex = 0;
  int _getColorIndex() {
    return _colorIndex++;
  }

  int _getAccountColor(int index) {
    final colors = [
      0xFF6C5CE7, // Purple
      0xFF00B894, // Green
      0xFFE17055, // Orange
      0xFF0984E3, // Blue
      0xFFD63031, // Red
      0xFFFDAA3D, // Yellow
    ];
    return colors[index % colors.length];
  }

  /// Get all accounts for the user
  Future<List<Account>> getAccounts() async {
    final snapshot = await _accountsCollection.orderBy('createdAt').get();
    return snapshot.docs.map((doc) => Account.fromJson(doc.data())).toList();
  }

  /// Update an account
  Future<void> updateAccount(Account account) async {
    await _accountsCollection.doc(account.id).update(account.toJson());
  }

  /// Delete an account and all its data
  Future<void> deleteAccount(String accountId) async {
    // Delete all subcollections first
    await _deleteSubcollection(accountId, 'transactions');
    await _deleteSubcollection(accountId, 'budgets');
    await _deleteSubcollection(accountId, 'loans');
    await _deleteSubcollection(accountId, 'goals');

    // Delete the account document
    await _accountsCollection.doc(accountId).delete();
    debugPrint('Account $accountId deleted');
  }

  /// Delete all accounts, all subcollections, and the user's document from Firestore
  Future<void> deleteAllUserData() async {
    stopAllSync();
    try {
      final accountsSnapshot = await _accountsCollection.get();
      for (final doc in accountsSnapshot.docs) {
        await deleteAccount(doc.id);
      }
      // Delete user root document in Firestore
      await _userDoc.delete();
      debugPrint('All Firestore data for user $userId deleted');
    } catch (e) {
      debugPrint('Error deleting user Firestore data: $e');
    }
  }

  Future<void> _deleteSubcollection(
    String accountId,
    String subcollection,
  ) async {
    final snapshot = await _getAccountSubcollection(
      accountId,
      subcollection,
    ).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Set default account
  Future<void> setDefaultAccount(String accountId) async {
    // First, unset all accounts as default
    final accounts = await getAccounts();
    for (final account in accounts) {
      if (account.isDefault) {
        await _accountsCollection.doc(account.id).update({'isDefault': false});
      }
    }
    // Set the new default
    await _accountsCollection.doc(accountId).update({'isDefault': true});
  }

  // ============== TRANSACTIONS ==============

  /// Get transactions for a specific account
  Future<List<Transaction>> getTransactions(String accountId) async {
    final snapshot = await _getAccountSubcollection(
      accountId,
      'transactions',
    ).orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => Transaction.fromJson(doc.data()))
        .toList();
  }

  /// Add transaction to account (excludes SMS transactions)
  Future<void> addTransaction(String accountId, Transaction transaction) async {
    // Don't sync SMS transactions to Firebase
    if (transaction.smsBody != null && transaction.smsBody!.isNotEmpty) {
      debugPrint('Skipping SMS transaction sync to Firebase');
      return;
    }
    await _getAccountSubcollection(
      accountId,
      'transactions',
    ).doc(transaction.id).set(transaction.toJson());
  }

  /// Update transaction in account
  Future<void> updateTransaction(
    String accountId,
    Transaction transaction,
  ) async {
    // Don't sync SMS transactions to Firebase
    if (transaction.smsBody != null && transaction.smsBody!.isNotEmpty) {
      return;
    }
    await _getAccountSubcollection(
      accountId,
      'transactions',
    ).doc(transaction.id).update(transaction.toJson());
  }

  /// Delete transaction from account
  Future<void> deleteTransaction(String accountId, String transactionId) async {
    await _getAccountSubcollection(
      accountId,
      'transactions',
    ).doc(transactionId).delete();
  }

  // ============== BUDGETS ==============

  /// Get budgets for a specific account
  Future<List<Budget>> getBudgets(String accountId) async {
    final snapshot = await _getAccountSubcollection(accountId, 'budgets').get();
    return snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList();
  }

  /// Add or update budget
  Future<void> saveBudget(String accountId, Budget budget) async {
    final budgetId = '${budget.year}_${budget.month}';
    await _getAccountSubcollection(
      accountId,
      'budgets',
    ).doc(budgetId).set(budget.toJson());
  }

  /// Delete budget
  Future<void> deleteBudget(String accountId, int year, int month) async {
    final budgetId = '${year}_$month';
    await _getAccountSubcollection(accountId, 'budgets').doc(budgetId).delete();
  }

  // ============== LOANS ==============

  /// Get loans for a specific account
  Future<List<Loan>> getLoans(String accountId) async {
    final snapshot = await _getAccountSubcollection(accountId, 'loans').get();
    return snapshot.docs.map((doc) => _loanFromJson(doc.data())).toList();
  }

  /// Add loan to account
  Future<void> addLoan(String accountId, Loan loan) async {
    await _getAccountSubcollection(
      accountId,
      'loans',
    ).doc(loan.id).set(_loanToJson(loan));
  }

  /// Update loan
  Future<void> updateLoan(String accountId, Loan loan) async {
    await _getAccountSubcollection(
      accountId,
      'loans',
    ).doc(loan.id).update(_loanToJson(loan));
  }

  /// Delete loan
  Future<void> deleteLoan(String accountId, String loanId) async {
    await _getAccountSubcollection(accountId, 'loans').doc(loanId).delete();
  }

  Map<String, dynamic> _loanToJson(Loan loan) {
    return {
      'id': loan.id,
      'title': loan.title,
      'totalAmount': loan.totalAmount,
      'paidAmount': loan.paidAmount,
      'type': loan.type.index,
      'startDate': loan.startDate.toIso8601String(),
      'dueDate': loan.dueDate?.toIso8601String(),
      'notes': loan.notes,
    };
  }

  Loan _loanFromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      title: json['title'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      type: LoanType.values[json['type'] ?? 0],
      startDate: DateTime.parse(json['startDate']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      notes: json['notes'],
    );
  }

  // ============== GOALS ==============

  /// Get goals for a specific account
  Future<List<Goal>> getGoals(String accountId) async {
    final snapshot = await _getAccountSubcollection(accountId, 'goals').get();
    return snapshot.docs.map((doc) => _goalFromJson(doc.data())).toList();
  }

  /// Add goal to account
  Future<void> addGoal(String accountId, Goal goal) async {
    await _getAccountSubcollection(
      accountId,
      'goals',
    ).doc(goal.id).set(_goalToJson(goal));
  }

  /// Update goal
  Future<void> updateGoal(String accountId, Goal goal) async {
    await _getAccountSubcollection(
      accountId,
      'goals',
    ).doc(goal.id).update(_goalToJson(goal));
  }

  /// Delete goal
  Future<void> deleteGoal(String accountId, String goalId) async {
    await _getAccountSubcollection(accountId, 'goals').doc(goalId).delete();
  }

  Map<String, dynamic> _goalToJson(Goal goal) {
    return {
      'id': goal.id,
      'title': goal.title,
      'targetAmount': goal.targetAmount,
      'savedAmount': goal.savedAmount,
      'deadline': goal.deadline?.toIso8601String(),
      'iconCode': goal.iconCode,
      'colorValue': goal.colorValue,
    };
  }

  Goal _goalFromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      iconCode: json['iconCode'],
      colorValue: json['colorValue'],
    );
  }

  // ============== REAL-TIME SYNC ==============

  /// Start listening to account changes
  void startAccountsSync() {
    _accountsSubscription?.cancel();
    _accountsSubscription = _accountsCollection
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
          final accounts = snapshot.docs
              .map((doc) => Account.fromJson(doc.data()))
              .toList();
          onAccountsChanged?.call(accounts);
        });
  }

  /// Start listening to transactions for a specific account
  void startTransactionsSync(String accountId) {
    _transactionsSubscription?.cancel();
    _transactionsSubscription =
        _getAccountSubcollection(
          accountId,
          'transactions',
        ).orderBy('date', descending: true).snapshots().listen((snapshot) {
          final transactions = snapshot.docs
              .map((doc) => Transaction.fromJson(doc.data()))
              .toList();
          onTransactionsChanged?.call(transactions);
        });
  }

  /// Start listening to budgets for a specific account
  void startBudgetsSync(String accountId) {
    _budgetsSubscription?.cancel();
    _budgetsSubscription = _getAccountSubcollection(accountId, 'budgets')
        .snapshots()
        .listen((snapshot) {
          final budgets = snapshot.docs
              .map((doc) => Budget.fromJson(doc.data()))
              .toList();
          onBudgetsChanged?.call(budgets);
        });
  }

  /// Start listening to loans for a specific account
  void startLoansSync(String accountId) {
    _loansSubscription?.cancel();
    _loansSubscription = _getAccountSubcollection(accountId, 'loans')
        .snapshots()
        .listen((snapshot) {
          final loans = snapshot.docs
              .map((doc) => _loanFromJson(doc.data()))
              .toList();
          onLoansChanged?.call(loans);
        });
  }

  /// Start listening to goals for a specific account
  void startGoalsSync(String accountId) {
    _goalsSubscription?.cancel();
    _goalsSubscription = _getAccountSubcollection(accountId, 'goals')
        .snapshots()
        .listen((snapshot) {
          final goals = snapshot.docs
              .map((doc) => _goalFromJson(doc.data()))
              .toList();
          onGoalsChanged?.call(goals);
        });
  }

  /// Start all sync listeners for an account
  void startAllSync(String accountId) {
    startAccountsSync();
    startTransactionsSync(accountId);
    startBudgetsSync(accountId);
    startLoansSync(accountId);
    startGoalsSync(accountId);
    debugPrint('Started real-time sync for account: $accountId');
  }

  /// Stop all sync listeners
  void stopAllSync() {
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _budgetsSubscription?.cancel();
    _loansSubscription?.cancel();
    _goalsSubscription?.cancel();
    debugPrint('Stopped all real-time sync');
  }

  /// Dispose and clean up
  void dispose() {
    stopAllSync();
  }

  /// Initialize default account if none exists
  Future<Account> initializeDefaultAccount({
    bool showSmsTransactions = true,
  }) async {
    final accounts = await getAccounts();

    if (accounts.isEmpty) {
      // Create default "Personal" account with SMS enabled by default
      final defaultAccount = await createAccount(
        name: 'Personal',
        colorValue: 0xFF6C5CE7,
        isDefault: true,
        showSmsTransactions: showSmsTransactions,
      );
      debugPrint(
        'Created default Personal account (SMS: $showSmsTransactions)',
      );

      // Migrate all existing data from old paths to new account
      await _migrateOldTransactions(defaultAccount.id);
      await _migrateOldLoans(defaultAccount.id);
      await _migrateOldGoals(defaultAccount.id);
      await _migrateOldBudgets(defaultAccount.id);

      return defaultAccount;
    }

    // Get the default account or first account
    final defaultAccount = accounts.firstWhere(
      (a) => a.isDefault,
      orElse: () => accounts.first,
    );

    // Fix: If the default Personal account has SMS disabled, enable it
    // This handles accounts created before showSmsTransactions was added
    if (defaultAccount.name == 'Personal' &&
        !defaultAccount.showSmsTransactions) {
      defaultAccount.showSmsTransactions = true;
      await updateAccount(defaultAccount);
      debugPrint('Enabled SMS transactions for existing Personal account');
    }

    return defaultAccount;
  }

  /// Migrate transactions from old path (users/{userId}/transactions) to new account path
  Future<void> _migrateOldTransactions(String accountId) async {
    try {
      // Get transactions from old path
      final oldTransactionsRef = _userDoc.collection('transactions');
      final oldSnapshot = await oldTransactionsRef.get();

      if (oldSnapshot.docs.isEmpty) {
        debugPrint('No old transactions to migrate');
        return;
      }

      debugPrint(
        'Migrating ${oldSnapshot.docs.length} transactions to account $accountId...',
      );

      final newTransactionsRef = _getAccountSubcollection(
        accountId,
        'transactions',
      );

      // Migrate each transaction
      for (final doc in oldSnapshot.docs) {
        final data = doc.data();
        data['accountId'] = accountId; // Update accountId
        await newTransactionsRef.doc(doc.id).set(data);
      }

      debugPrint(
        'Migrated ${oldSnapshot.docs.length} transactions successfully',
      );
    } catch (e) {
      debugPrint('Error migrating transactions: $e');
    }
  }

  /// Migrate loans from old path (users/{userId}/loans) to new account path
  Future<void> _migrateOldLoans(String accountId) async {
    try {
      final oldLoansRef = _userDoc.collection('loans');
      final oldSnapshot = await oldLoansRef.get();

      if (oldSnapshot.docs.isEmpty) {
        debugPrint('No old loans to migrate');
        return;
      }

      debugPrint(
        'Migrating ${oldSnapshot.docs.length} loans to account $accountId...',
      );

      final newLoansRef = _getAccountSubcollection(accountId, 'loans');

      for (final doc in oldSnapshot.docs) {
        final data = doc.data();
        data['accountId'] = accountId;
        await newLoansRef.doc(doc.id).set(data);
      }

      debugPrint('Migrated ${oldSnapshot.docs.length} loans successfully');
    } catch (e) {
      debugPrint('Error migrating loans: $e');
    }
  }

  /// Migrate goals from old path (users/{userId}/goals) to new account path
  Future<void> _migrateOldGoals(String accountId) async {
    try {
      final oldGoalsRef = _userDoc.collection('goals');
      final oldSnapshot = await oldGoalsRef.get();

      if (oldSnapshot.docs.isEmpty) {
        debugPrint('No old goals to migrate');
        return;
      }

      debugPrint(
        'Migrating ${oldSnapshot.docs.length} goals to account $accountId...',
      );

      final newGoalsRef = _getAccountSubcollection(accountId, 'goals');

      for (final doc in oldSnapshot.docs) {
        final data = doc.data();
        data['accountId'] = accountId;
        await newGoalsRef.doc(doc.id).set(data);
      }

      debugPrint('Migrated ${oldSnapshot.docs.length} goals successfully');
    } catch (e) {
      debugPrint('Error migrating goals: $e');
    }
  }

  /// Migrate budgets from old path (users/{userId}/budgets) to new account path
  Future<void> _migrateOldBudgets(String accountId) async {
    try {
      final oldBudgetsRef = _userDoc.collection('budgets');
      final oldSnapshot = await oldBudgetsRef.get();

      if (oldSnapshot.docs.isEmpty) {
        debugPrint('No old budgets to migrate');
        return;
      }

      debugPrint(
        'Migrating ${oldSnapshot.docs.length} budgets to account $accountId...',
      );

      final newBudgetsRef = _getAccountSubcollection(accountId, 'budgets');

      for (final doc in oldSnapshot.docs) {
        final data = doc.data();
        data['accountId'] = accountId;
        await newBudgetsRef.doc(doc.id).set(data);
      }

      debugPrint('Migrated ${oldSnapshot.docs.length} budgets successfully');
    } catch (e) {
      debugPrint('Error migrating budgets: $e');
    }
  }
}
