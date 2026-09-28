import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  final VoidCallback? onObjetivos;
  final VoidCallback? onComparar;

  const MoreScreen({super.key, this.onObjetivos, this.onComparar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Más',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Objetivos de ahorro'),
                  subtitle: const Text('Metas y planes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onObjetivos,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.compare_arrows,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Comparar estado de cuenta'),
                  subtitle: const Text('Validar cargos con tu tarjeta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onComparar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
