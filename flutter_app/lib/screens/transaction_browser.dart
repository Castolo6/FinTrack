import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../widgets/transaction_tile.dart';

/// Searchable, filterable transaction list shared by the Movements tab and
/// standalone transaction-list routes.
class TransactionBrowser extends StatefulWidget {
  final List<Transaction>? transactions;
  final bool Function(Transaction)? filter;
  final String? subtitle;
  final bool showTitle;
  final bool showTotal;

  const TransactionBrowser({
    super.key,
    this.transactions,
    this.filter,
    this.subtitle,
    this.showTitle = false,
    this.showTotal = true,
  });

  @override
  State<TransactionBrowser> createState() => _TransactionBrowserState();
}

class _TransactionBrowserState extends State<TransactionBrowser> {
  final _searchController = TextEditingController();
  String? _categoryId;
  String? _accountId;
  TransactionType? _type;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount =>
      (_searchController.text.trim().isEmpty ? 0 : 1) +
      (_categoryId == null ? 0 : 1) +
      (_accountId == null ? 0 : 1) +
      (_type == null ? 0 : 1) +
      (_dateRange == null ? 0 : 1);

  void _clearFilters() {
    setState(() {
      _categoryId = null;
      _accountId = null;
      _type = null;
      _dateRange = null;
      _searchController.clear();
    });
  }

  Future<void> _selectDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      helpText: 'Filtrar por fechas',
      saveText: 'Aplicar',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: DateUtils.dateOnly(selected.start),
        end: DateUtils.dateOnly(selected.end),
      );
    });
  }

  bool _matchesDateRange(Transaction transaction) {
    final range = _dateRange;
    if (range == null) return true;
    final date = DateUtils.dateOnly(transaction.date);
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  List<Transaction> _visibleTransactions(AppState state) {
    final query = _searchController.text.trim().toLowerCase();
    final source = widget.transactions ?? state.transactions;
    final visible = source.where((transaction) {
      if (widget.filter != null && !widget.filter!(transaction)) return false;
      if (_type != null && transaction.type != _type) return false;
      if (_categoryId != null && transaction.categoryId != _categoryId) {
        return false;
      }
      if (_accountId != null &&
          transaction.accountId != _accountId &&
          transaction.toAccountId != _accountId) {
        return false;
      }
      if (!_matchesDateRange(transaction)) return false;

      if (query.isEmpty) return true;
      final category = transaction.categoryId == null
          ? null
          : state.categoryById(transaction.categoryId!);
      final account = state.accountById(transaction.accountId);
      final destination = transaction.toAccountId == null
          ? null
          : state.accountById(transaction.toAccountId!);
      final searchable = [
        transaction.description,
        transaction.notes ?? '',
        category?.name ?? '',
        account?.name ?? '',
        destination?.name ?? '',
        transaction.type.label,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
    visible.sort((a, b) => b.date.compareTo(a.date));
    return visible;
  }

  int _totalFor(List<Transaction> transactions) =>
      transactions.fold<int>(0, (sum, transaction) {
        if (transaction.type == TransactionType.income) {
          return sum + transaction.amount;
        }
        if (transaction.type == TransactionType.expense) {
          return sum - transaction.amount;
        }
        return sum;
      });

  String _dateRangeLabel() {
    final range = _dateRange;
    if (range == null) return 'Cualquier fecha';
    return '${Formatters.date(range.start)} – ${Formatters.date(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = _visibleTransactions(state);
    final total = _totalFor(transactions);
    final categories = [...state.categories]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final accounts = [...state.accounts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return CustomScrollView(
      key: const ValueKey('transaction-browser-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showTitle || widget.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showTitle)
                          Text(
                            'Movimientos',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                TextField(
                  key: const ValueKey('transaction-search'),
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Buscar movimientos',
                    hintText: 'Descripción, categoría o cuenta',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Borrar búsqueda',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ExpansionTile(
                    key: const ValueKey('transaction-filter-expansion'),
                    leading: const Icon(Icons.filter_list),
                    title: const Text('Filtros'),
                    subtitle: Text(
                      _activeFilterCount == 0
                          ? 'Todos los movimientos'
                          : '$_activeFilterCount filtro(s) aplicado(s)',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      DropdownButtonFormField<TransactionType?>(
                        key: const ValueKey('transaction-type-filter'),
                        initialValue: _type,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: [
                          const DropdownMenuItem<TransactionType?>(
                            value: null,
                            child: Text('Todos los tipos'),
                          ),
                          ...TransactionType.values.map(
                            (type) => DropdownMenuItem<TransactionType?>(
                              value: type,
                              child: Text(type.label),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _type = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        key: const ValueKey('transaction-category-filter'),
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas las categorías'),
                          ),
                          ...categories.map(
                            (category) => DropdownMenuItem<String?>(
                              value: category.id,
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        key: const ValueKey('transaction-account-filter'),
                        initialValue: _accountId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Cuenta'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas las cuentas'),
                          ),
                          ...accounts.map(
                            (account) => DropdownMenuItem<String?>(
                              value: account.id,
                              child: Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _accountId = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('transaction-date-filter'),
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                _dateRangeLabel(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (_dateRange != null)
                            IconButton(
                              tooltip: 'Quitar rango de fechas',
                              onPressed: () =>
                                  setState(() => _dateRange = null),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: const ValueKey('transaction-clear-filters'),
                          onPressed:
                              _activeFilterCount == 0 &&
                                  _searchController.text.isEmpty
                              ? null
                              : _clearFilters,
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Limpiar filtros'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${transactions.length} '
                        '${transactions.length == 1 ? 'movimiento' : 'movimientos'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.showTotal)
                        Text(
                          Formatters.currency(total.abs()),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: total >= 0
                                ? colorScheme.primary
                                : colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (transactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.transactions.isEmpty
                      ? 'Aún no tienes movimientos registrados.'
                      : 'No hay movimientos que coincidan con la búsqueda o los filtros.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) => Card(
                key: ValueKey('transaction-${transactions[index].id}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: TransactionTile(
                  transaction: transactions[index],
                  state: state,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
