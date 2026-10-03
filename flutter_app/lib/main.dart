import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/accounts_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/statement_reconciliation_screen.dart';
import 'screens/transactions_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/responsive_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);

  Object? firebaseStartupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseStartupError = error;
  }
  runApp(FinTrackApp(firebaseStartupError: firebaseStartupError));
}

class FinTrackApp extends StatelessWidget {
  final Object? firebaseStartupError;

  const FinTrackApp({super.key, this.firebaseStartupError});

  @override
  Widget build(BuildContext context) {
    if (firebaseStartupError != null) {
      return _AppScaffold(
        child: _FirebaseStartupError(error: firebaseStartupError!),
      );
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final user = waiting ? null : snapshot.data;

        Widget app = _AppScaffold(
          child: !waiting
              ? (user == null
                    ? const AuthScreen()
                    : _WorkspaceHome(key: ValueKey(user.uid), user: user))
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );

        // The provider must live above MaterialApp so every pushed route and
        // dialog can read AppState.
        if (user == null) return app;
        return ChangeNotifierProvider<AppState>(
          key: ValueKey(user.uid),
          create: (_) {
            final state = AppState.forUser(user.uid);
            // Load after the first frame: notifying listeners while the
            // provider is being built would throw.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!state.isDisposed) {
                state.loadFromFirestore();
              }
            });
            return state;
          },
          child: app,
        );
      },
    );
  }
}

class _AppScaffold extends StatelessWidget {
  final Widget child;

  const _AppScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: child,
    );
  }
}

class _WorkspaceHome extends StatelessWidget {
  final User user;

  const _WorkspaceHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.loadError != null) {
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudieron cargar tus datos',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(state.loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: state.reloadFromFirestore,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                      TextButton(
                        onPressed: () => AuthService().signOut(),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return HomePage(onSignOut: () => AuthService().signOut());
      },
    );
  }
}

class _FirebaseStartupError extends StatelessWidget {
  final Object error;

  const _FirebaseStartupError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No se pudo iniciar Firebase',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback? onSignOut;

  const HomePage({super.key, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
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
      onSignOut: onSignOut,
      onOpenProfile: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      banner: appState.persistenceError == null
          ? null
          : MaterialBanner(
              content: Text(appState.persistenceError!),
              actions: [
                TextButton(
                  onPressed: appState.clearPersistenceError,
                  child: const Text('Cerrar'),
                ),
              ],
            ),
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
