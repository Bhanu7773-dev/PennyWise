import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/loan.dart';
import '../models/goal.dart';
import '../models/account.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/hive_transaction_repository.dart';
import '../repositories/firestore_transaction_repository.dart';
import '../services/sms_service.dart';
import '../services/account_service.dart';
import '../utils/app_theme.dart';

class MoneyProvider extends ChangeNotifier {
  late TransactionRepository _repository;
  late HiveTransactionRepository
  _localRepository; // For SMS transactions (local only)
  final Box _settingsBox = Hive.box('settings');
  final Box<String> _deletedSmsBox = Hive.box<String>('deletedSmsIds');
  late Box<Budget> _budgetBox;
  String _userName = 'User';
  String _cardName = 'VISA';
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
  String? _userId;
  String? _photoURL;
  Budget? _currentBudget;
  List<Transaction> _transactions = [];
  bool _smsTrackingEnabled = false;
  bool _biometricLockEnabled = false;
  bool _isLoading = true; // Loading state for skeleton
  AppThemeMode _appThemeMode = AppThemeMode.defaultDark;

  // Multi-account support
  AccountService? _accountService;
  List<Account> _accounts = [];
  Account? _activeAccount;
  String? _activeAccountId;

  String get userName => _userName;
  String get cardName => _cardName;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  String? get userId => _userId;
  String? get photoURL => _photoURL;
  Budget? get currentBudget => _currentBudget;
  Box get settingsBox => _settingsBox;
  List<Transaction> get transactions => _transactions;
  bool get smsTrackingEnabled => _smsTrackingEnabled;
  bool get biometricLockEnabled => _biometricLockEnabled;
  bool get isLoading => _isLoading; // Expose loading state
  AppThemeMode get appThemeMode => _appThemeMode;

  // Account getters
  List<Account> get accounts => _accounts;
  Account? get activeAccount => _activeAccount;
  String? get activeAccountId => _activeAccountId;

  // Card design selection
  String _selectedCardDesign = 'default';
  String get selectedCardDesign => _selectedCardDesign;

  MoneyProvider() {
    _init();
  }

  void _loadCardDesign() {
    _selectedCardDesign = _settingsBox.get(
      'selectedCardDesign',
      defaultValue: 'default',
    );
    notifyListeners();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _initRepository();
    _loadSettings();
    _initBudget();
    _loadCardDesign();

    _isLoading = false;
    notifyListeners();
  }

  /// Reload all data from Hive boxes (useful after restore from backup)
  Future<void> reloadData() async {
    _isLoading = true;
    notifyListeners();

    // Reload transactions
    await _loadTransactions();

    // Reload categories
    _categories = _categoryBox.values.toList();

    // Reload budgets
    _loadCurrentBudget();

    // Reload loans
    _loadLoans();

    // Reload goals
    _loadGoals();

    // Reload settings
    _loadSettings();

    _isLoading = false;
    notifyListeners();
  }

  /// Import restored transactions from Hive to Firebase
  /// Called after restore from Google Drive backup for logged-in users
  Future<void> importRestoredDataToFirebase() async {
    if (_accountService == null || _activeAccountId == null) {
      debugPrint('No account service - skipping Firebase import');
      return;
    }

    debugPrint('Importing restored data to Firebase...');

    // Get transactions from Hive that were restored
    final transactionBox = Hive.box<Transaction>('transactions');
    final restoredTransactions = transactionBox.values.toList();

    debugPrint('Found ${restoredTransactions.length} transactions to import');

    int imported = 0;
    for (final t in restoredTransactions) {
      // Skip SMS transactions - they stay in Hive
      if (t.smsBody != null && t.smsBody!.isNotEmpty) {
        debugPrint('Skipping SMS transaction: ${t.title}');
        continue;
      }

      try {
        // Determine which account to add to
        final accountId = t.accountId.isNotEmpty && t.accountId != 'default'
            ? t.accountId
            : _activeAccountId!;

        // Create transaction with correct userId
        final transaction = Transaction(
          id: t.id,
          title: t.title,
          amount: t.amount,
          date: t.date,
          isExpense: t.isExpense,
          category: t.category,
          accountId: accountId,
          userId: _userId,
          notes: t.notes,
          receiptPath: t.receiptPath,
          receiptBase64: t.receiptBase64,
          subcategory: t.subcategory,
        );

        await _accountService!.addTransaction(accountId, transaction);
        imported++;
        debugPrint('Imported: ${t.title}');
      } catch (e) {
        debugPrint('Error importing transaction ${t.title}: $e');
      }
    }

    debugPrint('Imported $imported transactions to Firebase');

    // Clear the Hive transactions box (keep only SMS transactions)
    final smsTransactions = restoredTransactions
        .where((t) => t.smsBody != null && t.smsBody!.isNotEmpty)
        .toList();
    await transactionBox.clear();
    for (final t in smsTransactions) {
      await transactionBox.add(t);
    }

    // Import loans
    final loanBox = Hive.box<Loan>('loans');
    final restoredLoans = loanBox.values.toList();
    debugPrint('Importing ${restoredLoans.length} loans...');
    for (final loan in restoredLoans) {
      try {
        await _accountService!.addLoan(_activeAccountId!, loan);
      } catch (e) {
        debugPrint('Error importing loan: $e');
      }
    }

    // Import goals
    final goalBox = Hive.box<Goal>('goals');
    final restoredGoals = goalBox.values.toList();
    debugPrint('Importing ${restoredGoals.length} goals...');
    for (final goal in restoredGoals) {
      try {
        await _accountService!.addGoal(_activeAccountId!, goal);
      } catch (e) {
        debugPrint('Error importing goal: $e');
      }
    }

    // Reload data from Firebase
    await _loadAccountData(_activeAccountId!);
    notifyListeners();
  }

