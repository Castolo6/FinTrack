import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../theme/app_theme.dart';
import 'account_detail_screen.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _openAccount(BuildContext context, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountDetailScreen(accountId: account.id),
      ),
    );
  }

  void _addAccount(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddAccountScreen()));
  }

  void _editAccount(BuildContext context, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddAccountScreen(account: account)),
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    Account account,
    AppState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          '¿Eliminar "${account.name}"? Esta acción no se puede deshacer.',
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
    if (confirmed != true || !context.mounted) return;
    final deleted = state.deleteAccount(account.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Cuenta eliminada.'
              : 'No se puede eliminar: la cuenta tiene movimientos asociados.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final assets = state.accounts.where((a) => a.isAsset).toList();
    final liabilities = state.accounts.where((a) => a.isLiability).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus cuentas',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Activos',
            total: state.totalAssets,
            isDebt: false,
          ),
          const SizedBox(height: 10),
          ...assets.map(
            (a) => _AccountCard(
              account: a,
              state: state,
              onTap: () => _openAccount(context, a),
              onEdit: () => _editAccount(context, a),
              onDelete: () => _deleteAccount(context, a, state),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Tarjetas y deudas',
            total: state.totalLiabilities,
            isDebt: true,
          ),
          const SizedBox(height: 10),
          ...liabilities.map(
            (a) => _AccountCard(
              account: a,
              state: state,
              onTap: () => _openAccount(context, a),
              onEdit: () => _editAccount(context, a),
              onDelete: () => _deleteAccount(context, a, state),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addAccount(context),
              icon: const Icon(Icons.add),
              label: const Text('Añadir cuenta, tarjeta o activo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int total;
  final bool isDebt;

  const _SectionHeader({
    required this.title,
    required this.total,
    required this.isDebt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${isDebt ? '-' : ''}${Formatters.currencyCompact(total)}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: isDebt ? AppTheme.error : AppTheme.success,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final AppState state;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AccountCard({
    required this.account,
    required this.state,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final balance = state.balanceFor(account.id);
    final displayBalance = account.isLiability ? balance.abs() : balance;
    final isNegative = !account.isLiability && balance < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  account.type.icon,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      account.type.label +
                          (account.lastDigits != null
                              ? ' ···${account.lastDigits}'
                              : ''),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (account.limit != null && account.isLiability)
                      Text(
                        'Límite ${Formatters.currencyCompact(account.limit!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(displayBalance),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isNegative
                          ? AppTheme.error
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (account.type == AccountType.creditCard)
                    Text(
                      'Disp. ${Formatters.currencyCompact(state.availableCreditFor(account.id))}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
