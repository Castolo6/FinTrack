import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';

class AddGoalMovementScreen extends StatefulWidget {
  final Goal goal;
  final GoalMovement? movement;

  const AddGoalMovementScreen({super.key, required this.goal, this.movement});

  @override
  State<AddGoalMovementScreen> createState() => _AddGoalMovementScreenState();
}

class _AddGoalMovementScreenState extends State<AddGoalMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _accountId;
  DateTime _date = DateTime.now();
  GoalMovementType _type = GoalMovementType.contribution;

  @override
  void initState() {
    super.initState();
    final movement = widget.movement;
    _amountController.text = movement?.amount.toString() ?? '';
    _descriptionController.text = movement?.description ?? '';
    _accountId = movement?.accountId;
    _date = movement?.date ?? DateTime.now();
    _type = movement?.type ?? GoalMovementType.contribution;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _amount() =>
      int.tryParse(
        _amountController.text.replaceAll('.', '').replaceAll(',', '').trim(),
      ) ??
      0;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final movement = GoalMovement(
      id: widget.movement?.id ?? const Uuid().v4(),
      goalId: widget.goal.id,
      accountId: _accountId!,
      description: _descriptionController.text.trim().isEmpty
          ? (_type == GoalMovementType.contribution
                ? 'Aporte de ahorro'
                : 'Retiro de ahorro')
          : _descriptionController.text.trim(),
      amount: _amount(),
      date: _date,
      type: _type,
    );
    if (widget.movement == null) {
      context.read<AppState>().addGoalMovement(movement);
    } else {
      context.read<AppState>().updateGoalMovement(movement);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accounts = state.accounts.where((a) => a.isAsset).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.movement == null
              ? 'Movimiento de ahorro'
              : 'Editar movimiento',
        ),
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.goal.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<GoalMovementType>(
                segments: const [
                  ButtonSegment(
                    value: GoalMovementType.contribution,
                    label: Text('Aportar'),
                    icon: Icon(Icons.add),
                  ),
                  ButtonSegment(
                    value: GoalMovementType.withdrawal,
                    label: Text('Retirar'),
                    icon: Icon(Icons.remove),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    setState(() => _type = selection.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto (CLP)',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (_) =>
                    _amount() <= 0 ? 'Ingresa un monto válido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _accountId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Dónde está el dinero',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem<String?>(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _accountId = value),
                validator: (value) =>
                    value == null ? 'Selecciona una cuenta o billetera' : null,
              ),
              if (accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Primero agrega una cuenta o billetera como Mercado Pago.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej. Ahorro mensual',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'El aporte o retiro actualiza la meta; no modifica el saldo de la cuenta ni se cuenta como gasto.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    widget.movement != null
                        ? 'Guardar cambios'
                        : (_type == GoalMovementType.contribution
                              ? 'Registrar aporte'
                              : 'Registrar retiro'),
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
