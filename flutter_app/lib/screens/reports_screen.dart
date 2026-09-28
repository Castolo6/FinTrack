import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import 'account_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late DateTimeRange _range;
  late TabController _categoryTabController;

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona el periodo de los reportes',
    );
    if (range != null) {
      setState(() {
        _range = DateTimeRange(
          start: DateTime(range.start.year, range.start.month, range.start.day),
          end: DateTime(range.end.year, range.end.month, range.end.day),
        );
      });
    }
  }

  bool _inRange(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(_range.start) && !day.isAfter(_range.end);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = state.transactions
        .where((transaction) => _inRange(transaction.date))
        .toList();
    final income = transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final expenses = transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final expensesByCategory = <String, int>{};
    for (final transaction in transactions.where(
      (transaction) => transaction.type == TransactionType.expense,
    )) {
      final id = transaction.categoryId ?? 'uncategorized';
      expensesByCategory.update(
        id,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final incomeByCategory = <String, int>{};
    for (final transaction in transactions.where(
      (transaction) => transaction.type == TransactionType.income,
    )) {
      final id = transaction.categoryId ?? 'uncategorized';
      incomeByCategory.update(
        id,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final sortedIncomeCategories = incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final showingIncomeCategories = _categoryTabController.index == 1;
    final displayedCategories = showingIncomeCategories
        ? sortedIncomeCategories
        : sortedCategories;
    final timeline = _buildTimeline(transactions);
    final insights = _buildInsights(
      state,
      income: income,
      expenses: expenses,
      categories: sortedCategories,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportes',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu panorama financiero en el periodo seleccionado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickRange,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Rango de fechas',
                prefixIcon: Icon(Icons.date_range),
              ),
              child: Text(
                '${Formatters.date(_range.start)} – ${Formatters.date(_range.end)}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _HealthSummary(
            income: income,
            expenses: expenses,
            netWorth: state.netWorth,
            topCategory: sortedCategories.isEmpty
                ? null
                : sortedCategories.first,
            categoryName: sortedCategories.isEmpty
                ? null
                : _categoryName(state, sortedCategories.first.key),
          ),
          const SizedBox(height: 12),
          _InsightsCard(insights: insights),
          const SizedBox(height: 24),
          _SectionHeading(title: 'Ingresos y gastos por fecha'),
          const SizedBox(height: 8),
          _TimelineChart(buckets: timeline),
          const SizedBox(height: 24),
          _SectionHeading(title: 'Distribución por categoría'),
          const SizedBox(height: 4),
          TabBar(
            controller: _categoryTabController,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(key: ValueKey('report-expense-tab'), text: 'Gastos'),
              Tab(key: ValueKey('report-income-tab'), text: 'Ingresos'),
            ],
          ),
          const SizedBox(height: 8),
          if (displayedCategories.isEmpty)
            _EmptyCard(
              message: showingIncomeCategories
                  ? 'No hay ingresos categorizados en este rango.'
                  : 'No hay gastos categorizados en este rango.',
            )
          else ...[
            _CategoryChart(
              entries: displayedCategories,
              categoryName: (id) => _categoryName(state, id),
              categoryColor: (id) => _categoryColor(state, id, colorScheme),
            ),
            const SizedBox(height: 8),
            ...displayedCategories.map((entry) {
              final category = state.categoryById(entry.key);
              final displayedTotal = showingIncomeCategories
                  ? income
                  : expenses;
              final share = displayedTotal > 0
                  ? entry.value / displayedTotal
                  : 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _categoryColor(
                      state,
                      entry.key,
                      colorScheme,
                    ).withValues(alpha: 0.16),
                    child: Icon(
                      category?.icon ?? Icons.category_outlined,
                      color: _categoryColor(state, entry.key, colorScheme),
                    ),
                  ),
                  title: Text(_categoryName(state, entry.key)),
                  subtitle: Text(
                    '${(share * 100).toStringAsFixed(0)}% de tus ${showingIncomeCategories ? 'ingresos' : 'gastos'}',
                  ),
                  trailing: Text(
                    Formatters.currency(entry.value),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          _SectionHeading(title: 'Activos, tarjetas y créditos'),
          const SizedBox(height: 8),
          _BalanceCard(state: state),
          const SizedBox(height: 24),
          _SectionHeading(title: 'Cuentas de activo'),
          const SizedBox(height: 8),
          ...state.accounts
              .where((account) => account.isAsset)
              .map(
                (account) => _AccountReportTile(account: account, state: state),
              ),
          const SizedBox(height: 16),
          _SectionHeading(title: 'Tarjetas y créditos'),
          const SizedBox(height: 8),
          ...state.accounts
              .where((account) => account.isLiability)
              .map(
                (account) => _AccountReportTile(account: account, state: state),
              ),
          const SizedBox(height: 12),
          const _InfoNote(
            text:
                'Las transferencias y pagos de deuda no se cuentan como egresos. Se cuentan los gastos originales para evitar duplicarlos.',
          ),
        ],
      ),
    );
  }

  String _categoryName(AppState state, String id) => id == 'uncategorized'
      ? 'Sin categoría'
      : state.categoryById(id)?.name ?? 'Sin categoría';

  Color _categoryColor(AppState state, String id, ColorScheme colorScheme) =>
      state.categoryById(id)?.color ?? colorScheme.outline;

  List<_PeriodBucket> _buildTimeline(List<Transaction> transactions) {
    final totalDays = _range.end.difference(_range.start).inDays + 1;
    final mode = totalDays <= 31
        ? _TimelineMode.day
        : totalDays <= 120
        ? _TimelineMode.week
        : _TimelineMode.month;
    final count = switch (mode) {
      _TimelineMode.day => totalDays,
      _TimelineMode.week => (totalDays / 7).ceil(),
      _TimelineMode.month =>
        (_range.end.year - _range.start.year) * 12 +
            _range.end.month -
            _range.start.month +
            1,
    };
    final buckets = List.generate(count, (index) {
      final date = switch (mode) {
        _TimelineMode.day => _range.start.add(Duration(days: index)),
        _TimelineMode.week => _range.start.add(Duration(days: index * 7)),
        _TimelineMode.month => DateTime(
          _range.start.year,
          _range.start.month + index,
        ),
      };
      return _PeriodBucket(date: date, income: 0, expenses: 0);
    });

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.income &&
          transaction.type != TransactionType.expense) {
        continue;
      }
      final index = switch (mode) {
        _TimelineMode.day => transaction.date.difference(_range.start).inDays,
        _TimelineMode.week =>
          transaction.date.difference(_range.start).inDays ~/ 7,
        _TimelineMode.month =>
          (transaction.date.year - _range.start.year) * 12 +
              transaction.date.month -
              _range.start.month,
      };
      if (index < 0 || index >= buckets.length) continue;
      final current = buckets[index];
      buckets[index] = transaction.type == TransactionType.income
          ? current.copyWith(income: current.income + transaction.amount)
          : current.copyWith(expenses: current.expenses + transaction.amount);
    }
    return buckets;
  }

  List<_Insight> _buildInsights(
    AppState state, {
    required int income,
    required int expenses,
    required List<MapEntry<String, int>> categories,
  }) {
    final insights = <_Insight>[];
    if (income == 0 && expenses == 0) {
      insights.add(
        const _Insight(
          title: 'Aún no hay actividad',
          description:
              'Registra ingresos y gastos para recibir observaciones financieras.',
          icon: Icons.lightbulb_outline,
          tone: _InsightTone.neutral,
        ),
      );
    } else if (expenses > income) {
      insights.add(
        _Insight(
          title: 'Tus gastos superan tus ingresos',
          description:
              'La diferencia del periodo es ${Formatters.currency(expenses - income)}. Revisa gastos variables y próximos pagos.',
          icon: Icons.warning_amber_rounded,
          tone: _InsightTone.warning,
        ),
      );
    } else if (income > expenses) {
      insights.add(
        _Insight(
          title: 'Flujo positivo',
          description:
              'Te quedan ${Formatters.currency(income - expenses)} después de los gastos registrados en este periodo.',
          icon: Icons.check_circle_outline,
          tone: _InsightTone.positive,
        ),
      );
    }

    if (categories.isNotEmpty && expenses > 0) {
      final top = categories.first;
      final share = top.value / expenses;
      if (share >= 0.3) {
        insights.add(
          _Insight(
            title: 'Mayor gasto: ${_categoryName(state, top.key)}',
            description:
                'Representa ${(share * 100).toStringAsFixed(0)}% de tus egresos (${Formatters.currency(top.value)}). Revisa si puedes ajustar ese presupuesto.',
            icon: Icons.pie_chart_outline,
            tone: _InsightTone.warning,
          ),
        );
      }
    }

    final fullMonthBudgets = state.budgets.where((budget) {
      final monthStart = DateTime(budget.month.year, budget.month.month, 1);
      final monthEnd = DateTime(budget.month.year, budget.month.month + 1, 0);
      return !monthStart.isBefore(_range.start) &&
          !monthEnd.isAfter(_range.end);
    });
    for (final budget in fullMonthBudgets) {
      final spent = state.spentForBudget(budget);
      if (spent > budget.limit) {
        insights.add(
          _Insight(
            title:
                'Presupuesto excedido: ${_categoryName(state, budget.categoryId)}',
            description:
                'Superaste el límite por ${Formatters.currency(spent - budget.limit)} en ${Formatters.monthYear(budget.month)}.',
            icon: Icons.trending_up,
            tone: _InsightTone.warning,
          ),
        );
      }
    }

    final cards = state.accounts.where(
      (account) => account.type == AccountType.creditCard,
    );
    final totalLimit = cards.fold<int>(
      0,
      (sum, card) => sum + (card.limit ?? 0),
    );
    final totalCardDebt = cards.fold<int>(
      0,
      (sum, card) => sum + state.balanceFor(card.id),
    );
    if (totalLimit > 0 && totalCardDebt / totalLimit >= 0.5) {
      insights.add(
        _Insight(
          title: 'Uso alto de tarjetas',
          description:
              'Has usado ${(totalCardDebt / totalLimit * 100).toStringAsFixed(0)}% del límite total. Considera priorizar el pago de deuda.',
          icon: Icons.credit_card,
          tone: _InsightTone.warning,
        ),
      );
    }

    return insights;
  }
}

