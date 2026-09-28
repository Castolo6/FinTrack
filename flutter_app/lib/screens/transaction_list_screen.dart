import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../widgets/transaction_tile.dart';

class TransactionListScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Transaction>? transactions;
  final bool Function(Transaction)? filter;

  const TransactionListScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.transactions,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    final source = transactions ?? state.transactions;
    final filtered = filter != null
        ? source.where(filter!).toList()
        : List<Transaction>.from(source);
    filtered.sort((a, b) => b.date.compareTo(a.date));

    final total = filtered.fold<int>(0, (sum, t) {
      if (t.type == TransactionType.income) return sum + t.amount;
      if (t.type == TransactionType.expense) return sum - t.amount;
      return sum;
    });

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(total.abs()),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: total >= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  Text(
                    total >= 0 ? 'Total positivo' : 'Total negativo',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay movimientos para mostrar.'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: TransactionTile(
                      transaction: filtered[index],
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
