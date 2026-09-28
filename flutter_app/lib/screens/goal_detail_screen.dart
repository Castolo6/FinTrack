import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../widgets/transaction_tile.dart';
import 'add_goal_movement_screen.dart';

class GoalDetailScreen extends StatelessWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goal = state.goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => Goal(id: '', name: '', target: 0),
    );

    if (goal.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Objetivo')),
        body: const Center(child: Text('Objetivo no encontrado.')),
      );
    }

    final saved = state.savedForGoal(goalId);
    final goalMovements = state.goalMovementsFor(goalId)
      ..sort((a, b) => b.date.compareTo(a.date));
    final transactions = state.transactionsForGoal(goalId)
      ..sort((a, b) => b.date.compareTo(a.date));
    final progress = goal.target > 0
        ? (saved / goal.target).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meta de ahorro', style: theme.textTheme.bodySmall),
                      Text(
                        Formatters.currency(goal.target),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (goal.savingsLocation?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ahorro en ${goal.savingsLocation}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: colorScheme.outline.withValues(
                            alpha: 0.25,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ahorrado: ${Formatters.currency(saved)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (goal.deadline != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Fecha objetivo: ${Formatters.date(goal.deadline!)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aportes y retiros',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddGoalMovementScreen(goal: goal),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Movimiento'),
                  ),
                ],
              ),
            ),
          ),
          if (goalMovements.isEmpty && transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no hay aportes. Usa “Movimiento” para registrar uno.',
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: goalMovements.length + transactions.length,
                itemBuilder: (context, index) {
                  if (index >= goalMovements.length) {
                    final transaction =
                        transactions[index - goalMovements.length];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: TransactionTile(
                        transaction: transaction,
                        state: state,
                      ),
                    );
                  }
                  final movement = goalMovements[index];
                  final account = state.accountById(movement.accountId);
                  final contribution =
                      movement.type == GoalMovementType.contribution;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          contribution ? Icons.savings : Icons.money_off,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(movement.description),
                      subtitle: Text(
                        '${account?.name ?? 'Cuenta'} · ${Formatters.date(movement.date)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${contribution ? '+' : '-'}${Formatters.currency(movement.amount)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: contribution
                                  ? colorScheme.tertiary
                                  : colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddGoalMovementScreen(
                                      goal: goal,
                                      movement: movement,
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (value != 'delete') return;
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminar movimiento'),
                                  content: const Text(
                                    '¿Eliminar este aporte o retiro?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                state.deleteGoalMovement(movement.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                        ],
                      ),
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