enum _TimelineMode { day, week, month }

class _PeriodBucket {
  final DateTime date;
  final int income;
  final int expenses;

  const _PeriodBucket({
    required this.date,
    required this.income,
    required this.expenses,
  });

  _PeriodBucket copyWith({int? income, int? expenses}) => _PeriodBucket(
    date: date,
    income: income ?? this.income,
    expenses: expenses ?? this.expenses,
  );
}

class _HealthSummary extends StatelessWidget {
  final int income;
  final int expenses;
  final int netWorth;
  final MapEntry<String, int>? topCategory;
  final String? categoryName;

  const _HealthSummary({
    required this.income,
    required this.expenses,
    required this.netWorth,
    required this.topCategory,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final flow = income - expenses;
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dónde se está gastando más',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (topCategory == null)
                  Text(
                    'No hay gastos registrados en este periodo.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  Text(
                    categoryName!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    Formatters.currency(topCategory!.value),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _MetricCard(
                title: 'Ingresos',
                amount: income,
                color: colorScheme.tertiary,
                icon: Icons.south_west,
              ),
              _MetricCard(
                title: 'Egresos',
                amount: expenses,
                color: colorScheme.error,
                icon: Icons.north_east,
              ),
              _MetricCard(
                title: 'Flujo neto',
                amount: flow,
                color: flow >= 0 ? colorScheme.tertiary : colorScheme.error,
                icon: Icons.compare_arrows,
              ),
              _MetricCard(
                title: 'Patrimonio',
                amount: netWorth,
                color: colorScheme.primary,
                icon: Icons.account_balance,
              ),
            ];
            final columns = constraints.maxWidth < 520 ? 2 : 4;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int amount;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.bodySmall),
            Text(
              Formatters.currency(amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

enum _InsightTone { positive, warning, neutral }

class _Insight {
  final String title;
  final String description;
  final IconData icon;
  final _InsightTone tone;

  const _Insight({
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
  });
}

class _InsightsCard extends StatelessWidget {
  final List<_Insight> insights;

  const _InsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos a tener en cuenta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (insights.isEmpty)
              const Text('Aún no hay suficiente información para sugerencias.'),
            ...insights.map((item) {
              final color = switch (item.tone) {
                _InsightTone.positive => scheme.tertiary,
                _InsightTone.warning => scheme.error,
                _InsightTone.neutral => scheme.primary,
              };
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: color, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.description,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineChart extends StatelessWidget {
  final List<_PeriodBucket> buckets;

  const _TimelineChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (buckets.isEmpty) {
      return const _EmptyCard(message: 'Sin datos para mostrar en este rango.');
    }
    final maxValue = buckets.fold<int>(
      0,
      (max, bucket) =>
          [max, bucket.income, bucket.expenses].reduce((a, b) => a > b ? a : b),
    );
    final interval = buckets.length > 8 ? (buckets.length / 6).ceil() : 1;
    final groups = buckets
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: entry.value.income.toDouble(),
                color: scheme.tertiary,
                width: 7,
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                toY: entry.value.expenses.toDouble(),
                color: scheme.error,
                width: 7,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 16, 12),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxValue == 0 ? 100 : maxValue * 1.2,
                  barGroups: groups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outline.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => Text(
                          Formatters.currencyCompact(value.toInt()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= buckets.length ||
                              index % interval != 0) {
                            return const SizedBox.shrink();
                          }
                          final date = buckets[index].date;
                          final label = buckets.length > 12
                              ? '${date.month}/${date.year % 100}'
                              : '${date.day}/${date.month}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _Legend(color: scheme.tertiary, label: 'Ingresos'),
                _Legend(color: scheme.error, label: 'Gastos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final String Function(String) categoryName;
  final Color Function(String) categoryColor;

  const _CategoryChart({
    required this.entries,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    if (total == 0) {
      return const _EmptyCard(
        message: 'Sin gastos categorizados para mostrar.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: entries.map((entry) {
                final percent = entry.value / total * 100;
                return PieChartSectionData(
                  color: categoryColor(entry.key),
                  value: entry.value.toDouble(),
                  title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
                  radius: 74,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AppState state;

  const _BalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _BalanceLine(
              label: 'Activos totales',
              amount: state.totalAssets,
              color: scheme.tertiary,
            ),
            const Divider(height: 24),
            _BalanceLine(
              label: 'Deudas totales',
              amount: state.totalLiabilities,
              color: scheme.error,
            ),
            const Divider(height: 24),
            _BalanceLine(
              label: 'Patrimonio neto',
              amount: state.netWorth,
              color: scheme.primary,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceLine extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final bool bold;

  const _BalanceLine({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w700 : null,
        ),
      ),
      Text(
        Formatters.currency(amount),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _AccountReportTile extends StatelessWidget {
  final Account account;
  final AppState state;

  const _AccountReportTile({required this.account, required this.state});

  @override
  Widget build(BuildContext context) {
    final balance = state.balanceFor(account.id);
    final isCreditCard = account.type == AccountType.creditCard;
    final paidInstallments = state.loanPaymentsFor(account.id).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          account.type.icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(account.name),
        subtitle: Text(
          isCreditCard
              ? 'Deuda ${Formatters.currency(balance)} · Disponible ${Formatters.currency(state.availableCreditFor(account.id))}'
              : account.type == AccountType.loan
              ? '$paidInstallments/${account.installmentCount ?? 0} cuotas pagadas'
              : account.type.label,
        ),
        trailing: Text(
          Formatters.currency(balance),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountDetailScreen(accountId: account.id),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message)),
    ),
  );
}

class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}
