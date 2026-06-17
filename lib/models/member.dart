// lib/models/member.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Member.fromMap(String id, Map<String, dynamic> map) {
    return Member(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      plan: map['plan'] ?? 'Basic',
      joinDate: (map['joinDate'] as Timestamp).toDate(),
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'plan': plan,
      'joinDate': joinDate,
      'expiryDate': expiryDate,
    };
  }
}