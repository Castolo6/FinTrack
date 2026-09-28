import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/app_models.dart';
import 'package:flutter_app/providers/app_state.dart';
import 'package:flutter_app/screens/statement_reconciliation_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CL', null);
  });

  testWidgets('statement-only charge can be added with a selected category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final today = DateTime.now();
    final date =
        '${today.day.toString().padLeft(2, '0')}/'
        '${today.month.toString().padLeft(2, '0')}/${today.year}';

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: StatementReconciliationScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'SANTIAGO $date TIENDA PRUEBA '
      r'$ 12.345',
    );
    await tester.ensureVisible(find.text('Comparar gastos'));
    await tester.tap(find.text('Comparar gastos'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Solo en el estado de cuenta'));
    await tester.tap(find.text('Solo en el estado de cuenta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Agregar a la app'));
    await tester.tap(find.text('Agregar a la app'));
    await tester.pumpAndSettle();

    final dropdowns = find.byType(DropdownButton<String>);
    expect(dropdowns, findsWidgets);
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comida').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Agregar gasto').last);
    await tester.pumpAndSettle();

    final added = state.transactions.singleWhere(
      (transaction) => transaction.description == 'TIENDA PRUEBA',
    );
    expect(added.amount, 12345);
    expect(added.type, TransactionType.expense);
    expect(added.accountId, 'tarjeta');
    expect(added.categoryId, 'comida');
    expect(added.date.year, today.year);
    expect(added.date.month, today.month);
    expect(added.date.day, today.day);
  });
}
