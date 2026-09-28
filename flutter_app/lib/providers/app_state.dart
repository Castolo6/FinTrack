import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/firestore_repository.dart';

class AppState extends ChangeNotifier {
  AppState() : _repository = null;

  AppState.forUser(String userId)
    : _repository = FirestoreRepository(uid: userId),
      _isLoading = true {
    // A signed-in account must never be prefilled with the demo user's data.
    _accounts.clear();
    _transactions.clear();
    _budgets.clear();
    _goals.clear();
    _goalMovements.clear();
    _loanInstallmentPayments.clear();
  }

  final FirestoreRepository? _repository;
  bool _isLoading = false;
  String? _loadError;
  String? _persistenceError;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String? get persistenceError => _persistenceError;

  void clearPersistenceError() {
    _persistenceError = null;
    notifyListeners();
  }

  Future<void> loadFromFirestore() async {
    final repository = _repository;
    if (repository == null) return;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final data = await repository.loadUserData();
      _accounts
        ..clear()
        ..addAll(data.accounts);
      _transactions
        ..clear()
        ..addAll(data.transactions);
      _budgets
        ..clear()
        ..addAll(data.budgets);
      _goals
        ..clear()
        ..addAll(data.goals);
      _goalMovements
        ..clear()
        ..addAll(data.goalMovements);
      _loanInstallmentPayments
        ..clear()
        ..addAll(data.loanPayments);

      if (data.categories.isNotEmpty) {
        _categories
          ..clear()
          ..addAll(data.categories);
      } else {
        // Create starter categories for a brand-new user without demo finances.
        for (final category in _categories) {
          await repository.saveCategory(category);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Firestore load failed: $error\n$stackTrace');
      _loadError = _firebaseErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadFromFirestore() => loadFromFirestore();

  void _persist(Future<void>? operation) {
    if (operation == null) return;
    unawaited(
      operation.catchError((Object error) {
        _persistenceError = _firebaseErrorMessage(error);
        notifyListeners();
      }),
    );
  }

  String _firebaseErrorMessage(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firestore: permisos denegados. Revisa las reglas de seguridad.';
      }
      return 'Firebase ${error.plugin} (${error.code}): '
          '${error.message ?? 'No se pudo completar la operación.'}';
    }
    final message = error.toString();
    if (message.contains('permission-denied')) {
      return 'Firebase no permitió guardar los datos. Revisa las reglas de Firestore.';
    }
    return 'No se pudieron sincronizar los datos con Firebase. Revisa tu conexión e inténtalo de nuevo. Detalle: $message';
  }

  // Sample data. This version is intentionally local and resets on reload.
  final List<Account> _accounts = [
    Account(
      id: 'banco',
      name: 'Cuenta corriente',
      type: AccountType.bank,
      lastDigits: 1234,
    ),
    Account(
      id: 'tarjeta',
      name: 'Visa',
      type: AccountType.creditCard,
      lastDigits: 4242,
      limit: 1500000,
    ),
    Account(id: 'efectivo', name: 'Efectivo', type: AccountType.cash),
    Account(
      id: 'credito-ejemplo',
      name: 'Crédito de consumo',
      type: AccountType.loan,
      openingBalance: 1200000,
      installmentCount: 12,
      installmentAmount: 100000,
      firstDueDate: DateTime(2026, 10, 5),
    ),
  ];

  final List<Category> _categories = [
    Category(
      id: 'comida',
      name: 'Comida',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    Category(
      id: 'transporte',
      name: 'Transporte',
      icon: Icons.directions_car,
      color: Colors.blue,
    ),
    Category(
      id: 'entretenimiento',
      name: 'Entretenimiento',
      icon: Icons.movie,
      color: Colors.purple,
    ),
    Category(
      id: 'salud',
      name: 'Salud',
      icon: Icons.local_hospital,
      color: Colors.red,
    ),
    Category(
      id: 'servicios',
      name: 'Servicios',
      icon: Icons.wifi,
      color: Colors.teal,
    ),
    Category(
      id: 'otros',
      name: 'Otros',
      icon: Icons.category,
      color: Colors.grey,
    ),
  ];

  final List<Transaction> _transactions = [
    Transaction(
      id: 't1',
      description: 'Sueldo',
      amount: 2500000,
      type: TransactionType.income,
      date: DateTime(2026, 9, 1),
      accountId: 'banco',
    ),
    Transaction(
      id: 't2',
      description: 'Mercado',
      amount: 145000,
      type: TransactionType.expense,
      date: DateTime(2026, 9, 5),
      accountId: 'banco',
      categoryId: 'comida',
    ),
    Transaction(
      id: 't3',
      description: 'Cine',
      amount: 20000,
      type: TransactionType.expense,
      date: DateTime(2026, 9, 7),
      accountId: 'tarjeta',
      categoryId: 'entretenimiento',
    ),
    Transaction(
      id: 't4',
      description: 'Uber Eats',
      amount: 22000,
      type: TransactionType.expense,
      date: DateTime(2026, 9, 10),
      accountId: 'tarjeta',
      categoryId: 'comida',
    ),
    Transaction(
      id: 't5',
      description: 'Gasolina',
      amount: 65000,
      type: TransactionType.expense,
      date: DateTime(2026, 9, 12),
      accountId: 'banco',
      categoryId: 'transporte',
    ),
  ];

  final List<Budget> _budgets = [
    Budget(
      id: 'b1',
      categoryId: 'comida',
      limit: 400000,
      month: DateTime(2026, 9),
    ),
    Budget(
      id: 'b2',
      categoryId: 'entretenimiento',
      limit: 100000,
      month: DateTime(2026, 9),
    ),
    Budget(
      id: 'b3',
      categoryId: 'transporte',
      limit: 150000,
      month: DateTime(2026, 9),
    ),
  ];

  final List<Goal> _goals = [
    Goal(
      id: 'g1',
      name: 'Vacaciones',
      target: 2000000,
      deadline: DateTime(2027, 3, 1),
    ),
  ];
  final List<GoalMovement> _goalMovements = [];
  final List<LoanInstallmentPayment> _loanInstallmentPayments = [];

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<Goal> get goals => List.unmodifiable(_goals);
  List<GoalMovement> get goalMovements => List.unmodifiable(_goalMovements);
  List<LoanInstallmentPayment> get loanInstallmentPayments =>
      List.unmodifiable(_loanInstallmentPayments);

  Account? accountById(String id) => _firstOrNull(_accounts, (a) => a.id == id);
  Category? categoryById(String id) =>
      _firstOrNull(_categories, (c) => c.id == id);
  Goal? goalById(String id) => _firstOrNull(_goals, (g) => g.id == id);
  Budget? budgetById(String id) => _firstOrNull(_budgets, (b) => b.id == id);

  T? _firstOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  /// Asset balances are positive. Liability balances are the amount owed,
  /// also positive. Card payments reduce the liability and bank balance.
  int balanceFor(String accountId) {
    final account = accountById(accountId);
    if (account == null) return 0;

    var balance = account.openingBalance;
    for (final transaction in _transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          if (transaction.accountId == accountId) {
            balance += account.isLiability
                ? -transaction.amount
                : transaction.amount;
          }
        case TransactionType.expense:
          if (transaction.accountId == accountId) {
            balance += account.isLiability
                ? transaction.amount
                : -transaction.amount;
          }
        case TransactionType.transfer:
          if (transaction.accountId == accountId) balance -= transaction.amount;
          if (transaction.toAccountId == accountId) {
            balance += transaction.amount;
          }
        case TransactionType.payment:
          if (transaction.accountId == accountId) balance -= transaction.amount;
          if (transaction.toAccountId == accountId && account.isLiability) {
            balance -= transaction.amount;
          }
        case TransactionType.adjustment:
          if (transaction.accountId == accountId) balance += transaction.amount;
      }
    }
    return balance;
  }

  int availableCreditFor(String accountId) {
    final account = accountById(accountId);
    if (account == null || account.type != AccountType.creditCard) return 0;
    return ((account.limit ?? 0) - balanceFor(accountId)).clamp(
      0,
      account.limit ?? 0,
    );
  }

  int get totalAssets => _accounts
      .where((a) => a.isAsset)
      .fold<int>(0, (sum, a) => sum + balanceFor(a.id));

  int get totalLiabilities => _accounts
      .where((a) => a.isLiability)
      .fold<int>(0, (sum, a) => sum + balanceFor(a.id));

  int get netWorth => totalAssets - totalLiabilities;

  int monthlyExpenses({DateTime? month}) {
    final period = month ?? DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.expense && _sameMonth(t.date, period),
        )
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int monthlyIncome({DateTime? month}) {
    final period = month ?? DateTime.now();
    return _transactions
        .where(
          (t) => t.type == TransactionType.income && _sameMonth(t.date, period),
        )
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int spentByCategory(String categoryId, {DateTime? month}) {
    final period = month ?? DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.categoryId == categoryId &&
              _sameMonth(t.date, period),
        )
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int spentForBudget(Budget budget) =>
      spentByCategory(budget.categoryId, month: budget.month);

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  int savedForGoal(String goalId) {
    final movements = _goalMovements
        .where((m) => m.goalId == goalId)
        .fold<int>(0, (sum, m) => sum + m.signedAmount);
    final legacyLinked = _transactions
        .where((t) => t.goalId == goalId)
        .fold<int>(0, (sum, t) => sum + t.signedAmountForGoal());
    return movements + legacyLinked;
  }

  List<Transaction> transactionsForGoal(String goalId) =>
      _transactions.where((t) => t.goalId == goalId).toList();

  List<GoalMovement> goalMovementsFor(String goalId) =>
      _goalMovements.where((m) => m.goalId == goalId).toList();

  List<LoanInstallmentPayment> loanPaymentsFor(String accountId) =>
      _loanInstallmentPayments
          .where((payment) => payment.loanAccountId == accountId)
          .toList();

  LoanInstallmentPayment? loanPaymentForInstallment(
    String accountId,
    int installmentNumber,
  ) => _firstOrNull(
    _loanInstallmentPayments,
    (payment) =>
        payment.loanAccountId == accountId &&
        payment.installmentNumber == installmentNumber,
  );

  bool isLoanInstallmentPaid(String accountId, int installmentNumber) =>
      loanPaymentForInstallment(accountId, installmentNumber) != null;

  bool isScheduledLoanPaymentTransaction(String transactionId) =>
      _loanInstallmentPayments.any(
        (payment) => payment.transactionId == transactionId,
      );

  /// Uses the requested quota for regular installments and adjusts the last
  /// one so the schedule totals exactly the agreed total payable.
  int installmentAmountFor(Account account, int installmentNumber) {
    final count = account.installmentCount ?? 0;
    final quota = account.installmentAmount ?? 0;
    if (account.type != AccountType.loan ||
        count < 1 ||
        installmentNumber < 1 ||
        installmentNumber > count) {
      return 0;
    }
    if (installmentNumber == count) {
      final finalAmount = account.openingBalance - quota * (count - 1);
      return finalAmount > 0 ? finalAmount : quota;
    }
    return quota;
  }

  DateTime installmentDueDate(Account account, int installmentNumber) {
    final firstDue = account.firstDueDate ?? DateTime.now();
    final monthIndex = firstDue.month - 1 + installmentNumber - 1;
    final year = firstDue.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, firstDue.day.clamp(1, lastDayOfMonth));
  }

  bool payLoanInstallment({
    required String loanAccountId,
    required int installmentNumber,
    required String paidFromAccountId,
  }) {
    final loan = accountById(loanAccountId);
    final source = accountById(paidFromAccountId);
    if (loan == null ||
        loan.type != AccountType.loan ||
        source == null ||
        !source.isLiquid ||
        isLoanInstallmentPaid(loanAccountId, installmentNumber)) {
      return false;
    }
    final amount = installmentAmountFor(loan, installmentNumber);
    if (amount <= 0) return false;

    final transactionId = 'loan-payment-$loanAccountId-$installmentNumber';
    final paidDate = DateTime.now();
    final transaction = Transaction(
      id: transactionId,
      description:
          'Cuota $installmentNumber/${loan.installmentCount} · ${loan.name}',
      amount: amount,
      type: TransactionType.payment,
      date: paidDate,
      accountId: paidFromAccountId,
      toAccountId: loanAccountId,
      notes: 'Pago de cuota de crédito.',
    );
    final payment = LoanInstallmentPayment(
      id: 'installment-$loanAccountId-$installmentNumber',
      loanAccountId: loanAccountId,
      installmentNumber: installmentNumber,
      transactionId: transactionId,
      paidFromAccountId: paidFromAccountId,
      amount: amount,
      paidDate: paidDate,
    );
    _transactions.add(transaction);
    _loanInstallmentPayments.add(payment);
    _persist(_repository?.saveLoanPayment(payment, transaction));
    notifyListeners();
    return true;
  }

  void undoLoanInstallmentPayment(String loanAccountId, int installmentNumber) {
    final payment = loanPaymentForInstallment(loanAccountId, installmentNumber);
    if (payment == null) return;
    _loanInstallmentPayments.removeWhere((item) => item.id == payment.id);
    _transactions.removeWhere((item) => item.id == payment.transactionId);
    _persist(_repository?.deleteLoanPayment(payment));
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _persist(_repository?.saveTransaction(transaction));
    notifyListeners();
  }

  void updateTransaction(Transaction transaction) {
    if (isScheduledLoanPaymentTransaction(transaction.id)) return;
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index < 0) return;
    _transactions[index] = transaction;
    _persist(_repository?.saveTransaction(transaction));
    notifyListeners();
  }

