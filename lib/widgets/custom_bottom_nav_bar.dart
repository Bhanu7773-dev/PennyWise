import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isAmoled
                ? Colors.black.withOpacity(0.3)
                : (isLight
                      ? Colors.white.withOpacity(0.2)
                      : Theme.of(context).cardColor.withOpacity(0.8)),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isAmoled
                  ? Colors.white
                  : (isLight
                        ? Colors.black.withOpacity(0.5)
                        : Theme.of(context).dividerColor),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Animated Selector Background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: selectedIndex * 64.0, // 48 (icon+padding) + 16 (spacing)
                top: 0,
                bottom: 0,
                child: Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: isAmoled || isLight
                        ? (isLight ? Colors.black : Colors.white)
                        : Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Icons Row
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
                  const SizedBox(width: 16),
                  _buildNavItem(
                    context,
                    1,
                    Icons.bar_chart_rounded,
                    'Analytics',
                  ),
                  const SizedBox(width: 16),
                  _buildNavItem(
                    context,
                    2,
                    Icons.auto_graph_rounded,
                    'Advance',
                  ),
                  const SizedBox(width: 16),
                  _buildNavItem(context, 3, Icons.settings_rounded, 'Settings'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onItemSelected(index),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isSelected
              ? (isAmoled ? Colors.black : Colors.white)
              : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }
}
