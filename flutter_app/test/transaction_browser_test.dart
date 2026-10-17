import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/app_models.dart';
import 'package:flutter_app/providers/app_state.dart';
import 'package:flutter_app/screens/transaction_browser.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CL', null);
  });

  Future<AppState> pumpBrowser(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    state.addTransaction(
      Transaction(
        id: 'filter-comida',
        description: 'FilterMarker compra',
        amount: 12000,
        type: TransactionType.expense,
        date: DateTime(2026, 10, 2),
        accountId: 'banco',
        categoryId: 'comida',
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'filter-salud',
        description: 'FilterMarker farmacia',
        amount: 8000,
        type: TransactionType.income,
        date: DateTime(2026, 10, 10),
        accountId: 'efectivo',
        categoryId: 'salud',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: TransactionBrowser()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('search filters transactions by description as the user types', (
    tester,
  ) async {
    await pumpBrowser(tester);

    await tester.enterText(
      find.byKey(const ValueKey('transaction-search')),
      'FilterMarker',
    );
    await tester.pumpAndSettle();

    expect(find.text('FilterMarker compra'), findsOneWidget);
    expect(find.text('FilterMarker farmacia'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('transaction-search')),
      'farmacia',
    );
    await tester.pumpAndSettle();

    expect(find.text('FilterMarker compra'), findsNothing);
    expect(find.text('FilterMarker farmacia'), findsOneWidget);
  });

  testWidgets(
    'category, account and type filters can be combined and cleared',
    (tester) async {
      await pumpBrowser(tester);
      await tester.tap(
        find.byKey(const ValueKey('transaction-filter-expansion')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('transaction-category-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comida').last);
      await tester.pumpAndSettle();

      expect(find.text('FilterMarker compra'), findsOneWidget);
      expect(find.text('FilterMarker farmacia'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('transaction-account-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Efectivo').last);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No hay movimientos que coincidan con la búsqueda o los filtros.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('transaction-clear-filters')));
      await tester.pumpAndSettle();
      expect(find.text('FilterMarker compra'), findsOneWidget);
      expect(find.text('FilterMarker farmacia'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('transaction-type-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingreso').last);
      await tester.pumpAndSettle();
      expect(find.text('FilterMarker compra'), findsNothing);
      expect(find.text('FilterMarker farmacia'), findsOneWidget);
    },
  );

  testWidgets('date filter opens a configurable inclusive range picker', (
    tester,
  ) async {
    await pumpBrowser(tester);
    await tester.tap(
      find.byKey(const ValueKey('transaction-filter-expansion')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('transaction-date-filter')));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
