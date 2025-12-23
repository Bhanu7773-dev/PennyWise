import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../providers/money_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/currencies.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  int _currentPage = 0;
  bool _isAnimating = false;
  CurrencyData _selectedCurrency = defaultCurrency;
  List<CurrencyData> _filteredCurrencies = worldCurrencies;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = worldCurrencies;
      } else {
        _filteredCurrencies = worldCurrencies.where((currency) {
          final countryLower = currency.country.toLowerCase();
          final codeLower = currency.code.toLowerCase();
          final nameLower = currency.name.toLowerCase();
          final queryLower = query.toLowerCase();
          return countryLower.contains(queryLower) ||
              codeLower.contains(queryLower) ||
              nameLower.contains(queryLower);
        }).toList();
      }
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isAnimating = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        final user = userCredential.user!;

        // Always use the newly selected currency from onboarding
        // This overwrites any existing Firebase profile currency
        await _initializeAndNavigate(
          name: user.displayName ?? 'User',
          currency: _selectedCurrency.symbol,
          currencyCode: _selectedCurrency.code,
          isGuest: false,
          userId: user.uid,
          photoURL: user.photoURL,
        );
      } else {
        setState(() => _isAnimating = false);
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (mounted) {
        setState(() => _isAnimating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isAnimating = true);

    // Check if there is a previous guest session to restore
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final prevGuestId = provider.settingsBox.get('guestUserId');
    final prevGuestName = provider.settingsBox.get('guestUserName');

    if (prevGuestId != null) {
      // RESTORE PREVIOUS GUEST SESSION but use newly selected currency
      await _initializeAndNavigate(
        name: prevGuestName ?? _nameController.text.trim(),
        currency: _selectedCurrency.symbol,
        currencyCode: _selectedCurrency.code,
        isGuest: true,
        userId: prevGuestId,
      );
    } else {
      // CREATE NEW GUEST SESSION
      if (_nameController.text.trim().isEmpty) {
        setState(() => _isAnimating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
        return;
      }

      await _initializeAndNavigate(
        name: _nameController.text.trim(),
        currency: _selectedCurrency.symbol,
        currencyCode: _selectedCurrency.code,
        isGuest: true,
        userId: const Uuid().v4(),
      );
    }
  }

  Future<void> _initializeAndNavigate({
    required String name,
    required String currency,
    required String currencyCode,
    required bool isGuest,
    required String? userId,
    String? photoURL,
  }) async {
    try {
      final provider = Provider.of<MoneyProvider>(context, listen: false);
      await provider.initializeUser(
        name: name,
        currency: currency,
        currencyCode: currencyCode,
        isGuest: isGuest,
        userId: userId,
        photoURL: photoURL,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Initialization Error: $e');
      if (mounted) {
        setState(() => _isAnimating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPage(
                title: 'Track Your\nExpenses',
                subtitle: 'Keep track of every penny you spend with ease.',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildSwipeTutorialPage(),
              _buildCurrencyPage(),
              _buildSetupPage(),
            ],
          ),

          // Page Indicators
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primary
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: AppTheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'NEXT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeTutorialPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon at top
          Icon(
            Icons.swipe,
            size: 80,
            color: AppTheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 32),

          const Text(
            'Swipe to Manage\nTransactions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),

          const SizedBox(height: 12),

          Text(
            'On the Home Screen, swipe any transaction\nto quickly edit or delete it',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // Home screen indicator
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Home Screen Transaction List',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 250.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

          const SizedBox(height: 24),

          // Swipe demonstration card
          Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    // Swipe Right - Edit
                    _buildSwipeHint(
                          icon: Icons.edit_outlined,
                          iconColor: Colors.blue,
                          direction: 'Swipe Right',
                          action: 'Edit Transaction',
                          arrowIcon: Icons.arrow_forward,
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideX(begin: -0.3, end: 0),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white12, height: 1),
                    ),

                    // Swipe Left - Delete
                    _buildSwipeHint(
                          icon: Icons.delete_outline,
                          iconColor: Colors.redAccent,
                          direction: 'Swipe Left',
                          action: 'Delete Transaction',
                          arrowIcon: Icons.arrow_back,
                        )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideX(begin: 0.3, end: 0),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

          const SizedBox(height: 48),

          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'GOT IT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildSwipeHint({
    required IconData icon,
    required Color iconColor,
    required String direction,
    required String action,
    required IconData arrowIcon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(arrowIcon, color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    direction,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                action,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.currency_exchange,
            size: 60,
            color: AppTheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          const Text(
            'Select Your\nCurrency',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
          const SizedBox(height: 8),
          Text(
            'Choose the currency for tracking your expenses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _filterCurrencies,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search country or currency...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          // Currency List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = currency.code == _selectedCurrency.code;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Flag
                          Text(
                            currency.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          // Country & Currency Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.country,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  currency.name,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Currency Code & Symbol
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.code,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currency.symbol,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // Checkmark
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 400.ms),
          ),

          const SizedBox(height: 16),

          // Selected Currency Display & Next Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _selectedCurrency.flag,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedCurrency.symbol} ${_selectedCurrency.code}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _selectedCurrency.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'NEXT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60), // Space for page indicators
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85, // Occupy more height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 3), // Push content down
            // Decorative Icon
            Icon(
              Icons.rocket_launch_outlined,
              size: 80,
              color: AppTheme.primary.withOpacity(0.8),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            const Text(
              'Let\'s Get\nStarted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),

            const SizedBox(height: 48),

            // Google Sign In Button
            ElevatedButton.icon(
              onPressed: _isAnimating ? null : _handleGoogleLogin,
              icon: const Icon(
                Icons.g_mobiledata,
                size: 32,
                color: Colors.black,
              ),
              label: const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 32),

            const Row(
              children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ],
            ),

            const SizedBox(height: 32),

            // Guest Setup
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Colors.white70,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isAnimating ? null : _handleGuestLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppTheme.primary.withOpacity(0.4),
              ),
              child: _isAnimating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CONTINUE AS GUEST',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),

            const Spacer(flex: 1), // Reduced bottom spacer
          ],
        ),
      ),
    );
  }
}
