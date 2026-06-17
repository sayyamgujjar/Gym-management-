// lib/models/trainer.dart - UPDATED WITH ASSIGNED MEMBERS

import 'package:cloud_firestore/cloud_firestore.dart';

class Trainer {
  final String id;
  final String name;
  final String specialty;
  final String phone;
  final String email;
  final List<String> assignedMembers; // NEW: List of assigned member IDs

  Trainer({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.email,
    this.assignedMembers = const [], // NEW
  });

  factory Trainer.fromMap(String id, Map<String, dynamic> map) {
    return Trainer(
      id: id,
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      assignedMembers: List<String>.from(map['assignedMembers'] ?? []), // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'email': email,
      'assignedMembers': assignedMembers, // NEW
    };
  }
}