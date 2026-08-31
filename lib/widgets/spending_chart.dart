import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final transactions = provider.transactions
        .where((t) => t.isExpense)
        .toList();
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    // Group expenses by day for the last 7 days
    final List<double> dailyTotals = List.filled(7, 0.0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var t in transactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      final difference = today.difference(date).inDays;
      if (difference >= 0 && difference < 7) {
        dailyTotals[6 - difference] += t.amount;
      }
    }

    // Find max value for Y-axis scaling
    double maxY = dailyTotals.reduce((curr, next) => curr > next ? curr : next);
    if (maxY == 0) maxY = 100; // Default if no data

    return AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isLight
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < 7) {
                          final date = today.subtract(
                            Duration(days: 6 - index),
                          );
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: isLight
                                    ? Colors.black54
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat.compact().format(value),
                          style: TextStyle(
                            color: isLight ? Colors.black54 : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.left,
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY * 1.2, // Add some padding on top
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7, (index) {
                      return FlSpot(index.toDouble(), dailyTotals[index]);
                    }),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        isAmoled
                            ? Colors.white
                            : (isLight ? Colors.black : AppTheme.expense),
                        isAmoled
                            ? Colors.white60
                            : (isLight
                                  ? Colors.black54
                                  : AppTheme.expense.withOpacity(0.5)),
                      ],
                    ),
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isLight
                              ? Colors.white
                              : (isAmoled ? Colors.black : Colors.white),
                          strokeWidth: 2,
                          strokeColor: isAmoled
                              ? Colors.white
                              : (isLight ? Colors.black : AppTheme.expense),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          (isAmoled
                                  ? Colors.white
                                  : (isLight ? Colors.black : AppTheme.expense))
                              .withOpacity(0.3),
                          (isAmoled
                                  ? Colors.white
                                  : (isLight ? Colors.black : AppTheme.expense))
                              .withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: Curves.easeOutBack,
          alignment: Alignment.center,
        )
        .fadeIn(duration: 500.ms);
  }
}
