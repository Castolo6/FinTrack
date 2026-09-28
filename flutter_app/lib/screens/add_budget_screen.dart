import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../services/formatters.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  String? _categoryId;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.budget?.categoryId;
    _month = widget.budget?.month ?? DateTime.now();
    _limitController.text = widget.budget?.limit.toString() ?? '';
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  int _limit() =>
      int.tryParse(
        _limitController.text.replaceAll('.', '').replaceAll(',', '').trim(),
      ) ??
      0;

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona un día del mes',
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final budget = Budget(
      id: widget.budget?.id ?? const Uuid().v4(),
      categoryId: _categoryId!,
      limit: _limit(),
      month: _month,
    );
    final state = context.read<AppState>();
    final saved = widget.budget == null
        ? state.addBudget(budget)
        : state.updateBudget(budget);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ya existe un presupuesto para esa categoría y ese mes.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final categories = state.categories;
    final isEditing = widget.budget != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar presupuesto' : 'Añadir presupuesto'),
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories
                    .map(
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
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Límite mensual (CLP)',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.pie_chart),
                ),
                validator: (_) =>
                    _limit() <= 0 ? 'Ingresa un límite válido' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickMonth,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Mes del presupuesto',
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(Formatters.monthYear(_month)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    isEditing ? 'Guardar cambios' : 'Guardar presupuesto',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El gasto se calcula con movimientos de esa categoría y mes.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
