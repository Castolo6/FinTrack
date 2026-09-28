import 'transaction.dart';

class StatementCharge {
  final int lineNumber;
  final DateTime date;
  final String merchant;
  final int amount;
  final String rawLine;

  const StatementCharge({
    required this.lineNumber,
    required this.date,
    required this.merchant,
    required this.amount,
    required this.rawLine,
  });
}

class StatementParseResult {
  final List<StatementCharge> charges;
  final int skippedLines;
  final List<String> skippedExamples;

  const StatementParseResult({
    required this.charges,
    required this.skippedLines,
    required this.skippedExamples,
  });
}

enum ReconciliationStatus { matched, possible, statementOnly, manualOnly }

class ReconciliationRow {
  final ReconciliationStatus status;
  final StatementCharge? statementCharge;
  final Transaction? manualTransaction;

  const ReconciliationRow({
    required this.status,
    this.statementCharge,
    this.manualTransaction,
  });
}

class ReconciliationResult {
  final List<ReconciliationRow> matches;
  final List<ReconciliationRow> possible;
  final List<ReconciliationRow> statementOnly;
  final List<ReconciliationRow> manualOnly;

  const ReconciliationResult({
    required this.matches,
    required this.possible,
    required this.statementOnly,
    required this.manualOnly,
  });
}
