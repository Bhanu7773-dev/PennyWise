import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../models/goal.dart';
import '../utils/app_theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final goals = provider.goals;
    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.savedAmount);
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final overallProgress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0.0;
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
          'Financial Goals',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
      ),
      body: Column(
        children: [
          if (goals.isNotEmpty)
            _buildOverallProgress(
              context,
              provider,
              totalSaved,
              totalTarget,
              overallProgress,
            ),
          Expanded(
            child: goals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 64,
                          color: isLight
                              ? Colors.black26
                              : Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No goals set yet',
                          style: TextStyle(
                            color: isLight
                                ? Colors.black45
                                : Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return _buildGoalCard(context, provider, goal, index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, provider),
        backgroundColor: isAmoled
            ? Colors.white
            : (isLight ? Colors.white : AppTheme.primary),
        shape: isLight
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black),
              )
            : null,
        child: Icon(
          Icons.add,
          color: isAmoled
              ? Colors.black
              : (isLight ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(
    BuildContext context,
    MoneyProvider provider,
    double totalSaved,
    double totalTarget,
    double progress,
  ) {
    final currency = provider.currencySymbol;

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      margin: const EdgeInsets.all(16),
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
                color: isAmoled ? Colors.white : Colors.white.withOpacity(0.1),
              ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Saved',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.compactCurrency(
                      symbol: currency,
                    ).format(totalSaved),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.compactCurrency(
                      symbol: currency,
                    ).format(totalTarget),
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isLight
                  ? Colors.black.withOpacity(0.1)
                  : Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAmoled || isLight
                    ? (isLight ? Colors.black : Colors.white)
                    : AppTheme.primary,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Completed',
            style: TextStyle(
              color: isLight
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildGoalCard(
    BuildContext context,
    MoneyProvider provider,
    Goal goal,
    int index,
  ) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final currency = provider.currencySymbol;
    final progress = goal.progress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAmoled || isLight
            ? Colors.transparent
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: isLight
            ? Border.all(color: Colors.black)
            : Border.all(
                color: isAmoled ? Colors.white : Colors.white.withOpacity(0.05),
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Delete button at top right
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => _showDeleteDialog(context, provider, goal),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: isLight
                      ? Colors.black.withOpacity(0.1)
                      : Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAmoled || isLight
                        ? (isLight ? Colors.black : Colors.white)
                        : goal.color,
                  ),
                  strokeWidth: 8,
                ),
              ),
              Icon(
                goal.icon,
                color: isAmoled || isLight
                    ? (isLight ? Colors.black : Colors.white)
                    : goal.color,
                size: 28,
              ),
            ],
          ),
          Column(
            children: [
              Text(
                goal.title,
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormat.compactCurrency(symbol: currency).format(goal.savedAmount)} / ${NumberFormat.compactCurrency(symbol: currency).format(goal.targetAmount)}',
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAddSavingsDialog(context, provider, goal),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLight
                    ? Colors.black.withOpacity(0.05)
                    : Colors.white.withOpacity(0.1),
                foregroundColor: isLight ? Colors.black : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isAmoled || isLight
                      ? (isLight
                            ? const BorderSide(color: Colors.black)
                            : const BorderSide(color: Colors.white))
                      : BorderSide.none,
                ),
              ),
              child: const Text('Add Money', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).scale();
  }

  void _showAddGoalDialog(BuildContext context, MoneyProvider provider) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.savings;

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isAmoled
              ? Colors.black
              : (isLight ? Colors.white : const Color(0xFF1E293B)),
          shape: isAmoled || isLight
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isLight ? Colors.black : Colors.white,
                  ),
                )
              : null,
          title: Text(
            'New Goal',
            style: TextStyle(color: isLight ? Colors.black : Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Goal Title',
                    labelStyle: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white70,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isLight ? Colors.black26 : Colors.white30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    labelStyle: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white70,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isLight ? Colors.black26 : Colors.white30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pick Color',
                  style: TextStyle(
                    color: isLight ? Colors.black54 : Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.pink,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(
                                      color: isLight
                                          ? Colors.black
                                          : Colors.white,
                                      width: 2,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isLight
                      ? Colors.black54
                      : (isAmoled ? Colors.white : null),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    final newGoal = Goal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      targetAmount: amount,
                      iconCode: selectedIcon.codePoint,
                      colorValue: selectedColor.toARGB32(),
                    );
                    provider.addGoal(newGoal);
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAmoled || isLight
                    ? (isLight ? Colors.white : Colors.white)
                    : AppTheme.primary,
                foregroundColor: isAmoled || isLight
                    ? Colors.black
                    : Colors.white,
                side: isLight ? const BorderSide(color: Colors.black) : null,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSavingsDialog(
    BuildContext context,
    MoneyProvider provider,
    Goal goal,
  ) {
    final amountController = TextEditingController();

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isAmoled
            ? Colors.black
            : (isLight ? Colors.white : const Color(0xFF1E293B)),
        shape: isAmoled || isLight
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isLight ? Colors.black : Colors.white),
              )
            : null,
        title: Text(
          'Add to ${goal.title}',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
          decoration: InputDecoration(
            labelText: 'Amount',
            labelStyle: TextStyle(
              color: isLight ? Colors.black54 : Colors.white70,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isLight ? Colors.black26 : Colors.white30,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isLight
                    ? Colors.black54
                    : (isAmoled ? Colors.white : null),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                provider.addSavingsToGoal(goal.id, amount);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAmoled || isLight
                  ? (isLight ? Colors.white : Colors.white)
                  : AppTheme.primary,
              foregroundColor: isAmoled || isLight
                  ? Colors.black
                  : Colors.white,
              side: isLight ? const BorderSide(color: Colors.black) : null,
            ),
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    MoneyProvider provider,
    Goal goal,
  ) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isAmoled
            ? Colors.black
            : (isLight ? Colors.white : const Color(0xFF1E293B)),
        shape: isAmoled || isLight
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isLight ? Colors.black : Colors.white),
              )
            : null,
        title: Text(
          'Delete Goal?',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: isLight ? Colors.black54 : Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isLight
                    ? Colors.black54
                    : (isAmoled ? Colors.white : null),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteGoal(goal.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
