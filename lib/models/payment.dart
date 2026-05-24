class Payment {
  final String id;
  final String memberName;
  final int amount;

  Payment({
    required this.id,
    required this.memberName,
    required this.amount,
  });

  factory Payment.fromMap(String id, Map<String, dynamic> data) {
    return Payment(
      id: id,
      memberName: data['memberName'] ?? '',
      amount: data['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberName': memberName,
      'amount': amount,
    };
  }
}
