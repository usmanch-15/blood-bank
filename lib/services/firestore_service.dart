import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import '../models/donation_model.dart';
import '../models/reward_model.dart';
import '../models/notification_model.dart';
import '../models/misuse_report_model.dart';

import '../constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER ====================

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        uid,
      );
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> addRewardPoints(String uid, int points) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'rewardPoints': FieldValue.increment(points),
      });
    } catch (e) {
      throw Exception('Error updating reward points: $e');
    }
  }

  // ==================== BLOOD REQUEST ====================

  Future<String> createBloodRequest(BloodRequestModel request) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .add(request.toFirestore());

      return doc.id;
    } catch (e) {
      throw Exception('Error creating blood request: $e');
    }
  }

  Stream<List<BloodRequestModel>> getAllBloodRequests() {
    return _firestore
        .collection(AppConstants.bloodRequestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => BloodRequestModel.fromFirestore(
      d.data() as Map<String, dynamic>,
      d.id,
    ))
        .toList());
  }

  Future<void> updateBloodRequestStatus(String id, String status) async {
    try {
      await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .doc(id)
          .update({
        'status': status,
        'fulfilledAt': status == 'fulfilled' ? DateTime.now() : null,
      });
    } catch (e) {
      throw Exception('Error updating request: $e');
    }
  }

  // ==================== DONATION ====================

  Future<String> createDonation(DonationModel donation) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.donationsCollection)
          .add(donation.toFirestore());

      await addRewardPoints(donation.donorId, donation.pointsEarned);

      await updateUser(donation.donorId, {
        'lastDonationDate': DateTime.now(),
      });

      return doc.id;
    } catch (e) {
      throw Exception('Error creating donation: $e');
    }
  }

  Stream<List<DonationModel>> getDonationHistory(String donorId) {
    return _firestore
        .collection(AppConstants.donationsCollection)
        .where('donorId', isEqualTo: donorId)
        .orderBy('donationDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => DonationModel.fromFirestore(
      d.data() as Map<String, dynamic>,
      d.id,
    ))
        .toList());
  }

  // ==================== BLOOD DRIVES ====================

  Stream<List<BloodDriveModel>> getAllBloodDrives() {
    return _firestore
        .collection('blood_drives')
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return BloodDriveModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList());
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>> getDonationStatistics() async {
    try {
      final donations =
      await _firestore.collection(AppConstants.donationsCollection).get();

      final requests =
      await _firestore.collection(AppConstants.bloodRequestsCollection).get();

      return {
        'totalDonations': donations.size,
        'totalRequests': requests.size,
        'fulfillmentRate':
        (donations.size / (requests.size + 1) * 100).toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Error getting statistics: $e');
    }
  }

  // ==================== HELPERS ====================

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _deg(lat2 - lat1);
    final dLon = _deg(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg(lat1)) *
            cos(_deg(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg(double d) => d * (3.14159265359 / 180);
}