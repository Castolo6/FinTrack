import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/statement_charge.dart';
import 'package:flutter_app/models/transaction.dart';
import 'package:flutter_app/services/statement_comparison_service.dart';

void main() {
  group('StatementTextParser', () {
    test(
      'parses Chilean CLP amounts and foreign purchases billed in pesos',
      () {
        const text = '''
2. PERIODO ACTUAL
SANTIAGO 28/08/2026 MAUDI SPA \$ 28.000
SANTIAGO 03/09/2026 PAYU *UBER EATS \$ 12.460
ANTHROPIC.CO 13/09/2026 ANTHROPIC* CLAUDE SUB US 23,80 \$ 22.978
866-712-7753 22/09/2026 APPLE.COM/BILL CL 3.290,00 \$ 3.290
''';

        final result = StatementTextParser.parse(text);

        expect(result.charges, hasLength(4));
        expect(result.charges[0].date, DateTime(2026, 8, 28));
        expect(result.charges[0].amount, 28000);
        expect(result.charges[0].merchant, 'MAUDI SPA');
        expect(result.charges[1].amount, 12460);
        expect(result.charges[1].merchant, 'PAYU *UBER EATS');
        expect(result.charges[2].amount, 22978);
        expect(result.charges[2].merchant, 'ANTHROPIC* CLAUDE SUB');
        expect(result.charges[3].amount, 3290);
        expect(result.charges[3].merchant, 'APPLE.COM/BILL');
      },
    );
  });

  group('StatementComparisonService', () {
    test(
      'matches the reported MAUDI purchase when its date is inside the range',
      () {
        final parsed = StatementTextParser.parse(
          r'SANTIAGO 28/08/2026 MAUDI SPA $ 28.000',
        );
        final manual = [
          Transaction(
            id: 'manual-maudi',
            description: 'MAUDI SPA',
            amount: 28000,
            type: TransactionType.expense,
            date: DateTime(2026, 8, 28),
            accountId: 'visa',
          ),
        ];

        final result = StatementComparisonService.compare(
          manualExpenses: manual,
          statementCharges: parsed.charges,
          startDate: DateTime(2026, 8, 28),
          endDate: DateTime(2026, 9, 24),
        );

        expect(result.matches, hasLength(1));
        expect(result.statementOnly, isEmpty);
        expect(result.manualOnly, isEmpty);
      },
    );

    test(
      'suggests a match when date and amount match but merchant differs',
      () {
        final parsed = StatementTextParser.parse(
          r'SANTIAGO 03/09/2026 PAYU *UBER EATS $ 12.460',
        );
        final manual = [
          Transaction(
            id: 'manual-uber',
            description: 'Uber Eats',
            amount: 12460,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 3),
            accountId: 'visa',
          ),
        ];

        final result = StatementComparisonService.compare(
          manualExpenses: manual,
          statementCharges: parsed.charges,
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
        );

        expect(parsed.charges, hasLength(1));
        expect(result.matches, isEmpty);
        expect(result.possible, hasLength(1));
        expect(result.statementOnly, isEmpty);
        expect(result.manualOnly, isEmpty);
      },
    );

    test(
      'matches by date, amount and merchant and leaves unmatched lines separate',
      () {
        final manual = [
          Transaction(
            id: 'manual-1',
            description: 'PAYU *UBER EATS',
            amount: 12460,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 3),
            accountId: 'visa',
          ),
          Transaction(
            id: 'manual-2',
            description: 'Cine',
            amount: 20000,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 7),
            accountId: 'visa',
          ),
        ];
        final charges = [
          StatementCharge(
            lineNumber: 1,
            date: DateTime(2026, 9, 3),
            merchant: 'PAYU *UBER EATS',
            amount: 12460,
            rawLine: 'SANTIAGO 03/09/2026 PAYU *UBER EATS \$ 12.460',
          ),
          StatementCharge(
            lineNumber: 2,
            date: DateTime(2026, 9, 4),
            merchant: 'APPLE.COM/BILL',
            amount: 3290,
            rawLine: 'SANTIAGO 04/09/2026 APPLE.COM/BILL \$ 3.290',
          ),
        ];

        final result = StatementComparisonService.compare(
          manualExpenses: manual,
          statementCharges: charges,
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
        );

        expect(result.matches, hasLength(1));
        expect(result.statementOnly, hasLength(1));
        expect(result.manualOnly, hasLength(1));
        expect(result.possible, isEmpty);
      },
    );

    test('uses a one-to-one match for duplicate charges', () {
      final manual = [
        Transaction(
          id: 'manual-1',
          description: 'Uber Eats',
          amount: 12460,
          type: TransactionType.expense,
          date: DateTime(2026, 9, 3),
          accountId: 'visa',
        ),
      ];
      final charges = List.generate(
        2,
        (index) => StatementCharge(
          lineNumber: index + 1,
          date: DateTime(2026, 9, 3),
          merchant: 'PAYU *UBER EATS',
          amount: 12460,
          rawLine: 'PAYU *UBER EATS \$ 12.460',
        ),
      );

      final result = StatementComparisonService.compare(
        manualExpenses: manual,
        statementCharges: charges,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      expect(result.matches, isEmpty);
      expect(result.possible, hasLength(1));
      expect(result.statementOnly, hasLength(1));
      expect(result.manualOnly, isEmpty);
    });

    test(
      'flags a same-date and amount match with a different merchant for review',
      () {
        final manual = [
          Transaction(
            id: 'manual-1',
            description: 'Compra local',
            amount: 11000,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 21),
            accountId: 'visa',
          ),
        ];
        final charges = [
          StatementCharge(
            lineNumber: 1,
            date: DateTime(2026, 9, 21),
            merchant: 'MERPAGO*KRISPYKREME',
            amount: 11000,
            rawLine: r'LAS CONDES 21/09/2026 MERPAGO*KRISPYKREME $ 11.000',
          ),
        ];

        final result = StatementComparisonService.compare(
          manualExpenses: manual,
          statementCharges: charges,
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
        );

        expect(result.possible, hasLength(1));
        expect(result.matches, isEmpty);
      },
    );

    test(
      'includes both range boundaries and excludes dates outside the range',
      () {
        final manual = [
          Transaction(
            id: 'before',
            description: 'Compra antes',
            amount: 1000,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 9),
            accountId: 'visa',
          ),
          Transaction(
            id: 'start',
            description: 'Compra inicio',
            amount: 2000,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 10),
            accountId: 'visa',
          ),
          Transaction(
            id: 'end',
            description: 'Compra fin',
            amount: 3000,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 20),
            accountId: 'visa',
          ),
          Transaction(
            id: 'after',
            description: 'Compra después',
            amount: 4000,
            type: TransactionType.expense,
            date: DateTime(2026, 9, 21),
            accountId: 'visa',
          ),
        ];
        final charges = [
          StatementCharge(
            lineNumber: 1,
            date: DateTime(2026, 9, 9),
            merchant: 'Compra antes',
            amount: 1000,
            rawLine: 'Compra antes',
          ),
          StatementCharge(
            lineNumber: 2,
            date: DateTime(2026, 9, 10),
            merchant: 'Compra inicio',
            amount: 2000,
            rawLine: 'Compra inicio',
          ),
          StatementCharge(
            lineNumber: 3,
            date: DateTime(2026, 9, 20),
            merchant: 'Compra fin',
            amount: 3000,
            rawLine: 'Compra fin',
          ),
          StatementCharge(
            lineNumber: 4,
            date: DateTime(2026, 9, 21),
            merchant: 'Compra después',
            amount: 4000,
            rawLine: 'Compra después',
          ),
        ];

        final result = StatementComparisonService.compare(
          manualExpenses: manual,
          statementCharges: charges,
          startDate: DateTime(2026, 9, 10),
          endDate: DateTime(2026, 9, 20),
        );

        expect(result.matches, hasLength(2));
        expect(result.statementOnly, isEmpty);
        expect(result.manualOnly, isEmpty);
      },
    );
  });
}
