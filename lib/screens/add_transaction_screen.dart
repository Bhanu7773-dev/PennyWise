import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../providers/money_provider.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../widgets/category_search_sheet.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool initialIsExpense;

  const AddTransactionScreen({super.key, this.initialIsExpense = true});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amount = '0';
  String _note = '';
  late bool _isExpense;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialIsExpense;
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 10);
    }
  }

  void _showCategorySearch(MoneyProvider provider) {
    _vibrate();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySearchSheet(
        isExpense: _isExpense,
        onCategorySelected: (category) {
          setState(() {
            _selectedCategoryId = category.id;
          });
        },
      ),
    );
  }

  void _onKeyTap(String value) {
    _vibrate();
    setState(() {
      if (value == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          _amount += value;
        }
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          if (_amount.length < 9) {
            _amount += value;
          }
        }
      }
    });
  }

  void _saveTransaction() {
    if (double.parse(_amount) == 0) return;

    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final selectedCategory = provider.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => provider.categories.firstWhere((c) => c.id == 'other'),
    );

    final transaction = Transaction(
      id: const Uuid().v4(),
      title: _note.isEmpty ? selectedCategory.name : _note,
      amount: double.parse(_amount),
      date: DateTime.now(),
      isExpense: _isExpense,
      category: selectedCategory.name,
    );

    provider.addTransaction(transaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    return Scaffold(
      backgroundColor: isAmoled
          ? Colors.black
          : (isLight ? Colors.white : AppTheme.background),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isLight ? Colors.black : Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isExpense ? 'New Expense' : 'New Income',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
        actions: [
          Switch(
            value: !_isExpense,
            onChanged: (value) {
              setState(() {
                _isExpense = !value;
              });
            },
            activeThumbColor: AppTheme.income,
            inactiveThumbColor: AppTheme.expense,
            inactiveTrackColor: AppTheme.expense.withOpacity(0.5),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<MoneyProvider>(
        builder: (context, provider, child) => Column(
          children: [
            const Spacer(),
            // Amount Display
            Text(
              '${provider.currencySymbol}$_amount',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: isAmoled || isLight
                    ? (isLight ? Colors.black : Colors.white)
                    : (_isExpense ? AppTheme.expense : AppTheme.income),
                fontWeight: FontWeight.bold,
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),

            // Note Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: TextStyle(
                    color: isLight
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) => _note = value,
              ),
            ),
            const SizedBox(height: 32),

            // Category Selector Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCategorySearch(provider),
                    icon: const Icon(
                      Icons.search,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final category = provider.categories[index];
                  _selectedCategoryId ??= category.id; // Initialize if null
                  final isSelected = category.id == _selectedCategoryId;
                  return GestureDetector(
                    onTap: () {
                      _vibrate();
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                    },
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isAmoled
                                  ? Colors.white
                                  : (isLight
                                        ? Colors.transparent
                                        : category.color))
                            : (isAmoled || isLight
                                  ? Colors.transparent
                                  : AppTheme.surface),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? (isAmoled
                                    ? Colors.white
                                    : (isLight
                                          ? Colors.black
                                          : Colors.transparent))
                              : (isAmoled
                                    ? Colors.white.withOpacity(0.3)
                                    : (isLight
                                          ? Colors.black.withOpacity(0.1)
                                          : category.color.withOpacity(0.2))),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 18,
                            color: isSelected
                                ? (isAmoled ? Colors.black : Colors.black)
                                : (isAmoled
                                      ? Colors.white
                                      : (isLight
                                            ? Colors.black
                                            : category.color)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected
                                  ? (isAmoled ? Colors.black : Colors.black)
                                  : (isLight ? Colors.black : Colors.white),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Keypad
            _buildKeypad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeyRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeyRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildKeyRow(['.', '0', '⌫']),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Hero(
              tag:
                  'hero_action_${widget.initialIsExpense ? 'expense' : 'income'}',
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAmoled
                      ? Colors.white
                      : (isLight
                            ? Colors.black
                            : (_isExpense
                                  ? AppTheme.expense
                                  : AppTheme.income)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'SAVE TRANSACTION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAmoled
                        ? Colors.black
                        : (isLight ? Colors.white : Colors.white),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;

    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onKeyTap(key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isAmoled
                        ? Colors.transparent
                        : (isLight
                              ? Colors.transparent
                              : AppTheme.surface.withOpacity(0.3)),
                    border: Border.all(
                      color: isAmoled
                          ? Colors.white
                          : (isLight
                                ? Colors.black.withOpacity(0.1)
                                : Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 24,
                      color: isLight ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
