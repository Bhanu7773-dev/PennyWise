import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/goal.dart';
import '../models/account.dart';

class GoogleDriveService {
  static const String _backupFileName = 'pennywise_backup.json';
  static const String _appDataFolder = 'appDataFolder';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      drive.DriveApi.driveAppdataScope,
    ],
  );

  // Check if user is signed in with Drive scope
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Sign in to Google with Drive scope
  Future<GoogleSignInAccount?> signIn() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      
      // Check if already signed in
      if (account != null) {
        // Request additional scopes if needed
        final bool hasAccess = await _googleSignIn.requestScopes([
          drive.DriveApi.driveAppdataScope,
        ]);
        if (hasAccess) {
          return account;
        }
      }
      
      // Try silent sign in first
      account = await _googleSignIn.signInSilently();
      if (account != null) {
        // Request Drive scope
        await _googleSignIn.requestScopes([
          drive.DriveApi.driveAppdataScope,
        ]);
        return account;
      }

      // If not signed in, prompt full sign in
      account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return null;
    }
  }

  // Get Drive API client
  Future<drive.DriveApi?> _getDriveApi() async {
    final account = await signIn();
    if (account == null) return null;

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) {
      debugPrint('Failed to get authenticated client');
      return null;
    }

    return drive.DriveApi(authClient);
  }

  // Backup data to Google Drive
  Future<BackupResult> backupToGoogleDrive({
    List<Transaction>? transactions,
    List<Loan>? loans,
    List<Goal>? goals,
    List<Account>? accounts,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult(
          success: false,
          message: 'Failed to connect to Google Drive. Please sign in.',
        );
      }

      // Prepare backup data (pass provider data for items that might be in Firebase)
      final backupData = await _prepareBackupData(
        providerTransactions: transactions,
        providerLoans: loans,
        providerGoals: goals,
        providerAccounts: accounts,
      );
      final jsonString = jsonEncode(backupData);
      final bytes = utf8.encode(jsonString);

      // Check if backup file already exists
      final existingFile = await _findBackupFile(driveApi);

      final media = drive.Media(Stream.value(bytes), bytes.length);

      if (existingFile != null) {
        // Update existing file
        await driveApi.files.update(
          drive.File(),
          existingFile.id!,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final driveFile = drive.File()
          ..name = _backupFileName
          ..parents = [_appDataFolder];

        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      final timestamp = DateTime.now();
      return BackupResult(
        success: true,
        message: 'Backup successful!',
        timestamp: timestamp,
        itemCount: _getItemCount(backupData),
      );
    } catch (e) {
      debugPrint('Backup Error: $e');
      return BackupResult(
        success: false,
        message: 'Backup failed: ${e.toString()}',
      );
    }
  }

  // Restore data from Google Drive
  Future<RestoreResult> restoreFromGoogleDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return RestoreResult(
          success: false,
          message: 'Failed to connect to Google Drive. Please sign in.',
        );
      }

      // Find backup file
      final backupFile = await _findBackupFile(driveApi);
      if (backupFile == null) {
        return RestoreResult(
          success: false,
          message: 'No backup found on Google Drive.',
        );
      }

      // Download file content
      final response =
          await driveApi.files.get(
                backupFile.id!,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Restore data
      final itemCount = await _restoreBackupData(backupData);

      return RestoreResult(
        success: true,
        message: 'Restore successful!',
        itemCount: itemCount,
        backupDate: backupFile.modifiedTime,
      );
    } catch (e) {
      debugPrint('Restore Error: $e');
      return RestoreResult(
        success: false,
        message: 'Restore failed: ${e.toString()}',
      );
    }
  }

  // Get backup info without restoring
  Future<BackupInfo?> getBackupInfo() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final backupFile = await _findBackupFile(driveApi);
      if (backupFile == null) return null;

      return BackupInfo(
        fileName: backupFile.name ?? _backupFileName,
        modifiedTime: backupFile.modifiedTime,
        size: int.tryParse(backupFile.size ?? '0') ?? 0,
      );
    } catch (e) {
      debugPrint('Get Backup Info Error: $e');
      return null;
    }
  }

  // Delete backup from Google Drive
  Future<bool> deleteBackup() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final backupFile = await _findBackupFile(driveApi);
      if (backupFile == null) return true; // No file to delete

      await driveApi.files.delete(backupFile.id!);
      return true;
    } catch (e) {
      debugPrint('Delete Backup Error: $e');
      return false;
    }
  }

  // Find existing backup file
  Future<drive.File?> _findBackupFile(drive.DriveApi driveApi) async {
    final fileList = await driveApi.files.list(
      spaces: _appDataFolder,
      q: "name = '$_backupFileName'",
      $fields: 'files(id, name, modifiedTime, size)',
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first;
    }
    return null;
  }

  // Prepare backup data from Hive boxes and provider
  Future<Map<String, dynamic>> _prepareBackupData({
    List<Transaction>? providerTransactions,
    List<Loan>? providerLoans,
    List<Goal>? providerGoals,
    List<Account>? providerAccounts,
  }) async {
    final transactionBox = Hive.box<Transaction>('transactions');
    final categoryBox = Hive.box<Category>('categories');
    final budgetBox = Hive.box<Budget>('budgets');
    final loanBox = Hive.box<Loan>('loans');
    final goalBox = Hive.box<Goal>('goals');
    final settingsBox = Hive.box('settings');

    // Use provider data if available (includes Firebase data), otherwise use Hive
    // Note: Accounts are stored in Firebase only, so use provider data or empty list
    final transactionsToBackup = providerTransactions ?? transactionBox.values.toList();
    final loansToBackup = providerLoans ?? loanBox.values.toList();
    final goalsToBackup = providerGoals ?? goalBox.values.toList();
    final accountsToBackup = providerAccounts ?? <Account>[];

    debugPrint('Preparing backup data...');
    debugPrint('Accounts to backup: ${accountsToBackup.length}');
    debugPrint('Transactions to backup: ${transactionsToBackup.length}');
    debugPrint('Categories in Hive box: ${categoryBox.length}');
    debugPrint('Loans to backup: ${loansToBackup.length}');
    debugPrint('Goals to backup: ${goalsToBackup.length}');

    return {
      'version': 2,
      'timestamp': DateTime.now().toIso8601String(),
      'accounts': accountsToBackup.map((a) => _accountToJson(a)).toList(),
      'transactions': transactionsToBackup
          .map((t) => _transactionToJson(t))
          .toList(),
      'categories': categoryBox.values.map((c) => _categoryToJson(c)).toList(),
      'budgets': budgetBox.values.map((b) => _budgetToJson(b)).toList(),
      'loans': loansToBackup.map((l) => _loanToJson(l)).toList(),
      'goals': goalsToBackup.map((g) => _goalToJson(g)).toList(),
      'settings': {
        'userName': settingsBox.get('userName'),
        'cardName': settingsBox.get('cardName'),
        'currencySymbol': settingsBox.get('currencySymbol'),
        'currencyCode': settingsBox.get('currencyCode'),
      },
    };
  }

  // Restore backup data to Hive boxes
  Future<int> _restoreBackupData(Map<String, dynamic> backupData) async {
    int itemCount = 0;
    
    debugPrint('Starting restore...');
    debugPrint('Backup data keys: ${backupData.keys}');

    // Note: Accounts are stored in Firebase, not Hive
    // We backup accounts for reference but restore needs to be handled via Firebase
    if (backupData['accounts'] != null) {
      final accountsList = backupData['accounts'] as List;
      debugPrint('Backup contains ${accountsList.length} accounts (stored in Firebase, not Hive)');
      // Accounts will be synced to Firebase through the provider after restore
      itemCount += accountsList.length;
    }

    // Restore transactions
    if (backupData['transactions'] != null) {
      final transactionBox = Hive.box<Transaction>('transactions');
      await transactionBox.clear();
      final transactionsList = backupData['transactions'] as List;
      debugPrint('Restoring ${transactionsList.length} transactions...');
      for (var t in transactionsList) {
        try {
          final transaction = _jsonToTransaction(Map<String, dynamic>.from(t));
          await transactionBox.add(transaction);
          itemCount++;
        } catch (e) {
          debugPrint('Error restoring transaction: $e');
        }
      }
      debugPrint('Transactions restored: ${transactionBox.length}');
    }

    // Restore categories
    if (backupData['categories'] != null) {
      final categoryBox = Hive.box<Category>('categories');
      await categoryBox.clear();
      final categoriesList = backupData['categories'] as List;
      debugPrint('Restoring ${categoriesList.length} categories...');
      for (var c in categoriesList) {
        try {
          final category = _jsonToCategory(Map<String, dynamic>.from(c));
          await categoryBox.add(category);
          itemCount++;
        } catch (e) {
          debugPrint('Error restoring category: $e');
        }
      }
      debugPrint('Categories restored: ${categoryBox.length}');
    }

    // Restore budgets
    if (backupData['budgets'] != null) {
      final budgetBox = Hive.box<Budget>('budgets');
      await budgetBox.clear();
      final budgetsList = backupData['budgets'] as List;
      debugPrint('Restoring ${budgetsList.length} budgets...');
      for (var b in budgetsList) {
        try {
          final budget = _jsonToBudget(Map<String, dynamic>.from(b));
          await budgetBox.add(budget);
          itemCount++;
        } catch (e) {
          debugPrint('Error restoring budget: $e');
        }
      }
    }

    // Restore loans
    if (backupData['loans'] != null) {
      final loanBox = Hive.box<Loan>('loans');
      await loanBox.clear();
      final loansList = backupData['loans'] as List;
      debugPrint('Restoring ${loansList.length} loans...');
      for (var l in loansList) {
        try {
          final loan = _jsonToLoan(Map<String, dynamic>.from(l));
          await loanBox.add(loan);
          itemCount++;
        } catch (e) {
          debugPrint('Error restoring loan: $e');
        }
      }
    }

    // Restore goals
    if (backupData['goals'] != null) {
      final goalBox = Hive.box<Goal>('goals');
      await goalBox.clear();
      final goalsList = backupData['goals'] as List;
      debugPrint('Restoring ${goalsList.length} goals...');
      for (var g in goalsList) {
        try {
          final goal = _jsonToGoal(Map<String, dynamic>.from(g));
          await goalBox.add(goal);
          itemCount++;
        } catch (e) {
          debugPrint('Error restoring goal: $e');
        }
      }
    }

    // Restore settings
    if (backupData['settings'] != null) {
      final settingsBox = Hive.box('settings');
      final settings = Map<String, dynamic>.from(backupData['settings']);
      debugPrint('Restoring settings: $settings');
      if (settings['userName'] != null) {
        await settingsBox.put('userName', settings['userName']);
      }
      if (settings['cardName'] != null) {
        await settingsBox.put('cardName', settings['cardName']);
      }
      if (settings['currencySymbol'] != null) {
        await settingsBox.put('currencySymbol', settings['currencySymbol']);
      }
      if (settings['currencyCode'] != null) {
        await settingsBox.put('currencyCode', settings['currencyCode']);
      }
    }
    
    debugPrint('Restore complete. Total items: $itemCount');

    return itemCount;
  }

  int _getItemCount(Map<String, dynamic> backupData) {
    int count = 0;
    if (backupData['accounts'] != null) {
      count += (backupData['accounts'] as List).length;
    }
    if (backupData['transactions'] != null) {
      count += (backupData['transactions'] as List).length;
    }
    if (backupData['categories'] != null) {
      count += (backupData['categories'] as List).length;
    }
    if (backupData['budgets'] != null) {
      count += (backupData['budgets'] as List).length;
    }
    if (backupData['loans'] != null) {
      count += (backupData['loans'] as List).length;
    }
    if (backupData['goals'] != null) {
      count += (backupData['goals'] as List).length;
    }
    return count;
  }

  // JSON conversion methods
  Map<String, dynamic> _transactionToJson(Transaction t) {
    return {
      'id': t.id,
      'title': t.title,
      'amount': t.amount,
      'category': t.category,
      'date': t.date.toIso8601String(),
      'isExpense': t.isExpense,
      'notes': t.notes,
      'receiptPath': t.receiptPath,
      'receiptBase64': t.receiptBase64,
      'isExcluded': t.isExcluded,
      'userId': t.userId,
      'smsBody': t.smsBody,
      'accountId': t.accountId,
      'referenceNumber': t.referenceNumber,
      'bankName': t.bankName,
      'accountLast4': t.accountLast4,
      'subcategory': t.subcategory,
    };
  }

  Transaction _jsonToTransaction(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      date: DateTime.parse(json['date']),
      isExpense: json['isExpense'] ?? true,
      notes: json['notes'],
      receiptPath: json['receiptPath'],
      receiptBase64: json['receiptBase64'],
      isExcluded: json['isExcluded'] ?? false,
      userId: json['userId'],
      smsBody: json['smsBody'],
      accountId: json['accountId'] ?? 'default',
      referenceNumber: json['referenceNumber'],
      bankName: json['bankName'],
      accountLast4: json['accountLast4'],
      subcategory: json['subcategory'],
    );
  }

  Map<String, dynamic> _categoryToJson(Category c) {
    return {
      'id': c.id,
      'name': c.name,
      'iconCode': c.iconCode,
      'colorValue': c.colorValue,
      'isCustom': c.isCustom,
      'parentId': c.parentId,
      'subcategoryIds': c.subcategoryIds,
    };
  }

  Category _jsonToCategory(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconCode: json['iconCode'] ?? 0,
      colorValue: json['colorValue'] ?? 0,
      isCustom: json['isCustom'] ?? true,
      parentId: json['parentId'],
      subcategoryIds: json['subcategoryIds'] != null
          ? List<String>.from(json['subcategoryIds'])
          : null,
    );
  }

  Map<String, dynamic> _budgetToJson(Budget b) {
    return {
      'monthlyLimit': b.monthlyLimit,
      'month': b.month,
      'year': b.year,
      'accountId': b.accountId,
      'categoryLimits': b.categoryLimits,
    };
  }

  Budget _jsonToBudget(Map<String, dynamic> json) {
    return Budget(
      monthlyLimit: (json['monthlyLimit'] ?? 0).toDouble(),
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      accountId: json['accountId'] ?? 'default',
      categoryLimits: json['categoryLimits'] != null
          ? Map<String, double>.from(
              (json['categoryLimits'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> _loanToJson(Loan l) {
    return {
      'id': l.id,
      'title': l.title,
      'totalAmount': l.totalAmount,
      'paidAmount': l.paidAmount,
      'type': l.type.index,
      'startDate': l.startDate.toIso8601String(),
      'dueDate': l.dueDate?.toIso8601String(),
      'notes': l.notes,
    };
  }

  Loan _jsonToLoan(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      type: LoanType.values[json['type'] ?? 0],
      startDate: DateTime.parse(json['startDate']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> _goalToJson(Goal g) {
    return {
      'id': g.id,
      'title': g.title,
      'targetAmount': g.targetAmount,
      'savedAmount': g.savedAmount,
      'deadline': g.deadline?.toIso8601String(),
      'iconCode': g.iconCode,
      'colorValue': g.colorValue,
    };
  }

  Goal _jsonToGoal(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      savedAmount: (json['savedAmount'] ?? 0).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      iconCode: json['iconCode'] ?? Icons.savings.codePoint,
      colorValue: json['colorValue'] ?? Colors.blue.value,
    );
  }

  Map<String, dynamic> _accountToJson(Account a) {
    return {
      'id': a.id,
      'name': a.name,
      'colorValue': a.colorValue,
      'iconCode': a.iconCode,
      'createdAt': a.createdAt.toIso8601String(),
      'isDefault': a.isDefault,
      'showSmsTransactions': a.showSmsTransactions,
    };
  }
}

// Result classes
class BackupResult {
  final bool success;
  final String message;
  final DateTime? timestamp;
  final int? itemCount;

  BackupResult({
    required this.success,
    required this.message,
    this.timestamp,
    this.itemCount,
  });
}

class RestoreResult {
  final bool success;
  final String message;
  final int? itemCount;
  final DateTime? backupDate;

  RestoreResult({
    required this.success,
    required this.message,
    this.itemCount,
    this.backupDate,
  });
}

class BackupInfo {
  final String fileName;
  final DateTime? modifiedTime;
  final int size;

  BackupInfo({required this.fileName, this.modifiedTime, required this.size});
}
