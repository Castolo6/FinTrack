import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_app/models/app_models.dart';
import 'package:flutter_app/providers/app_state.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';
import 'package:flutter_app/services/budget_alerts.dart';
import 'package:flutter_app/widgets/budget_progress.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CL', null);
  });

  group('budget alert thresholds', () {
    test('warns at 80%, distinguishes reached limit and exceeded', () {
      expect(budgetAlertLevel(spent: 79, limit: 100), BudgetAlertLevel.none);
      expect(
        budgetAlertLevel(spent: 80, limit: 100),
        BudgetAlertLevel.nearLimit,
      );
      expect(
        budgetAlertLevel(spent: 100, limit: 100),
        BudgetAlertLevel.reachedLimit,
      );
      expect(
        budgetAlertLevel(spent: 101, limit: 100),
        BudgetAlertLevel.exceeded,
      );
      expect(budgetPercent(spent: 85, limit: 100), 85);
    });
  });

  testWidgets('dashboard shows a warning for a budget at 80 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final now = DateTime.now();
    state.addBudget(
      Budget(
        id: 'current-month-budget-alert',
        categoryId: 'comida',
        limit: 100000,
        month: now,
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'current-month-budget-expense',
        description: 'Compra dentro del limite',
        amount: 85000,
        type: TransactionType.expense,
        date: now,
        accountId: 'banco',
        categoryId: 'comida',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alertas de presupuesto'), findsOneWidget);
    expect(find.text('Cerca del límite'), findsWidgets);
    expect(find.textContaining('85% usado en Comida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget progress explains an exceeded budget', (tester) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(
          body: BudgetProgress(
            categoryName: 'Comida',
            spent: 120000,
            limit: 100000,
            color: Colors.orange,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Excedido'), findsOneWidget);
    expect(find.textContaining('Superaste el límite por'), findsOneWidget);
  });
}
