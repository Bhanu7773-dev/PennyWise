import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/app_theme.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final transactions = _getFilteredTransactions(provider.transactions);
    final groupedTransactions = _groupTransactionsByDate(transactions);

    return Scaffold(
      backgroundColor: isAmoled
          ? Colors.black
          : (isLight
                ? Colors.white
                : Theme.of(context).scaffoldBackgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildDateSelector(),
            Expanded(
              child: groupedTransactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: groupedTransactions.keys.length,
                      itemBuilder: (context, index) {
                        final date = groupedTransactions.keys.elementAt(index);
                        final dayTransactions = groupedTransactions[date]!;
                        return _buildDaySection(
                          date,
                          dayTransactions,
                          provider,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isAmoled
                    ? Colors.transparent
                    : (isLight
                          ? Colors.transparent
                          : Theme.of(context).cardColor),
                borderRadius: BorderRadius.circular(12),
                border: isAmoled
                    ? Border.all(color: Colors.white)
                    : (isLight
                          ? Border.all(
                              color: Colors.black.withOpacity(0.1),
                            )
                          : null),
              ),
              child: Icon(
                Icons.arrow_back,
                color: isLight
                    ? Colors.black
                    : Theme.of(context).iconTheme.color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Hero(
            tag: 'hero_action_history',
            child: Material(
              color: Colors.transparent,
              child: Text(
                'History',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 12, // Show last 12 months
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 30 * index));
          final isSelected =
              date.month == _selectedMonth.month &&
              date.year == _selectedMonth.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = date;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isAmoled
                          ? Colors.white
                          : (isLight
                                ? Colors.transparent
                                : const Color(0xFF6366F1)))
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? (isAmoled
                            ? Colors.white
                            : (isLight
                                  ? Colors.black
                                  : const Color(0xFF6366F1)))
                      : (isAmoled
                            ? Colors.white.withOpacity(0.3)
                            : (isLight
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.1))),
                ),
                boxShadow: isSelected && !isAmoled && !isLight
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                DateFormat('MMM yyyy').format(date),
                style: TextStyle(
                  color: isSelected
                      ? (isAmoled
                            ? Colors.black
                            : (isLight ? Colors.black : Colors.white))
                      : (isAmoled
                            ? Colors.white70
                            : Theme.of(context).textTheme.bodyMedium?.color
                                  ?.withOpacity(0.6)),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaySection(
    String date,
    List<Transaction> transactions,
    MoneyProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            date,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...transactions.map(
          (tx) => _buildTransactionTile(tx, provider),
        ), // Pass provider
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildTransactionTile(Transaction tx, MoneyProvider provider) {
    final isExpense = tx.isExpense;
    final color = isExpense ? AppTheme.expense : AppTheme.income;

    // Find category
    final category = provider.categories.firstWhere(
      (c) => c.id == tx.category,
      orElse: () => Category(
        id: 'unknown',
        name: tx.category, // Fallback to storing name if ID not found
        iconCode: Icons.category.codePoint,
        colorValue: Colors.grey.toARGB32(),
        isCustom: false,
      ),
    );

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAmoled || isLight
            ? Colors.transparent
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAmoled
              ? Colors.white
              : (isLight
                    ? Colors.black.withOpacity(0.5)
                    : Theme.of(context).dividerColor.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAmoled
                  ? Colors.transparent
                  : Color(category.colorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: isAmoled
                  ? Border.all(color: Colors.white.withOpacity(0.2))
                  : (isLight
                        ? Border.all(color: Colors.black.withOpacity(0.1))
                        : null),
            ),
            child: Icon(
              IconData(category.iconCode, fontFamily: 'MaterialIcons'),
              color: isAmoled ? Colors.white : Color(category.colorValue),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tx.bankName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${tx.bankName} • ${tx.accountLast4 ?? "Cash"}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? "-" : "+"}${provider.currencySymbol}${NumberFormat('#,##0').format(tx.amount)}',
                style: TextStyle(
                  color: isAmoled ? Colors.white : color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('hh:mm a').format(tx.date),
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(
    List<Transaction> allTransactions,
  ) {
    return allTransactions.where((tx) {
      return tx.date.month == _selectedMonth.month &&
          tx.date.year == _selectedMonth.year;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final Map<String, List<Transaction>> grouped = {};

    for (var tx in transactions) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      String key;
      if (txDate == today) {
        key = 'Today';
      } else if (txDate == yesterday) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMM dd, yyyy').format(tx.date);
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(tx);
    }

    return grouped;
  }
}
