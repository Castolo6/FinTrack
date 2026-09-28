import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../widgets/budget_progress.dart';
import '../widgets/transaction_tile.dart';

class BudgetDetailScreen extends StatelessWidget {
  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final budget = state.budgets.firstWhere(
      (b) => b.id == budgetId,
      orElse: () => Budget(id: '', categoryId: '', limit: 0),
    );
    final category = state.categoryById(budget.categoryId);

    if (budget.id.isEmpty || category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Presupuesto')),
        body: const Center(child: Text('Presupuesto no encontrado.')),
      );
    }

    final transactions =
        state.transactions
            .where(
              (t) =>
                  t.type == TransactionType.expense &&
                  t.categoryId == budget.categoryId &&
                  t.date.year == budget.month.year &&
                  t.date.month == budget.month.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final spent = state.spentForBudget(budget);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      Formatters.monthYear(budget.month),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  BudgetProgress(
                    categoryName: category.name,
                    spent: spent,
                    limit: budget.limit,
                    color: category.color,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Gastos en esta categoría',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay gastos en esta categoría.'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: TransactionTile(
                      transaction: transactions[index],
                      state: state,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
