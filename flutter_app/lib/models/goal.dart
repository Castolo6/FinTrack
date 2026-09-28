class Goal {
  final String id;
  final String name;
  final int target;
  final DateTime? deadline;
  final String? savingsLocation;

  Goal({
    required this.id,
    required this.name,
    required this.target,
    this.deadline,
    this.savingsLocation,
  });
}
