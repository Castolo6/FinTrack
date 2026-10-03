import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/responsive_scaffold.dart';

void main() {
  List<AppDestination> destinations() => [
    AppDestination(
      label: 'Resumen',
      icon: Icons.dashboard_outlined,
      screen: const Text('Resumen screen'),
    ),
    AppDestination(
      label: 'Cuentas',
      icon: Icons.account_balance_wallet_outlined,
      screen: const Text('Cuentas screen'),
    ),
    AppDestination(
      label: 'Movimientos',
      icon: Icons.receipt_long_outlined,
      screen: const Text('Movimientos screen'),
    ),
    AppDestination(
      label: 'Presupuestos',
      icon: Icons.pie_chart_outline,
      screen: const Text('Presupuestos screen'),
    ),
  ];

  Future<void> pumpHome(
    WidgetTester tester, {
    required double width,
    required VoidCallback onOpenProfile,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScaffold(
          title: 'FinTrack',
          destinations: destinations(),
          onOpenProfile: onOpenProfile,
          onSignOut: () {},
          floatingActionButton: FloatingActionButton(onPressed: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile app bar shows profile icon next to add and sign out', (
    tester,
  ) async {
    var opened = false;
    await pumpHome(tester, width: 400, onOpenProfile: () => opened = true);

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('desktop app bar shows profile icon next to sign out', (
    tester,
  ) async {
    var opened = false;
    await pumpHome(tester, width: 1000, onOpenProfile: () => opened = true);

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('profile icon is absent when no callback is provided', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScaffold(
          title: 'FinTrack',
          destinations: destinations(),
          onSignOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsNothing);
  });
}
