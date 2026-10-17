import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/app_models.dart';
import 'package:flutter_app/providers/app_state.dart';
import 'package:flutter_app/services/formatters.dart';
import 'package:flutter_app/screens/reports_screen.dart';
import 'package:flutter_app/screens/transaction_list_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CL', null);
  });

  testWidgets('report category tabs switch between expense and income charts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final now = DateTime.now();
    state.addTransaction(
      Transaction(
        id: 'expense-current-month',
        description: 'Compra de supermercado',
        amount: 45000,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, now.day),
        accountId: 'banco',
        categoryId: 'comida',
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'income-contract',
        description: 'Trabajo independiente',
        amount: 300000,
        type: TransactionType.income,
        date: DateTime(now.year, now.month, now.day),
        accountId: 'banco',
        categoryId: 'servicios',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: ReportsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-categories-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Distribución por categoría'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-expense-tab')), findsOneWidget);
    expect(find.text('Comida'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('report-income-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Servicios'), findsOneWidget);
    expect(find.textContaining('300.000'), findsOneWidget);
  });

  testWidgets('reports compare current month metrics with the prior month', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    final previousMonthLastDay = DateTime(
      previousMonth.year,
      previousMonth.month + 1,
      0,
    ).day;
    final previousEnd = DateTime(
      previousMonth.year,
      previousMonth.month,
      now.day.clamp(1, previousMonthLastDay),
    );
    state.addTransaction(
      Transaction(
        id: 'comparison-current-income',
        description: 'Ingreso del mes actual',
        amount: 210000,
        type: TransactionType.income,
        date: now,
        accountId: 'banco',
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'comparison-previous-income',
        description: 'Ingreso del mes anterior',
        amount: 150000,
        type: TransactionType.income,
        date: previousEnd,
        accountId: 'banco',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: ReportsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('report-period-comparison')),
      findsOneWidget,
    );
    expect(find.text('Comparación mensual'), findsOneWidget);
    expect(
      find.text(
        '${Formatters.monthYear(now)} vs ${Formatters.monthYear(previousMonth)}',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report-comparison-ingresos')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report-comparison-gastos')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report-comparison-patrimonio')),
      findsOneWidget,
    );
    int periodTotal(DateTime start, DateTime end, TransactionType type) => state
        .transactions
        .where((transaction) {
          final day = DateUtils.dateOnly(transaction.date);
          return transaction.type == type &&
              !day.isBefore(start) &&
              !day.isAfter(end);
        })
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);

    expect(
      find.text(
        'Actual ${Formatters.currency(periodTotal(DateTime(now.year, now.month, 1), now, TransactionType.income))} · '
        'Anterior ${Formatters.currency(periodTotal(previousMonth, previousEnd, TransactionType.income))}',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Actual ${Formatters.currency(state.netWorthAt(now))} · '
        'Anterior ${Formatters.currency(state.netWorthAt(previousEnd))}',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('report tabs switch between flow, categories and assets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AppState(),
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: ReportsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-flow-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Ingresos y gastos por fecha'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report-categories-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Distribución por categoría'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-expense-tab')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report-assets-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Activos, tarjetas y créditos'), findsOneWidget);
    expect(find.text('Cuentas de activo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a category opens only its transactions in the period', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final now = DateTime.now();
    state.addTransaction(
      Transaction(
        id: 'category-detail-market-1',
        description: 'Compra mercado uno',
        amount: 1000,
        type: TransactionType.expense,
        date: now,
        accountId: 'banco',
        categoryId: 'comida',
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'category-detail-market-2',
        description: 'Compra mercado dos',
        amount: 2000,
        type: TransactionType.expense,
        date: now,
        accountId: 'banco',
        categoryId: 'comida',
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'category-detail-income',
        description: 'Reembolso mercado',
        amount: 500,
        type: TransactionType.income,
        date: now,
        accountId: 'banco',
        categoryId: 'comida',
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'category-detail-other',
        description: 'Carga bencina',
        amount: 4000,
        type: TransactionType.expense,
        date: now,
        accountId: 'banco',
        categoryId: 'transporte',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: ReportsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-categories-tab')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('report-category-expense-comida')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TransactionListScreen), findsOneWidget);
    expect(find.text('Comida · Gastos'), findsOneWidget);
    expect(find.text('Compra mercado uno'), findsOneWidget);
    expect(find.text('Compra mercado dos'), findsOneWidget);
    expect(find.text('Reembolso mercado'), findsNothing);
    expect(find.text('Carga bencina'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
