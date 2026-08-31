import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import '../models/transaction.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/category_search_sheet.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  String _amount = '';
  late bool _isExpense;
  late String _selectedCategory;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount = widget.transaction.amount.toStringAsFixed(0);
    _isExpense = widget.transaction.isExpense;
    _selectedCategory = widget.transaction.category;
    _notesController.text = widget.transaction.title;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _vibrate() async {
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
            _selectedCategory = category.name;
          });
        },
      ),
    );
  }

  void _onKeyTap(String value) {
    _vibrate();
    setState(() {
      if (value == '⌫') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          if (_amount.isEmpty) _amount = '0';
          _amount += value;
        }
      } else {
        if (_amount.length < 10) {
          _amount += value;
        }
      }
    });
  }

  void _saveTransaction() async {
    if (_amount.isEmpty || _notesController.text.isEmpty) return;

    final updatedTransaction = Transaction(
      id: widget.transaction.id,
      title: _notesController.text,
      amount: double.parse(_amount),
      date: widget.transaction.date,
      isExpense: _isExpense,
      category: _selectedCategory,
    );

    await Provider.of<MoneyProvider>(
      context,
      listen: false,
    ).updateTransaction(updatedTransaction);

    if (mounted) {
      Navigator.pop(context);
    }
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
          icon: Icon(
            Icons.arrow_back,
            color: isLight ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Transaction',
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
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer<MoneyProvider>(
          builder: (context, provider, child) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Column(
                  children: [
                    Text(
                      _isExpense ? 'Expense' : 'Income',
                      style: TextStyle(
                        color: _isExpense ? AppTheme.expense : AppTheme.income,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${provider.currencySymbol}${_amount.isEmpty ? "0" : _amount}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isAmoled
                            ? Colors.white
                            : (isLight ? Colors.black : Colors.white),
                      ),
                    ).animate(key: ValueKey(_amount)).fadeIn(duration: 100.ms),
                  ],
                ),
                const SizedBox(height: 8),

                // Category Selector Header
                Row(
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
                const SizedBox(height: 12),

                // Category Selector
                SizedBox(
                  height: 50,
                  child: Consumer<MoneyProvider>(
                    builder: (context, provider, child) {
                      final categories = provider.categories;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category.name == _selectedCategory;
                          return GestureDetector(
                            onTap: () {
                              _vibrate();
                              setState(() {
                                _selectedCategory = category.name;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isLight
                                        ? Colors.transparent
                                        : (isAmoled ? Colors.white : category.color))
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
                                        ? Colors.black.withOpacity(0.2)
                                        : category.color.withOpacity(0.3))),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 18,
                                    color: isSelected
                                        ? (isAmoled
                                              ? Colors.black
                                              : (isLight
                                                    ? Colors.black
                                                    : Colors.white))
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
                                          ? (isAmoled || isLight
                                                ? Colors.black
                                                : Colors.white)
                                          : (isLight
                                                ? Colors.black
                                                : Colors.white),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate(delay: (50 * index).ms).fadeIn().scale();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Input
                TextField(
                  controller: _notesController,
                  style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add notes',
                    hintStyle: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: isLight
                        ? Colors.black.withOpacity(0.05)
                        : AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Keypad
                _buildKeypad(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
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
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAmoled
                    ? Colors.white
                    : (isLight ? Colors.black : AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'UPDATE TRANSACTION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isAmoled
                      ? Colors.black
                      : (isLight ? Colors.white : Colors.black),
                  letterSpacing: 1.0,
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