  Future<void> _initRepository() async {
    final isGuest = _settingsBox.get('isGuest', defaultValue: true);
    final userId = _settingsBox.get('userId');

    // Always initialize local repository for SMS transactions
    final box = Hive.box<Transaction>('transactions');
    _localRepository = HiveTransactionRepository(box);

    if (!isGuest && userId != null) {
      _userId = userId; // Set userId for returning users
      _repository = FirestoreTransactionRepository(userId);

      // Initialize account service for non-guest users
      _accountService = AccountService(userId);
      // Accounts and transactions will be loaded via _initializeAccounts
      // which sets up real-time sync and loads account-specific data
      await _initializeAccounts();
    } else {
      _repository = _localRepository;
      // Only load from local repository for guest users
      await _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    try {
      // Get transactions from main repository (Firebase or Hive)
      final mainTransactions = await _repository.getTransactions();

      // Get local SMS transactions (always from Hive)
      final localTransactions = await _localRepository.getTransactions();

      // Merge: start with main transactions
      final Map<String, Transaction> transactionMap = {};

      for (final t in mainTransactions) {
        if (_userId != null && t.userId == _userId) {
          transactionMap[t.id] = t;
        }
      }

      // Add local SMS transactions (only those with smsBody)
      // These take priority for SMS-specific fields like receiptPath
      for (final t in localTransactions) {
        if (t.smsBody != null && t.smsBody!.isNotEmpty) {
          // SMS transaction - always use local version as it has user edits
          // (receiptPath, notes, category changes, etc.)
          transactionMap[t.id] = t;
        }
      }

      _transactions = transactionMap.values.toList();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
    }
    notifyListeners();
  }

  void _loadSettings() {
    _userName = _settingsBox.get('userName', defaultValue: 'User');
    _cardName = _settingsBox.get('cardName', defaultValue: 'VISA');
    _currencySymbol = _settingsBox.get('currencySymbol', defaultValue: '₹');
    _currencyCode = _settingsBox.get('currencyCode', defaultValue: 'INR');
    _userId = _settingsBox.get('userId');
    _photoURL = _settingsBox.get('photoURL');
    _smsTrackingEnabled = _settingsBox.get(
      'smsTrackingEnabled',
      defaultValue: false,
    );
    _biometricLockEnabled = _settingsBox.get(
      'biometricLockEnabled',
      defaultValue: false,
    );
    _selectedCardDesign = _settingsBox.get(
      'selectedCardDesign',
      defaultValue: 'default',
    );

    final themeIndex = _settingsBox.get('appThemeMode', defaultValue: 0);
    _appThemeMode = AppThemeMode.values[themeIndex];

    if (_smsTrackingEnabled) {
      syncSmsTransactions();
    }
    notifyListeners();
  }

  Future<void> setSmsTracking(bool enabled) async {
    _smsTrackingEnabled = enabled;
    await _settingsBox.put('smsTrackingEnabled', enabled);
    notifyListeners();
  }

  Future<void> setBiometricLock(bool enabled) async {
    _biometricLockEnabled = enabled;
    await _settingsBox.put('biometricLockEnabled', enabled);
    notifyListeners();
  }

  Future<void> setSelectedCardDesign(String design) async {
    _selectedCardDesign = design;
    await _settingsBox.put('selectedCardDesign', design);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _appThemeMode = mode;
    await _settingsBox.put('appThemeMode', mode.index);
    notifyListeners();
  }

  late Box<Category> _categoryBox;
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  late Box<Loan> _loanBox;
  List<Loan> _loans = [];
  List<Loan> get loans => _loans;

  late Box<Goal> _goalBox;
  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  Future<void> _initBudget() async {
    _budgetBox = await Hive.openBox<Budget>('budgets');
    _categoryBox = await Hive.openBox<Category>('categories');
    _loanBox = await Hive.openBox<Loan>('loans');
    _goalBox = await Hive.openBox<Goal>('goals');
    await _initCategories();
    _loadCurrentBudget();
    _loadLoans();
    _loadGoals();
  }

  void _loadLoans() {
    _loans = _loanBox.values.toList();
    notifyListeners();
  }

  void _loadGoals() {
    _goals = _goalBox.values.toList();
    notifyListeners();
  }

  Future<void> _initCategories() async {
    if (_categoryBox.isEmpty) {
      final defaultCategories = [
        // Food & Drinks
        Category(
          id: 'food',
          name: 'Food & Drinks',
          iconCode: Icons.fastfood.codePoint,
          colorValue: Colors.orange.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'food_groceries',
            'food_restaurant',
            'food_coffee',
            'food_delivery',
            'food_snacks',
          ],
        ),
        Category(
          id: 'food_groceries',
          name: 'Groceries',
          iconCode: Icons.local_grocery_store.codePoint,
          colorValue: Colors.orange.toARGB32(),
          isCustom: false,
          parentId: 'food',
        ),
        Category(
          id: 'food_restaurant',
          name: 'Restaurants',
          iconCode: Icons.restaurant.codePoint,
          colorValue: Colors.orange.shade700.toARGB32(),
          isCustom: false,
          parentId: 'food',
        ),
        Category(
          id: 'food_coffee',
          name: 'Coffee & Tea',
          iconCode: Icons.local_cafe.codePoint,
          colorValue: Colors.brown.toARGB32(),
          isCustom: false,
          parentId: 'food',
        ),
        Category(
          id: 'food_delivery',
          name: 'Food Delivery',
          iconCode: Icons.delivery_dining.codePoint,
          colorValue: Colors.deepOrange.toARGB32(),
          isCustom: false,
          parentId: 'food',
        ),
        Category(
          id: 'food_snacks',
          name: 'Snacks',
          iconCode: Icons.cookie.codePoint,
          colorValue: Colors.amber.toARGB32(),
          isCustom: false,
          parentId: 'food',
        ),

        // Transport
        Category(
          id: 'transport',
          name: 'Transport',
          iconCode: Icons.directions_bus.codePoint,
          colorValue: Colors.blue.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'transport_fuel',
            'transport_public',
            'transport_taxi',
            'transport_parking',
            'transport_maintenance',
          ],
        ),
        Category(
          id: 'transport_fuel',
          name: 'Fuel',
          iconCode: Icons.local_gas_station.codePoint,
          colorValue: Colors.blue.shade700.toARGB32(),
          isCustom: false,
          parentId: 'transport',
        ),
        Category(
          id: 'transport_public',
          name: 'Public Transport',
          iconCode: Icons.train.codePoint,
          colorValue: Colors.blue.shade600.toARGB32(),
          isCustom: false,
          parentId: 'transport',
        ),
        Category(
          id: 'transport_taxi',
          name: 'Taxi & Rideshare',
          iconCode: Icons.local_taxi.codePoint,
          colorValue: Colors.yellow.shade700.toARGB32(),
          isCustom: false,
          parentId: 'transport',
        ),
        Category(
          id: 'transport_parking',
          name: 'Parking',
          iconCode: Icons.local_parking.codePoint,
          colorValue: Colors.blueGrey.toARGB32(),
          isCustom: false,
          parentId: 'transport',
        ),
        Category(
          id: 'transport_maintenance',
          name: 'Vehicle Maintenance',
          iconCode: Icons.build.codePoint,
          colorValue: Colors.grey.toARGB32(),
          isCustom: false,
          parentId: 'transport',
        ),

        // Shopping
        Category(
          id: 'shopping',
          name: 'Shopping',
          iconCode: Icons.shopping_bag.codePoint,
          colorValue: Colors.purple.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'shopping_clothes',
            'shopping_electronics',
            'shopping_home',
            'shopping_beauty',
            'shopping_gifts',
          ],
        ),
        Category(
          id: 'shopping_clothes',
          name: 'Clothing',
          iconCode: Icons.checkroom.codePoint,
          colorValue: Colors.purple.shade400.toARGB32(),
          isCustom: false,
          parentId: 'shopping',
        ),
        Category(
          id: 'shopping_electronics',
          name: 'Electronics',
          iconCode: Icons.devices.codePoint,
          colorValue: Colors.indigo.toARGB32(),
          isCustom: false,
          parentId: 'shopping',
        ),
        Category(
          id: 'shopping_home',
          name: 'Home & Garden',
          iconCode: Icons.home.codePoint,
          colorValue: Colors.teal.toARGB32(),
          isCustom: false,
          parentId: 'shopping',
        ),
        Category(
          id: 'shopping_beauty',
          name: 'Beauty & Personal Care',
          iconCode: Icons.face.codePoint,
          colorValue: Colors.pink.toARGB32(),
          isCustom: false,
          parentId: 'shopping',
        ),
        Category(
          id: 'shopping_gifts',
          name: 'Gifts',
          iconCode: Icons.card_giftcard.codePoint,
          colorValue: Colors.red.shade300.toARGB32(),
          isCustom: false,
          parentId: 'shopping',
        ),

        // Entertainment
        Category(
          id: 'entertainment',
          name: 'Entertainment',
          iconCode: Icons.movie.codePoint,
          colorValue: Colors.red.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'entertainment_movies',
            'entertainment_games',
            'entertainment_music',
            'entertainment_sports',
            'entertainment_subscriptions',
          ],
        ),
        Category(
          id: 'entertainment_movies',
          name: 'Movies & Cinema',
          iconCode: Icons.theaters.codePoint,
          colorValue: Colors.red.shade700.toARGB32(),
          isCustom: false,
          parentId: 'entertainment',
        ),
        Category(
          id: 'entertainment_games',
          name: 'Games',
          iconCode: Icons.sports_esports.codePoint,
          colorValue: Colors.deepPurple.toARGB32(),
          isCustom: false,
          parentId: 'entertainment',
        ),
        Category(
          id: 'entertainment_music',
          name: 'Music & Concerts',
          iconCode: Icons.music_note.codePoint,
          colorValue: Colors.pink.shade400.toARGB32(),
          isCustom: false,
          parentId: 'entertainment',
        ),
        Category(
          id: 'entertainment_sports',
          name: 'Sports Events',
          iconCode: Icons.sports.codePoint,
          colorValue: Colors.green.shade600.toARGB32(),
          isCustom: false,
          parentId: 'entertainment',
        ),
        Category(
          id: 'entertainment_subscriptions',
          name: 'Subscriptions',
          iconCode: Icons.subscriptions.codePoint,
          colorValue: Colors.blue.shade400.toARGB32(),
          isCustom: false,
          parentId: 'entertainment',
        ),

