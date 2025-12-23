import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class SpendingHeatmap extends StatefulWidget {
  const SpendingHeatmap({super.key});

  @override
  State<SpendingHeatmap> createState() => _SpendingHeatmapState();
}

class _SpendingHeatmapState extends State<SpendingHeatmap> {
  late DateTime _currentMonth;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final isLight = provider.appThemeMode == AppThemeMode.light;

    // Get daily spending for current month
    final dailySpending = _getDailySpending(provider);
    final maxSpending = dailySpending.values.isEmpty
        ? 0.0
        : dailySpending.values.reduce((a, b) => a > b ? a : b);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;

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
          // Month Navigation
          _buildMonthNavigation(),
          const SizedBox(height: 16),

          // Weekday Headers
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),

          // Calendar Grid
          _buildCalendarGrid(dailySpending, maxSpending, provider),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(maxSpending, provider),

          // Selected Day Details
          if (_selectedDay != null)
            _buildSelectedDayDetails(dailySpending, provider),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMonthNavigation() {
    final isLight =
        Provider.of<MoneyProvider>(context).appThemeMode == AppThemeMode.light;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
              _selectedDay = null;
            });
          },
          icon: Icon(
            Icons.chevron_left,
            color: isLight ? Colors.black : Colors.white,
          ),
          style: IconButton.styleFrom(
            backgroundColor: isLight
                ? Colors.black.withOpacity(0.1)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: TextStyle(
            color: isLight ? Colors.black : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed:
              _currentMonth.month == DateTime.now().month &&
                  _currentMonth.year == DateTime.now().year
              ? null
              : () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                    _selectedDay = null;
                  });
                },
          icon: Icon(
            Icons.chevron_right,
            color:
                _currentMonth.month == DateTime.now().month &&
                    _currentMonth.year == DateTime.now().year
                ? (isLight ? Colors.black26 : Colors.white24)
                : (isLight ? Colors.black : Colors.white),
          ),
          style: IconButton.styleFrom(
            backgroundColor: isLight
                ? Colors.black.withOpacity(0.1)
                : Colors.white.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final isLight =
        Provider.of<MoneyProvider>(context).appThemeMode == AppThemeMode.light;
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (day) => SizedBox(
              width: 40,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLight
                      ? Colors.black54
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(
    Map<int, double> dailySpending,
    double maxSpending,
    MoneyProvider provider,
  ) {
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    final today = DateTime.now();
    final isCurrentMonth =
        _currentMonth.month == today.month && _currentMonth.year == today.year;

    List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      currentRow.add(const SizedBox(width: 40, height: 40));
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final spending = dailySpending[day] ?? 0.0;
      final intensity = maxSpending > 0 ? (spending / maxSpending) : 0.0;
      final isToday = isCurrentMonth && day == today.day;
      final isFuture = isCurrentMonth && day > today.day;
      final isSelected = _selectedDay == day;

      currentRow.add(
        GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                      setState(() {
                        _selectedDay = _selectedDay == day ? null : day;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isFuture
                      ? (isLight
                            ? Colors.black.withOpacity(0.02)
                            : Colors.white.withOpacity(0.02))
                      : _getHeatmapColor(intensity, isLight),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : isToday
                        ? AppTheme.primary
                        : (isLight ? Colors.black : Colors.transparent),
                    width: isSelected || isToday ? 2 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isFuture
                          ? (isLight ? Colors.black26 : Colors.white24)
                          : intensity > 0.5
                          ? Colors.white
                          : (isLight ? Colors.black87 : Colors.white70),
                      fontSize: 11,
                      fontWeight: isToday || isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            )
            .animate(delay: Duration(milliseconds: day * 20))
            .scale(begin: const Offset(0.5, 0.5), duration: 200.ms),
      );

      if ((startWeekday + day) % 7 == 0) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: currentRow,
          ),
        );
        currentRow = [];
      }
    }

    // Fill remaining cells
    while (currentRow.length < 7) {
      currentRow.add(const SizedBox(width: 40, height: 40));
    }
    if (currentRow.isNotEmpty) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: currentRow,
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildLegend(double maxSpending, MoneyProvider provider) {
    final isLight = provider.appThemeMode == AppThemeMode.light;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: TextStyle(
            color: isLight ? Colors.black54 : Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = index / 4;
          return Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getHeatmapColor(intensity, isLight),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'More',
          style: TextStyle(
            color: isLight ? Colors.black54 : Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Max: ${provider.currencySymbol}${NumberFormat.compact().format(maxSpending)}',
          style: TextStyle(
            color: isLight ? Colors.black54 : Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetails(
    Map<int, double> dailySpending,
    MoneyProvider provider,
  ) {
    final spending = dailySpending[_selectedDay] ?? 0.0;
    final date = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      _selectedDay!,
    );
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    // Get transactions for selected day
    final dayTransactions = provider.transactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      return tDate.isAtSameMomentAs(date) && t.isExpense && !t.isExcluded;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAmoled || isLight ? Colors.transparent : null,
        gradient: isAmoled
            ? null
            : LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  AppTheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? Colors.black
              : (isAmoled ? Colors.white : AppTheme.primary.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(date),
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${provider.currencySymbol}${NumberFormat('#,##0').format(spending)}',
                style: TextStyle(
                  color: spending > 0 ? AppTheme.expense : Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (dayTransactions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            ...dayTransactions
                .take(3)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? Colors.black.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.category[0].toUpperCase(),
                                style: TextStyle(
                                  color: isLight
                                      ? Colors.black87
                                      : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              t.title,
                              style: TextStyle(
                                color: isLight
                                    ? Colors.black87
                                    : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${provider.currencySymbol}${NumberFormat('#,##0').format(t.amount)}',
                          style: TextStyle(
                            color: isLight ? Colors.black54 : Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (dayTransactions.length > 3)
              Text(
                '+${dayTransactions.length - 3} more transactions',
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.4)
                      : Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ] else if (spending == 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.celebration, color: AppTheme.income, size: 16),
                const SizedBox(width: 8),
                Text(
                  'No spending day! 🎉',
                  style: TextStyle(color: AppTheme.income, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Map<int, double> _getDailySpending(MoneyProvider provider) {
    final Map<int, double> dailySpending = {};

    for (var t in provider.transactions) {
      if (t.isExpense &&
          !t.isExcluded &&
          t.date.month == _currentMonth.month &&
          t.date.year == _currentMonth.year) {
        dailySpending[t.date.day] = (dailySpending[t.date.day] ?? 0) + t.amount;
      }
    }

    return dailySpending;
  }

  Color _getHeatmapColor(double intensity, bool isLight) {
    if (intensity <= 0) {
      return isLight
          ? Colors.black.withOpacity(0.05)
          : Colors.white.withOpacity(0.05);
    }

    // Gradient from green (low) -> yellow (medium) -> orange -> red (high)
    if (intensity <= 0.25) {
      return Color.lerp(
        const Color(0xFF1B5E20).withOpacity(0.6), // Dark green
        const Color(0xFF4CAF50).withOpacity(0.7), // Green
        intensity * 4,
      )!;
    } else if (intensity <= 0.5) {
      return Color.lerp(
        const Color(0xFF4CAF50).withOpacity(0.7), // Green
        const Color(0xFFFFC107).withOpacity(0.8), // Yellow
        (intensity - 0.25) * 4,
      )!;
    } else if (intensity <= 0.75) {
      return Color.lerp(
        const Color(0xFFFFC107).withOpacity(0.8), // Yellow
        const Color(0xFFFF9800).withOpacity(0.9), // Orange
        (intensity - 0.5) * 4,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFFF9800).withOpacity(0.9), // Orange
        const Color(0xFFF44336), // Red
        (intensity - 0.75) * 4,
      )!;
    }
  }
}
