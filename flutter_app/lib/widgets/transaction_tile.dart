import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../theme/app_theme.dart';
import '../screens/add_transaction_screen.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final AppState state;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final category = transaction.categoryId != null
        ? state.categoryById(transaction.categoryId!)
        : null;
    final account = state.accountById(transaction.accountId);
    final destination = transaction.toAccountId != null
        ? state.accountById(transaction.toAccountId!)
        : null;
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;

    final signColor = isIncome
        ? AppTheme.success
        : (isExpense ? colorScheme.onSurface : colorScheme.onSurfaceVariant);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              category?.color.withValues(alpha: 0.15) ??
              colorScheme.outline.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          category?.icon ?? Icons.receipt,
          color: category?.color ?? colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${account?.name ?? 'Cuenta'}${destination == null ? '' : ' → ${destination.name}'} · ${transaction.type.label} · ${Formatters.dateShort(transaction.date)}',
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isIncome ? '+' : (isExpense ? '-' : '')}${Formatters.currency(transaction.amount)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: signColor,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (state.isScheduledLoanPaymentTransaction(transaction.id))
            const SizedBox(width: 8)
          else
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AddTransactionScreen(transaction: transaction),
                    ),
                  );
                  return;
                }
                if (value != 'delete') return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar movimiento'),
                    content: Text('¿Eliminar "${transaction.description}"?'),
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
                if (confirmed == true && context.mounted) {
                  state.deleteTransaction(transaction.id);
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
  }
}
