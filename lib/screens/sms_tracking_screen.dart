import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import 'sms_permission_screen.dart';

class SmsTrackingScreen extends StatelessWidget {
  const SmsTrackingScreen({super.key});

  void _showClearBlocklistDialog(BuildContext context, MoneyProvider provider) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isAmoled
                ? Colors.black
                : (isLight ? Colors.white : AppTheme.surface),
            borderRadius: BorderRadius.circular(24),
            border: isLight
                ? Border.all(color: Colors.black)
                : Border.all(
                    color: isAmoled
                        ? Colors.white
                        : Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isAmoled
                      ? Colors.white
                      : (isLight
                            ? Colors.transparent
                            : Colors.amber.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20),
                  border: isLight ? Border.all(color: Colors.black) : null,
                ),
                child: Icon(
                  Icons.restore_rounded,
                  color: isLight
                      ? Colors.black
                      : (isAmoled ? Colors.black : Colors.amber),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Restore Blocked Transactions?',
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This will clear the blocklist and allow ${provider.blockedSmsCount} previously deleted SMS transaction${provider.blockedSmsCount > 1 ? 's' : ''} to be imported again on next sync.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: isAmoled || isLight
                              ? Border.all(
                                  color: isLight ? Colors.black : Colors.white,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isLight ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        provider.clearSmsBlocklist();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: isLight ? Colors.white : Colors.white,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Blocklist cleared! Sync to restore.',
                                ),
                              ],
                            ),
                            backgroundColor: isAmoled
                                ? Colors.black
                                : (isLight ? Colors.black : AppTheme.income),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isAmoled || isLight
                                  ? const BorderSide(color: Colors.white)
                                  : BorderSide.none,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isAmoled
                              ? Colors.white
                              : (isLight ? Colors.white : Colors.amber),
                          borderRadius: BorderRadius.circular(12),
                          border: isLight
                              ? Border.all(color: Colors.black)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Restore',
                            style: TextStyle(
                              color: isAmoled
                                  ? Colors.black
                                  : (isLight ? Colors.black : Colors.black87),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
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
          'SMS Tracking',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isAmoled
              ? Colors.black
              : (isLight ? Colors.transparent : theme.scaffoldBackgroundColor),
        ),
        child: Consumer<MoneyProvider>(
          builder: (context, provider, _) {
            final isEnabled = provider.smsTrackingEnabled;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isAmoled || isLight
                            ? Colors.transparent
                            : (isEnabled
                                  ? AppTheme.primary.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.05)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLight
                              ? Colors.black
                              : (isAmoled
                                    ? Colors.white
                                    : (isEnabled
                                          ? AppTheme.primary.withOpacity(0.3)
                                          : Colors.white.withOpacity(0.1))),
                          width: 2,
                        ),
                        boxShadow: isAmoled || isLight
                            ? null
                            : [
                                BoxShadow(
                                  color: isEnabled
                                      ? AppTheme.primary.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.sms_outlined,
                        size: 64,
                        color: isLight
                            ? Colors.black
                            : (isEnabled || isAmoled
                                  ? Colors.white
                                  : Colors.white54),
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'SMS Transaction Tracking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isLight ? Colors.black : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(begin: 0.3),

                    const SizedBox(height: 16),

                    Text(
                      'Automatically read transaction SMS messages from banks and add them to your expenses. This feature requires SMS read permission.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isLight
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.6),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? (isAmoled || isLight
                                  ? Colors.transparent
                                  : AppTheme.income.withOpacity(0.1))
                            : (isAmoled || isLight
                                  ? Colors.transparent
                                  : AppTheme.expense.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLight
                              ? Colors.black
                              : (isEnabled
                                    ? (isAmoled
                                          ? Colors.white
                                          : AppTheme.income.withOpacity(0.3))
                                    : (isAmoled
                                          ? Colors.white
                                          : AppTheme.expense.withOpacity(0.3))),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? (isAmoled || isLight
                                        ? (isLight
                                              ? AppTheme.income
                                              : Colors.white)
                                        : AppTheme.income)
                                  : (isAmoled || isLight
                                        ? (isLight
                                              ? AppTheme.expense
                                              : Colors.white54)
                                        : AppTheme.expense),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEnabled ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isLight
                                  ? Colors.black
                                  : (isEnabled
                                        ? (isAmoled
                                              ? Colors.white
                                              : AppTheme.income)
                                        : (isAmoled
                                              ? Colors.white54
                                              : AppTheme.expense)),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    if (provider.blockedSmsCount > 0)
                      GestureDetector(
                        onTap: () =>
                            _showClearBlocklistDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isAmoled || isLight
                                ? Colors.transparent
                                : Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: isLight
                                ? Border.all(color: Colors.black)
                                : Border.all(
                                    color: isAmoled
                                        ? Colors.white
                                        : Colors.amber.withOpacity(0.3),
                                  ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restore_rounded,
                                color: isLight
                                    ? Colors.black
                                    : (isAmoled ? Colors.white : Colors.amber),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Restore ${provider.blockedSmsCount} blocked transaction${provider.blockedSmsCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: isLight
                                      ? Colors.black
                                      : (isAmoled
                                            ? Colors.white
                                            : Colors.amber),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isEnabled) {
                            provider.setSmsTracking(false);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SmsPermissionScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAmoled || isLight
                              ? Colors.white
                              : (isEnabled
                                    ? AppTheme.expense
                                    : AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isAmoled || isLight
                                ? (isLight
                                      ? const BorderSide(color: Colors.black)
                                      : const BorderSide(color: Colors.white))
                                : BorderSide.none,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEnabled ? 'DISABLE FEATURE' : 'ENABLE FEATURE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAmoled || isLight
                                ? Colors.black
                                : Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 1.0),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
