import 'package:flutter/material.dart';
import '../services/formatters.dart';
import '../services/budget_alerts.dart';
import '../theme/app_theme.dart';

class BudgetProgress extends StatelessWidget {
  final String categoryName;
  final int spent;
  final int limit;
  final Color color;
  final VoidCallback? onTap;

  const BudgetProgress({
    super.key,
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final alertLevel = budgetAlertLevel(spent: spent, limit: limit);
    final exceeded = alertLevel == BudgetAlertLevel.exceeded;
    final reachedLimit = alertLevel == BudgetAlertLevel.reachedLimit;
    final nearLimit = alertLevel == BudgetAlertLevel.nearLimit;

    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (exceeded)
                  _Badge(
                    text: 'Excedido',
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                  )
                else if (reachedLimit)
                  _Badge(
                    text: 'Límite alcanzado',
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                  )
                else if (nearLimit)
                  _Badge(
                    text: 'Cerca del límite',
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation<Color>(
                  exceeded || reachedLimit
                      ? AppTheme.error
                      : (nearLimit ? AppTheme.warning : color),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.currency(spent),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'de ${Formatters.currency(limit)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (alertLevel != BudgetAlertLevel.none) ...[
              const SizedBox(height: 6),
              Text(
                exceeded
                    ? 'Superaste el límite por ${Formatters.currency(spent - limit)}'
                    : reachedLimit
                    ? 'Límite mensual alcanzado.'
                    : 'Has usado ${budgetPercent(spent: spent, limit: limit)}% del presupuesto.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: exceeded || reachedLimit
                      ? colorScheme.error
                      : colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  const _Badge({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