        // Health
        Category(
          id: 'health',
          name: 'Health',
          iconCode: Icons.local_hospital.codePoint,
          colorValue: Colors.green.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'health_doctor',
            'health_pharmacy',
            'health_fitness',
            'health_insurance',
          ],
        ),
        Category(
          id: 'health_doctor',
          name: 'Doctor & Hospital',
          iconCode: Icons.medical_services.codePoint,
          colorValue: Colors.red.shade400.toARGB32(),
          isCustom: false,
          parentId: 'health',
        ),
        Category(
          id: 'health_pharmacy',
          name: 'Pharmacy',
          iconCode: Icons.local_pharmacy.codePoint,
          colorValue: Colors.green.shade600.toARGB32(),
          isCustom: false,
          parentId: 'health',
        ),
        Category(
          id: 'health_fitness',
          name: 'Gym & Fitness',
          iconCode: Icons.fitness_center.codePoint,
          colorValue: Colors.orange.shade600.toARGB32(),
          isCustom: false,
          parentId: 'health',
        ),
        Category(
          id: 'health_insurance',
          name: 'Health Insurance',
          iconCode: Icons.health_and_safety.codePoint,
          colorValue: Colors.blue.shade600.toARGB32(),
          isCustom: false,
          parentId: 'health',
        ),

        // Education
        Category(
          id: 'education',
          name: 'Education',
          iconCode: Icons.school.codePoint,
          colorValue: Colors.yellow.shade700.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'education_books',
            'education_courses',
            'education_supplies',
            'education_tuition',
          ],
        ),
        Category(
          id: 'education_books',
          name: 'Books',
          iconCode: Icons.menu_book.codePoint,
          colorValue: Colors.brown.shade400.toARGB32(),
          isCustom: false,
          parentId: 'education',
        ),
        Category(
          id: 'education_courses',
          name: 'Online Courses',
          iconCode: Icons.laptop.codePoint,
          colorValue: Colors.blue.shade500.toARGB32(),
          isCustom: false,
          parentId: 'education',
        ),
        Category(
          id: 'education_supplies',
          name: 'School Supplies',
          iconCode: Icons.edit.codePoint,
          colorValue: Colors.amber.shade600.toARGB32(),
          isCustom: false,
          parentId: 'education',
        ),
        Category(
          id: 'education_tuition',
          name: 'Tuition',
          iconCode: Icons.account_balance.codePoint,
          colorValue: Colors.indigo.shade400.toARGB32(),
          isCustom: false,
          parentId: 'education',
        ),

        // Bills & Utilities
        Category(
          id: 'bills',
          name: 'Bills & Utilities',
          iconCode: Icons.receipt.codePoint,
          colorValue: Colors.grey.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'bills_electricity',
            'bills_water',
            'bills_internet',
            'bills_phone',
            'bills_rent',
          ],
        ),
        Category(
          id: 'bills_electricity',
          name: 'Electricity',
          iconCode: Icons.electric_bolt.codePoint,
          colorValue: Colors.yellow.shade600.toARGB32(),
          isCustom: false,
          parentId: 'bills',
        ),
        Category(
          id: 'bills_water',
          name: 'Water',
          iconCode: Icons.water_drop.codePoint,
          colorValue: Colors.blue.shade300.toARGB32(),
          isCustom: false,
          parentId: 'bills',
        ),
        Category(
          id: 'bills_internet',
          name: 'Internet & WiFi',
          iconCode: Icons.wifi.codePoint,
          colorValue: Colors.cyan.toARGB32(),
          isCustom: false,
          parentId: 'bills',
        ),
        Category(
          id: 'bills_phone',
          name: 'Phone Bill',
          iconCode: Icons.phone_android.codePoint,
          colorValue: Colors.green.shade400.toARGB32(),
          isCustom: false,
          parentId: 'bills',
        ),
        Category(
          id: 'bills_rent',
          name: 'Rent',
          iconCode: Icons.house.codePoint,
          colorValue: Colors.brown.shade600.toARGB32(),
          isCustom: false,
          parentId: 'bills',
        ),

        // Income - Salary
        Category(
          id: 'salary',
          name: 'Income',
          iconCode: Icons.attach_money.codePoint,
          colorValue: Colors.green.shade800.toARGB32(),
          isCustom: false,
          subcategoryIds: [
            'income_salary',
            'income_freelance',
            'income_investments',
            'income_gifts',
          ],
        ),
        Category(
          id: 'income_salary',
          name: 'Salary',
          iconCode: Icons.work.codePoint,
          colorValue: Colors.green.shade700.toARGB32(),
          isCustom: false,
          parentId: 'salary',
        ),
        Category(
          id: 'income_freelance',
          name: 'Freelance',
          iconCode: Icons.laptop_mac.codePoint,
          colorValue: Colors.teal.shade600.toARGB32(),
          isCustom: false,
          parentId: 'salary',
        ),
        Category(
          id: 'income_investments',
          name: 'Investments',
          iconCode: Icons.trending_up.codePoint,
          colorValue: Colors.blue.shade700.toARGB32(),
          isCustom: false,
          parentId: 'salary',
        ),
        Category(
          id: 'income_gifts',
          name: 'Gifts Received',
          iconCode: Icons.redeem.codePoint,
          colorValue: Colors.pink.shade300.toARGB32(),
          isCustom: false,
          parentId: 'salary',
        ),

        // Other
        Category(
          id: 'other',
          name: 'Other',
          iconCode: Icons.category.codePoint,
          colorValue: Colors.grey.shade400.toARGB32(),
          isCustom: false,
        ),
      ];
      await _categoryBox.addAll(defaultCategories);
    }
    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  Future<void> addCategory(String name, IconData icon, Color color) async {
    final newCategory = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      iconCode: icon.codePoint,
      colorValue: color.toARGB32(),
      isCustom: true,
    );
    await _categoryBox.add(newCategory);
    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  Future<void> addSubcategory(
    String parentId,
    String name,
    IconData icon,
    Color color,
  ) async {
    final subcategoryId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create the subcategory
    final newSubcategory = Category(
      id: subcategoryId,
      name: name,
      iconCode: icon.codePoint,
      colorValue: color.toARGB32(),
      isCustom: true,
      parentId: parentId,
    );
    await _categoryBox.add(newSubcategory);

    // Update parent category's subcategoryIds
    final parentIndex = _categoryBox.values.toList().indexWhere(
      (c) => c.id == parentId,
    );
    if (parentIndex != -1) {
      final parent = _categoryBox.getAt(parentIndex)!;
      final updatedSubcategoryIds = List<String>.from(parent.subcategoryIds)
        ..add(subcategoryId);
      final updatedParent = Category(
        id: parent.id,
        name: parent.name,
        iconCode: parent.iconCode,
        colorValue: parent.colorValue,
        isCustom: parent.isCustom,
        parentId: parent.parentId,
        subcategoryIds: updatedSubcategoryIds,
      );
      await _categoryBox.putAt(parentIndex, updatedParent);
    }

    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    final categoryToDelete = _categoryBox.values.firstWhere((c) => c.id == id);

    // If it's a parent category, delete all subcategories first
    if (categoryToDelete.hasSubcategories) {
      for (final subId in categoryToDelete.subcategoryIds) {
        final subCategory = _categoryBox.values.firstWhere(
          (c) => c.id == subId,
          orElse: () => categoryToDelete,
        );
        if (subCategory.id == subId) {
          await subCategory.delete();
        }
      }
    }

    // If it's a subcategory, remove from parent's subcategoryIds
    if (categoryToDelete.parentId != null) {
      final parentIndex = _categoryBox.values.toList().indexWhere(
        (c) => c.id == categoryToDelete.parentId,
      );
      if (parentIndex != -1) {
        final parent = _categoryBox.getAt(parentIndex)!;
        final updatedSubcategoryIds = List<String>.from(parent.subcategoryIds)
          ..remove(id);
        final updatedParent = Category(
          id: parent.id,
          name: parent.name,
          iconCode: parent.iconCode,
          colorValue: parent.colorValue,
          isCustom: parent.isCustom,
          parentId: parent.parentId,
          subcategoryIds: updatedSubcategoryIds,
        );
        await _categoryBox.putAt(parentIndex, updatedParent);
      }
    }

    await categoryToDelete.delete();
    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  // Get only top-level categories (not subcategories)
  List<Category> get topLevelCategories =>
      _categories.where((c) => c.parentId == null).toList();

  // Get subcategories for a specific parent
  List<Category> getSubcategories(String parentId) {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);

    // Clear and re-add all categories in new order
    await _categoryBox.clear();
    await _categoryBox.addAll(_categories);
    notifyListeners();
  }

  Future<void> addLoan(Loan loan) async {
    // Save to Firebase if account service available (real-time sync will update UI)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.addLoan(_activeAccountId!, loan);
      // Real-time sync will update _loans via onLoansChanged callback
    } else {
      // Fallback to local storage for guest users
      await _loanBox.add(loan);
      _loadLoans();
    }
  }

  Future<void> updateLoan(Loan loan) async {
    // Update in Firebase (real-time sync will update UI)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.updateLoan(_activeAccountId!, loan);
      // Real-time sync will update _loans via onLoansChanged callback
    } else {
      // Fallback for guest users
      await loan.save();
      _loadLoans();
    }
  }

  Future<void> deleteLoan(String id) async {
    // Delete from Firebase (real-time sync will update UI)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.deleteLoan(_activeAccountId!, id);
      // Real-time sync will update _loans via onLoansChanged callback
    } else {
      // Fallback for guest users
      final loanToDelete = _loanBox.values.firstWhere((l) => l.id == id);
      await loanToDelete.delete();
      _loadLoans();
    }
  }

  double get totalLent {
    return _loans
        .where((l) => l.type == LoanType.given)
        .fold(0.0, (sum, item) => sum + item.remainingAmount);
  }

  double get totalBorrowed {
    return _loans
        .where((l) => l.type == LoanType.taken)
        .fold(0.0, (sum, item) => sum + item.remainingAmount);
  }

  Future<void> addGoal(Goal goal) async {
    // Save to Firebase if account service available (real-time sync will update UI)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.addGoal(_activeAccountId!, goal);
      // Real-time sync will update _goals via onGoalsChanged callback
    } else {
      // Fallback to local storage for guest users
      await _goalBox.add(goal);
      _loadGoals();
    }
  }

  Future<void> updateGoal(Goal goal) async {
    // Update in Firebase (real-time sync will update UI)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.updateGoal(_activeAccountId!, goal);
      // Real-time sync will update _goals via onGoalsChanged callback
    } else {
      // Fallback for guest users
      await goal.save();
      _loadGoals();
    }
  }

  Future<void> deleteGoal(String id) async {
    // Delete from Firebase (real-time sync will update UI)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.deleteGoal(_activeAccountId!, id);
      // Real-time sync will update _goals via onGoalsChanged callback
    } else {
      // Fallback for guest users
      final goalToDelete = _goalBox.values.firstWhere((g) => g.id == id);
      await goalToDelete.delete();
      _loadGoals();
    }
  }

  Future<void> addSavingsToGoal(String id, double amount) async {
    // Find the goal from the current list
    final goalIndex = _goals.indexWhere((g) => g.id == id);
    if (goalIndex == -1) return;

    final goal = _goals[goalIndex];
    goal.savedAmount += amount;
    if (goal.savedAmount > goal.targetAmount) {
      goal.savedAmount = goal.targetAmount;
    }

    // Update in Firebase (real-time sync will update UI)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.updateGoal(_activeAccountId!, goal);
      // Real-time sync will update _goals via onGoalsChanged callback
    } else {
      // Fallback for guest users
      await goal.save();
      _loadGoals();
    }
  }

  void _loadCurrentBudget() {
    if (_userId == null && _activeAccountId == null) {
      _currentBudget = null;
      notifyListeners();
      return;
    }
    final now = DateTime.now();
    final accountId = _activeAccountId ?? _userId!;
    _currentBudget = _budgetBox.values.firstWhere(
      (b) =>
          b.month == now.month &&
          b.year == now.year &&
          b.accountId == accountId,
      orElse: () => Budget(
        monthlyLimit: 0,
        month: now.month,
        year: now.year,
        accountId: accountId,
      ),
    );
    notifyListeners();
  }

  Future<void> setBudget(double limit) async {
    final accountId = _activeAccountId ?? _userId;
    if (accountId == null) return;

    final now = DateTime.now();
    final existing = _budgetBox.values.where(
      (b) =>
          b.month == now.month &&
          b.year == now.year &&
          b.accountId == accountId,
    );

    Budget budget;
    if (existing.isNotEmpty) {
      budget = existing.first;
      budget.monthlyLimit = limit;
      await budget.save();
      _currentBudget = budget;
    } else {
      budget = Budget(
        monthlyLimit: limit,
        month: now.month,
        year: now.year,
        accountId: accountId,
      );
      await _budgetBox.add(budget);
      _currentBudget = budget;
    }

    // Save to Firebase
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.saveBudget(_activeAccountId!, budget);
    }
    notifyListeners();
  }

  Future<void> setCategoryLimit(String categoryName, double limit) async {
    final accountId = _activeAccountId ?? _userId;
    if (accountId == null) return;

    if (_currentBudget == null) {
      await setBudget(0);
    }

    if (_currentBudget != null) {
      _currentBudget!.categoryLimits[categoryName] = limit;
      await _currentBudget!.save();

      // Save to Firebase
      if (_accountService != null && _activeAccountId != null) {
        await _accountService!.saveBudget(_activeAccountId!, _currentBudget!);
      }
      notifyListeners();
    }
  }

  double getCategoryLimit(String categoryName) {
    return _currentBudget?.categoryLimits[categoryName] ?? 0;
  }

  double getCategorySpent(String categoryName) {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              !t.isExcluded &&
              t.isExpense &&
              t.category == categoryName &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get budgetProgress {
    if (_currentBudget == null || _currentBudget!.monthlyLimit == 0) return 0;
    final now = DateTime.now();
    final monthExpenses = _transactions
        .where(
          (t) =>
              !t.isExcluded &&
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    return monthExpenses / _currentBudget!.monthlyLimit;
  }

  double get monthlySpent {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              !t.isExcluded &&
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _settingsBox.put('userName', name);
    notifyListeners();
  }

  final SmsService _smsService = SmsService();

  Future<void> syncSmsTransactions() async {
    if (!_smsTrackingEnabled) return;

    // Use a default user ID for now as auth is not fully implemented or use a placeholder
    final userId =
        _userId ??
        'guest_user'; // Use actual userId if available, else a guest placeholder

    final smsTransactions = await _smsService.syncMessages(userId);

    // Get blocklisted IDs (deleted SMS transactions)
    final blockedIds = _deletedSmsBox.values.toSet();

    // Get existing local transactions to preserve user edits
    final existingLocalTransactions = await _localRepository.getTransactions();
    final existingLocalMap = <String, Transaction>{};
    for (final t in existingLocalTransactions) {
      existingLocalMap[t.id] = t;
    }

    print('========== SMS SYNC ==========');
    print('SMS Blocklist: ${blockedIds.length} IDs blocked');
    print('Existing local transactions: ${existingLocalMap.length}');

    int addedCount = 0;
    int blockedCount = 0;
    int skippedCount = 0;

    for (final transaction in smsTransactions) {
      // Skip if this transaction was previously deleted by user
      if (blockedIds.contains(transaction.id)) {
        blockedCount++;
        continue;
      }

      // Check if this transaction already exists in local storage
      final existingLocal = existingLocalMap[transaction.id];

      if (existingLocal != null) {
        // Transaction already exists in local storage
        // Skip to preserve user edits (receiptPath, notes, category, etc.)
        skippedCount++;
        continue;
      }

      // Check if it exists in the in-memory list (might be from Firebase)
      final index = _transactions.indexWhere((t) => t.id == transaction.id);

      if (index == -1) {
        // New transaction - save to LOCAL storage only (not Firebase)
        await _localRepository.addTransaction(transaction);
        addedCount++;
      }
      // If it exists in memory but not in local storage, don't add it
      // (it's probably a Firebase transaction, not an SMS one)
    }

    print(
      'SMS Sync Summary: $addedCount added, $blockedCount blocked, $skippedCount preserved',
    );
    print('===============================');

    if (addedCount > 0) {
      // Reload all transactions to include new SMS transactions
      if (_accountService != null && _activeAccountId != null) {
        await _loadAccountData(_activeAccountId!);
      } else {
        await _loadTransactions(); // For guest users
      }
    }
  }

  Future<void> setCardName(String name) async {
    _cardName = name;
    await _settingsBox.put('cardName', name);
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    await _settingsBox.put('currencySymbol', symbol);
    notifyListeners();
  }

  double get totalBalance {
    return _transactions.where((item) => !item.isExcluded).fold(0, (sum, item) {
      return sum + (item.isExpense ? -item.amount : item.amount);
    });
  }

  double get totalIncome {
    return _transactions
        .where((item) => !item.isExcluded && !item.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((item) => !item.isExcluded && item.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  Future<void> addTransaction(Transaction transaction) async {
    final accountId = _activeAccountId ?? _userId;
    if (accountId == null) return;

    // Ensure the transaction has the correct userId and accountId
    final newTransaction = Transaction(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      isExpense: transaction.isExpense,
      category: transaction.category,
      accountId: accountId,
      userId: _userId,
      notes: transaction.notes,
      receiptPath: transaction.receiptPath,
      receiptBase64: transaction.receiptBase64,
    );

    // Save to Firebase via account service (non-SMS only)
    if (_accountService != null && _activeAccountId != null) {
      await _accountService!.addTransaction(_activeAccountId!, newTransaction);
      // Real-time sync will update the transactions list automatically
    } else {
      // Fallback to old repository for guest users
      await _repository.addTransaction(newTransaction);
      await _loadTransactions();
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    debugPrint('');
    debugPrint('========== DELETE CALLED ==========');
    debugPrint('ID: ${transaction.id}');
    debugPrint('Title: ${transaction.title}');
    debugPrint('Amount: ${transaction.amount}');
    debugPrint(
      'Has SMS Body: ${transaction.smsBody != null && transaction.smsBody!.isNotEmpty}',
    );

    // If it's an SMS transaction, add to blocklist to prevent re-import
    if (transaction.smsBody != null && transaction.smsBody!.isNotEmpty) {
      await _deletedSmsBox.add(transaction.id);
      debugPrint('>>> ADDED TO BLOCKLIST <<<');
      // SMS transactions are stored locally, so delete from local repository
      await _localRepository.deleteTransaction(transaction.id);
      // Reload transactions for guest users or reload account data for logged-in users
      if (_accountService != null && _activeAccountId != null) {
        await _loadAccountData(_activeAccountId!);
      } else {
        await _loadTransactions();
      }
    } else {
      debugPrint('>>> NOT AN SMS TRANSACTION - NOT BLOCKING <<<');
      // Delete from Firebase via account service
      if (_accountService != null && _activeAccountId != null) {
        await _accountService!.deleteTransaction(
          _activeAccountId!,
          transaction.id,
        );
        // Real-time sync will update the transactions list automatically
      } else {
        // Fallback to old repository for guest users
        await _repository.deleteTransaction(transaction.id);
        await _loadTransactions();
      }
    }
    debugPrint('====================================');
  }

  // Get count of blocked SMS transactions
  int get blockedSmsCount => _deletedSmsBox.length;

  // Clear the SMS blocklist to allow re-importing deleted transactions
  Future<void> clearSmsBlocklist() async {
    final count = _deletedSmsBox.length;
    await _deletedSmsBox.clear();
    debugPrint('========== BLOCKLIST CLEARED ==========');
    debugPrint('Cleared $count blocked SMS IDs');
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction newTransaction) async {
    // Check if it's an SMS transaction - use local repository for SMS
    final isSmsTransaction =
        newTransaction.smsBody != null && newTransaction.smsBody!.isNotEmpty;

    if (isSmsTransaction) {
      // SMS transactions are stored locally only
      await _localRepository.updateTransaction(newTransaction);
      // Reload to update UI
      if (_accountService != null && _activeAccountId != null) {
        await _loadAccountData(_activeAccountId!);
      } else {
        await _loadTransactions();
      }
    } else {
      // Non-SMS transactions use Firebase via account service
      if (_accountService != null && _activeAccountId != null) {
        await _accountService!.updateTransaction(
          _activeAccountId!,
          newTransaction,
        );
        // Reload to ensure UI updates immediately
        await _loadAccountData(_activeAccountId!);
      } else {
        await _repository.updateTransaction(newTransaction);
        await _loadTransactions();
      }
    }
  }

  Future<void> initializeUser({
    required String name,
    required String currency,
    required String currencyCode,
    required bool isGuest,
    required String? userId,
    String? photoURL,
  }) async {
    _userName = name;
    _currencySymbol = currency;
    _currencyCode = currencyCode;
    _userId = userId;
    _photoURL = photoURL;

    // Persist to Hive (local settings)
    await _settingsBox.put('userName', name);
    await _settingsBox.put('currencySymbol', currency);
    await _settingsBox.put('currencyCode', currencyCode);
    await _settingsBox.put('isGuest', isGuest);
    await _settingsBox.put('userId', userId);
    if (photoURL != null) {
      await _settingsBox.put('photoURL', photoURL);
    } else {
      await _settingsBox.delete('photoURL');
    }

    // If Guest, save backup credentials for re-login
    if (isGuest) {
      await _settingsBox.put('guestUserId', userId);
      await _settingsBox.put('guestUserName', name);
      await _settingsBox.put('guestCurrency', currency);
      await _settingsBox.put('guestCurrencyCode', currencyCode);
    }

    // Switch Repository based on user type
    if (!isGuest && userId != null) {
      _repository = FirestoreTransactionRepository(userId);

      // Initialize account service
      _accountService = AccountService(userId);

      // Save user profile to Firebase
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': name,
          'currencySymbol': currency,
          'currencyCode': currencyCode,
          'photoURL': photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Initialize default account and load accounts
        // This also loads transactions via _loadAccountData
        await _initializeAccounts();
      } catch (e) {
        debugPrint('Failed to save user profile to Firebase: $e');
      }
    } else {
      final box = Hive.box<Transaction>('transactions');
      _repository = HiveTransactionRepository(box);
      // Only load transactions for guest users (non-guest uses account service)
      await _loadTransactions();
    }

    // Ensure budget box is open before accessing it
    if (!Hive.isBoxOpen('budgets')) {
      _budgetBox = await Hive.openBox<Budget>('budgets');
    } else {
      _budgetBox = Hive.box<Budget>('budgets');
    }

    // Initialize default budget if not exists
    final now = DateTime.now();
    final existingBudget = _budgetBox.values.where(
      (b) =>
          b.month == now.month && b.year == now.year && b.accountId == userId,
    );

    if (existingBudget.isEmpty) {
      await _budgetBox.add(
        Budget(
          monthlyLimit: 0,
          month: now.month,
          year: now.year,
          accountId: userId!,
        ),
      );
    }

    _loadCurrentBudget();
    notifyListeners();
  }

  // ============== MULTI-ACCOUNT MANAGEMENT ==============

  /// Initialize accounts - load existing or create default
  Future<void> _initializeAccounts() async {
    if (_accountService == null) return;

    try {
      // Get or create default account
      final defaultAccount = await _accountService!.initializeDefaultAccount();

      // Load all accounts
      _accounts = await _accountService!.getAccounts();

      // Set active account from saved preference or use default
      final savedActiveAccountId = _settingsBox.get('activeAccountId');
      if (savedActiveAccountId != null &&
          _accounts.any((a) => a.id == savedActiveAccountId)) {
        _activeAccountId = savedActiveAccountId;
        _activeAccount = _accounts.firstWhere(
          (a) => a.id == savedActiveAccountId,
        );
      } else {
        _activeAccountId = defaultAccount.id;
        _activeAccount = defaultAccount;
        await _settingsBox.put('activeAccountId', defaultAccount.id);
      }

      // Setup real-time sync callbacks
      _setupAccountSyncCallbacks();

      // Start real-time sync for active account
      _accountService!.startAllSync(_activeAccountId!);

      // Load data for active account
      await _loadAccountData(_activeAccountId!);

      debugPrint('✅ Accounts initialized. Active: ${_activeAccount?.name}');
    } catch (e) {
      debugPrint('Error initializing accounts: $e');
    }
    notifyListeners();
  }

  /// Setup callbacks for real-time sync
  void _setupAccountSyncCallbacks() {
    if (_accountService == null) return;

    _accountService!.onAccountsChanged = (accounts) {
      _accounts = accounts;
      // Update active account reference
      if (_activeAccountId != null) {
        _activeAccount = accounts.firstWhere(
          (a) => a.id == _activeAccountId,
          orElse: () => accounts.first,
        );
      }
      notifyListeners();
    };

    _accountService!.onTransactionsChanged = (transactions) {
      // Merge with SMS transactions (local only)
      _mergeTransactionsWithSms(transactions);
    };

    _accountService!.onBudgetsChanged = (budgets) {
      _loadCurrentBudgetFromList(budgets);
    };

    _accountService!.onLoansChanged = (loans) {
      _loans = loans;
      notifyListeners();
    };

    _accountService!.onGoalsChanged = (goals) {
      _goals = goals;
      notifyListeners();
    };
  }

  /// Merge Firebase transactions with local SMS transactions
  /// Only includes SMS transactions if the active account has showSmsTransactions enabled
  Future<void> _mergeTransactionsWithSms(
    List<Transaction> firebaseTransactions,
  ) async {
    try {
      final Map<String, Transaction> transactionMap = {};

      // Add Firebase transactions
      for (final t in firebaseTransactions) {
        transactionMap[t.id] = t;
      }

      // Only add SMS transactions if the active account has SMS enabled
      final showSms = _activeAccount?.showSmsTransactions ?? false;
      if (showSms) {
        final localTransactions = await _localRepository.getTransactions();
        // Add local SMS transactions (these take priority)
        for (final t in localTransactions) {
          if (t.smsBody != null && t.smsBody!.isNotEmpty) {
            transactionMap[t.id] = t;
          }
        }
      }

      _transactions = transactionMap.values.toList();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Error merging transactions: $e');
    }
  }

  /// Update the stored profile photo URL and persist it to settings.
  Future<void> setPhotoURL(String? photoURL) async {
    _photoURL = photoURL;
    if (photoURL != null && photoURL.isNotEmpty) {
      await _settingsBox.put('photoURL', photoURL);
    } else {
      await _settingsBox.delete('photoURL');
    }
    notifyListeners();
  }

  /// Load budget from list
  void _loadCurrentBudgetFromList(List<Budget> budgets) {
    final now = DateTime.now();
    try {
      _currentBudget = budgets.firstWhere(
        (b) => b.month == now.month && b.year == now.year,
        orElse: () => Budget(
          monthlyLimit: 0,
          month: now.month,
          year: now.year,
          accountId: _activeAccountId ?? 'default',
        ),
      );
    } catch (e) {
      _currentBudget = Budget(
        monthlyLimit: 0,
        month: now.month,
        year: now.year,
        accountId: _activeAccountId ?? 'default',
      );
    }
    notifyListeners();
  }

  /// Load all data for a specific account
  Future<void> _loadAccountData(String accountId) async {
    if (_accountService == null) return;

    try {
      // Load transactions (merged with SMS)
      final transactions = await _accountService!.getTransactions(accountId);
      await _mergeTransactionsWithSms(transactions);

      // Load budgets
      final budgets = await _accountService!.getBudgets(accountId);
      _loadCurrentBudgetFromList(budgets);

      // Load loans
      _loans = await _accountService!.getLoans(accountId);

      // Load goals
      _goals = await _accountService!.getGoals(accountId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading account data: $e');
    }
  }

  /// Create a new account
  Future<Account?> createAccount(
    String name, {
    int? colorValue,
    bool showSmsTransactions = false,
  }) async {
    if (_accountService == null) return null;

    try {
      final account = await _accountService!.createAccount(
        name: name,
        colorValue: colorValue,
        showSmsTransactions: showSmsTransactions,
      );

      // Reload accounts
      _accounts = await _accountService!.getAccounts();
      notifyListeners();

      return account;
    } catch (e) {
      debugPrint('Error creating account: $e');
      return null;
    }
  }

  /// Update account SMS setting
  Future<void> updateAccountSmsEnabled(String accountId, bool enabled) async {
    if (_accountService == null) return;

    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      account.showSmsTransactions = enabled;
      await _accountService!.updateAccount(account);

      // If this is the active account, reload transactions
      if (accountId == _activeAccountId) {
        _activeAccount = account;
        await _loadAccountData(accountId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating account SMS setting: $e');
    }
  }

  /// Switch to a different account
  Future<void> switchAccount(String accountId) async {
    if (_accountService == null) return;
    if (accountId == _activeAccountId) return;

    try {
      // Stop current sync
      _accountService!.stopAllSync();

      // Update active account
      _activeAccountId = accountId;
      _activeAccount = _accounts.firstWhere((a) => a.id == accountId);
      await _settingsBox.put('activeAccountId', accountId);

      // Clear all current data immediately to show loading state
      _transactions = [];
      _loans = [];
      _goals = [];
      _currentBudget = null;
      notifyListeners();

      // Load data for new account first
      await _loadAccountData(accountId);

      // Then start sync for new account (callbacks will update data going forward)
      _accountService!.startAllSync(accountId);

      debugPrint('✅ Switched to account: ${_activeAccount?.name}');
    } catch (e) {
      debugPrint('Error switching account: $e');
    }
  }

  /// Delete an account
  Future<bool> deleteAccount(String accountId) async {
    if (_accountService == null) return false;
    if (_accounts.length <= 1) return false; // Can't delete last account
    if (accountId == _activeAccountId)
      return false; // Can't delete active account

    try {
      await _accountService!.deleteAccount(accountId);
      _accounts = await _accountService!.getAccounts();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  /// Update account name
  Future<void> updateAccountName(String accountId, String newName) async {
    if (_accountService == null) return;

    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      account.name = newName;
      await _accountService!.updateAccount(account);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating account name: $e');
    }
  }

  /// Load user profile from Firebase (for returning users on new devices)
  Future<Map<String, dynamic>?> loadUserProfileFromFirebase(
    String userId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Failed to load user profile from Firebase: $e');
    }
    return null;
  }

  Future<void> logout() async {
    // Stop account sync
    _accountService?.stopAllSync();
    _accountService?.dispose();
    _accountService = null;

    _userName = 'User';
    _currencySymbol = '₹';
    _currencyCode = 'INR';
    _userId = null;

    await _settingsBox.delete('userName');
    await _settingsBox.delete('currencySymbol');
    await _settingsBox.delete('currencyCode');
    await _settingsBox.delete('isGuest');
    await _settingsBox.delete('userId');
    await _settingsBox.delete('photoURL');
    await _settingsBox.delete('activeAccountId');

    // NOTE: We do NOT delete 'guestUserId', 'guestUserName', etc.
    // This allows guests to "log back in" and restore their data.

    _transactions = [];
    _currentBudget = null;
    _accounts = [];
    _activeAccount = null;
    _activeAccountId = null;
    _loans = [];
    _goals = [];

    notifyListeners();
  }
}
