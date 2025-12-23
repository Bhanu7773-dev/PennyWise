import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import 'sms_tracking_screen.dart';
import 'net_worth_screen.dart';
import 'category_management_screen.dart';
import 'budget_planning_screen.dart';
import 'loans_screen.dart';
import 'goals_screen.dart';
import 'currency_converter_screen.dart';

class AdvanceScreen extends StatelessWidget {
  const AdvanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final isHighContrast = isAmoled || isLight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Advanced Features',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: Container(
        color: isHighContrast
            ? Theme.of(context).scaffoldBackgroundColor
            : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildFeatureTile(
              context,
              'SMS Transaction Tracking',
              'Automatically track transactions from SMS messages',
              Icons.sms_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SmsTrackingScreen(),
                ),
              ),
              isEnabled: provider.smsTrackingEnabled,
            ),
            _buildFeatureTile(
              context,
              'Net Worth Analysis',
              'Visualize your financial growth over time',
              Icons.show_chart_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NetWorthScreen()),
              ),
            ),
            _buildFeatureTile(
              context,
              'Category Management',
              'Create and customize transaction categories',
              Icons.category_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              ),
            ),
            _buildFeatureTile(
              context,
              'Budget Planning',
              'Set monthly limits for categories',
              Icons.account_balance_wallet_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetPlanningScreen(),
                ),
              ),
            ),
            _buildFeatureTile(
              context,
              'Loans Management',
              'Track money lent and borrowed',
              Icons.handshake_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoansScreen()),
              ),
            ),
            _buildFeatureTile(
              context,
              'Financial Goals',
              'Set and track savings goals',
              Icons.flag_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalsScreen()),
              ),
            ),
            _buildFeatureTile(
              context,
              'Currency Converter',
              'Convert between world currencies with live rates',
              Icons.currency_exchange_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencyConverterScreen(),
                ),
              ),
            ),
            // Add more advanced features here in the future
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool? isEnabled,
  }) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    final isHighContrast = isAmoled || isLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isHighContrast
              ? Colors.transparent
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighContrast
                ? Theme.of(context).iconTheme.color!.withOpacity(0.2)
                : (isEnabled == true
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Theme.of(context).dividerColor),
          ),
          boxShadow: isHighContrast
              ? null
              : [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHighContrast
                    ? Colors.transparent
                    : (isEnabled == true
                          ? Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest),
                shape: BoxShape.circle,
                border: isHighContrast
                    ? Border.all(
                        color: Theme.of(
                          context,
                        ).iconTheme.color!.withOpacity(0.2),
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isHighContrast
                    ? Theme.of(context).iconTheme.color
                    : (isEnabled == true
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodySmall?.color
                                ?.withOpacity(0.5)),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (isEnabled != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEnabled ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isEnabled ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
