import 'package:flutter/material.dart';

enum AccountType { cash, bank, wallet, savings, creditCard, loan, asset }

extension AccountTypeLabel on AccountType {
  String get label {
    return switch (this) {
      AccountType.cash => 'Efectivo',
      AccountType.bank => 'Cuenta bancaria',
      AccountType.wallet => 'Billetera / app',
      AccountType.savings => 'Cuenta de ahorro',
      AccountType.creditCard => 'Tarjeta de crédito',
      AccountType.loan => 'Préstamo / crédito',
      AccountType.asset => 'Bien',
    };
  }

  IconData get icon {
    return switch (this) {
      AccountType.cash => Icons.money,
      AccountType.bank => Icons.account_balance,
      AccountType.wallet => Icons.account_balance_wallet,
      AccountType.savings => Icons.savings,
      AccountType.creditCard => Icons.credit_card,
      AccountType.loan => Icons.receipt_long,
      AccountType.asset => Icons.real_estate_agent,
    };
  }
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final int? lastDigits;
  final int? limit;
  final String? notes;
  final int openingBalance;
  final int? installmentCount;
  final int? installmentAmount;
  final DateTime? firstDueDate;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.lastDigits,
    this.limit,
    this.notes,
    this.openingBalance = 0,
    this.installmentCount,
    this.installmentAmount,
    this.firstDueDate,
  });

  bool get isLiability =>
      type == AccountType.creditCard || type == AccountType.loan;
  bool get isAsset => !isLiability;
  bool get isLiquid =>
      type == AccountType.cash ||
      type == AccountType.bank ||
      type == AccountType.wallet ||
      type == AccountType.savings;

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? lastDigits,
    int? limit,
    String? notes,
    int? openingBalance,
    int? installmentCount,
    int? installmentAmount,
    DateTime? firstDueDate,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lastDigits: lastDigits ?? this.lastDigits,
      limit: limit ?? this.limit,
      notes: notes ?? this.notes,
      openingBalance: openingBalance ?? this.openingBalance,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      firstDueDate: firstDueDate ?? this.firstDueDate,
    );
  }
}
