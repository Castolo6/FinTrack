enum TransactionType { income, expense, transfer, payment, adjustment }

extension TransactionTypeLabel on TransactionType {
  String get label {
    return switch (this) {
      TransactionType.income => 'Ingreso',
      TransactionType.expense => 'Gasto',
      TransactionType.transfer => 'Transferencia',
      TransactionType.payment => 'Pago de deuda',
      TransactionType.adjustment => 'Ajuste',
    };
  }
}

class Transaction {
  final String id;
  final String description;
  final int amount; // always positive CLP
  final TransactionType type;
  final DateTime date;
  final String accountId; // source / payment account
  final String? toAccountId; // destination for transfers / payments
  final String? categoryId;
  final String? goalId;
  final String? notes;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.goalId,
    this.notes,
  });

  /// Net effect for a given account.
  /// Returns positive/negative CLP depending on the account role.
  int signedAmountFor(String accountId) {
    return switch (type) {
      TransactionType.income => accountId == this.accountId ? amount : 0,
      TransactionType.expense => accountId == this.accountId ? -amount : 0,
      TransactionType.transfer =>
        accountId == this.accountId
            ? -amount
            : (accountId == toAccountId ? amount : 0),
      TransactionType.payment =>
        accountId == this.accountId
            ? -amount
            : (accountId == toAccountId ? amount : 0),
      TransactionType.adjustment => accountId == this.accountId ? amount : 0,
    };
  }

  /// Net effect for a goal. Positive contributions increase savings,
  /// negative ones decrease it.
  int signedAmountForGoal() {
    return switch (type) {
      TransactionType.income => amount,
      TransactionType.expense => -amount,
      TransactionType.transfer => amount,
      TransactionType.payment => -amount,
      TransactionType.adjustment => amount,
    };
  }

  Transaction copyWith({
    String? id,
    String? description,
    int? amount,
    TransactionType? type,
    DateTime? date,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    String? goalId,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      goalId: goalId ?? this.goalId,
      notes: notes ?? this.notes,
    );
  }
}

enum GoalMovementType { contribution, withdrawal }

class GoalMovement {
  final String id;
  final String goalId;
  final String accountId;
  final String description;
  final int amount;
  final DateTime date;
  final GoalMovementType type;

  GoalMovement({
    required this.id,
    required this.goalId,
    required this.accountId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  int get signedAmount =>
      type == GoalMovementType.contribution ? amount : -amount;
}
