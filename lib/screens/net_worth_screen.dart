import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

enum TimeRange { week, month, threeMonths, sixMonths, year, all }

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  List<FlSpot> _spots = [];
  double _minY = 0;
  double _maxY = 0;
  List<DateTime> _dates = [];
  TimeRange _selectedRange = TimeRange.all;

  double _highest = 0;
  double _lowest = 0;
  double _average = 0;
  double _monthlyChange = 0;
  double _monthlyChangePercent = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateNetWorthData();
    });
  }

  void _calculateNetWorthData() {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final transactions = provider.transactions
        .where((t) => !t.isExcluded)
        .toList();

    if (transactions.isEmpty) return;

    transactions.sort((a, b) => a.date.compareTo(b.date));

    final Map<DateTime, double> dailyNetWorth = {};
    double currentNetWorth = 0;

    DateTime normalizeDate(DateTime date) {
      return DateTime(date.year, date.month, date.day);
    }

    for (var t in transactions) {
      final date = normalizeDate(t.date);
      final amount = t.isExpense ? -t.amount : t.amount;
      currentNetWorth += amount;
      dailyNetWorth[date] = currentNetWorth;
    }

    // Filter based on TimeRange
    final now = DateTime.now();
    DateTime? startDate;
    switch (_selectedRange) {
      case TimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimeRange.threeMonths:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case TimeRange.sixMonths:
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case TimeRange.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case TimeRange.all:
        startDate = null;
        break;
    }

    var sortedDates = dailyNetWorth.keys.toList()..sort();
    if (startDate != null) {
      sortedDates = sortedDates
          .where((d) => d.isAfter(startDate!) || d.isAtSameMomentAs(startDate))
          .toList();
    }

    _dates = sortedDates;

    if (sortedDates.isEmpty) {
      setState(() {
        _spots = [];
        _highest = 0;
        _lowest = 0;
        _average = 0;
      });
      return;
    }

    _spots = [];
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    double sumVal = 0;

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final value = dailyNetWorth[date]!;
      _spots.add(FlSpot(i.toDouble(), value));

      if (value < minVal) minVal = value;
      if (value > maxVal) maxVal = value;
      sumVal += value;
    }

    _highest = maxVal;
    _lowest = minVal;
    _average = sumVal / sortedDates.length;

    final range = maxVal - minVal;
    _minY = minVal - (range * 0.1);
    _maxY = maxVal + (range * 0.1);

    if (_minY == _maxY) {
      _minY -= 100;
      _maxY += 100;
    }

    // Calculate Monthly Change (Current Month)
    final startOfMonth = DateTime(now.year, now.month, 1);
    // Find value at start of month (or earliest available in month)
    double startMonthValue = 0;
    // Find the last value before or on startOfMonth
    final entriesBeforeMonth = dailyNetWorth.entries
        .where((e) => e.key.isBefore(startOfMonth))
        .toList();
    if (entriesBeforeMonth.isNotEmpty) {
      entriesBeforeMonth.sort((a, b) => a.key.compareTo(b.key));
      startMonthValue = entriesBeforeMonth.last.value;
    } else {
      // If no data before this month, start from 0 or first data point of month
      final entriesInMonth = dailyNetWorth.entries
          .where((e) => !e.key.isBefore(startOfMonth))
          .toList();
      if (entriesInMonth.isNotEmpty) {
        entriesInMonth.sort((a, b) => a.key.compareTo(b.key));
        // Technically start of month value is 0 if no prior history, or we can take the first transaction's impact
        // Let's assume 0 if completely new, but if we have history it carries over.
        // If entriesBeforeMonth is empty, it means account started this month or no transactions before.
        startMonthValue = 0;
      }
    }

    final currentVal = dailyNetWorth[sortedDates.last] ?? 0;
    _monthlyChange = currentVal - startMonthValue;
    if (startMonthValue != 0) {
      _monthlyChangePercent = (_monthlyChange / startMonthValue.abs()) * 100;
    } else {
      _monthlyChangePercent = _monthlyChange > 0 ? 100 : 0;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final totalNetWorth = provider.totalBalance;
    final currency = provider.currencySymbol;
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isAmoled
          ? Colors.black
          : (isLight ? Colors.white : theme.scaffoldBackgroundColor),
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
          'Net Worth Analysis',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isAmoled
              ? Colors.black
              : (isLight ? Colors.transparent : theme.scaffoldBackgroundColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isAmoled || isLight ? Colors.transparent : null,
                  gradient: isAmoled || isLight
                      ? null
                      : LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.2),
                            const Color(0xFF2D3459).withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(24),
                  border: isLight
                      ? Border.all(color: Colors.black)
                      : Border.all(
                          color: isAmoled
                              ? Colors.white
                              : Colors.white.withOpacity(0.1),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Net Worth',
                          style: TextStyle(
                            color: isLight
                                ? Colors.black.withOpacity(0.7)
                                : Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _monthlyChange >= 0
                                ? AppTheme.income.withOpacity(0.2)
                                : AppTheme.expense.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _monthlyChange >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isAmoled
                                    ? Colors.white
                                    : (_monthlyChange >= 0
                                          ? AppTheme.income
                                          : AppTheme.expense),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_monthlyChangePercent.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: isAmoled
                                      ? Colors.white
                                      : (_monthlyChange >= 0
                                            ? AppTheme.income
                                            : AppTheme.expense),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        symbol: currency,
                        decimalDigits: 0,
                      ).format(totalNetWorth),
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn().slideX(),
                    const SizedBox(height: 8),
                    Text(
                      '${_monthlyChange >= 0 ? '+' : ''}${NumberFormat.currency(symbol: currency, decimalDigits: 0).format(_monthlyChange)} this month',
                      style: TextStyle(
                        color: isLight
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 24),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TimeRange.values.map((range) {
                    final isSelected = _selectedRange == range;
                    String label;
                    switch (range) {
                      case TimeRange.week:
                        label = '1W';
                        break;
                      case TimeRange.month:
                        label = '1M';
                        break;
                      case TimeRange.threeMonths:
                        label = '3M';
                        break;
                      case TimeRange.sixMonths:
                        label = '6M';
                        break;
                      case TimeRange.year:
                        label = '1Y';
                        break;
                      case TimeRange.all:
                        label = 'ALL';
                        break;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRange = range;
                            _calculateNetWorthData();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isAmoled
                                      ? Colors.white
                                      : (isLight
                                            ? Colors.black
                                            : AppTheme.primary))
                                : (isLight
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? (isAmoled
                                        ? Colors.white
                                        : (isLight
                                              ? Colors.black
                                              : AppTheme.primary))
                                  : (isLight
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.1)),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? (isAmoled || isLight
                                        ? (isLight
                                              ? Colors.white
                                              : Colors.black)
                                        : Colors.white)
                                  : (isLight
                                        ? Colors.black.withOpacity(0.7)
                                        : Colors.white.withOpacity(0.7)),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              SizedBox(
                height: 250,
                child: _spots.isEmpty
                    ? Center(
                        child: Text(
                          'Not enough data for chart',
                          style: TextStyle(
                            color: isLight
                                ? Colors.black.withOpacity(0.5)
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.only(
                          right: 16,
                          left: 0,
                          top: 24,
                          bottom: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isAmoled || isLight
                              ? Colors.transparent
                              : const Color(0xFF1A1F38).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: isLight
                              ? Border.all(color: Colors.black)
                              : Border.all(
                                  color: isAmoled
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.05),
                                ),
                        ),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: (_maxY - _minY) / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: isLight
                                      ? Colors.black.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.05),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: (_dates.length / 4).ceilToDouble(),
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < _dates.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          DateFormat(
                                            'MMM d',
                                          ).format(_dates[index]),
                                          style: TextStyle(
                                            color: isLight
                                                ? Colors.black.withOpacity(0.5)
                                                : Colors.white.withOpacity(0.5),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: (_maxY - _minY) / 5,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      NumberFormat.compact().format(value),
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.5),
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.left,
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (_dates.length - 1).toDouble(),
                            minY: _minY,
                            maxY: _maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _spots,
                                isCurved: true,
                                gradient: LinearGradient(
                                  colors: isAmoled
                                      ? [Colors.white, Colors.white70]
                                      : (isLight
                                            ? [Colors.black, Colors.black54]
                                            : [
                                                AppTheme.primary,
                                                const Color(0xFF6366F1),
                                              ]),
                                ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: isAmoled
                                        ? [
                                            Colors.white.withOpacity(0.2),
                                            Colors.white.withOpacity(0.0),
                                          ]
                                        : (isLight
                                              ? [
                                                  Colors.black.withOpacity(0.1),
                                                  Colors.black.withOpacity(0.0),
                                                ]
                                              : [
                                                  AppTheme.primary.withOpacity(
                                                    0.3,
                                                  ),
                                                  AppTheme.primary.withOpacity(
                                                    0.0,
                                                  ),
                                                ]),
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) => isAmoled
                                    ? Colors.black
                                    : (isLight
                                          ? Colors.white
                                          : const Color(0xFF2D3459)),
                                tooltipBorder: isLight
                                    ? const BorderSide(color: Colors.black)
                                    : (isAmoled
                                          ? const BorderSide(
                                              color: Colors.white,
                                            )
                                          : BorderSide.none),
                                tooltipPadding: const EdgeInsets.all(12),
                                tooltipMargin: 16,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((
                                    LineBarSpot touchedSpot,
                                  ) {
                                    final textStyle = TextStyle(
                                      color: isLight
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    );
                                    return LineTooltipItem(
                                      '${DateFormat('MMM d').format(_dates[touchedSpot.x.toInt()])}\n',
                                      textStyle.copyWith(
                                        color: isLight
                                            ? Colors.black.withOpacity(0.7)
                                            : Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: NumberFormat.currency(
                                            symbol: currency,
                                            decimalDigits: 0,
                                          ).format(touchedSpot.y),
                                          style: textStyle,
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                              handleBuiltInTouches: true,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms).scale(),
              ),

              const SizedBox(height: 24),

              Text(
                'Statistics',
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Highest',
                      _highest,
                      currency,
                      Icons.arrow_upward,
                      AppTheme.income,
                      500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Lowest',
                      _lowest,
                      currency,
                      Icons.arrow_downward,
                      AppTheme.expense,
                      600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Average',
                _average,
                currency,
                Icons.functions,
                const Color(0xFF6366F1),
                700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    String currency,
    IconData icon,
    Color color,
    int delay,
  ) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
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
                color: isAmoled ? Colors.white : Colors.white.withOpacity(0.05),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAmoled || isLight
                      ? (isLight ? Colors.transparent : Colors.white)
                      : color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: isLight ? Border.all(color: Colors.black) : null,
                ),
                child: Icon(
                  icon,
                  color: isLight
                      ? Colors.black
                      : (isAmoled ? Colors.black : color),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.compactCurrency(symbol: currency).format(value),
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2);
  }
}
