import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../widgets/budget_progress.dart';
import 'add_budget_screen.dart';
import 'budget_detail_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _addBudget(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddBudgetScreen()));
  }

  void _editBudget(BuildContext context, Budget budget) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddBudgetScreen(budget: budget)));
  }

  Future<void> _deleteBudget(
    BuildContext context,
    Budget budget,
    AppState state,
  ) async {
    final category =
        state.categoryById(budget.categoryId)?.name ?? 'este presupuesto';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: Text(
          '¿Eliminar el presupuesto de $category para ${Formatters.monthYear(budget.month)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) state.deleteBudget(budget.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final budgets = state.budgets.toList()
      ..sort((a, b) => b.month.compareTo(a.month));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presupuestos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Seguimiento mensual por categoría',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...budgets.map((budget) {
            final category = state.categoryById(budget.categoryId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            Formatters.monthYear(budget.month),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        BudgetProgress(
                          categoryName: category?.name ?? 'Sin categoría',
                          spent: state.spentForBudget(budget),
                          limit: budget.limit,
                          color: category?.color ?? colorScheme.primary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BudgetDetailScreen(budgetId: budget.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editBudget(context, budget);
                      if (value == 'delete') {
                        _deleteBudget(context, budget, state);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addBudget(context),
              icon: const Icon(Icons.add),
              label: const Text('Añadir presupuesto'),
            ),
          ),
        ],
      ),
    );
  }
}
