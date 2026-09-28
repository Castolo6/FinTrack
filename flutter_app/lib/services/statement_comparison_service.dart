import '../models/app_models.dart';
import '../models/statement_charge.dart';

/// Parses the text layer of Chilean card statements. The final CLP amount on
/// each dated line is used (for foreign purchases, this is the billed amount).
class StatementTextParser {
  StatementTextParser._();

  static final _datePattern = RegExp(r'\b(\d{2})/(\d{2})/(\d{4})\b');
  static final _moneyPattern = RegExp(r'\$\s*([0-9][0-9.]*(?:,[0-9]{1,2})?)');
  static final _foreignAmountSuffix = RegExp(
    r'\s+\b(?:US|USD|CL|CLP)\s*[\d.,]+\s*$',
    caseSensitive: false,
  );

  static StatementParseResult parse(String text) {
    final charges = <StatementCharge>[];
    final skippedExamples = <String>[];
    var skippedLines = 0;
    final lines = text.split(RegExp(r'\r?\n'));

    for (var index = 0; index < lines.length; index++) {
      final raw = lines[index].trim();
      if (raw.isEmpty) continue;

      final dateMatch = _datePattern.firstMatch(raw);
      final moneyMatches = _moneyPattern.allMatches(raw).toList();
      if (dateMatch == null || moneyMatches.isEmpty) {
        // Headings are expected; only retain a few for a useful parse report.
        if (skippedExamples.length < 3 &&
            (dateMatch != null || raw.contains(r'$'))) {
          skippedExamples.add(raw);
        }
        skippedLines++;
        continue;
      }

      final day = int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      final year = int.parse(dateMatch.group(3)!);
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        skippedLines++;
        continue;
      }

      // The last currency value represents the amount charged in CLP on the
      // statement, including lines that also show a foreign-currency amount.
      final moneyMatch = moneyMatches.last;
      final amountText = moneyMatch.group(1)!;
      final amount = _parseChileanPesos(amountText);
      final merchantStart = dateMatch.end;
      final merchantEnd = moneyMatch.start;
      if (amount <= 0 || merchantEnd <= merchantStart) {
        skippedLines++;
        continue;
      }

      var merchant = raw.substring(merchantStart, merchantEnd).trim();
      merchant = merchant.replaceFirst(_foreignAmountSuffix, '').trim();
      merchant = merchant.replaceAll(RegExp(r'\s+'), ' ');
      if (merchant.isEmpty) {
        skippedLines++;
        continue;
      }

      charges.add(
        StatementCharge(
          lineNumber: index + 1,
          date: date,
          merchant: merchant,
          amount: amount,
          rawLine: raw,
        ),
      );
    }

    return StatementParseResult(
      charges: List.unmodifiable(charges),
      skippedLines: skippedLines,
      skippedExamples: List.unmodifiable(skippedExamples),
    );
  }

  static int _parseChileanPesos(String value) {
    // Chilean statements use dots for thousands; commas, if present, are
    // fractional currency digits and are discarded for CLP comparisons.
    final wholePesos = value.split(',').first.replaceAll('.', '');
    return int.tryParse(wholePesos) ?? 0;
  }
}

class StatementComparisonService {
  StatementComparisonService._();

  static ReconciliationResult compare({
    required List<Transaction> manualExpenses,
    required List<StatementCharge> statementCharges,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final manual =
        manualExpenses
            .where(
              (transaction) =>
                  transaction.type == TransactionType.expense &&
                  _isWithinRange(transaction.date, start, end),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final statement =
        statementCharges
            .where((charge) => _isWithinRange(charge.date, start, end))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final usedManualIds = <String>{};
    final matched = <ReconciliationRow>[];
    final possible = <ReconciliationRow>[];
    final statementOnly = <ReconciliationRow>[];

    // A confirmed match requires the same date, amount and description.
    // Description normalization ignores case, accents and punctuation only.
    for (final charge in statement) {
      final candidates =
          manual
              .where(
                (transaction) =>
                    !usedManualIds.contains(transaction.id) &&
                    transaction.amount == charge.amount &&
                    _sameDay(transaction.date, charge.date) &&
                    _sameDescription(transaction.description, charge.merchant),
              )
              .toList()
            ..sort(
              (a, b) => _merchantSimilarity(
                b.description,
                charge.merchant,
              ).compareTo(_merchantSimilarity(a.description, charge.merchant)),
            );

      if (candidates.isNotEmpty) {
        final transaction = candidates.first;
        usedManualIds.add(transaction.id);
        matched.add(
          ReconciliationRow(
            status: ReconciliationStatus.matched,
            statementCharge: charge,
            manualTransaction: transaction,
          ),
        );
      }
    }

    // Same date and amount with a different description is only a suggestion.
    // Suggestions are never confirmed automatically.
    for (final charge in statement) {
      if (matched.any(
        (row) => row.statementCharge?.lineNumber == charge.lineNumber,
      )) {
        continue;
      }
      final candidates =
          manual.where((transaction) {
            if (usedManualIds.contains(transaction.id) ||
                transaction.amount != charge.amount) {
              return false;
            }
            return _sameDay(transaction.date, charge.date);
          }).toList()..sort((a, b) {
            final scoreDifference = _merchantSimilarity(
              b.description,
              charge.merchant,
            ).compareTo(_merchantSimilarity(a.description, charge.merchant));
            return scoreDifference;
          });

      if (candidates.isEmpty) {
        statementOnly.add(
          ReconciliationRow(
            status: ReconciliationStatus.statementOnly,
            statementCharge: charge,
          ),
        );
      } else {
        final transaction = candidates.first;
        usedManualIds.add(transaction.id);
        possible.add(
          ReconciliationRow(
            status: ReconciliationStatus.possible,
            statementCharge: charge,
            manualTransaction: transaction,
          ),
        );
      }
    }

    final manualOnly = manual
        .where((transaction) => !usedManualIds.contains(transaction.id))
        .map(
          (transaction) => ReconciliationRow(
            status: ReconciliationStatus.manualOnly,
            manualTransaction: transaction,
          ),
        )
        .toList();

    return ReconciliationResult(
      matches: List.unmodifiable(matched),
      possible: List.unmodifiable(possible),
      statementOnly: List.unmodifiable(statementOnly),
      manualOnly: List.unmodifiable(manualOnly),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _sameDescription(String first, String second) =>
      _normalize(first) == _normalize(second);

  static bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static double _merchantSimilarity(String first, String second) {
    final a = _normalize(first);
    final b = _normalize(second);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (a.contains(b) || b.contains(a)) return 0.82;

    final tokensA = _tokens(first);
    final tokensB = _tokens(second);
    if (tokensA.isEmpty || tokensB.isEmpty) return 0;
    final common = tokensA.intersection(tokensB).length;
    if (common == 0) return 0;
    return common / tokensA.union(tokensB).length;
  }

  static String _normalize(String value) => _withoutAccents(value.toUpperCase())
      .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static Set<String> _tokens(String value) {
    final normalized = _withoutAccents(value.toUpperCase());
    return RegExp(r'[A-Z0-9]+')
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .where((token) => token.length > 1)
        .toSet();
  }

  static String _withoutAccents(String value) {
    const replacements = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };
    var result = value;
    replacements.forEach((from, to) => result = result.replaceAll(from, to));
    return result;
  }
}
