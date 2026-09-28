import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';
import '../widgets/transaction_tile.dart';

class AccountDetailScreen extends StatelessWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  Future<void> _payInstallment(
    BuildContext context,
    AppState state,
    Account loan,
    int installmentNumber,
  ) async {
    final sources = state.accounts
        .where((account) => account.isLiquid)
        .toList();
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una cuenta bancaria o billetera para pagar.'),
        ),
      );
      return;
    }

    String? sourceAccountId = sources.first.id;
    final amount = state.installmentAmountFor(loan, installmentNumber);
    final selectedSource = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            'Pagar cuota $installmentNumber/${loan.installmentCount}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monto: ${Formatters.currency(amount)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: sourceAccountId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pagar desde',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: sources
                    .map(
                      (source) => DropdownMenuItem(
                        value: source.id,
                        child: Text(source.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => sourceAccountId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: sourceAccountId == null
                  ? null
                  : () => Navigator.pop(dialogContext, sourceAccountId),
              child: const Text('Confirmar pago'),
            ),
          ],
        ),
      ),
    );
    if (selectedSource == null || !context.mounted) return;

    final paid = state.payLoanInstallment(
      loanAccountId: loan.id,
      installmentNumber: installmentNumber,
      paidFromAccountId: selectedSource,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paid ? 'Cuota marcada como pagada.' : 'No se pudo registrar el pago.',
        ),
      ),
    );
  }

  Future<void> _undoInstallment(
    BuildContext context,
    AppState state,
    Account loan,
    int installmentNumber,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deshacer pago'),
        content: Text(
          '¿Marcar la cuota $installmentNumber como pendiente y revertir el pago registrado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Deshacer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      state.undoLoanInstallmentPayment(loan.id, installmentNumber);
    }
  }

  Widget _installmentTile(
    BuildContext context,
    AppState state,
    Account loan,
    int installmentNumber,
  ) {
    final theme = Theme.of(context);
    final paid = state.isLoanInstallmentPaid(loan.id, installmentNumber);
    final payment = state.loanPaymentForInstallment(loan.id, installmentNumber);
    final dueDate = state.installmentDueDate(loan, installmentNumber);
    final amount = state.installmentAmountFor(loan, installmentNumber);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: paid
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            paid ? Icons.check : Icons.event,
            color: paid
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Cuota $installmentNumber/${loan.installmentCount} · ${Formatters.currency(amount)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          paid
              ? 'Pagada ${Formatters.date(payment!.paidDate)} · ${state.accountById(payment.paidFromAccountId)?.name ?? 'Cuenta'}'
              : 'Vence ${Formatters.date(dueDate)}',
        ),
        trailing: paid
            ? IconButton(
                tooltip: 'Deshacer pago',
                onPressed: () =>
                    _undoInstallment(context, state, loan, installmentNumber),
                icon: Icon(Icons.undo, color: theme.colorScheme.tertiary),
              )
            : IconButton(
                tooltip: 'Pagar cuota',
                onPressed: () =>
                    _payInstallment(context, state, loan, installmentNumber),
                icon: Icon(
                  Icons.payments_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final account = state.accountById(accountId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cuenta')),
        body: const Center(child: Text('Cuenta no encontrada.')),
      );
    }

    final transactions =
        state.transactions
            .where(
              (t) => t.accountId == accountId || t.toAccountId == accountId,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final balance = state.balanceFor(accountId);
    final displayBalance = account.isLiability ? balance.abs() : balance;

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
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
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              account.type.icon,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.type.label,
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  account.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        account.type == AccountType.loan
                            ? 'Total pendiente de pago'
                            : account.type == AccountType.creditCard
                            ? 'Deuda actual'
                            : 'Saldo actual',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        Formatters.currency(displayBalance),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: account.isLiability
                              ? colorScheme.error
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (account.type == AccountType.creditCard) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Disponible: ${Formatters.currency(state.availableCreditFor(account.id))}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (account.type == AccountType.loan &&
              (account.installmentCount ?? 0) > 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Cuotas (${state.loanPaymentsFor(account.id).length}/${account.installmentCount} pagadas)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.builder(
                itemCount: account.installmentCount!,
                itemBuilder: (context, index) =>
                    _installmentTile(context, state, account, index + 1),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Movimientos',
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
                  child: Text('No hay movimientos para esta cuenta.'),
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
