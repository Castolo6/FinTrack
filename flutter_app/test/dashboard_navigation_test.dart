import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/app_models.dart';
import 'package:flutter_app/providers/app_state.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';
import 'package:flutter_app/screens/transaction_list_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CL', null);
  });

  testWidgets('dashboard all-transactions button opens a complete list page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    state.addTransaction(
      Transaction(
        id: 'dashboard-route-test',
        description: 'Movimiento de prueba',
        amount: 12345,
        type: TransactionType.expense,
        date: DateTime.now(),
        accountId: 'banco',
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

    await tester.tap(find.byKey(const ValueKey('dashboard-all-transactions')));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionListScreen), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Movimiento de prueba'), findsOneWidget);
    expect(find.textContaining('12.345'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
