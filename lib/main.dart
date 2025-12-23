import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'models/budget.dart';
import 'models/category.dart';
import 'models/loan.dart';
import 'models/goal.dart';
import 'models/account.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/lock_screen.dart';
import 'utils/app_theme.dart';
import 'providers/money_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(LoanTypeAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(AccountAdapter());
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<String>(
    'deletedSmsIds',
  ); // Blocklist for deleted SMS transactions
  final settingsBox = await Hive.openBox('settings');
  final userName = settingsBox.get('userName');

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MoneyProvider())],
      child: PennyWiseApp(
        initialRoute: userName != null ? '/home' : '/onboarding',
      ),
    ),
  );
}

class PennyWiseApp extends StatelessWidget {
  final String initialRoute;
  const PennyWiseApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<MoneyProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'PennyWise',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(provider.appThemeMode),
          home: LockScreen(
            isEnabled: provider.biometricLockEnabled && initialRoute == '/home',
            child: initialRoute == '/home'
                ? const HomeScreen()
                : const OnboardingScreen(),
          ),
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/home': (context) => LockScreen(
              isEnabled: provider.biometricLockEnabled,
              child: const HomeScreen(),
            ),
          },
        );
      },
    );
  }
}
