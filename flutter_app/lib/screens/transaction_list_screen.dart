import 'package:flutter/material.dart';
import '../models/app_models.dart';
import 'transaction_browser.dart';

class TransactionListScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Transaction>? transactions;
  final bool Function(Transaction)? filter;

  const TransactionListScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.transactions,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: TransactionBrowser(
        transactions: transactions,
        filter: filter,
        subtitle: subtitle,
        showTotal: true,
      ),
    );
  }
}
