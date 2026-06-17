// lib/services/firestore_service.dart - USER ISOLATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../models/attendance_record.dart';
import '../models/payment.dart';
import '../models/trainer.dart';
import '../models/plan.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ⭐ GET CURRENT USER ID - THIS IS THE KEY TO ISOLATION
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ⭐ USER-SPECIFIC COLLECTIONS (each user has their own data)
  CollectionReference get members => _db
      .collection('users')
      .doc(_currentUserId)
      .collection('members');

  CollectionReference get attendanceRecords => _db
      .collection('users')
      .doc(_currentUserId)
      .collection('attendance');

  CollectionReference get payments => _db
      .collection('users')
      .doc(_currentUserId)
      .collection('payments');

  CollectionReference get trainers => _db
      .collection('users')
      .doc(_currentUserId)
      .collection('trainers');

  CollectionReference get plans => _db
      .collection('users')
      .doc(_currentUserId)
      .collection('plans');

  // ⭐ GUARD: Check if user is logged in
  void _checkAuth() {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
  }

  // ============ MEMBERS CRUD ============

  /// Get all members as a stream
  Stream<List<Member>> getMembers() {
    _checkAuth();
    return members.snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            Member.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Add a new member
  Future<void> addMember(Member member) async {
    _checkAuth();
    await members.doc(member.id).set(member.toMap());
  }

  /// Update an existing member
  Future<void> updateMember(Member member) async {
    _checkAuth();
    await members.doc(member.id).update(member.toMap());
  }

  /// Delete a member (WITH CASCADE DELETE - removes all related data)
  Future<void> deleteMember(String id) async {
    _checkAuth();
    try {
      debugPrint('🗑️ Starting cascade delete for member: $id');

      // 1. Delete all attendance records for this member
      final attendanceSnapshot = await attendanceRecords
          .where('memberId', isEqualTo: id)
          .get();

      for (var doc in attendanceSnapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('✅ Deleted ${attendanceSnapshot.docs.length} attendance records');

      // 2. Delete all payment records for this member
      final paymentsSnapshot = await payments
          .where('memberId', isEqualTo: id)
          .get();

      for (var doc in paymentsSnapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('✅ Deleted ${paymentsSnapshot.docs.length} payment records');

      // 3. Remove member from trainer assignments
      final trainersSnapshot = await trainers
          .where('assignedMembers', arrayContains: id)
          .get();

      for (var doc in trainersSnapshot.docs) {
        await doc.reference.update({
          'assignedMembers': FieldValue.arrayRemove([id])
        });
      }
      debugPrint('✅ Removed from ${trainersSnapshot.docs.length} trainer assignments');

      // 4. Finally delete the member
      await members.doc(id).delete();
      debugPrint('✅ Member deleted successfully');

    } catch (e) {
      debugPrint('❌ Error in cascade delete: $e');
      rethrow;
    }
  }

  /// Extend membership expiry date
  Future<void> extendMembership(String memberId, DateTime newExpiryDate) async {
    _checkAuth();
    await members.doc(memberId).update({
      'expiryDate': newExpiryDate,
    });
  }

  /// Get a single member by ID
  Future<Member?> getMemberById(String id) async {
    _checkAuth();
    final doc = await members.doc(id).get();
    if (doc.exists) {
      return Member.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Get members expiring in next N days
  Stream<List<Member>> getExpiringMembers(int days) {
    _checkAuth();
    final endDate = DateTime.now().add(Duration(days: days));

    return members.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Member.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((member) {
        final now = DateTime.now();
        return member.expiryDate.isAfter(now) &&
            member.expiryDate.isBefore(endDate);
      })
          .toList();
    });
  }

  /// Get count of active members
  Stream<int> getActiveMembersCount() {
    _checkAuth();
    return members.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Member.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((member) => DateTime.now().isBefore(member.expiryDate))
          .length;
    });
  }

  /// Get count of expired members
  Stream<int> getExpiredMembersCount() {
    _checkAuth();
    return members.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Member.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((member) => DateTime.now().isAfter(member.expiryDate))
          .length;
    });
  }

  /// Get total members count
  Stream<int> getTotalMembersCount() {
    _checkAuth();
    return members.snapshots().map((snap) => snap.size);
  }

  // ============ ATTENDANCE SYSTEM ============

  /// Mark attendance for a specific date
  Future<void> markAttendanceForDate(
      String memberId,
      String memberName,
      DateTime date,
      ) async {
    _checkAuth();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final recordId = '${memberId}_$dateStr';

      final record = AttendanceRecord(
        id: recordId,
        memberId: memberId,
        memberName: memberName,
        timestamp: date,
        date: dateStr,
        month: date.month,
        year: date.year,
        day: date.day,
      );

      await attendanceRecords.doc(recordId).set(record.toMap());
      debugPrint('✅ Attendance marked: $memberName on $dateStr');
    } catch (e) {
      debugPrint('❌ Error marking attendance: $e');
      rethrow;
    }
  }

  /// Unmark attendance for a specific date
  Future<void> unmarkAttendance(String memberId, DateTime date) async {
    _checkAuth();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final recordId = '${memberId}_$dateStr';

      await attendanceRecords.doc(recordId).delete();
      debugPrint('🗑️ Attendance unmarked: $recordId');
    } catch (e) {
      debugPrint('❌ Error unmarking attendance: $e');
      rethrow;
    }
  }

  /// Check if attendance is marked for a member on a specific date
  Future<bool> isAttendanceMarked(String memberId, DateTime date) async {
    _checkAuth();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final recordId = '${memberId}_$dateStr';

      final doc = await attendanceRecords.doc(recordId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking attendance: $e');
      return false;
    }
  }

  /// Get attendance records for a specific date
  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) async {
    _checkAuth();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final snapshot = await attendanceRecords
          .where('date', isEqualTo: dateStr)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting attendance for date: $e');
      return [];
    }
  }

  /// Get attendance count for a specific date
  Future<int> getAttendanceCountForDate(DateTime date) async {
    _checkAuth();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final snapshot = await attendanceRecords
          .where('date', isEqualTo: dateStr)
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('❌ Error getting attendance count: $e');
      return 0;
    }
  }

  /// Get today's attendance count (for home page)
  Stream<int> getTodayAttendanceCount() {
    _checkAuth();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return attendanceRecords
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Get attendance records for a specific member
  Future<List<AttendanceRecord>> getMemberAttendance(
      String memberId, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    _checkAuth();
    try {
      Query query = attendanceRecords.where('memberId', isEqualTo: memberId);

      if (startDate != null) {
        final startStr = DateFormat('yyyy-MM-dd').format(startDate);
        query = query.where('date', isGreaterThanOrEqualTo: startStr);
      }

      if (endDate != null) {
        final endStr = DateFormat('yyyy-MM-dd').format(endDate);
        query = query.where('date', isLessThanOrEqualTo: endStr);
      }

      final snapshot = await query.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting member attendance: $e');
      return [];
    }
  }

  /// Get attendance records for a specific month
  Future<List<AttendanceRecord>> getMonthlyAttendance(int month, int year) async {
    _checkAuth();
    try {
      final snapshot = await attendanceRecords
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .orderBy('day', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting monthly attendance: $e');
      return [];
    }
  }

  /// Get attendance statistics for a date range
  Future<Map<String, dynamic>> getAttendanceStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _checkAuth();
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      final snapshot = await attendanceRecords
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();

      final records = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      final uniqueDates = records.map((r) => r.date).toSet().length;
      final totalAttendance = records.length;
      final uniqueMembers = records.map((r) => r.memberId).toSet().length;

      final memberAttendance = <String, int>{};
      for (var record in records) {
        memberAttendance[record.memberName] =
            (memberAttendance[record.memberName] ?? 0) + 1;
      }

      return {
        'totalDays': uniqueDates,
        'totalAttendance': totalAttendance,
        'uniqueMembers': uniqueMembers,
        'averagePerDay': uniqueDates > 0 ? (totalAttendance / uniqueDates).toStringAsFixed(1) : '0',
        'memberAttendance': memberAttendance,
      };
    } catch (e) {
      debugPrint('❌ Error getting attendance stats: $e');
      return {};
    }
  }

  /// Get member attendance percentage for current month
  Future<double> getMemberAttendancePercentage(String memberId) async {
    _checkAuth();
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final records = await getMemberAttendance(
        memberId,
        startDate: firstDay,
        endDate: lastDay,
      );

      final totalDays = lastDay.day;
      final presentDays = records.length;

      return (presentDays / totalDays) * 100;
    } catch (e) {
      debugPrint('❌ Error calculating attendance percentage: $e');
      return 0.0;
    }
  }

  /// Bulk mark attendance
  Future<void> bulkMarkAttendance(
      List<String> memberIds,
      Map<String, String> memberNames,
      DateTime date,
      ) async {
    _checkAuth();
    try {
      final batch = _db.batch();

      for (final memberId in memberIds) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final recordId = '${memberId}_$dateStr';

        final record = AttendanceRecord(
          id: recordId,
          memberId: memberId,
          memberName: memberNames[memberId] ?? 'Unknown',
          timestamp: date,
          date: dateStr,
          month: date.month,
          year: date.year,
          day: date.day,
        );

        batch.set(attendanceRecords.doc(recordId), record.toMap());
      }

      await batch.commit();
      debugPrint('✅ Bulk attendance marked for ${memberIds.length} members');
    } catch (e) {
      debugPrint('❌ Error in bulk marking: $e');
      rethrow;
    }
  }

  // ============ PAYMENTS SYSTEM ============

  /// Generate payment record when member joins or renews
  Future<void> generatePayment(Payment payment) async {
    _checkAuth();
    try {
      await payments.doc(payment.id).set(payment.toMap());
      debugPrint('✅ Payment generated: ${payment.memberName} - Rs ${payment.amount}');
    } catch (e) {
      debugPrint('❌ Error generating payment: $e');
      rethrow;
    }
  }

  /// Get all payments as a stream
  Stream<List<Payment>> getPayments() {
    _checkAuth();
    return payments
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get payments for a specific member
  Future<List<Payment>> getMemberPayments(String memberId) async {
    _checkAuth();
    try {
      final snapshot = await payments
          .where('memberId', isEqualTo: memberId)
          .orderBy('paymentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting member payments: $e');
      return [];
    }
  }

  /// Mark payment as paid WITHOUT overwriting original date
  Future<void> markPaymentAsPaid(String paymentId) async {
    _checkAuth();
    try {
      final doc = await payments.doc(paymentId).get();
      if (!doc.exists) throw Exception("Payment not found");

      await payments.doc(paymentId).update({
        'status': 'Paid',
        'paidDate': DateTime.now(),
      });

      debugPrint('✅ Payment marked as paid: $paymentId');
    } catch (e) {
      debugPrint('❌ Error marking payment as paid: $e');
      rethrow;
    }
  }

  /// Get pending payments count
  Stream<int> getPendingPaymentsCount() {
    _checkAuth();
    return payments
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Get paid payments count
  Stream<int> getPaidPaymentsCount() {
    _checkAuth();
    return payments
        .where('status', isEqualTo: 'Paid')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Get total revenue for current month
  Stream<double> getMonthlyRevenue() {
    _checkAuth();
    final now = DateTime.now();

    return payments
        .where('status', isEqualTo: 'Paid')
        .where('month', isEqualTo: now.month)
        .where('year', isEqualTo: now.year)
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final payment = Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        total += payment.amount;
      }
      return total;
    });
  }

  /// Get total revenue (all time)
  Future<double> getTotalRevenue() async {
    _checkAuth();
    try {
      final snapshot = await payments
          .where('status', isEqualTo: 'Paid')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final payment = Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        total += payment.amount;
      }
      return total;
    } catch (e) {
      debugPrint('❌ Error getting total revenue: $e');
      return 0.0;
    }
  }

  /// Get payment statistics for a month
  Future<Map<String, dynamic>> getMonthlyPaymentStats(int month, int year) async {
    _checkAuth();
    try {
      final snapshot = await payments
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      final allPayments = snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      final paidPayments = allPayments.where((p) => p.status == 'Paid').toList();
      final pendingPayments = allPayments.where((p) => p.status == 'Pending').toList();

      double totalRevenue = 0;
      for (var payment in paidPayments) {
        totalRevenue += payment.amount;
      }

      double pendingAmount = 0;
      for (var payment in pendingPayments) {
        pendingAmount += payment.amount;
      }

      return {
        'totalPayments': allPayments.length,
        'paidCount': paidPayments.length,
        'pendingCount': pendingPayments.length,
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
        'collectionRate': allPayments.isEmpty
            ? 0.0
            : (paidPayments.length / allPayments.length * 100),
      };
    } catch (e) {
      debugPrint('❌ Error getting monthly payment stats: $e');
      return {};
    }
  }

  /// DELETE payment
  Future<void> deletePayment(String paymentId) async {
    _checkAuth();
    try {
      await payments.doc(paymentId).delete();
      debugPrint('🗑️ Payment deleted: $paymentId');
    } catch (e) {
      debugPrint('❌ Error deleting payment: $e');
      rethrow;
    }
  }

  /// UPDATE payment
  Future<void> updatePayment(Payment payment) async {
    _checkAuth();
    try {
      await payments.doc(payment.id).update(payment.toMap());
      debugPrint('✅ Payment updated: ${payment.id}');
    } catch (e) {
      debugPrint('❌ Error updating payment: $e');
      rethrow;
    }
  }

  

  /// Get overdue payments
  Future<List<Payment>> getOverduePayments() async {
    _checkAuth();
    try {
      final now = DateTime.now();
      final snapshot = await payments
          .where('status', isEqualTo: 'Pending')
          .get();

      return snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((payment) => payment.dueDate.isBefore(now))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting overdue payments: $e');
      return [];
    }
  }

  /// Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange(DateTime start, DateTime end) async {
    _checkAuth();
    try {
      final snapshot = await payments
          .where('paymentDate', isGreaterThanOrEqualTo: start)
          .where('paymentDate', isLessThanOrEqualTo: end)
          .orderBy('paymentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting payments by date range: $e');
      return [];
    }
  }

  // ============ TRAINERS ============

  Stream<List<Trainer>> getTrainers() {
    _checkAuth();
    return trainers.snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Trainer.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addTrainer(Trainer trainer) async {
    _checkAuth();
    await trainers.doc(trainer.id).set(trainer.toMap());
  }

  Future<void> updateTrainer(Trainer trainer) async {
    _checkAuth();
    await trainers.doc(trainer.id).update(trainer.toMap());
  }

  Future<void> deleteTrainer(String id) async {
    _checkAuth();
    await trainers.doc(id).delete();
  }

  // ============ PLANS ============

  Stream<List<Plan>> getPlans() {
    _checkAuth();
    return plans.snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Plan.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addPlan(Plan plan) async {
    _checkAuth();
    await plans.doc(plan.id).set(plan.toMap());
  }

  Future<void> updatePlan(Plan plan) async {
    _checkAuth();
    await plans.doc(plan.id).update(plan.toMap());
  }

  Future<void> deletePlan(String id) async {
    _checkAuth();
    await plans.doc(id).delete();
  }

  // ============ HELPER METHODS ============

  /// Get member by phone number
  Future<Member?> getMemberByPhone(String phone) async {
    _checkAuth();
    try {
      final snapshot = await members.where('phone', isEqualTo: phone).get();
      if (snapshot.docs.isNotEmpty) {
        return Member.fromMap(snapshot.docs.first.id, snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting member by phone: $e');
      return null;
    }
  }

  /// Get member by email
  Future<Member?> getMemberByEmail(String email) async {
    _checkAuth();
    try {
      final snapshot = await members.where('email', isEqualTo: email).get();
      if (snapshot.docs.isNotEmpty) {
        return Member.fromMap(snapshot.docs.first.id, snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting member by email: $e');
      return null;
    }
  }

  /// Get upcoming expirations (next 30 days)
  Future<List<Member>> getUpcomingExpirations(int days) async {
    _checkAuth();
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: days));

      final snapshot = await members.get();

      return snapshot.docs
          .map((doc) => Member.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((member) {
        return member.expiryDate.isAfter(now) &&
            member.expiryDate.isBefore(endDate);
      })
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting upcoming expirations: $e');
      return [];
    }
  }

  /// Get monthly membership growth
  Future<Map<String, int>> getMonthlyMembershipGrowth() async {
    _checkAuth();
    try {
      final now = DateTime.now();

      final snapshot = await members.get();
      final allMembers = snapshot.docs
          .map((doc) => Member.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      final result = <String, int>{};

      for (int i = 0; i < 6; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormat('MMM yyyy').format(month);

        final count = allMembers
            .where((member) =>
        member.joinDate.year == month.year &&
            member.joinDate.month == month.month)
            .length;

        result[monthKey] = count;
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error getting membership growth: $e');
      return {};
    }
  }
}