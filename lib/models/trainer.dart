// Trainer management updated
class Trainer {
  final String id;
  final String name;
  final String specialty;

  Trainer({
    required this.id,
    required this.name,
    required this.specialty,
  });

  factory Trainer.fromMap(String id, Map<String, dynamic> data) {
    return Trainer(
      id: id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
    };
  }
}
