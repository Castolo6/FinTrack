import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/budget_alerts.dart';
import '../services/formatters.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_progress.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'budget_detail_screen.dart';
import 'budgets_screen.dart';
import 'transaction_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openTransactions(BuildContext context, {TransactionType? type}) {
    final now = DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionListScreen(
          title: type == TransactionType.expense
              ? 'Gastos del mes'
              : (type == TransactionType.income
                    ? 'Ingresos del mes'
                    : 'Todos los movimientos'),
          filter: (t) {
            final matchesType = type == null || t.type == type;
            final matchesMonth =
                t.date.year == now.year && t.date.month == now.month;
            return matchesType && matchesMonth;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recent = state.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final currentMonthBudgets = state.budgets
        .where(
          (b) =>
              b.month.year == DateTime.now().year &&
              b.month.month == DateTime.now().month,
        )
        .toList();
    final budgetAlerts =
        currentMonthBudgets
            .where(
              (budget) =>
                  budgetAlertLevel(
                    spent: state.spentForBudget(budget),
                    limit: budget.limit,
                  ) !=
                  BudgetAlertLevel.none,
            )
            .toList()
          ..sort((a, b) {
            final aLevel = budgetAlertLevel(
              spent: state.spentForBudget(a),
              limit: a.limit,
            );
            final bLevel = budgetAlertLevel(
              spent: state.spentForBudget(b),
              limit: b.limit,
            );
            return bLevel.index.compareTo(aLevel.index);
          });

    return RefreshIndicator(
      onRefresh: () async {
        // Placeholder for future data refresh.
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              Formatters.monthYear(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SummaryCard(
              title: 'Patrimonio neto',
              amount: state.netWorth,
              subtitle: 'Activos - pasivos',
              accentColor: colorScheme.primary,
              icon: Icons.account_balance_wallet,
              onTap: () => _openTransactions(context),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Gastos',
                    amount: state.monthlyExpenses(),
                    subtitle: 'Este mes',
                    accentColor: AppTheme.error,
                    icon: Icons.trending_down,
                    onTap: () => _openTransactions(
                      context,
                      type: TransactionType.expense,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SummaryCard(
                    title: 'Ingresos',
                    amount: state.monthlyIncome(),
                    subtitle: 'Este mes',
                    accentColor: AppTheme.success,
                    icon: Icons.trending_up,
                    onTap: () => _openTransactions(
                      context,
                      type: TransactionType.income,
                    ),
                  ),
                ),
              ],
            ),
            if (budgetAlerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.notifications_active, color: colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Text(
                    'Alertas de presupuesto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: budgetAlerts.map((budget) {
                    final spent = state.spentForBudget(budget);
                    final level = budgetAlertLevel(
                      spent: spent,
                      limit: budget.limit,
                    );
                    final category = state.categoryById(budget.categoryId);
                    final isOverLimit = level == BudgetAlertLevel.exceeded;
                    final isAtLimit = level == BudgetAlertLevel.reachedLimit;
                    final title = isOverLimit
                        ? 'Presupuesto excedido'
                        : isAtLimit
                        ? 'Límite alcanzado'
                        : 'Cerca del límite';
                    final message = isOverLimit
                        ? 'Superaste ${category?.name ?? 'el presupuesto'} por ${Formatters.currency(spent - budget.limit)}.'
                        : isAtLimit
                        ? 'Alcanzaste el límite de ${category?.name ?? 'la categoría'}.'
                        : '${budgetPercent(spent: spent, limit: budget.limit)}% usado en ${category?.name ?? 'la categoría'} · te quedan ${Formatters.currency(budget.limit - spent)}.';
                    final alertColor = isOverLimit || isAtLimit
                        ? colorScheme.error
                        : colorScheme.tertiary;

                    return ListTile(
                      leading: Icon(
                        isOverLimit || isAtLimit
                            ? Icons.error_outline
                            : Icons.warning_amber_rounded,
                        color: alertColor,
                      ),
                      title: Text(title),
                      subtitle: Text(message),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BudgetDetailScreen(budgetId: budget.id),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Presupuestos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  key: const ValueKey('dashboard-all-budgets'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Presupuestos')),
                          body: const BudgetsScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...currentMonthBudgets.map((b) {
              final category = state.categoryById(b.categoryId);
              final spent = state.spentForBudget(b);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BudgetProgress(
                  categoryName: category?.name ?? 'Sin categoría',
                  spent: spent,
                  limit: b.limit,
                  color: category?.color ?? colorScheme.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BudgetDetailScreen(budgetId: b.id),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actividad reciente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  key: const ValueKey('dashboard-all-transactions'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const TransactionListScreen(title: 'Movimientos'),
                      ),
                    );
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No hay movimientos registrados.')),
                ),
              )
            else
              Card(
                child: Column(
                  children: recent
                      .take(5)
                      .map((t) => TransactionTile(transaction: t, state: state))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
