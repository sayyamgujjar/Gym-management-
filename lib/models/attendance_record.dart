import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceRecord {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime timestamp;
  final String date;
  final int month;
  final int year;
  final int day;

  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.timestamp,
    required this.date,
    required this.month,
    required this.year,
    required this.day,
  });

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceRecord(
      id: id,
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      date: map['date'] ?? '',
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      day: map['day'] ?? DateTime.now().day,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'timestamp': Timestamp.fromDate(timestamp),
      'date': date,
      'month': month,
      'year': year,
      'day': day,
    };
  }

  String get formattedDate => DateFormat('dd/MM/yyyy').format(timestamp);
  String get formattedTime => DateFormat('hh:mm a').format(timestamp);
  String get formattedDateTime => DateFormat('dd/MM/yyyy hh:mm a').format(timestamp);
  String get dayName => DateFormat('EEEE').format(timestamp);

  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  @override
  String toString() {
    return 'AttendanceRecord(member: $memberName, date: $formattedDate, time: $formattedTime)';
  }
}