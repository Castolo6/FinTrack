import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/app_models.dart';
import 'package:flutter_app/providers/app_state.dart';

void main() {
  group('AppState financial operations', () {
    late AppState state;

    setUp(() => state = AppState());

    test(
      'card purchase increases debt and payment lowers debt and bank balance',
      () {
        expect(state.balanceFor('tarjeta'), 42000);
        expect(state.availableCreditFor('tarjeta'), 1458000);
        final bankBefore = state.balanceFor('banco');

        state.addTransaction(
          Transaction(
            id: 'pay-1',
            description: 'Pago Visa',
            amount: 10000,
            type: TransactionType.payment,
            date: DateTime(2026, 9, 20),
            accountId: 'banco',
            toAccountId: 'tarjeta',
          ),
        );

        expect(state.balanceFor('banco'), bankBefore - 10000);
        expect(state.balanceFor('tarjeta'), 32000);
        expect(state.availableCreditFor('tarjeta'), 1468000);
        expect(state.monthlyExpenses(month: DateTime(2026, 9)), 252000);
      },
    );

    test('transfer moves money without counting as expense', () {
      final bankBefore = state.balanceFor('banco');
      state.addTransaction(
        Transaction(
          id: 'transfer-1',
          description: 'Ahorro',
          amount: 50000,
          type: TransactionType.transfer,
          date: DateTime(2026, 9, 20),
          accountId: 'banco',
          toAccountId: 'efectivo',
        ),
      );

      expect(state.balanceFor('banco'), bankBefore - 50000);
      expect(state.balanceFor('efectivo'), 50000);
      expect(state.monthlyExpenses(month: DateTime(2026, 9)), 252000);
    });

    test('category budget is scoped to its month and rejects duplicates', () {
      final extra = Budget(
        id: 'budget-sep-extra',
        categoryId: 'comida',
        limit: 300000,
        month: DateTime(2026, 9),
      );
      expect(state.addBudget(extra), isFalse);

      final october = Budget(
        id: 'budget-oct',
        categoryId: 'comida',
        limit: 300000,
        month: DateTime(2026, 10),
      );
      expect(state.addBudget(october), isTrue);
      expect(state.spentForBudget(october), 0);
    });

    test(
      'goal contributions and withdrawals update progress without changing account balance',
      () {
        final before = state.balanceFor('banco');
        state.addGoalMovement(
          GoalMovement(
            id: 'goal-in',
            goalId: 'g1',
            accountId: 'banco',
            description: 'Aporte mensual',
            amount: 100000,
            date: DateTime(2026, 9, 20),
            type: GoalMovementType.contribution,
          ),
        );
        state.addGoalMovement(
          GoalMovement(
            id: 'goal-out',
            goalId: 'g1',
            accountId: 'banco',
            description: 'Retiro',
            amount: 25000,
            date: DateTime(2026, 9, 21),
            type: GoalMovementType.withdrawal,
          ),
        );

        expect(state.savedForGoal('g1'), 75000);
        expect(state.balanceFor('banco'), before);
      },
    );

    test(
      'credit installments track payments and adjust the final quota to total',
      () {
        final loan = Account(
          id: 'credito-personal',
          name: 'Crédito personal',
          type: AccountType.loan,
          openingBalance: 650000,
          installmentCount: 6,
          installmentAmount: 100000,
          firstDueDate: DateTime(2026, 10, 5),
        );
        state.addAccount(loan);

        expect(state.installmentAmountFor(loan, 1), 100000);
        expect(state.installmentAmountFor(loan, 6), 150000);
        final bankBefore = state.balanceFor('banco');
        final expensesBefore = state.monthlyExpenses(month: DateTime(2026, 9));

        expect(
          state.payLoanInstallment(
            loanAccountId: loan.id,
            installmentNumber: 1,
            paidFromAccountId: 'banco',
          ),
          isTrue,
        );
        expect(state.isLoanInstallmentPaid(loan.id, 1), isTrue);
        expect(state.balanceFor(loan.id), 550000);
        expect(state.balanceFor('banco'), bankBefore - 100000);
        expect(state.monthlyExpenses(month: DateTime(2026, 9)), expensesBefore);
        expect(
          state.payLoanInstallment(
            loanAccountId: loan.id,
            installmentNumber: 1,
            paidFromAccountId: 'banco',
          ),
          isFalse,
        );

        state.undoLoanInstallmentPayment(loan.id, 1);
        expect(state.isLoanInstallmentPaid(loan.id, 1), isFalse);
        expect(state.balanceFor(loan.id), 650000);
        expect(state.balanceFor('banco'), bankBefore);
      },
    );

    test('account with history cannot be deleted; unused account can', () {
      expect(state.deleteAccount('banco'), isFalse);
      state.addAccount(
        Account(id: 'new', name: 'Nueva cuenta', type: AccountType.bank),
      );
      expect(state.deleteAccount('new'), isTrue);
    });
  });
}
