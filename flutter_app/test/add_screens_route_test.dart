import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/app_state.dart';
import 'package:flutter_app/screens/accounts_screen.dart';
import 'package:flutter_app/screens/add_account_screen.dart';
import 'package:flutter_app/screens/add_budget_screen.dart';
import 'package:flutter_app/screens/add_category_screen.dart';
import 'package:flutter_app/screens/add_goal_screen.dart';
import 'package:flutter_app/screens/add_transaction_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CL', null);
  });

  // Mirrors the real app tree: the provider sits above MaterialApp, so routes
  // pushed on the root navigator can still read AppState.
  Future<AppState> pumpApp(WidgetTester tester, {required Widget home}) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('add account screen opens from the accounts list', (
    tester,
  ) async {
    await pumpApp(tester, home: const Scaffold(body: AccountsScreen()));

    await tester.tap(find.text('Añadir cuenta, tarjeta o activo'));
    await tester.pumpAndSettle();

    expect(find.byType(AddAccountScreen), findsOneWidget);
    expect(find.text('Añadir cuenta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add screens pushed on the root navigator find AppState', (
    tester,
  ) async {
    final state = await pumpApp(
      tester,
      home: const Scaffold(body: AccountsScreen()),
    );
    final rootContext = tester.element(find.byType(AccountsScreen));
    final navigator = rootContext.findAncestorStateOfType<NavigatorState>()!;

    final cases = <(Type, Widget)>[
      (AddBudgetScreen, const AddBudgetScreen()),
      (AddCategoryScreen, const AddCategoryScreen()),
      (AddGoalScreen, const AddGoalScreen()),
      (AddTransactionScreen, const AddTransactionScreen()),
    ];

    for (final (type, screen) in cases) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
      await tester.pumpAndSettle();

      expect(find.byType(type), findsOneWidget);
      expect(tester.takeException(), isNull);

      navigator.pop();
      await tester.pumpAndSettle();
    }

    expect(state.isDisposed, isFalse);
  });
}
