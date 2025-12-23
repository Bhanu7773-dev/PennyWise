import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_widget.dart';
import '../widgets/transaction_list.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/theme_reveal.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'advance_screen.dart';
import 'net_worth_screen.dart';
import 'settings_screen.dart';
import 'all_transactions_screen.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Disable animations after initial load
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _shouldAnimate = false;
        });
      }
    });
  }

  bool _shouldAnimate = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final theme = Theme.of(context);
    final isLightTheme = provider.appThemeMode == AppThemeMode.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLightTheme
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: isLightTheme ? Brightness.light : Brightness.dark,
      ),
    );

    return ThemeRevealController(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Gradient removed for solid background
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildHomePage(provider),
                const AnalyticsScreen(),
                const AdvanceScreen(),
                const SettingsScreen(),
              ],
            ),

            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child:
                    CustomBottomNavBar(
                          selectedIndex: _currentPage,
                          onItemSelected: _onNavItemTapped,
                        )
                        .animate(value: _shouldAnimate ? null : 1.0)
                        .fadeIn(delay: 1000.ms)
                        .slideY(begin: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage(MoneyProvider provider) {
    final theme = Theme.of(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final isHighContrast = isAmoled || isLight;
    return Stack(
      children: [
        // Gradient removed for solid background
        if (!isHighContrast)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.0,
                MediaQuery.of(context).padding.top + 16,
                20.0,
                100.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                'Welcome Back,',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              )
                              .animate(value: _shouldAnimate ? null : 1)
                              .fadeIn()
                              .slideX(begin: -0.2),
                          const SizedBox(height: 4),
                          Text(
                                provider.userName,
                                style: TextStyle(
                                  color: theme.textTheme.titleLarge?.color,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              )
                              .animate(value: _shouldAnimate ? 0 : 1)
                              .fadeIn(delay: 100.ms)
                              .slideX(begin: -0.2),
                        ],
                      ),
                      const Spacer(),
                      const TriThemeToggle(),
                      const SizedBox(width: 12),
                      GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  barrierDismissible: true,
                                  barrierColor: Colors.black.withOpacity(0.5),
                                  transitionDuration: const Duration(
                                    milliseconds: 400,
                                  ),
                                  reverseTransitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const ProfileDialog(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'profile_ring',
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isHighContrast
                                        ? theme.iconTheme.color!.withOpacity(
                                            0.5,
                                          )
                                        : theme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.cardColor,
                                  backgroundImage: provider.photoURL != null
                                      ? NetworkImage(provider.photoURL!)
                                      : null,
                                  child: provider.photoURL == null
                                      ? Icon(
                                          Icons.person,
                                          color: theme.iconTheme.color,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          )
                          .animate(value: _shouldAnimate ? 0 : 1)
                          .scale(delay: 200.ms),
                    ],
                  ),

                  const SizedBox(height: 32),

                    HomeBalanceCard(shouldAnimate: _shouldAnimate),
                  const SizedBox(height: 16),

                  BudgetWidget()
                      .animate(value: _shouldAnimate ? null : 1.0)
                      .fadeIn(delay: 350.ms)
                      .slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: isHighContrast
                              ? theme.textTheme.titleLarge?.color
                              : Colors.white.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      )
                      .animate(value: _shouldAnimate ? 0 : 1)
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        context,
                        icon: Icons.arrow_upward_rounded,
                        label: 'Expense',
                        color: Colors.red,
                        delay: 500,
                        heroTag: 'hero_action_expense',
                        isAmoled: isAmoled,
                        isHighContrast: isHighContrast,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTransactionScreen(
                                initialIsExpense: true,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.arrow_downward_rounded,
                        label: 'Income',
                        color: Colors.green,
                        delay: 600,
                        heroTag: 'hero_action_income',
                        isAmoled: isAmoled,
                        isHighContrast: isHighContrast,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTransactionScreen(
                                initialIsExpense: false,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.history_rounded,
                        label: 'History',
                        color: const Color(0xFF6366F1),
                        delay: 700,
                        heroTag: 'hero_action_history',
                        isAmoled: isAmoled,
                        isHighContrast: isHighContrast,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AllTransactionsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.show_chart_rounded,
                        label: 'Net Worth',
                        color: Colors.cyan,
                        delay: 800,
                        heroTag: 'hero_action_net_worth',
                        isAmoled: isAmoled,
                        isHighContrast: isHighContrast,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NetWorthScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                        'Recent Transactions',
                        style: TextStyle(
                          color: isHighContrast
                              ? theme.textTheme.titleLarge?.color
                              : Colors.white.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      )
                      .animate(value: _shouldAnimate ? 0 : 1)
                      .fadeIn(delay: 900.ms),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 400,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.8, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: TransactionList(animate: _shouldAnimate),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
    required VoidCallback onTap,
    required String heroTag,
    bool isAmoled = false,
    bool isHighContrast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child:
          Column(
                children: [
                  Hero(
                    tag: heroTag,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isHighContrast
                            ? Colors.transparent
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isHighContrast
                              ? Theme.of(
                                  context,
                                ).iconTheme.color!.withOpacity(0.5)
                              : color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isHighContrast
                            ? Theme.of(context).iconTheme.color
                            : color,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isHighContrast
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
              .animate(value: _shouldAnimate ? null : 1.0)
              .fadeIn(delay: delay.ms)
              .scale(
                delay: delay.ms,
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOutBack,
              ),
    );
  }
}
