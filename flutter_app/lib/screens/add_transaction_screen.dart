import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late TransactionType _type;
  late DateTime _date;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _type = transaction?.type ?? TransactionType.expense;
    _date = transaction?.date ?? DateTime.now();
    _accountId = transaction?.accountId;
    _toAccountId = transaction?.toAccountId;
    _categoryId = transaction?.categoryId;
    _descriptionController.text = transaction?.description ?? '';
    _amountController.text = transaction?.amount.toString() ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<Account> _sourceAccounts(List<Account> accounts) {
    if (_type == TransactionType.transfer || _type == TransactionType.payment) {
      return accounts.where((a) => a.isLiquid).toList();
    }
    return accounts;
  }

  List<Account> _destinationAccounts(List<Account> accounts) {
    if (_type == TransactionType.payment) {
      return accounts.where((a) => a.type == AccountType.creditCard).toList();
    }
    if (_type == TransactionType.transfer) {
      return accounts.where((a) => a.isLiquid && a.id != _accountId).toList();
    }
    return const [];
  }

  void _changeType(TransactionType? value) {
    if (value == null) return;
    setState(() {
      _type = value;
      _categoryId =
          value == TransactionType.expense || value == TransactionType.income
          ? _categoryId
          : null;
      _toAccountId = null;
      final allowedSources = _sourceAccounts(context.read<AppState>().accounts);
      if (_accountId == null ||
          !allowedSources.any((a) => a.id == _accountId)) {
        _accountId = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  int _amount() =>
      int.tryParse(
        _amountController.text.replaceAll('.', '').replaceAll(',', '').trim(),
      ) ??
      0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.transaction;
    final transaction = Transaction(
      id: existing?.id ?? const Uuid().v4(),
      description: _descriptionController.text.trim(),
      amount: _amount(),
      type: _type,
      date: _date,
      accountId: _accountId!,
      toAccountId:
          _type == TransactionType.transfer || _type == TransactionType.payment
          ? _toAccountId
          : null,
      categoryId:
          _type == TransactionType.expense || _type == TransactionType.income
          ? _categoryId
          : null,
      goalId: existing?.goalId,
      notes: existing?.notes,
    );

    final state = context.read<AppState>();
    if (existing == null) {
      state.addTransaction(transaction);
    } else {
      state.updateTransaction(transaction);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accounts = _sourceAccounts(state.accounts);
    final destinations = _destinationAccounts(state.accounts);
    final categories = state.categories;
    final theme = Theme.of(context);
    final needsDestination =
        _type == TransactionType.transfer || _type == TransactionType.payment;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? 'Añadir movimiento'
              : 'Editar movimiento',
        ),
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
              DropdownButtonFormField<TransactionType>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de movimiento',
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text('Gasto'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text('Ingreso'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.transfer,
                    child: Text('Transferencia entre cuentas'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.payment,
                    child: Text('Pago de tarjeta'),
                  ),
                ],
                onChanged: _changeType,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  labelText: 'Monto (CLP)',
                ),
                validator: (value) =>
                    _amount() <= 0 ? 'Ingresa un monto válido' : null,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción / comercio',
                  hintText: 'Ej. Cine, Supermercado, Pago Visa',
                  prefixIcon: Icon(Icons.storefront),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa una descripción'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _accountId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: needsDestination
                      ? 'Cuenta de origen'
                      : 'Cuenta / tarjeta',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                ),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem<String?>(
                        value: a.id,
                        child: Text('${a.name} (${a.type.label})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _accountId = value;
                  if (_toAccountId == value) _toAccountId = null;
                }),
                validator: (value) =>
                    value == null ? 'Selecciona una cuenta' : null,
              ),
              if (needsDestination) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _toAccountId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _type == TransactionType.payment
                        ? 'Tarjeta que se paga'
                        : 'Cuenta de destino',
                    prefixIcon: Icon(
                      _type == TransactionType.payment
                          ? Icons.credit_card
                          : Icons.call_received,
                    ),
                  ),
                  items: destinations
                      .map(
                        (a) => DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text('${a.name} (${a.type.label})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _toAccountId = value),
                  validator: (value) => value == null
                      ? (_type == TransactionType.payment
                            ? 'Selecciona la tarjeta'
                            : 'Selecciona una cuenta de destino')
                      : null,
                ),
                if (destinations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _type == TransactionType.payment
                          ? 'Primero agrega una tarjeta de crédito.'
                          : 'Agrega otra cuenta para hacer una transferencia.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
              if (_type == TransactionType.expense ||
                  _type == TransactionType.income) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _type == TransactionType.income
                        ? 'Categoría de ingreso (opcional)'
                        : 'Categoría (opcional)',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin categoría'),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(c.icon, color: c.color, size: 20),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    widget.transaction == null
                        ? 'Guardar movimiento'
                        : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
