enum BudgetAlertLevel { none, nearLimit, reachedLimit, exceeded }

BudgetAlertLevel budgetAlertLevel({required int spent, required int limit}) {
  if (limit <= 0 || spent < limit * 0.8) return BudgetAlertLevel.none;
  if (spent > limit) return BudgetAlertLevel.exceeded;
  if (spent == limit) return BudgetAlertLevel.reachedLimit;
  return BudgetAlertLevel.nearLimit;
}

int budgetPercent({required int spent, required int limit}) {
  if (limit <= 0) return 0;
  return (spent * 100 / limit).round();
}
