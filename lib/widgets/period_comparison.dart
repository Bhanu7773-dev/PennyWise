import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class PeriodComparison extends StatefulWidget {
  const PeriodComparison({super.key});

  @override
  State<PeriodComparison> createState() => _PeriodComparisonState();
}

class _PeriodComparisonState extends State<PeriodComparison> {
  bool _isWeekly = true; // true = weekly, false = monthly

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAmoled || isLight
            ? Colors.transparent
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: isLight
            ? Border.all(color: Colors.black)
            : Border.all(
                color: isAmoled ? Colors.white : Colors.white.withOpacity(0.1),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Header
          _buildToggleHeader(),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 220,
            child: _isWeekly
                ? _buildWeeklyChart(provider)
                : _buildMonthlyChart(provider),
          ),

          const SizedBox(height: 16),

          // Stats Summary
          _isWeekly
              ? _buildWeeklySummary(provider)
              : _buildMonthlySummary(provider),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildToggleHeader() {
    final isAmoled =
        Provider.of<MoneyProvider>(context).appThemeMode == AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context).appThemeMode == AppThemeMode.light;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isAmoled || isLight
            ? (isLight
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1))
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isAmoled || isLight
            ? Border.all(
                color: isLight ? Colors.black : Colors.white.withOpacity(0.2),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Weekly', _isWeekly, () {
            setState(() => _isWeekly = true);
          }),
          _buildToggleButton('Monthly', !_isWeekly, () {
            setState(() => _isWeekly = false);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    final isAmoled =
        Provider.of<MoneyProvider>(context).appThemeMode == AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context).appThemeMode == AppThemeMode.light;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAmoled
                    ? Colors.white
                    : (isLight ? Colors.black : AppTheme.primary))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? (isAmoled || isLight
                      ? (isLight ? Colors.white : Colors.black)
                      : Colors.white)
                : (isLight ? Colors.black54 : Colors.white54),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Calculate a nice round interval for the Y axis based on max value
  double _calculateNiceInterval(double maxValue) {
    if (maxValue <= 0) return 100;

    // Find the order of magnitude
    final magnitude = maxValue.toString().split('.')[0].length;
    final base = [
      1,
      10,
      100,
      1000,
      10000,
      100000,
      1000000,
      10000000,
    ][magnitude.clamp(0, 7)];

    // Calculate rough interval (aim for 4-6 grid lines)
    final roughInterval = maxValue / 4;

    // Round to a nice number
    if (roughInterval <= base * 0.1) return base * 0.1;
    if (roughInterval <= base * 0.2) return base * 0.2;
    if (roughInterval <= base * 0.25) return base * 0.25;
    if (roughInterval <= base * 0.5) return base * 0.5;
    if (roughInterval <= base) return base.toDouble();
    if (roughInterval <= base * 2) return base * 2;
    if (roughInterval <= base * 2.5) return base * 2.5;
    if (roughInterval <= base * 5) return base * 5;
    return base * 10;
  }

  Widget _buildWeeklyChart(MoneyProvider provider) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final weeklyData = _getWeeklyData(provider);

    // Get max value from both expense and income
    final allValues = weeklyData.expand(
      (e) => [e['expense'] as double, e['income'] as double],
    );
    double maxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100.0;

    // Calculate nice interval for Y axis
    final interval = _calculateNiceInterval(maxY);
    final adjustedMaxY = (maxY / interval).ceil() * interval * 1.1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: adjustedMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1F38),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = weeklyData[group.x];
              final isExpense = rodIndex == 0;
              return BarTooltipItem(
                '${data['label']}\n${isExpense ? 'Expense' : 'Income'}: ${provider.currencySymbol}${NumberFormat.compact().format(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < weeklyData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weeklyData[index]['label'] as String,
                      style: TextStyle(
                        color: index == weeklyData.length - 1
                            ? (isLight ? Colors.black : Colors.white)
                            : (isLight ? Colors.black54 : Colors.white54),
                        fontSize: 11,
                        fontWeight: index == weeklyData.length - 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              interval: interval,
              getTitlesWidget: (value, meta) {
                // Skip if it's beyond our max
                if (value > adjustedMaxY) return const SizedBox();
                return Text(
                  NumberFormat.compact().format(value),
                  style: TextStyle(
                    color: isLight ? Colors.black38 : Colors.white38,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isLight
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(weeklyData.length, (index) {
          final data = weeklyData[index];
          final isCurrentWeek = index == weeklyData.length - 1;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data['expense'] as double,
                color: isCurrentWeek
                    ? (isAmoled
                          ? Colors.white
                          : (isLight ? Colors.black : AppTheme.expense))
                    : (isAmoled
                          ? Colors.white60
                          : (isLight
                                ? Colors.black54
                                : AppTheme.expense.withOpacity(0.5))),
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: adjustedMaxY,
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
              BarChartRodData(
                toY: data['income'] as double,
                color: isCurrentWeek
                    ? (isAmoled
                          ? Colors.white.withOpacity(0.3)
                          : (isLight ? Colors.black38 : AppTheme.income))
                    : (isAmoled
                          ? Colors.white38
                          : (isLight
                                ? Colors.black26
                                : AppTheme.income.withOpacity(0.5))),
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyChart(MoneyProvider provider) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final monthlyData = _getMonthlyData(provider);
    final allValues = monthlyData.expand(
      (e) => [e['expense'] as double, e['income'] as double],
    );
    double maxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100.0;

    // Calculate nice interval for Y axis
    final interval = _calculateNiceInterval(maxY);
    final adjustedMaxY = (maxY / interval).ceil() * interval * 1.1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: adjustedMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1F38),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = monthlyData[group.x];
              final isExpense = rodIndex == 0;
              return BarTooltipItem(
                '${data['label']}\n${isExpense ? 'Expense' : 'Income'}: ${provider.currencySymbol}${NumberFormat.compact().format(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < monthlyData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthlyData[index]['label'] as String,
                      style: TextStyle(
                        color: index == monthlyData.length - 1
                            ? (isLight ? Colors.black : Colors.white)
                            : (isLight ? Colors.black54 : Colors.white54),
                        fontSize: 11,
                        fontWeight: index == monthlyData.length - 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              interval: interval,
              getTitlesWidget: (value, meta) {
                // Skip if it's beyond our max
                if (value > adjustedMaxY) return const SizedBox();
                return Text(
                  NumberFormat.compact().format(value),
                  style: TextStyle(
                    color: isLight ? Colors.black38 : Colors.white38,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isLight
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(monthlyData.length, (index) {
          final data = monthlyData[index];
          final isCurrentMonth = index == monthlyData.length - 1;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data['expense'] as double,
                color: isCurrentMonth
                    ? (isAmoled
                          ? Colors.white
                          : (isLight ? Colors.black : AppTheme.expense))
                    : (isAmoled
                          ? Colors.white60
                          : (isLight
                                ? Colors.black54
                                : AppTheme.expense.withOpacity(0.5))),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: adjustedMaxY,
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
              BarChartRodData(
                toY: data['income'] as double,
                color: isCurrentMonth
                    ? (isAmoled
                          ? Colors.white.withOpacity(0.3)
                          : (isLight ? Colors.black38 : AppTheme.income))
                    : (isAmoled
                          ? Colors.white38
                          : (isLight
                                ? Colors.black26
                                : AppTheme.income.withOpacity(0.5))),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWeeklySummary(MoneyProvider provider) {
    final weeklyData = _getWeeklyData(provider);
    if (weeklyData.length < 2) return const SizedBox();

    final thisWeek = weeklyData.last;
    final lastWeek = weeklyData[weeklyData.length - 2];

    final expenseChange =
        (thisWeek['expense'] as double) - (lastWeek['expense'] as double);
    final expenseChangePercent = (lastWeek['expense'] as double) > 0
        ? (expenseChange / (lastWeek['expense'] as double)) * 100
        : 0.0;

    return _buildSummaryCard(
      title: 'This Week vs Last Week',
      currentAmount: thisWeek['expense'] as double,
      previousAmount: lastWeek['expense'] as double,
      change: expenseChange,
      changePercent: expenseChangePercent,
      provider: provider,
    );
  }

  Widget _buildMonthlySummary(MoneyProvider provider) {
    final monthlyData = _getMonthlyData(provider);
    if (monthlyData.length < 2) return const SizedBox();

    final thisMonth = monthlyData.last;
    final lastMonth = monthlyData[monthlyData.length - 2];

    final expenseChange =
        (thisMonth['expense'] as double) - (lastMonth['expense'] as double);
    final expenseChangePercent = (lastMonth['expense'] as double) > 0
        ? (expenseChange / (lastMonth['expense'] as double)) * 100
        : 0.0;

    return _buildSummaryCard(
      title: 'This Month vs Last Month',
      currentAmount: thisMonth['expense'] as double,
      previousAmount: lastMonth['expense'] as double,
      change: expenseChange,
      changePercent: expenseChangePercent,
      provider: provider,
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double currentAmount,
    required double previousAmount,
    required double change,
    required double changePercent,
    required MoneyProvider provider,
  }) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final isIncrease = change > 0;
    final changeColor = isIncrease ? AppTheme.expense : AppTheme.income;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAmoled || isLight ? Colors.transparent : null,
        gradient: isAmoled
            ? null
            : LinearGradient(
                colors: [
                  changeColor.withOpacity(0.15),
                  changeColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? Colors.black
              : (isAmoled ? Colors.white : changeColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isLight
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${provider.currencySymbol}${NumberFormat('#,##0').format(currentAmount)}',
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Previous',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${provider.currencySymbol}${NumberFormat('#,##0').format(previousAmount)}',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.trending_up : Icons.trending_down,
                color: changeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isIncrease ? '+' : ''}${provider.currencySymbol}${NumberFormat('#,##0').format(change.abs())}',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isIncrease ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                isIncrease ? 'Spending up ⚠️' : 'Spending down 🎉',
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getWeeklyData(MoneyProvider provider) {
    final List<Map<String, dynamic>> weeklyData = [];
    final now = DateTime.now();

    // Get last 4 weeks
    for (int i = 3; i >= 0; i--) {
      final weekEnd = now.subtract(Duration(days: now.weekday - 7 + (i * 7)));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      double expense = 0;
      double income = 0;

      for (var t in provider.transactions) {
        if (t.isExcluded) continue;
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        if (tDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            tDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
          if (t.isExpense) {
            expense += t.amount;
          } else {
            income += t.amount;
          }
        }
      }

      String label;
      if (i == 0) {
        label = 'This\nWeek';
      } else if (i == 1) {
        label = 'Last\nWeek';
      } else {
        label = '${i}W\nAgo';
      }

      weeklyData.add({
        'label': label,
        'expense': expense,
        'income': income,
        'start': weekStart,
        'end': weekEnd,
      });
    }

    return weeklyData;
  }

  List<Map<String, dynamic>> _getMonthlyData(MoneyProvider provider) {
    final List<Map<String, dynamic>> monthlyData = [];
    final now = DateTime.now();

    // Get last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);

      double expense = 0;
      double income = 0;

      for (var t in provider.transactions) {
        if (t.isExcluded) continue;
        if (t.date.month == month.month && t.date.year == month.year) {
          if (t.isExpense) {
            expense += t.amount;
          } else {
            income += t.amount;
          }
        }
      }

      monthlyData.add({
        'label': DateFormat('MMM').format(month),
        'expense': expense,
        'income': income,
        'month': month,
      });
    }

    return monthlyData;
  }
}
