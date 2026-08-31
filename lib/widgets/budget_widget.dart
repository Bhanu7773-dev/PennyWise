import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class BudgetWidget extends StatelessWidget {
  const BudgetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final isHighContrast = isAmoled || isLight;

    return GestureDetector(
      onTap: () => _showBudgetDialog(context, provider),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHighContrast ? Colors.transparent : null,
              gradient: isHighContrast
                  ? null
                  : LinearGradient(
                      colors: [
                        const Color(0xFF2D3459).withOpacity(0.3),
                        const Color(0xFF1A1F38).withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHighContrast
                    ? Theme.of(context).iconTheme.color!.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child:
                provider.currentBudget != null &&
                    provider.currentBudget!.monthlyLimit > 0
                ? _buildBudgetProgress(context, provider, isHighContrast)
                : _buildSetBudgetButton(context, isAmoled, isHighContrast),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetProgress(
    BuildContext context,
    MoneyProvider provider,
    bool isHighContrast,
  ) {
    final progress = provider.budgetProgress;
    final isOverBudget = progress > 1.0;
    final progressColor = progress > 0.8 ? AppTheme.expense : AppTheme.income;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isHighContrast
                        ? Colors.transparent
                        : progressColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: isHighContrast
                        ? Border.all(
                            color: Theme.of(
                              context,
                            ).iconTheme.color!.withOpacity(0.5),
                          )
                        : null,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isHighContrast
                        ? Theme.of(context).iconTheme.color
                        : progressColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: TextStyle(
                        color: isHighContrast
                            ? Theme.of(context).textTheme.titleSmall?.color
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% used',
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.edit_outlined,
              color: isHighContrast
                  ? Theme.of(context).iconTheme.color!.withOpacity(0.5)
                  : Colors.white.withOpacity(0.5),
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: isHighContrast
                    ? Theme.of(context).dividerColor
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOverBudget
                        ? [AppTheme.expense, AppTheme.expense.withOpacity(0.8)]
                        : [progressColor, progressColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${provider.currencySymbol}${NumberFormat.compact().format(provider.monthlySpent)}',
              style: TextStyle(
                color: isHighContrast
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              'Limit: ${provider.currencySymbol}${NumberFormat.compact().format(provider.currentBudget!.monthlyLimit)}',
              style: TextStyle(
                color: isHighContrast
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (isOverBudget) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.expense.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.expense,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Over budget by ${provider.currencySymbol}${NumberFormat.compact().format(provider.monthlySpent - provider.currentBudget!.monthlyLimit)}',
                  style: TextStyle(
                    color: AppTheme.expense,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSetBudgetButton(
    BuildContext context,
    bool isAmoled,
    bool isHighContrast,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighContrast
                ? Colors.transparent
                : AppTheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: isHighContrast
                ? Border.all(
                    color: Theme.of(context).iconTheme.color!.withOpacity(0.5),
                  )
                : null,
          ),
          child: Icon(
            Icons.add_chart,
            color: isHighContrast
                ? Theme.of(context).iconTheme.color
                : AppTheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Monthly Budget',
                style: TextStyle(
                  color: isHighContrast
                      ? Theme.of(context).textTheme.titleMedium?.color
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Track your spending with a budget limit',
                style: TextStyle(
                  color: isHighContrast
                      ? Theme.of(context).textTheme.bodySmall?.color
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          color: isHighContrast
              ? Theme.of(context).iconTheme.color!.withOpacity(0.4)
              : Colors.white.withOpacity(0.4),
          size: 16,
        ),
      ],
    );
  }

  void _showBudgetDialog(BuildContext context, MoneyProvider provider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Budget Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AnimatedBudgetDialog(provider: provider, animation: animation);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }
}

class _AnimatedBudgetDialog extends StatefulWidget {
  final MoneyProvider provider;
  final Animation<double> animation;

  const _AnimatedBudgetDialog({
    required this.provider,
    required this.animation,
  });

  @override
  State<_AnimatedBudgetDialog> createState() => _AnimatedBudgetDialogState();
}

class _AnimatedBudgetDialogState extends State<_AnimatedBudgetDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text:
          widget.provider.currentBudget?.monthlyLimit.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a single curved animation for smooth 60fps
    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, child) {
          final value = curvedAnimation.value;
          return Stack(
            children: [
              // Static blur background - no animated blur (expensive!)
              // The barrierColor handles the darkening
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
              // Dialog with optimized transform
              Center(
                child: FadeTransition(
                  opacity: curvedAnimation,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: _buildDialogContent(context),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final isAmoled = widget.provider.appThemeMode == AppThemeMode.amoled;
    final isLight = widget.provider.appThemeMode == AppThemeMode.light;
    final isHighContrast = isAmoled || isLight;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isAmoled ? Colors.black : (isLight ? Colors.white : null),
          gradient: isHighContrast
              ? null
              : LinearGradient(
                  colors: [
                    const Color(0xFF1A1F38),
                    const Color(0xFF2D3459),
                    AppTheme.primary.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isAmoled
                ? Colors.white
                : (isLight ? Colors.black : Colors.white.withOpacity(0.15)),
            width: isHighContrast ? 2 : 1,
          ),
          boxShadow: isHighContrast
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set Monthly Budget',
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                ),
                prefixText: '${widget.provider.currencySymbol} ',
                prefixStyle: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isHighContrast
                        ? (isLight ? Colors.black : Colors.white)
                        : AppTheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isLight
                          ? Colors.black.withOpacity(0.05)
                          : Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (widget.provider.currentBudget != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.provider.setBudget(0);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.expense.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: AppTheme.expense,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(_controller.text);
                      if (amount != null && amount > 0) {
                        widget.provider.setBudget(amount);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isHighContrast
                          ? (isLight ? Colors.black : Colors.white)
                          : AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: isHighContrast
                            ? (isLight ? Colors.white : Colors.black)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
