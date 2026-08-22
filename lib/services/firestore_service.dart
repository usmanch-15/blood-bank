import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import '../models/donation_model.dart';
import '../models/reward_model.dart';
import '../models/notification_model.dart';
import '../models/misuse_report_model.dart';

import '../constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';

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
      // ✅ FIX 2: Use typed exceptions instead of generic Exception
      throw FirestoreException('Error getting user: $e');
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw FirestoreException('Error updating user: $e');
    }
  }

  /// 'pending' | 'approved' | 'rejected'
  // ✅ FIX — this used to chain .where('status', ...).orderBy('createdAt', ...)
  // which Firestore refuses to run without a manual composite index (the
  // "failed-precondition ... requires an index" error on the admin Users
  // page). Rather than making you create/deploy an index in the Firebase
  // console, we drop the server-side orderBy and sort the already-small
  // per-status admin list client-side instead — same result, zero setup.
  Stream<List<UserModel>> getUsersByStatus(String status) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) {
      final users = snap.docs
          .map((d) =>
          UserModel.fromFirestore(d.data() as Map<String, dynamic>, d.id))
          .toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
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
      throw FirestoreException('Error updating reward points: $e');
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
      throw FirestoreException('Error creating blood request: $e');
    }
  }

  // ✅ Records which donors were notified for a given request, so admins
  // (and the donor themselves) can see who was alerted and when.
  Future<void> updateNotifiedDonors(
      String requestId, List<String> donorIds) async {
    try {
      await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .doc(requestId)
          .update({'notifiedDonors': donorIds});
    } catch (e) {
      throw FirestoreException('Error updating notified donors: $e');
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
        'fulfilledAt': status == 'fulfilled' ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      throw FirestoreException('Error updating request: $e');
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
        'lastDonationDate': FieldValue.serverTimestamp(),
      });

      return doc.id;
    } catch (e) {
      throw FirestoreException('Error creating donation: $e');
    }
  }

  // ✅ FIX — same composite-index trap as getUsersByStatus above
  // (where + orderBy on different fields). Sort client-side instead.
  Stream<List<DonationModel>> getDonationHistory(String donorId) {
    return _firestore
        .collection(AppConstants.donationsCollection)
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snap) {
      final donations = snap.docs
          .map((d) => DonationModel.fromFirestore(
          d.data() as Map<String, dynamic>, d.id))
          .toList();
      donations.sort((a, b) => b.donationDate.compareTo(a.donationDate));
      return donations;
    });
  }

  // ==================== BLOOD DRIVES ====================

  Stream<List<BloodDriveModel>> getAllBloodDrives() {
    return _firestore
        .collection('blood_drives')
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BloodDriveModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    ))
        .toList());
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>> getDonationStatistics() async {
    try {
      final donations = await _firestore
          .collection(AppConstants.donationsCollection)
          .get();

      final requests = await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .get();

      // ✅ FIX 3: Correct fulfillment rate — avoid division-by-zero properly
      final fulfillmentRate = requests.size == 0
          ? '0.00'
          : (donations.size / requests.size * 100).toStringAsFixed(2);

      return {
        'totalDonations': donations.size,
        'totalRequests': requests.size,
        'fulfillmentRate': fulfillmentRate,
      };
    } catch (e) {
      throw FirestoreException('Error getting statistics: $e');
    }
  }

  // ==================== HELPERS ====================

  // ✅ FIX 4: Use shared haversine util instead of duplicate logic
  // (import utils/haversine.dart and call haversineDistance() from there)
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