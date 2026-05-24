class Member {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String plan;
  final DateTime joinDate;
  final DateTime expiryDate;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.plan,
    required this.joinDate,
    required this.expiryDate,
  });

  factory Member.fromMap(Map<String, dynamic> map, String docId) {
    return Member(
      id: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      plan: map['plan'] ?? '',
      joinDate: DateTime.parse(map['joinDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'plan': plan,
      'joinDate': joinDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
}