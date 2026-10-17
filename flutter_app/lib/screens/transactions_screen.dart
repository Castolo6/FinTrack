import 'package:flutter/material.dart';
import 'transaction_browser.dart';

/// Body for the Movements navigation destination.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TransactionBrowser(showTitle: true, showTotal: false);
}
