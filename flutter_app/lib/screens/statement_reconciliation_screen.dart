import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../models/statement_charge.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../services/statement_comparison_service.dart';

class StatementReconciliationScreen extends StatefulWidget {
  const StatementReconciliationScreen({super.key});

  @override
  State<StatementReconciliationScreen> createState() =>
      _StatementReconciliationScreenState();
}

class _StatementReconciliationScreenState
    extends State<StatementReconciliationScreen> {
  final _statementController = TextEditingController();
  late DateTimeRange _dateRange;
  String? _accountId;
  StatementParseResult? _parseResult;
  ReconciliationResult? _result;
  String? _error;
  DateTimeRange? _suggestedRange;
  int _manualOutsideRange = 0;
  int _statementOutsideRange = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  void dispose() {
    _statementController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona el rango del estado de cuenta',
    );
    if (picked == null) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
      _result = null;
      _parseResult = null;
      _suggestedRange = null;
      _manualOutsideRange = 0;
      _statementOutsideRange = 0;
    });
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isInRange(DateTime date, DateTimeRange range) {
    final day = _dateOnly(date);
    return !day.isBefore(_dateOnly(range.start)) &&
        !day.isAfter(_dateOnly(range.end));
  }

  void _compare(AppState state, List<Account> cards, {DateTimeRange? range}) {
    final accountId = _accountId ?? (cards.isNotEmpty ? cards.first.id : null);
    if (accountId == null) {
      setState(
        () => _error = 'Primero agrega una tarjeta de crédito en Cuentas.',
      );
      return;
    }
    if (_statementController.text.trim().isEmpty) {
      setState(
        () => _error = 'Pega el texto del estado de cuenta para comparar.',
      );
      return;
    }

    final parsed = StatementTextParser.parse(_statementController.text);
    if (parsed.charges.isEmpty) {
      setState(() {
        _parseResult = parsed;
        _result = null;
        _suggestedRange = null;
        _manualOutsideRange = 0;
        _statementOutsideRange = 0;
        _error =
            'No reconocí cargos con fecha e importe. Pega las líneas de operaciones del estado.';
      });
      return;
    }
    final manual = state.transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.accountId == accountId,
        )
        .toList();
    final activeRange = range ?? _dateRange;
    final manualOutside = manual
        .where((transaction) => !_isInRange(transaction.date, activeRange))
        .toList();
    final statementOutside = parsed.charges
        .where((charge) => !_isInRange(charge.date, activeRange))
        .toList();

    // Suggest an expanded range for omitted manual expenses and statement
    // lines that could pair with them, not every old installment in the PDF.
    final relatedOmittedCharges = statementOutside.where(
      (charge) => manualOutside.any(
        (transaction) =>
            transaction.amount == charge.amount &&
            transaction.date.difference(charge.date).inDays.abs() <= 3,
      ),
    );
    final datesOutside = [
      ...manualOutside.map((transaction) => _dateOnly(transaction.date)),
      ...relatedOmittedCharges.map((charge) => _dateOnly(charge.date)),
    ];
    DateTimeRange? suggestedRange;
    if (datesOutside.isNotEmpty) {
      final allRangeDates = [
        _dateOnly(activeRange.start),
        _dateOnly(activeRange.end),
        ...datesOutside,
      ]..sort((a, b) => a.compareTo(b));
      suggestedRange = DateTimeRange(
        start: allRangeDates.first,
        end: allRangeDates.last,
      );
    }

    final comparison = StatementComparisonService.compare(
      manualExpenses: manual,
      statementCharges: parsed.charges,
      startDate: activeRange.start,
      endDate: activeRange.end,
    );

    setState(() {
      _accountId = accountId;
      _parseResult = parsed;
      _result = comparison;
      _error = null;
      _suggestedRange = suggestedRange;
      _manualOutsideRange = manualOutside.length;
      _statementOutsideRange = statementOutside.length;
    });
  }

  void _includeOmittedDates(AppState state, List<Account> cards) {
    final range = _suggestedRange;
    if (range == null) return;
    setState(() => _dateRange = range);
    _compare(state, cards, range: range);
  }

  Future<void> _addStatementCharge(
    AppState state,
    List<Account> cards,
    StatementCharge charge,
  ) async {
    final accountId = _accountId ?? (cards.isNotEmpty ? cards.first.id : null);
    final account = accountId == null ? null : state.accountById(accountId);
    if (account == null) return;

    final selectedCategoryId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var categoryId = '';
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Agregar gasto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${charge.merchant}\n${Formatters.date(charge.date)} · '
                  '${Formatters.currency(charge.amount)} · ${account.name}',
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: categoryId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Sin categoría'),
                        ),
                        ...state.categories.map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => categoryId = value ?? '');
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, categoryId),
                child: const Text('Agregar gasto'),
              ),
            ],
          ),
        );
      },
    );
    if (selectedCategoryId == null || !mounted) return;

    state.addTransaction(
      Transaction(
        id: const Uuid().v4(),
        description: charge.merchant,
        amount: charge.amount,
        type: TransactionType.expense,
        date: charge.date,
        accountId: account.id,
        categoryId: selectedCategoryId.isEmpty ? null : selectedCategoryId,
        notes: 'Agregado desde estado de cuenta: ${charge.rawLine}',
      ),
    );
    _compare(state, cards);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gasto agregado a tus movimientos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cards = state.accounts
        .where((account) => account.type == AccountType.creditCard)
        .toList();
    final selectedAccountId =
        _accountId ?? (cards.isNotEmpty ? cards.first.id : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparar estado de cuenta',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Compara los gastos que registraste con los cargos del estado. Esta operación no crea ni modifica movimientos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (cards.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Agrega una tarjeta de crédito para conciliar sus gastos.',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: selectedAccountId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tarjeta de crédito',
                prefixIcon: Icon(Icons.credit_card),
              ),
              items: cards
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _accountId = value;
                _result = null;
                _parseResult = null;
                _suggestedRange = null;
                _manualOutsideRange = 0;
                _statementOutsideRange = 0;
              }),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Rango de fechas',
                  prefixIcon: Icon(Icons.date_range),
                ),
                child: Text(
                  '${Formatters.date(_dateRange.start)} – ${Formatters.date(_dateRange.end)}',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _statementController,
            minLines: 7,
            maxLines: 14,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => setState(() {
              _result = null;
              _parseResult = null;
              _error = null;
              _suggestedRange = null;
              _manualOutsideRange = 0;
              _statementOutsideRange = 0;
            }),
            decoration: const InputDecoration(
              labelText: 'Texto del estado de cuenta',
              hintText:
                  'Pega aquí las líneas de cargos del estado...\nSANTIAGO 03/09/2026 PAYU *UBER EATS - CLP 12.460',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.content_paste),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compara el importe facturado en CLP. Las compras internacionales se comparan usando su cargo final en pesos. Por ahora, copia y pega el texto del estado; la carga directa de PDF queda pendiente.',
            style: theme.textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(message: _error!, color: colorScheme.error),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cards.isEmpty ? null : () => _compare(state, cards),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Comparar gastos'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultSummary(result: _result!),
            if (_manualOutsideRange > 0 || _statementOutsideRange > 0) ...[
              const SizedBox(height: 8),
              _InlineMessage(
                message:
                    'Fuera del rango: $_statementOutsideRange cargos del estado y $_manualOutsideRange gastos registrados. Por eso no participan en esta comparación.',
                color: colorScheme.primary,
              ),
              if (_suggestedRange != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _includeOmittedDates(state, cards),
                    icon: const Icon(Icons.date_range),
                    label: const Text('Ampliar rango para incluirlos'),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            if (_parseResult!.skippedLines > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Se leyeron ${_parseResult!.charges.length} cargos; se omitieron ${_parseResult!.skippedLines} líneas que no parecían operaciones.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            _ResultSection(
              title: 'Coinciden',
              icon: Icons.check_circle_outline,
              color: colorScheme.tertiary,
              rows: _result!.matches,
            ),
            _ResultSection(
              title: 'Posibles coincidencias · revisar',
              icon: Icons.help_outline,
              color: colorScheme.primary,
              rows: _result!.possible,
            ),
            _ResultSection(
              title: 'Solo en el estado de cuenta',
              icon: Icons.receipt_long,
              color: colorScheme.error,
              rows: _result!.statementOnly,
              onAddCharge: (charge) =>
                  _addStatementCharge(state, cards, charge),
            ),
            _ResultSection(
              title: 'Solo en mis gastos registrados',
              icon: Icons.edit_note,
              color: colorScheme.error,
              rows: _result!.manualOnly,
            ),
            const SizedBox(height: 8),
            const _InlineMessage(
              message:
                  'La comparación no agrega movimientos automáticamente. Solo se registran los cargos que confirmes con “Agregar a la app”.',
              color: Colors.blueGrey,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final ReconciliationResult result;

  const _ResultSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final counts = [
      ('Coinciden', result.matches.length, colorScheme.tertiary),
      ('Revisar', result.possible.length, colorScheme.primary),
      ('Solo estado', result.statementOnly.length, colorScheme.error),
      ('Solo registro', result.manualOnly.length, colorScheme.error),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : 4;
        final itemWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: counts
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.$2}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: item.$3,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<ReconciliationRow> rows;
  final ValueChanged<StatementCharge>? onAddCharge;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
    this.onAddCharge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${rows.length}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
        children: rows.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text('No hay elementos en esta sección.'),
                ),
              ]
            : rows
                  .map(
                    (row) => _ComparisonRow(
                      row: row,
                      statusColor: color,
                      onAddCharge: onAddCharge,
                    ),
                  )
                  .toList(),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final ReconciliationRow row;
  final Color statusColor;
  final ValueChanged<StatementCharge>? onAddCharge;

  const _ComparisonRow({
    required this.row,
    required this.statusColor,
    this.onAddCharge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final charge = row.statementCharge;
    final manual = row.manualTransaction;

    Widget line(String label, String description, DateTime date, int amount) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 82,
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            Expanded(
              child: Text(
                '${Formatters.dateShort(date)} · $description',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Formatters.currency(amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (charge != null)
            line('Estado', charge.merchant, charge.date, charge.amount),
          if (manual != null)
            line('Registrado', manual.description, manual.date, manual.amount),
          if (row.status == ReconciliationStatus.statementOnly &&
              charge != null &&
              onAddCharge != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => onAddCharge!(charge),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar a la app'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(
            color: theme.colorScheme.outline.withValues(alpha: 0.35),
            height: 1,
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final Color color;

  const _InlineMessage({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
