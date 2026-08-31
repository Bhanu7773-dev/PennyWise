import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/money_provider.dart';
import '../models/loan.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final loans = provider.loans;
    final givenLoans = loans.where((l) => l.type == LoanType.given).toList();
    final takenLoans = loans.where((l) => l.type == LoanType.taken).toList();
    final totalLent = provider.totalLent;
    final totalBorrowed = provider.totalBorrowed;
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
          'Loans',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isAmoled || isLight
              ? (isLight ? Colors.black : Colors.white)
              : AppTheme.primary,
          labelColor: isAmoled || isLight
              ? (isLight ? Colors.black : Colors.white)
              : AppTheme.primary,
          unselectedLabelColor: isLight ? Colors.black54 : Colors.white60,
          tabs: const [
            Tab(text: 'Given (Lent)'),
            Tab(text: 'Taken (Borrowed)'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(context, provider, totalLent, totalBorrowed),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoanList(context, provider, givenLoans, LoanType.given),
                _buildLoanList(context, provider, takenLoans, LoanType.taken),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLoanDialog(context, provider),
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

  Widget _buildSummaryCard(
    BuildContext context,
    MoneyProvider provider,
    double totalLent,
    double totalBorrowed,
  ) {
    final currency = provider.currencySymbol;
    final netBalance = totalLent - totalBorrowed;

    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Balance',
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(
                  symbol: currency,
                  decimalDigits: 0,
                ).format(netBalance),
                style: TextStyle(
                  color: isLight
                      ? Colors
                            .black // Monochrome
                      : (isAmoled
                            ? Colors.white
                            : (netBalance >= 0
                                  ? AppTheme.income
                                  : AppTheme.expense)),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    color: isLight
                        ? Colors
                              .black // Monochrome
                        : (isAmoled ? Colors.white : AppTheme.expense),
                    value: totalLent > 0 ? totalLent : 1,
                    title: '',
                    radius: 15,
                  ),
                  PieChartSectionData(
                    color: isLight
                        ? Colors
                              .black26 // Monochrome
                        : (isAmoled ? Colors.white70 : AppTheme.income),
                    value: totalBorrowed > 0 ? totalBorrowed : 1,
                    title: '',
                    radius: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildLoanList(
    BuildContext context,
    MoneyProvider provider,
    List<Loan> loans,
    LoanType type,
  ) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == LoanType.given ? Icons.outbond : Icons.call_received,
              size: 64,
              color: provider.appThemeMode == AppThemeMode.light
                  ? Colors.black26
                  : Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              type == LoanType.given
                  ? 'No loans given yet'
                  : 'No loans taken yet',
              style: TextStyle(
                color: provider.appThemeMode == AppThemeMode.light
                    ? Colors.black45
                    : Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _buildLoanCard(context, provider, loan);
      },
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    MoneyProvider provider,
    Loan loan,
  ) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;
    final currency = provider.currencySymbol;
    final progress = loan.progress;
    final isCompleted = loan.isCompleted;

    return GestureDetector(
      onTap: () => _showEditLoanDialog(context, provider, loan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAmoled || isLight
              ? Colors.transparent
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: isLight
              ? Border.all(color: Colors.black)
              : Border.all(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : (isAmoled
                            ? Colors.white
                            : Colors.white.withOpacity(0.05)),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    loan.title,
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      NumberFormat.currency(
                        symbol: currency,
                        decimalDigits: 0,
                      ).format(loan.totalAmount),
                      style: TextStyle(
                        color: isLight
                            ? Colors
                                  .black // Monochrome
                            : (isAmoled
                                  ? Colors.white
                                  : (loan.type == LoanType.given
                                        ? AppTheme.expense
                                        : AppTheme.income)),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    GestureDetector(
                      onTap: () =>
                          _showDeleteLoanDialog(context, provider, loan),
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: ${NumberFormat.currency(symbol: currency, decimalDigits: 0).format(loan.paidAmount)}',
                  style: TextStyle(
                    color: isLight
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Remaining: ${NumberFormat.currency(symbol: currency, decimalDigits: 0).format(loan.remainingAmount)}',
                  style: TextStyle(
                    color: isLight
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isLight
                    ? Colors.black.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted
                      ? (isLight ? Colors.black : Colors.green) // Monochrome
                      : (isLight
                            ? Colors.black54
                            : (isAmoled ? Colors.white : AppTheme.primary)),
                ),
                minHeight: 8,
              ),
            ),
            if (loan.dueDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Due: ${DateFormat('MMM d, y').format(loan.dueDate!)}',
                style: TextStyle(
                  color: isLight
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  void _showDeleteLoanDialog(
    BuildContext context,
    MoneyProvider provider,
    Loan loan,
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
          'Delete Loan?',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${loan.title}"? This action cannot be undone.',
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
              provider.deleteLoan(loan.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loan "${loan.title}" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context, MoneyProvider provider) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    LoanType selectedType = _tabController.index == 0
        ? LoanType.given
        : LoanType.taken;
    DateTime? selectedDate;
    bool recordAsTransaction = false;

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
            'Add Loan',
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
                    labelText: 'Title (e.g., Person Name)',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Type:',
                      style: TextStyle(
                        color: isLight ? Colors.black54 : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<LoanType>(
                      value: selectedType,
                      dropdownColor: isAmoled
                          ? Colors.black
                          : (isLight ? Colors.white : const Color(0xFF1E293B)),
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: LoanType.given,
                          child: Text(
                            'Given (Lent)',
                            style: TextStyle(
                              color: isLight ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: LoanType.taken,
                          child: Text(
                            'Taken (Borrowed)',
                            style: TextStyle(
                              color: isLight ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedDate == null
                        ? 'Select Due Date (Optional)'
                        : 'Due: ${DateFormat('MMM d, y').format(selectedDate!)}',
                    style: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white70,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: isLight ? Colors.black54 : Colors.white70,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAmoled || isLight
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLight
                          ? Colors.black12
                          : (isAmoled ? Colors.white24 : Colors.white10),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Record in Income / Expense',
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      selectedType == LoanType.given
                          ? 'Add loan as an Expense transaction'
                          : 'Add loan as an Income transaction',
                      style: TextStyle(
                        color: isLight ? Colors.black54 : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    value: recordAsTransaction,
                    activeThumbColor: isAmoled || isLight
                        ? (isLight ? Colors.black : Colors.white)
                        : AppTheme.primary,
                    onChanged: (val) =>
                        setState(() => recordAsTransaction = val),
                  ),
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
                    final newLoan = Loan(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      totalAmount: amount,
                      type: selectedType,
                      startDate: DateTime.now(),
                      dueDate: selectedDate,
                    );
                    provider.addLoan(newLoan);

                    if (recordAsTransaction) {
                      final isGiven = selectedType == LoanType.given;
                      provider.addTransaction(
                        Transaction(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: isGiven
                              ? 'Loan Given: ${titleController.text.trim()}'
                              : 'Loan Borrowed: ${titleController.text.trim()}',
                          amount: amount,
                          date: DateTime.now(),
                          isExpense: isGiven,
                          category: isGiven ? 'Financial & Taxes' : 'Income',
                          notes:
                              'Auto-created from Loan: ${titleController.text.trim()}',
                        ),
                      );
                    }

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

  void _showEditLoanDialog(
    BuildContext context,
    MoneyProvider provider,
    Loan loan,
  ) {
    final paidController = TextEditingController(
      text: loan.paidAmount.toStringAsFixed(0),
    );
    bool recordPaymentAsTransaction = false;

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
            'Update ${loan.title}',
            style: TextStyle(color: isLight ? Colors.black : Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Amount: ${provider.currencySymbol}${loan.totalAmount}',
                  style: TextStyle(
                    color: isLight ? Colors.black54 : Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: paidController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Paid Amount',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAmoled || isLight
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLight
                          ? Colors.black12
                          : (isAmoled ? Colors.white24 : Colors.white10),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Record in Income / Expense',
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      loan.type == LoanType.given
                          ? 'Add repayment received as Income'
                          : 'Add repayment made as Expense',
                      style: TextStyle(
                        color: isLight ? Colors.black54 : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    value: recordPaymentAsTransaction,
                    activeThumbColor: isAmoled || isLight
                        ? (isLight ? Colors.black : Colors.white)
                        : AppTheme.primary,
                    onChanged: (val) =>
                        setState(() => recordPaymentAsTransaction = val),
                  ),
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
                final oldPaid = loan.paidAmount;
                final paid = double.tryParse(paidController.text) ?? 0;
                if (paid >= 0 && paid <= loan.totalAmount) {
                  final diff = paid - oldPaid;
                  loan.paidAmount = paid;
                  provider.updateLoan(loan);

                  if (recordPaymentAsTransaction && diff > 0) {
                    final isRepaymentReceived = loan.type == LoanType.given;
                    provider.addTransaction(
                      Transaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: isRepaymentReceived
                            ? 'Loan Repaid by: ${loan.title}'
                            : 'Loan Repayment to: ${loan.title}',
                        amount: diff,
                        date: DateTime.now(),
                        isExpense: !isRepaymentReceived,
                        category: isRepaymentReceived
                            ? 'Income'
                            : 'Financial & Taxes',
                        notes:
                            'Auto-created from Loan repayment: ${loan.title}',
                      ),
                    );
                  }

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
                'Update',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
