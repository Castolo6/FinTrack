class Budget {
  final String id;
  final String categoryId;
  final int limit;
  final DateTime month;

  Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    DateTime? month,
  }) : month = DateTime(
         (month ?? DateTime.now()).year,
         (month ?? DateTime.now()).month,
       );
}
