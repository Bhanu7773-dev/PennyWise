import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currencies.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();

  CurrencyData? _fromCurrency;
  CurrencyData? _toCurrency;
  double? _convertedAmount;
  double? _exchangeRate;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // Cache for exchange rates
  Map<String, double> _ratesCache = {};
  String? _baseCurrencyCache;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set default currencies based on user's selected currency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MoneyProvider>(context, listen: false);
      final userCurrency = worldCurrencies.firstWhere(
        (c) => c.code == provider.currencyCode,
        orElse: () => worldCurrencies.firstWhere((c) => c.code == 'INR'),
      );
      setState(() {
        _fromCurrency = userCurrency;
        _toCurrency = worldCurrencies.firstWhere((c) => c.code == 'USD');
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchExchangeRates() async {
    if (_fromCurrency == null || _toCurrency == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _convertedAmount = null;
        _exchangeRate = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check cache first
      if (_baseCurrencyCache == _fromCurrency!.code && _ratesCache.isNotEmpty) {
        final rate = _ratesCache[_toCurrency!.code];
        if (rate != null) {
          setState(() {
            _exchangeRate = rate;
            _convertedAmount = amount * rate;
            _isLoading = false;
          });
          return;
        }
      }

      // Using free exchange rate API
      final response = await http
          .get(
            Uri.parse(
              'https://api.exchangerate-api.com/v4/latest/${_fromCurrency!.code}',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, dynamic>.from(data['rates']);

        // Cache the rates
        _ratesCache = rates.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        _baseCurrencyCache = _fromCurrency!.code;

        final rate = _ratesCache[_toCurrency!.code];

        if (rate != null) {
          setState(() {
            _exchangeRate = rate;
            _convertedAmount = amount * rate;
            _lastUpdated = DateTime.now();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Exchange rate not available for ${_toCurrency!.code}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch rates. Try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Check your connection.';
        _isLoading = false;
      });
    }
  }

  void _swapCurrencies() {
    _animationController.forward().then((_) {
      setState(() {
        final temp = _fromCurrency;
        _fromCurrency = _toCurrency;
        _toCurrency = temp;
        _convertedAmount = null;
        _exchangeRate = null;
      });
      _animationController.reverse();
      if (_amountController.text.isNotEmpty) {
        _fetchExchangeRates();
      }
    });
  }

  void _showCurrencyPicker(bool isFromCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CurrencyPickerSheet(
        selectedCurrency: isFromCurrency ? _fromCurrency : _toCurrency,
        onSelect: (currency) {
          setState(() {
            if (isFromCurrency) {
              _fromCurrency = currency;
            } else {
              _toCurrency = currency;
            }
            _convertedAmount = null;
            _exchangeRate = null;
          });
          Navigator.pop(context);
          if (_amountController.text.isNotEmpty) {
            _fetchExchangeRates();
          }
        },
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
        title: Text(
          'Currency Converter',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isLight ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isAmoled
              ? Colors.black
              : (isLight ? Colors.white : theme.scaffoldBackgroundColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Input Card
              _buildInputCard(isAmoled),

              const SizedBox(height: 24),

              // Currency Selection
              _buildCurrencySelectionCard(isAmoled),

              const SizedBox(height: 24),

              // Convert Button
              _buildConvertButton(isAmoled),

              const SizedBox(height: 24),

              // Result Card
              if (_convertedAmount != null ||
                  _isLoading ||
                  _errorMessage != null)
                _buildResultCard(isAmoled),

              const SizedBox(height: 24),

              // Quick Convert Amounts
              _buildQuickAmounts(isAmoled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(bool isAmoled) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAmoled || isLight ? Colors.transparent : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isLight
            ? Border.all(color: Colors.black)
            : Border.all(
                color: isAmoled ? Colors.white : Colors.white.withOpacity(0.05),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Amount',
            style: TextStyle(
              color: isLight
                  ? Colors.black.withOpacity(0.6)
                  : Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                color: isLight
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              prefixText: _fromCurrency?.symbol ?? '',
              prefixStyle: TextStyle(
                color: isAmoled
                    ? Colors.white
                    : (isLight ? Colors.black : AppTheme.primary),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            onChanged: (_) {
              if (_convertedAmount != null) {
                setState(() {
                  _convertedAmount = null;
                  _exchangeRate = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelectionCard(bool isAmoled) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAmoled || isLight ? Colors.transparent : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isLight
            ? Border.all(color: Colors.black)
            : Border.all(
                color: isAmoled ? Colors.white : Colors.white.withOpacity(0.05),
              ),
      ),
      child: Column(
        children: [
          // From Currency
          _buildCurrencySelector(
            label: 'From',
            currency: _fromCurrency,
            onTap: () => _showCurrencyPicker(true),
            isAmoled: isAmoled,
          ),

          const SizedBox(height: 16),

          // Swap Button
          ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _swapCurrencies,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAmoled || isLight
                      ? (isLight ? Colors.white : Colors.white)
                      : AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: isLight
                      ? Border.all(color: Colors.black)
                      : Border.all(
                          color: isAmoled
                              ? Colors.white
                              : AppTheme.primary.withOpacity(0.3),
                        ),
                ),
                child: Icon(
                  Icons.swap_vert_rounded,
                  color: isAmoled || isLight ? Colors.black : AppTheme.primary,
                  size: 28,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // To Currency
          _buildCurrencySelector(
            label: 'To',
            currency: _toCurrency,
            onTap: () => _showCurrencyPicker(false),
            isAmoled: isAmoled,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String label,
    required CurrencyData? currency,
    required VoidCallback onTap,
    required bool isAmoled,
  }) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? Colors.transparent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: isAmoled || isLight
              ? (isLight
                    ? Border.all(color: Colors.black)
                    : Border.all(color: Colors.white24))
              : null,
        ),
        child: Row(
          children: [
            Text(currency?.flag ?? '🌍', style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency != null
                        ? '${currency.code} - ${currency.name}'
                        : 'Select currency',
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isLight
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton(bool isAmoled) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return GestureDetector(
      onTap: _isLoading ? null : _fetchExchangeRates,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isAmoled || isLight
              ? (isLight ? Colors.white : Colors.white)
              : null,
          gradient: isAmoled || isLight
              ? null
              : LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isAmoled || isLight
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
          border: isAmoled || isLight
              ? (isLight
                    ? Border.all(color: Colors.black)
                    : Border.all(color: Colors.white))
              : null,
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isAmoled || isLight ? Colors.black : Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.currency_exchange,
                      color: isAmoled || isLight ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Convert',
                      style: TextStyle(
                        color: isAmoled || isLight
                            ? Colors.black
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResultCard(bool isAmoled) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isLight = provider.appThemeMode == AppThemeMode.light;

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isAmoled || isLight
              ? Colors.transparent
              : AppTheme.expense.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAmoled || isLight
                ? (isLight ? Colors.black : Colors.white)
                : AppTheme.expense.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: isLight ? Colors.red : AppTheme.expense,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: isLight ? Colors.black : AppTheme.expense,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isAmoled
              ? Colors.black
              : (isLight ? Colors.white : AppTheme.surface),
          borderRadius: BorderRadius.circular(20),
          border: isAmoled || isLight
              ? (isLight
                    ? Border.all(color: Colors.black)
                    : Border.all(color: Colors.white))
              : null,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: isAmoled || isLight ? Colors.black : null,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isAmoled || isLight
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.income.withOpacity(0.1),
                  AppTheme.primary.withOpacity(0.1),
                ],
              ),
        color: isAmoled || isLight
            ? (isLight ? Colors.transparent : Colors.black)
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAmoled
              ? Colors.white
              : (isLight ? Colors.black : AppTheme.income.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Converted Amount',
            style: TextStyle(
              color: isLight
                  ? Colors.black.withOpacity(0.6)
                  : Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _toCurrency?.symbol ?? '',
                style: TextStyle(
                  color: isAmoled
                      ? Colors.white
                      : (isLight ? Colors.black : AppTheme.income),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _convertedAmount?.toStringAsFixed(2) ?? '0.00',
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '1 ${_fromCurrency?.code} = ${_exchangeRate?.toStringAsFixed(4)} ${_toCurrency?.code}',
              style: TextStyle(
                color: isLight
                    ? Colors.black.withOpacity(0.8)
                    : Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          if (_lastUpdated != null) ...[
            const SizedBox(height: 12),
            Text(
              'Updated: ${_formatTime(_lastUpdated!)}',
              style: TextStyle(
                color: isLight
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAmounts(bool isAmoled) {
    final quickAmounts = [100, 500, 1000, 5000, 10000];
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Convert',
          style: TextStyle(
            color: isLight
                ? Colors.black.withOpacity(0.6)
                : Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quickAmounts.map((amount) {
            return GestureDetector(
              onTap: () {
                _amountController.text = amount.toString();
                _fetchExchangeRates();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isAmoled || isLight
                      ? (isLight ? Colors.transparent : Colors.transparent)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAmoled || isLight
                        ? (isLight ? Colors.black : Colors.white)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  '${_fromCurrency?.symbol ?? ''}$amount',
                  style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}

// Currency Picker Bottom Sheet
class _CurrencyPickerSheet extends StatefulWidget {
  final CurrencyData? selectedCurrency;
  final Function(CurrencyData) onSelect;

  const _CurrencyPickerSheet({
    required this.selectedCurrency,
    required this.onSelect,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CurrencyData> _filteredCurrencies = [];

  // Popular currencies to show at top
  final List<String> _popularCodes = [
    'USD',
    'EUR',
    'GBP',
    'INR',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
  ];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = worldCurrencies;
  }

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = worldCurrencies;
      } else {
        _filteredCurrencies = worldCurrencies.where((c) {
          return c.code.toLowerCase().contains(query.toLowerCase()) ||
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.country.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final popularCurrencies = worldCurrencies
        .where((c) => _popularCodes.contains(c.code))
        .toList();

    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isAmoled
            ? Colors.black
            : (isLight ? Colors.white : AppTheme.surface),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isAmoled || isLight
            ? (isLight
                  ? const Border(top: BorderSide(color: Colors.black))
                  : const Border(top: BorderSide(color: Colors.white)))
            : null,
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Select Currency',
                  style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isLight ? Colors.black54 : Colors.white54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCurrencies,
              style: TextStyle(color: isLight ? Colors.black : Colors.white),
              decoration: InputDecoration(
                hintText: 'Search currency or country...',
                hintStyle: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.4)
                      : Colors.white.withOpacity(0.4),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isLight
                      ? Colors.black.withOpacity(0.4)
                      : Colors.white.withOpacity(0.4),
                ),
                filled: true,
                fillColor: isLight
                    ? Colors.black.withOpacity(0.05)
                    : Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: isAmoled || isLight
                      ? (isLight
                            ? const BorderSide(color: Colors.black26)
                            : const BorderSide(color: Colors.white24))
                      : BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Scrollable content area
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Popular currencies (only show if not searching)
                if (_searchController.text.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Popular',
                          style: TextStyle(
                            color: isLight
                                ? Colors.black.withOpacity(0.5)
                                : Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: popularCurrencies.map((currency) {
                            final isSelected =
                                widget.selectedCurrency?.code == currency.code;
                            return GestureDetector(
                              onTap: () => widget.onSelect(currency),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isAmoled || isLight
                                            ? (isLight
                                                  ? Colors.black.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.white)
                                            : AppTheme.primary.withOpacity(0.2))
                                      : (isLight
                                            ? Colors.black.withOpacity(0.05)
                                            : Colors.white.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: isAmoled || isLight
                                              ? (isLight
                                                    ? Colors.black
                                                    : Colors.white)
                                              : AppTheme.primary,
                                        )
                                      : (isAmoled || isLight
                                            ? (isLight
                                                  ? null
                                                  : Border.all(
                                                      color: Colors.white10,
                                                    ))
                                            : null),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currency.flag,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      currency.code,
                                      style: TextStyle(
                                        color: isSelected
                                            ? (isAmoled || isLight
                                                  ? (isLight
                                                        ? Colors.black
                                                        : Colors.black)
                                                  : AppTheme.primary)
                                            : (isLight
                                                  ? Colors.black
                                                  : Colors.white),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: isLight
                        ? Colors.black.withOpacity(0.1)
                        : Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 8),
                ],

                // All currencies list
                ...List.generate(_filteredCurrencies.length, (index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected =
                      widget.selectedCurrency?.code == currency.code &&
                      widget.selectedCurrency?.country == currency.country;

                  return GestureDetector(
                    onTap: () => widget.onSelect(currency),
                    child: Container(
                      margin: const EdgeInsets.only(
                        bottom: 8,
                        left: 20,
                        right: 20,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isAmoled || isLight
                                  ? (isLight
                                        ? Colors.black.withOpacity(0.1)
                                        : Colors.white)
                                  : AppTheme.primary.withOpacity(0.1))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: isAmoled || isLight
                                    ? (isLight ? Colors.black : Colors.white)
                                    : AppTheme.primary.withOpacity(0.5),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            currency.flag,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currency.code} - ${currency.name}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isLight
                                              ? Colors.black
                                              : AppTheme.primary)
                                        : (isLight
                                              ? Colors.black
                                              : Colors.white),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currency.country,
                                  style: TextStyle(
                                    color: isLight
                                        ? Colors.black.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currency.symbol,
                            style: TextStyle(
                              color: isSelected
                                  ? (isLight ? Colors.black : AppTheme.primary)
                                  : (isLight ? Colors.black54 : Colors.white54),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: isLight ? Colors.black : AppTheme.primary,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
