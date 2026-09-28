import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart' show Color, IconData, Icons;
import '../models/app_models.dart';

class FirestoreUserData {
  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<GoalMovement> goalMovements;
  final List<LoanInstallmentPayment> loanPayments;

  const FirestoreUserData({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.goalMovements,
    required this.loanPayments,
  });
}

/// Stores all documents beneath `users/{uid}` so accounts cannot see each
/// other's financial data. Access is additionally restricted by firestore.rules.
class FirestoreRepository {
  static const List<IconData> _knownIcons = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.movie,
    Icons.local_hospital,
    Icons.wifi,
    Icons.shopping_bag,
    Icons.home,
    Icons.school,
    Icons.fitness_center,
    Icons.pets,
    Icons.flight,
    Icons.category,
  ];

  final FirebaseFirestore _firestore;
  final String uid;

  FirestoreRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _firestore.collection('users').doc(uid).collection(name);

  DocumentReference<Map<String, dynamic>> get _profileDocument =>
      _firestore.collection('users').doc(uid).collection('profile').doc('main');

  Future<FirestoreUserData> loadUserData() async {
    final snapshots = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      _collection('accounts').get(),
      _collection('categories').get(),
      _collection('transactions').get(),
      _collection('budgets').get(),
      _collection('goals').get(),
      _collection('goalMovements').get(),
      _collection('loanInstallmentPayments').get(),
    ]);

    return FirestoreUserData(
      accounts: snapshots[0].docs.map(_accountFromDocument).toList(),
      categories: snapshots[1].docs.map(_categoryFromDocument).toList(),
      transactions: snapshots[2].docs.map(_transactionFromDocument).toList(),
      budgets: snapshots[3].docs.map(_budgetFromDocument).toList(),
      goals: snapshots[4].docs.map(_goalFromDocument).toList(),
      goalMovements: snapshots[5].docs.map(_goalMovementFromDocument).toList(),
      loanPayments: snapshots[6].docs.map(_loanPaymentFromDocument).toList(),
    );
  }

  Future<UserProfile?> loadProfile() async {
    final document = await _profileDocument.get();
    if (!document.exists) return null;
    final data = document.data();
    if (data == null) return null;
    return UserProfile(
      userId: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      country: data['country'] as String? ?? 'Chile',
      currency: data['currency'] as String? ?? 'CLP',
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  Future<void> saveProfile(UserProfile profile) => _profileDocument.set({
    'displayName': profile.displayName,
    'email': profile.email,
    'country': profile.country,
    'currency': profile.currency,
    'createdAt': profile.createdAt ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> saveAccount(Account value) =>
      _put('accounts', value.id, _accountToMap(value));
  Future<void> saveCategory(Category value) =>
      _put('categories', value.id, _categoryToMap(value));
  Future<void> saveTransaction(Transaction value) =>
      _put('transactions', value.id, _transactionToMap(value));
  Future<void> saveBudget(Budget value) =>
      _put('budgets', value.id, _budgetToMap(value));
  Future<void> saveGoal(Goal value) =>
      _put('goals', value.id, _goalToMap(value));
  Future<void> saveGoalMovement(GoalMovement value) =>
      _put('goalMovements', value.id, _goalMovementToMap(value));

  Future<void> saveLoanPayment(
    LoanInstallmentPayment payment,
    Transaction transaction,
  ) async {
    final batch = _firestore.batch();
    batch.set(
      _collection('loanInstallmentPayments').doc(payment.id),
      _loanPaymentToMap(payment),
    );
    batch.set(
      _collection('transactions').doc(transaction.id),
      _transactionToMap(transaction),
    );
    await batch.commit();
  }

  Future<void> deleteAccount(String id) => _delete('accounts', id);
  Future<void> deleteCategory(String id) => _delete('categories', id);
  Future<void> deleteTransaction(String id) => _delete('transactions', id);
  Future<void> deleteBudget(String id) => _delete('budgets', id);
  Future<void> deleteGoalMovement(String id) => _delete('goalMovements', id);

  Future<void> deleteGoal(
    String id, {
    List<String> movementIds = const [],
  }) async {
    final batch = _firestore.batch();
    batch.delete(_collection('goals').doc(id));
    for (final movementId in movementIds) {
      batch.delete(_collection('goalMovements').doc(movementId));
    }
    await batch.commit();
  }

  Future<void> deleteLoanPayment(LoanInstallmentPayment payment) async {
    final batch = _firestore.batch();
    batch.delete(_collection('loanInstallmentPayments').doc(payment.id));
    batch.delete(_collection('transactions').doc(payment.transactionId));
    await batch.commit();
  }

  Future<void> deleteCategoryDocuments(String id) async {
    final transactionDocs = await _collection(
      'transactions',
    ).where('categoryId', isEqualTo: id).get();
    final budgetDocs = await _collection(
      'budgets',
    ).where('categoryId', isEqualTo: id).get();
    final batch = _firestore.batch();
    batch.delete(_collection('categories').doc(id));
    for (final document in [...transactionDocs.docs, ...budgetDocs.docs]) {
      final data = document.data()..remove('categoryId');
      batch.set(document.reference, data);
    }
    await batch.commit();
  }

  Future<void> _put(String collection, String id, Map<String, dynamic> data) =>
      _collection(collection).doc(id).set(data);

  Future<void> _delete(String collection, String id) =>
      _collection(collection).doc(id).delete();

  static Account _accountFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Account(
      id: document.id,
      name: data['name'] as String? ?? '',
      type: _enumByName(AccountType.values, data['type'], AccountType.bank),
      lastDigits: (data['lastDigits'] as num?)?.toInt(),
      limit: (data['limit'] as num?)?.toInt(),
      notes: data['notes'] as String?,
      openingBalance: (data['openingBalance'] as num?)?.toInt() ?? 0,
      installmentCount: (data['installmentCount'] as num?)?.toInt(),
      installmentAmount: (data['installmentAmount'] as num?)?.toInt(),
      firstDueDate: _dateFrom(data['firstDueDate']),
    );
  }

  static Map<String, dynamic> _accountToMap(Account value) => {
    'name': value.name,
    'type': value.type.name,
    'lastDigits': value.lastDigits,
    'limit': value.limit,
    'notes': value.notes,
    'openingBalance': value.openingBalance,
    'installmentCount': value.installmentCount,
    'installmentAmount': value.installmentAmount,
    'firstDueDate': value.firstDueDate,
  };

  static Category _categoryFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final storedColor = data['color'];
    final colorValue = storedColor is String
        ? int.tryParse(storedColor.replaceFirst('#', ''), radix: 16)
        : (storedColor as num?)?.toInt();
    return Category(
      id: document.id,
      name: data['name'] as String? ?? '',
      icon: _iconByCodePoint((data['iconCodePoint'] as num?)?.toInt()),
      color: Color(colorValue ?? 0xFF9E9E9E),
    );
  }

  static Map<String, dynamic> _categoryToMap(Category value) => {
    'name': value.name,
    'iconCodePoint': value.icon.codePoint,
    'iconFontFamily': value.icon.fontFamily,
    'iconFontPackage': value.icon.fontPackage,
    // Store ARGB as text: unsigned ARGB values can exceed signed 32-bit
    // range and trigger dart2js's unsupported Int64 MethodChannel codec.
    'color': value.color.toARGB32().toRadixString(16).padLeft(8, '0'),
  };

  static Transaction _transactionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Transaction(
      id: document.id,
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      type: _enumByName(
        TransactionType.values,
        data['type'],
        TransactionType.expense,
      ),
      date: _dateFrom(data['date']) ?? DateTime.now(),
      accountId: data['accountId'] as String? ?? '',
      toAccountId: data['toAccountId'] as String?,
      categoryId: data['categoryId'] as String?,
      goalId: data['goalId'] as String?,
      notes: data['notes'] as String?,
    );
  }

  static Map<String, dynamic> _transactionToMap(Transaction value) => {
    'description': value.description,
    'amount': value.amount,
    'type': value.type.name,
    'date': value.date,
    'accountId': value.accountId,
    'toAccountId': value.toAccountId,
    'categoryId': value.categoryId,
    'goalId': value.goalId,
    'notes': value.notes,
  };

  static Budget _budgetFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Budget(
      id: document.id,
      categoryId: data['categoryId'] as String? ?? '',
      limit: (data['limit'] as num?)?.toInt() ?? 0,
      month: _dateFrom(data['month']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _budgetToMap(Budget value) => {
    'categoryId': value.categoryId,
    'limit': value.limit,
    'month': value.month,
  };

  static Goal _goalFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Goal(
      id: document.id,
      name: data['name'] as String? ?? '',
      target: (data['target'] as num?)?.toInt() ?? 0,
      deadline: _dateFrom(data['deadline']),
      savingsLocation: data['savingsLocation'] as String?,
    );
  }

  static Map<String, dynamic> _goalToMap(Goal value) => {
    'name': value.name,
    'target': value.target,
    'deadline': value.deadline,
    'savingsLocation': value.savingsLocation,
  };

  static GoalMovement _goalMovementFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return GoalMovement(
      id: document.id,
      goalId: data['goalId'] as String? ?? '',
      accountId: data['accountId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: _dateFrom(data['date']) ?? DateTime.now(),
      type: _enumByName(
        GoalMovementType.values,
        data['type'],
        GoalMovementType.contribution,
      ),
    );
  }

  static Map<String, dynamic> _goalMovementToMap(GoalMovement value) => {
    'goalId': value.goalId,
    'accountId': value.accountId,
    'description': value.description,
    'amount': value.amount,
    'date': value.date,
    'type': value.type.name,
  };

  static LoanInstallmentPayment _loanPaymentFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return LoanInstallmentPayment(
      id: document.id,
      loanAccountId: data['loanAccountId'] as String? ?? '',
      installmentNumber: (data['installmentNumber'] as num?)?.toInt() ?? 0,
      transactionId: data['transactionId'] as String? ?? '',
      paidFromAccountId: data['paidFromAccountId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      paidDate: _dateFrom(data['paidDate']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _loanPaymentToMap(LoanInstallmentPayment value) =>
      {
        'loanAccountId': value.loanAccountId,
        'installmentNumber': value.installmentNumber,
        'transactionId': value.transactionId,
        'paidFromAccountId': value.paidFromAccountId,
        'amount': value.amount,
        'paidDate': value.paidDate,
      };

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static IconData _iconByCodePoint(int? codePoint) {
    for (final icon in _knownIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.category;
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? value,
    T fallback,
  ) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    return fallback;
  }
}
