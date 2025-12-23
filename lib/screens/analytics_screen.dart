import 'package:flutter/material.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/spending_chart.dart';
import '../widgets/spending_heatmap.dart';
import '../widgets/period_comparison.dart';
import '../utils/app_theme.dart';

import '../providers/money_provider.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Analytics',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spending Heatmap Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAmoled || isLight
                        ? Colors.transparent
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: isLight
                        ? Border.all(color: Colors.black)
                        : (isAmoled ? Border.all(color: Colors.white) : null),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: isLight
                        ? Colors.black
                        : (isAmoled ? Colors.white : Colors.orange),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Spending Heatmap',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLight ? Colors.black : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SpendingHeatmap(),

            const SizedBox(height: 32),

            // Weekly/Monthly Comparison Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAmoled || isLight
                        ? Colors.transparent
                        : AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: isLight
                        ? Border.all(color: Colors.black)
                        : (isAmoled ? Border.all(color: Colors.white) : null),
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    color: isLight
                        ? Colors.black
                        : (isAmoled ? Colors.white : AppTheme.primary),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Period Comparison',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLight ? Colors.black : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const PeriodComparison(),

            const SizedBox(height: 32),

            // Expense Breakdown Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAmoled || isLight
                        ? Colors.transparent
                        : Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: isLight
                        ? Border.all(color: Colors.black)
                        : (isAmoled ? Border.all(color: Colors.white) : null),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: isLight
                        ? Colors.black
                        : (isAmoled ? Colors.white : Colors.purple),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Expense Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLight ? Colors.black : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AnalyticsChart(),

            const SizedBox(height: 32),

            // Spending Trends Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAmoled || isLight
                        ? Colors.transparent
                        : AppTheme.expense.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: isLight
                        ? Border.all(color: Colors.black)
                        : (isAmoled ? Border.all(color: Colors.white) : null),
                  ),
                  child: Icon(
                    Icons.show_chart,
                    color: isLight
                        ? Colors.black
                        : (isAmoled ? Colors.white : AppTheme.expense),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Spending Trends (Last 7 Days)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLight ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SpendingChart(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
