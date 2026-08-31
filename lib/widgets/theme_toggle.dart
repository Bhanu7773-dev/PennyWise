import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/theme_reveal.dart'; // Import this

class TriThemeToggle extends StatelessWidget {
  const TriThemeToggle({super.key});

  void _vibrate() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final currentMode = provider.appThemeMode;
    final theme = Theme.of(context);

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;

    return Container(
      width: 100,
      height: 36,
      decoration: BoxDecoration(
        color: isAmoled || provider.appThemeMode == AppThemeMode.light
            ? Colors.transparent
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAmoled || provider.appThemeMode == AppThemeMode.light
              ? theme.iconTheme.color!.withOpacity(0.5)
              : theme.dividerColor,
        ),
      ),
      child: Stack(
        children: [
          // Animated Thumb
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            alignment: _getAlignment(currentMode),
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isAmoled
                    ? Colors.white
                    : (provider.appThemeMode == AppThemeMode.light
                          ? Colors.black
                          : theme.primaryColor),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isAmoled
                                ? Colors.white
                                : (provider.appThemeMode == AppThemeMode.light
                                      ? Colors.black
                                      : theme.primaryColor))
                            .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Interactive areas
          Row(
            children: [
              _buildToggleItem(
                context,
                AppThemeMode.defaultDark,
                Icons.contrast,
                provider,
              ),
              _buildToggleItem(
                context,
                AppThemeMode.amoled,
                Icons.nightlight_round,
                provider,
              ),
              _buildToggleItem(
                context,
                AppThemeMode.light,
                Icons.light_mode_outlined,
                provider,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Alignment _getAlignment(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultDark:
        return Alignment.centerLeft;
      case AppThemeMode.amoled:
        return Alignment.center;
      case AppThemeMode.light:
        return Alignment.centerRight;
    }
  }

  Widget _buildToggleItem(
    BuildContext context,
    AppThemeMode mode,
    IconData icon,
    MoneyProvider provider,
  ) {
    final isSelected = provider.appThemeMode == mode;
    final theme = Theme.of(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Capture tap details to get position
        onTapUp: (details) {
          if (!isSelected) {
            _vibrate();
            _changeTheme(context, provider, mode, details.globalPosition);
          }
        },
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? (isAmoled ? Colors.black : Colors.white)
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  void _changeTheme(
    BuildContext context,
    MoneyProvider provider,
    AppThemeMode mode,
    Offset tapPosition,
  ) {
    // Try to find the ThemeRevealController
    try {
      final controller = ThemeRevealController.of(context);
      controller.changeTheme(
        setTheme: () => provider.setThemeMode(mode),
        center: tapPosition,
      );
    } catch (e) {
      // Fallback if controller not found (e.g. settings screen)
      provider.setThemeMode(mode);
    }
  }
}
