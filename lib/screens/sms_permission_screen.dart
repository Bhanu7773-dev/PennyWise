import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class SmsPermissionScreen extends StatelessWidget {
  const SmsPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isAmoled ? Colors.black : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isAmoled ? Colors.black : theme.scaffoldBackgroundColor,
          ),
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero Icon
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isAmoled
                              ? Colors.transparent
                              : AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAmoled
                                ? Colors.white
                                : AppTheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: isAmoled
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.security,
                          size: 64,
                          color: isAmoled ? Colors.white : AppTheme.primary,
                        ),
                      ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        'SMS Permission',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn().slideY(begin: 0.3),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'PennyWise needs access to your SMS messages to automatically track your expenses and bill reminders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),

                      const SizedBox(height: 48),

                      // Features List
                      _buildFeatureRow(
                        context,
                        Icons.lock_outline,
                        'Private & Secure',
                        'Your data never leaves your device',
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                      const SizedBox(height: 24),

                      _buildFeatureRow(
                        context,
                        Icons.notifications_off_outlined,
                        'No Spam',
                        'We only read transactional messages',
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),

                      const SizedBox(height: 24),

                      _buildFeatureRow(
                        context,
                        Icons.battery_charging_full,
                        'Battery Efficient',
                        'Optimized for minimal battery usage',
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                    ],
                  ),
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grant Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Consumer<MoneyProvider>(
                        builder: (context, provider, _) {
                          final isAmoled =
                              provider.appThemeMode == AppThemeMode.amoled;
                          return ElevatedButton(
                            onPressed: () async {
                              final status = await Permission.sms.request();

                              if (context.mounted) {
                                if (status.isGranted) {
                                  provider.setSmsTracking(true);
                                  // Start syncing SMS immediately
                                  provider.syncSmsTransactions();

                                  Navigator.pop(
                                    context,
                                  ); // Close permission screen
                                  Navigator.pop(
                                    context,
                                  ); // Close tracking screen to return to advanced settings
                                } else if (status.isPermanentlyDenied) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isAmoled
                                          ? Colors.black
                                          : AppTheme.surface,
                                      shape: isAmoled
                                          ? RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              side: const BorderSide(
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                      title: const Text(
                                        'Permission Required',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'SMS permission is required to track transactions. Please enable it in settings.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            openAppSettings();
                                          },
                                          child: const Text('Open Settings'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAmoled
                                  ? Colors.white
                                  : AppTheme.primary,
                              foregroundColor: isAmoled
                                  ? Colors.black
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isAmoled
                                    ? const BorderSide(color: Colors.white)
                                    : BorderSide.none,
                              ),
                              elevation: isAmoled ? 0 : 8,
                              shadowColor: isAmoled
                                  ? Colors.transparent
                                  : AppTheme.primary.withOpacity(0.5),
                            ),
                            child: const Text(
                              'GRANT PERMISSION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 1.0),

                    const SizedBox(height: 16),

                    // Footer Text
                    Text(
                      'You can revoke this permission at any time in settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: isAmoled ? Border.all(color: Colors.white24) : null,
          ),
          child: Icon(
            icon,
            color: isAmoled ? Colors.white : AppTheme.primary,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
