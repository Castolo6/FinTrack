class LoanInstallmentPayment {
  final String id;
  final String loanAccountId;
  final int installmentNumber;
  final String transactionId;
  final String paidFromAccountId;
  final int amount;
  final DateTime paidDate;

  const LoanInstallmentPayment({
    required this.id,
    required this.loanAccountId,
    required this.installmentNumber,
    required this.transactionId,
    required this.paidFromAccountId,
    required this.amount,
    required this.paidDate,
  });
}
