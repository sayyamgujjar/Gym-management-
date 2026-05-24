import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member.dart';
import '../models/payment.dart';
import '../models/trainer.dart';

class FirestoreService {

  final FirebaseFirestore db = FirebaseFirestore.instance;

  // COLLECTIONS

  CollectionReference get members =>
      db.collection('members');

  CollectionReference get payments =>
      db.collection('payments');

  CollectionReference get trainers =>
      db.collection('trainers');

  // =========================================================
  // MEMBERS
  // =========================================================

  Stream<List<Member>> getMembers() {

    return members.snapshots().map((snapshot) {

      return snapshot.docs.map((doc) {

        return Member.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

      }).toList();
    });
  }

  // ADD MEMBER

  Future<void> addMember(Member member) async {

    await members.doc(member.id).set(
      member.toMap(),
    );
  }

  // DELETE MEMBER

  Future<void> deleteMember(String id) async {

    await members.doc(id).delete();
  }

  // UPDATE MEMBER

  Future<void> updateMember(Member member) async {

    await members.doc(member.id).update(
      member.toMap(),
    );
  }

  // =========================================================
  // PAYMENTS
  // =========================================================

  Stream<List<Payment>> getPayments() {

    return payments.snapshots().map((snapshot) {

      return snapshot.docs.map((doc) {

        return Payment.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

      }).toList();
    });
  }

  // ADD PAYMENT

  Future<void> addPayment(Payment payment) async {

    await payments.doc(payment.id).set(
      payment.toMap(),
    );
  }

  // DELETE PAYMENT

  Future<void> deletePayment(String id) async {

    await payments.doc(id).delete();
  }

  // =========================================================
  // TRAINERS
  // =========================================================

  Stream<List<Trainer>> getTrainers() {

    return trainers.snapshots().map((snapshot) {

      return snapshot.docs.map((doc) {

        return Trainer.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

      }).toList();
    });
  }

  // ADD TRAINER

  Future<void> addTrainer(Trainer trainer) async {

    await trainers.doc(trainer.id).set(
      trainer.toMap(),
    );
  }

  // DELETE TRAINER

  Future<void> deleteTrainer(String id) async {

    await trainers.doc(id).delete();
  }

  // UPDATE TRAINER

  Future<void> updateTrainer(Trainer trainer) async {

    await trainers.doc(trainer.id).update(
      trainer.toMap(),
    );
  }
}