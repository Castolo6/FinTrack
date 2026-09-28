import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/accounts_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/statement_reconciliation_screen.dart';
import 'screens/transactions_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/responsive_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);
  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'FinTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mainDestinations = [
      AppDestination(
        label: 'Resumen',
        icon: Icons.dashboard_outlined,
        screen: const DashboardScreen(),
      ),
      AppDestination(
        label: 'Cuentas',
        icon: Icons.account_balance_wallet_outlined,
        screen: const AccountsScreen(),
      ),
      AppDestination(
        label: 'Movimientos',
        icon: Icons.receipt_long_outlined,
        screen: const TransactionsScreen(),
      ),
      AppDestination(
        label: 'Presupuestos',
        icon: Icons.pie_chart_outline,
        screen: const BudgetsScreen(),
      ),
    ];

    final moreDestinations = [
      AppDestination(
        label: 'Objetivos',
        icon: Icons.flag_outlined,
        screen: const GoalsScreen(),
      ),
      AppDestination(
        label: 'Categorías',
        icon: Icons.label_outline,
        screen: const CategoriesScreen(),
      ),
      AppDestination(
        label: 'Comparar',
        icon: Icons.compare_arrows,
        screen: const StatementReconciliationScreen(),
      ),
      AppDestination(
        label: 'Reportes',
        icon: Icons.insert_chart_outlined,
        screen: const ReportsScreen(),
      ),
    ];

    return ResponsiveScaffold(
      title: 'FinTrack',
      destinations: [...mainDestinations, ...moreDestinations],
      moreDestinations: moreDestinations,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
    );
  }
}
