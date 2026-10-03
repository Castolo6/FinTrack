import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/app_models.dart';
import 'package:flutter_app/providers/app_state.dart';
import 'package:flutter_app/screens/reports_screen.dart';

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

    expect(find.text('Distribución por categoría'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-expense-tab')), findsOneWidget);
    expect(find.text('Comida'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('report-income-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Servicios'), findsOneWidget);
    expect(find.textContaining('300.000'), findsNWidgets(2));
  });
}
