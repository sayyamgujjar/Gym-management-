// lib/models/payment.dart - UPDATED
import 'package:flutter/material.dart';  // ADD THIS IMPORT
import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String memberId;
  final String memberName;
  final String plan;
  final double amount;
  final DateTime paymentDate;
  final DateTime dueDate;
  final String status; // 'Paid' or 'Pending'
  final int month;
  final int year;
  final DateTime? paidDate; // NEW: Date when payment was actually paid

  Payment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.plan,
    required this.amount,
    required this.paymentDate,
    required this.dueDate,
    required this.status,
    required this.month,
    required this.year,
    this.paidDate, // NEW
  });

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      plan: map['plan'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'Pending',
      month: map['month'] ?? 0,
      year: map['year'] ?? 0,
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null, // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'plan': plan,
      'amount': amount,
      'paymentDate': paymentDate,
      'dueDate': dueDate,
      'status': status,
      'month': month,
      'year': year,
      'paidDate': paidDate, // NEW
    };
  }

  // Helper method to check if payment is overdue
  bool get isOverdue {
    if (status == 'Paid') return false;
    return DateTime.now().isAfter(dueDate);
  }

  // Calculate days overdue
  int get daysOverdue {
    if (status == 'Paid') return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  static double getPlanAmount(String plan) {
    switch (plan) {
      case 'Basic':
        return 2000.0;
      case 'Premium':
        return 5000.0;
      case 'VIP':
        return 10000.0;
      default:
        return 0.0;
    }
  }

  // Get plan color for UI
  static Color getPlanColor(String plan) {
    switch (plan) {
      case 'Basic':
        return Colors.blue;
      case 'Premium':
        return Colors.purple;
      case 'VIP':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}