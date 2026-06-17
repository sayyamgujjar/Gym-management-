// lib/models/plan.dart

class Plan {
  final String id;
  final String name;
  final double price;
  final String description;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  factory Plan.fromMap(String id, Map<String, dynamic> map) {
    return Plan(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
    };
  }
}