import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;

  const AddAccountScreen({super.key, this.account});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastDigitsController = TextEditingController();
  final _limitController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  late AccountType _type;
  DateTime? _firstDueDate;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _type = account?.type ?? AccountType.bank;
    _nameController.text = account?.name ?? '';
    _lastDigitsController.text = account?.lastDigits?.toString() ?? '';
    _limitController.text = account?.limit?.toString() ?? '';
    _openingBalanceController.text = account?.openingBalance.toString() ?? '0';
    _installmentCountController.text =
        account?.installmentCount?.toString() ?? '';
    _installmentAmountController.text =
        account?.installmentAmount?.toString() ?? '';
    _firstDueDate = account?.firstDueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastDigitsController.dispose();
    _limitController.dispose();
    _openingBalanceController.dispose();
    _installmentCountController.dispose();
    _installmentAmountController.dispose();
    super.dispose();
  }

  bool get _showsLimit => _type == AccountType.creditCard;
  bool get _showsLoanTerms => _type == AccountType.loan;
  bool get _showsDigits =>
      _type == AccountType.bank ||
      _type == AccountType.creditCard ||
      _type == AccountType.loan;

  int _parseAmount(String text) =>
      int.tryParse(text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_showsLoanTerms && _firstDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el vencimiento de la primera cuota.'),
        ),
      );
      return;
    }
    final account = Account(
      id: widget.account?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _type,
      lastDigits: _showsDigits
          ? int.tryParse(_lastDigitsController.text.trim())
          : null,
      limit: _showsLimit ? _parseAmount(_limitController.text) : null,
      openingBalance: _parseAmount(_openingBalanceController.text),
      installmentCount: _showsLoanTerms
          ? int.tryParse(_installmentCountController.text.trim())
          : null,
      installmentAmount: _showsLoanTerms
          ? _parseAmount(_installmentAmountController.text)
          : null,
      firstDueDate: _showsLoanTerms ? _firstDueDate : null,
    );

    final state = context.read<AppState>();
    if (widget.account == null) {
      state.addAccount(account);
    } else {
      state.updateAccount(account);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isEditing = widget.account != null;
    final hasHistory =
        widget.account != null &&
        state.transactions.any(
          (transaction) =>
              transaction.accountId == widget.account!.id ||
              transaction.toAccountId == widget.account!.id,
        );
    final hasLoanPayments =
        widget.account?.type == AccountType.loan &&
        state.loanPaymentsFor(widget.account!.id).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar cuenta' : 'Añadir cuenta'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Guardar')),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo de cuenta', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<AccountType>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: AccountType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: hasHistory
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                            if (value == AccountType.loan &&
                                _firstDueDate == null) {
                              final now = DateTime.now();
                              _firstDueDate = DateTime(
                                now.year,
                                now.month + 1,
                                1,
                              );
                            }
                          });
                        }
                      },
              ),
              if (hasHistory)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'El tipo no se puede cambiar porque esta cuenta ya tiene movimientos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Cuenta corriente, Visa, Mercado Pago',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa un nombre'
                    : null,
              ),
              if (_showsDigits) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastDigitsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Últimos dígitos (opcional)',
                    prefixIcon: Icon(Icons.pin),
                  ),
                ),
              ],
              if (_showsLimit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Límite de crédito (CLP)',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    if (value == null || _parseAmount(value) <= 0) {
                      return 'Ingresa un límite válido';
                    }
                    return null;
                  },
                ),
              ],
              if (_showsLoanTerms) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _installmentCountController,
                  readOnly: hasLoanPayments,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de cuotas',
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  validator: (value) {
                    final count = int.tryParse(value?.trim() ?? '') ?? 0;
                    if (count < 1) return 'Ingresa un número de cuotas válido';
                    final total = _parseAmount(_openingBalanceController.text);
                    final installment = _parseAmount(
                      _installmentAmountController.text,
                    );
                    if (total > 0 &&
                        installment > 0 &&
                        installment * (count - 1) >= total) {
                      return 'El valor de las cuotas supera el total a pagar';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _installmentAmountController,
                  readOnly: hasLoanPayments,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor de cada cuota (CLP)',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    if (_parseAmount(value ?? '') <= 0) {
                      return 'Ingresa un valor de cuota válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: hasLoanPayments ? null : _pickFirstDueDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de vencimiento de la primera cuota',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text(
                      _firstDueDate == null
                          ? 'Selecciona una fecha'
                          : '${_firstDueDate!.day}/${_firstDueDate!.month}/${_firstDueDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasLoanPayments
                      ? 'Los términos se bloquean después de registrar pagos.'
                      : 'El total incluye intereses e impuestos. Si hay una diferencia por redondeo, se ajustará la última cuota.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _openingBalanceController,
                keyboardType: TextInputType.number,
                readOnly: hasLoanPayments,
                decoration: InputDecoration(
                  labelText: _type == AccountType.loan
                      ? 'Total a pagar (CLP)'
                      : _type == AccountType.creditCard
                      ? 'Deuda inicial (CLP)'
                      : 'Saldo inicial / valor actual (CLP)',
                  prefixText: '\$ ',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) {
                  if (_type == AccountType.loan &&
                      _parseAmount(value ?? '') <= 0) {
                    return 'Ingresa el total a pagar del crédito';
                  }
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      _parseAmount(value) < 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Guardar cambios' : 'Guardar cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFirstDueDate() async {
    final initial =
        _firstDueDate ?? DateTime.now().add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _firstDueDate = picked);
  }
}
