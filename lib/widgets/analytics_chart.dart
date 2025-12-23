import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class AnalyticsChart extends StatefulWidget {
  const AnalyticsChart({super.key});

  @override
  State<AnalyticsChart> createState() => _AnalyticsChartState();
}

class _AnalyticsChartState extends State<AnalyticsChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final transactions = provider.transactions
        .where((t) => t.isExpense)
        .toList();
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No expenses to show',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isLight ? Colors.black54 : Colors.white54,
          ),
        ),
      );
    }

    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (var t in transactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final List<PieChartSectionData> sections = [];
    int index = 0;
    categoryTotals.forEach((category, amount) {
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 110.0 : 100.0;

      final color = isAmoled
          ? (index == 0
                ? Colors.white
                : Colors.white.withOpacity(
                    1.0 - (index * 0.15).clamp(0.0, 0.7),
                  ))
          : (isLight
                ? (index == 0
                      ? Colors.black
                      : Colors.black.withOpacity(
                          1.0 - (index * 0.15).clamp(0.0, 0.7),
                        ))
                : Colors.primaries[index % Colors.primaries.length]);

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title:
              '${((amount / provider.totalExpense) * 100).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
          ),
          badgeWidget: _Badge(category, size: 40, borderColor: color),
          badgePositionPercentageOffset: .98,
        ),
      );
      index++;
    });

    return AspectRatio(
          aspectRatio: 1.3,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCirc,
            builder: (context, value, child) {
              return ShaderMask(
                shaderCallback: (rect) {
                  return SweepGradient(
                    startAngle: 0.0,
                    endAngle: 3.14 * 2,
                    stops: [value, value],
                    colors: const [Colors.white, Colors.transparent],
                    transform: GradientRotation(-3.14 / 2), // Start from top
                  ).createShader(rect);
                },
                child: child,
              );
            },
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
        )
        .animate()
        .scale(duration: 800.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 500.ms);
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.size, required this.borderColor});

  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          text[0],
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