  void deleteTransaction(String id) {
    final scheduledPayment = _loanInstallmentPayments.any(
      (payment) => payment.transactionId == id,
    );
    if (scheduledPayment) return;
    _transactions.removeWhere((t) => t.id == id);
    _persist(_repository?.deleteTransaction(id));
    notifyListeners();
  }

  void addAccount(Account account) {
    _accounts.add(account);
    _persist(_repository?.saveAccount(account));
    notifyListeners();
  }

  void updateAccount(Account account) {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index < 0) return;
    _accounts[index] = account;
    _persist(_repository?.saveAccount(account));
    notifyListeners();
  }

  /// Do not remove an account with history; that would make the ledger unclear.
  bool deleteAccount(String id) {
    final inTransactions = _transactions.any(
      (t) => t.accountId == id || t.toAccountId == id,
    );
    final inGoals = _goalMovements.any((m) => m.accountId == id);
    if (inTransactions || inGoals) return false;
    _accounts.removeWhere((a) => a.id == id);
    _persist(_repository?.deleteAccount(id));
    notifyListeners();
    return true;
  }

  bool addBudget(Budget budget) {
    final exists = _budgets.any(
      (b) =>
          b.categoryId == budget.categoryId &&
          _sameMonth(b.month, budget.month),
    );
    if (exists) return false;
    _budgets.add(budget);
    _persist(_repository?.saveBudget(budget));
    notifyListeners();
    return true;
  }

  bool updateBudget(Budget budget) {
    final duplicate = _budgets.any(
      (b) =>
          b.id != budget.id &&
          b.categoryId == budget.categoryId &&
          _sameMonth(b.month, budget.month),
    );
    if (duplicate) return false;
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index < 0) return false;
    _budgets[index] = budget;
    _persist(_repository?.saveBudget(budget));
    notifyListeners();
    return true;
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    _persist(_repository?.deleteBudget(id));
    notifyListeners();
  }

  void addGoal(Goal goal) {
    _goals.add(goal);
    _persist(_repository?.saveGoal(goal));
    notifyListeners();
  }

  void updateGoal(Goal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index < 0) return;
    _goals[index] = goal;
    _persist(_repository?.saveGoal(goal));
    notifyListeners();
  }

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    final removedGoalMovements = _goalMovements
        .where((m) => m.goalId == id)
        .toList();
    _goalMovements.removeWhere((m) => m.goalId == id);
    _persist(
      _repository?.deleteGoal(
        id,
        movementIds: removedGoalMovements
            .map((movement) => movement.id)
            .toList(),
      ),
    );
    for (var i = 0; i < _transactions.length; i++) {
      final t = _transactions[i];
      if (t.goalId == id) {
        _transactions[i] = Transaction(
          id: t.id,
          description: t.description,
          amount: t.amount,
          type: t.type,
          date: t.date,
          accountId: t.accountId,
          toAccountId: t.toAccountId,
          categoryId: t.categoryId,
          notes: t.notes,
        );
        _persist(_repository?.saveTransaction(_transactions[i]));
      }
    }
    notifyListeners();
  }

  void addGoalMovement(GoalMovement movement) {
    _goalMovements.add(movement);
    _persist(_repository?.saveGoalMovement(movement));
    notifyListeners();
  }

  void updateGoalMovement(GoalMovement movement) {
    final index = _goalMovements.indexWhere((m) => m.id == movement.id);
    if (index < 0) return;
    _goalMovements[index] = movement;
    _persist(_repository?.saveGoalMovement(movement));
    notifyListeners();
  }

  void deleteGoalMovement(String id) {
    _goalMovements.removeWhere((m) => m.id == id);
    _persist(_repository?.deleteGoalMovement(id));
    notifyListeners();
  }

  void addCategory(Category category) {
    _categories.add(category);
    _persist(_repository?.saveCategory(category));
    notifyListeners();
  }

  void updateCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index < 0) return;
    _categories[index] = category;
    _persist(_repository?.saveCategory(category));
    notifyListeners();
  }

  bool deleteCategory(String id) {
    final usedByTransactions = _transactions.any((t) => t.categoryId == id);
    final usedByBudgets = _budgets.any((b) => b.categoryId == id);
    if (usedByTransactions || usedByBudgets) return false;
    _categories.removeWhere((c) => c.id == id);
    _persist(_repository?.deleteCategoryDocuments(id));
    notifyListeners();
    return true;
  }
}
