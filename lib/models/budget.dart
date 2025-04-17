class Budget {
  final String id;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  double spentAmount;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spentAmount = 0.0,
  });

  double get remainingAmount => amount - spentAmount;
  double get progress => spentAmount / amount;
} 