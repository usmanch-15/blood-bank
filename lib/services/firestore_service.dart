<<<<<<< HEAD
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import '../models/user_model.dart';
// // import '../models/blood_request_model.dart';
// // import '../models/donation_model.dart';
// // import '../constants/app_constants.dart';
// //
// // /// Firestore service for database operations
// // class FirestoreService {
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //
// //   // ==================== User Operations ====================
// //
// //   /// Get user by UID
// //   Future<UserModel?> getUser(String uid) async {
// //     try {
// //       DocumentSnapshot doc = await _firestore
// //           .collection(AppConstants.usersCollection)
// //           .doc(uid)
// //           .get();
//
//       if (doc.exists) {
//         return UserModel.fromFirestore(
//           doc.data() as Map<String, dynamic>,
//           uid,
//         );
//       }
//       return null;
//     } catch (e) {
//       throw Exception('Error getting user: $e');
//     }
//   }
//
//   /// Get all users
//   Stream<List<UserModel>> getAllUsers() {
//     return _firestore
//         .collection(AppConstants.usersCollection)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => UserModel.fromFirestore(
//                   doc.data(),
//                   doc.id,
//                 ))
//             .toList());
//   }
//
//   /// Get users by role
//   Stream<List<UserModel>> getUsersByRole(String role) {
//     return _firestore
//         .collection(AppConstants.usersCollection)
//         .where('role', isEqualTo: role)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => UserModel.fromFirestore(
//                   doc.data(),
//                   doc.id,
//                 ))
//             .toList());
//   }
//
//   /// Update user eligibility
//   Future<void> updateUserEligibility(String uid, bool isEligible) async {
//     try {
//       await _firestore
//           .collection(AppConstants.usersCollection)
//           .doc(uid)
//           .update({'isEligible': isEligible});
//     } catch (e) {
//       throw Exception('Error updating user eligibility: $e');
//     }
//   }
//
//   // ==================== Blood Request Operations ====================
//
//   /// Create blood request
//   Future<String> createBloodRequest(BloodRequestModel request) async {
//     try {
//       DocumentReference docRef = await _firestore
//           .collection(AppConstants.bloodRequestsCollection)
//           .add(request.toFirestore());
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Error creating blood request: $e');
//     }
//   }
//
//   /// Get all blood requests
//   Stream<List<BloodRequestModel>> getAllBloodRequests() {
//     return _firestore
//         .collection(AppConstants.bloodRequestsCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => BloodRequestModel.fromFirestore(
//                   doc.data(),
//                   doc.id,
//                 ))
//             .toList());
//   }
//
//   /// Get blood requests by status
//   Stream<List<BloodRequestModel>> getBloodRequestsByStatus(String status) {
//     return _firestore
//         .collection(AppConstants.bloodRequestsCollection)
//         .where('status', isEqualTo: status)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => BloodRequestModel.fromFirestore(
//                   doc.data(),
//                   doc.id,
//                 ))
//             .toList());
//   }
//
//   /// Get blood requests by blood group
//   Stream<List<BloodRequestModel>> getBloodRequestsByBloodGroup(
//       String bloodGroup) {
//     return _firestore
//         .collection(AppConstants.bloodRequestsCollection)
//         .where('bloodGroup', isEqualTo: bloodGroup)
//         .where('status', isEqualTo: 'pending')
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => BloodRequestModel.fromFirestore(
//                   doc.data(),
//                   doc.id,
//                 ))
//             .toList());
//   }
//
//   /// Update blood request status
//   Future<void> updateBloodRequestStatus(String requestId, String status) async {
//     try {
//       Map<String, dynamic> updateData = {'status': status};
//       if (status == 'fulfilled') {
//         updateData['fulfilledAt'] = DateTime.now();
//       }
//       await _firestore
//           .collection(AppConstants.bloodRequestsCollection)
//           .doc(requestId)
//           .update(updateData);
//     } catch (e) {
//       throw Exception('Error updating blood request status: $e');
//     }
//   }
//
//   // ==================== Donation Operations ====================
//
//   /// Create donation record
//   Future<String> createDonation(DonationModel donation) async {
//     try {
//       DocumentReference docRef = await _firestore
//           .collection(AppConstants.donationsCollection)
//           .add(donation.toFirestore());
//
//       // Update user's last donation date and reward points
//       await _firestore
//           .collection(AppConstants.usersCollection)
//           .doc(donation.donorId)
//           .update({
//         'lastDonationDate': donation.donationDate,
//         'rewardPoints': FieldValue.increment(donation.pointsEarned),
//         'isEligible': false,
//       });
//
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Error creating donation: $e');
//     }
//   }
//
//   /// Get donations by donor ID
//   Stream<List<DonationModel>> getDonationsByDonor(String donorId) {
//     return _firestore
//         .collection(AppConstants.donationsCollection)
//         .where('donorId', isEqualTo: donorId)
//         .orderBy('donationDate', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => DonationModel.fromFirestore(
//                   doc.data(),
//                   doc.id,
//                 ))
//             .toList());
//   }
//
//   /// Get all donations
//   Stream<List<DonationModel>> getAllDonations() {
//     return _firestore
//         .collection(AppConstants.donationsCollection)
//         .orderBy('donationDate', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => DonationModel.fromFirestore(
//                   doc.data(),
//                   doc.id,
//                 ))
//             .toList());
//   }
//
//   // ==================== Admin Statistics ====================
//
//   /// Get dashboard statistics (mock data for now)
//   Future<Map<String, dynamic>> getDashboardStats() async {
//     try {
//       // Get counts from collections
//       QuerySnapshot usersSnapshot =
//           await _firestore.collection(AppConstants.usersCollection).get();
//       QuerySnapshot requestsSnapshot = await _firestore
//           .collection(AppConstants.bloodRequestsCollection)
//           .get();
//       QuerySnapshot donationsSnapshot =
//           await _firestore.collection(AppConstants.donationsCollection).get();
//
//       int totalUsers = usersSnapshot.docs.length;
//       int totalDonors = usersSnapshot.docs
//           .where((doc) => (doc.data() as Map<String, dynamic>)['role'] == AppConstants.roleDonor)
//           .length;
//       int totalReceivers = usersSnapshot.docs
//           .where((doc) => (doc.data() as Map<String, dynamic>)['role'] == AppConstants.roleReceiver)
//           .length;
//       int pendingRequests = requestsSnapshot.docs
//           .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending')
//           .length;
//       int totalDonations = donationsSnapshot.docs.length;
//
//       return {
//         'totalUsers': totalUsers,
//         'totalDonors': totalDonors,
//         'totalReceivers': totalReceivers,
//         'pendingRequests': pendingRequests,
//         'totalDonations': totalDonations,
//       };
//     } catch (e) {
//       throw Exception('Error getting dashboard stats: $e');
//     }
//   }
// }
=======
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import '../models/donation_model.dart';
import '../models/reward_model.dart';
import '../models/notification_model.dart';
import '../models/misuse_report_model.dart';
import '../constants/app_constants.dart';

/// Firestore service for complete database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== User Operations ====================

  /// Get user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          uid,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  /// Update user
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

  /// Add reward points to user
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

  /// Update user eligibility
  Future<void> updateUserEligibility(String uid, bool isEligible) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'isEligible': isEligible});
    } catch (e) {
      throw Exception('Error updating user eligibility: $e');
    }
  }

  /// Get users by role
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get nearby donors by location
  Future<List<UserModel>> getNearbyDonors(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleDonor)
          .where('isEligible', isEqualTo: true)
          .get();

      List<UserModel> nearbyDonors = [];

      for (var doc in snapshot.docs) {
        UserModel user = UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        if (user.latitude != null && user.longitude != null) {
          double distance = _calculateDistance(
            latitude,
            longitude,
            user.latitude!,
            user.longitude!,
          );

          if (distance <= radiusKm) {
            nearbyDonors.add(user);
          }
        }
      }

      // Sort by distance
      nearbyDonors.sort((a, b) {
        double distA = _calculateDistance(
          latitude,
          longitude,
          a.latitude ?? 0,
          a.longitude ?? 0,
        );
        double distB = _calculateDistance(
          latitude,
          longitude,
          b.latitude ?? 0,
          b.longitude ?? 0,
        );
        return distA.compareTo(distB);
      });

      return nearbyDonors;
    } catch (e) {
      throw Exception('Error getting nearby donors: $e');
    }
  }

  // ==================== Donation Operations ====================

  /// Create donation record
  Future<String> createDonation(DonationModel donation) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.donationsCollection)
          .add(donation.toFirestore());

      // Update user's last donation date and reward points
      await updateUser(donation.donorId, {
        'lastDonationDate': DateTime.now(),
      });

      await addRewardPoints(donation.donorId, donation.pointsEarned);

      return docRef.id;
    } catch (e) {
      throw Exception('Error creating donation: $e');
    }
  }

  /// Get donation history for a donor
  Stream<List<DonationModel>> getDonationHistory(String donorId) {
    return _firestore
        .collection(AppConstants.donationsCollection)
        .where('donorId', isEqualTo: donorId)
        .orderBy('donationDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DonationModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get all donations (for admin analytics)
  Stream<List<DonationModel>> getAllDonations() {
    return _firestore
        .collection(AppConstants.donationsCollection)
        .orderBy('donationDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DonationModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // ==================== Blood Request Operations ====================

  /// Create blood request
  Future<String> createBloodRequest(BloodRequestModel request) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating blood request: $e');
    }
  }

  /// Get all blood requests
  Stream<List<BloodRequestModel>> getAllBloodRequests() {
    return _firestore
        .collection(AppConstants.bloodRequestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get blood requests by status
  Stream<List<BloodRequestModel>> getBloodRequestsByStatus(String status) {
    return _firestore
        .collection(AppConstants.bloodRequestsCollection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get blood requests by blood group
  Stream<List<BloodRequestModel>> getBloodRequestsByBloodGroup(
    String bloodGroup,
  ) {
    return _firestore
        .collection(AppConstants.bloodRequestsCollection)
        .where('bloodGroup', isEqualTo: bloodGroup)
        .where('status', isEqualTo: 'pending')
        .orderBy('urgency')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Update blood request status
  Future<void> updateBloodRequestStatus(String requestId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .doc(requestId)
          .update({
            'status': status,
            'fulfilledAt': status == 'fulfilled' ? DateTime.now() : null,
          });
    } catch (e) {
      throw Exception('Error updating blood request: $e');
    }
  }

  // ==================== Reward Operations ====================

  /// Get or create reward record
  Future<RewardModel?> getRewards(String donorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('rewards')
          .where('donorId', isEqualTo: donorId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RewardModel.fromFirestore(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error getting rewards: $e');
    }
  }

  /// Update rewards
  Future<void> updateRewards(String rewardId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('rewards').doc(rewardId).update(data);
    } catch (e) {
      throw Exception('Error updating rewards: $e');
    }
  }

  /// Get certificate
  Future<Certificate?> getCertificate(String certificateId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('certificates').doc(certificateId).get();

      if (doc.exists) {
        return Certificate.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting certificate: $e');
    }
  }

  // ==================== Notification Operations ====================

  /// Create notification
  Future<String> createNotification(NotificationModel notification) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('notifications').add(
        notification.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  /// Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // ==================== Blood Drive Operations ====================

  /// Get all blood drives
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

  // ==================== Misuse Report Operations ====================

  /// Create misuse report
  Future<String> createMisuseReport(MisuseReportModel report) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('misuse_reports').add(
        report.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating misuse report: $e');
    }
  }

  /// Get all misuse reports (admin only)
  Stream<List<MisuseReportModel>> getAllMisuseReports() {
    return _firestore
        .collection('misuse_reports')
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MisuseReportModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get pending misuse reports
  Stream<List<MisuseReportModel>> getPendingMisuseReports() {
    return _firestore
        .collection('misuse_reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MisuseReportModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Update misuse report
  Future<void> updateMisuseReport(
    String reportId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('misuse_reports')
          .doc(reportId)
          .update(data);
    } catch (e) {
      throw Exception('Error updating misuse report: $e');
    }
  }

  // ==================== Analytics Operations ====================

  /// Get donation statistics
  Future<Map<String, dynamic>> getDonationStatistics() async {
    try {
      QuerySnapshot donations =
          await _firestore.collection(AppConstants.donationsCollection).get();
      QuerySnapshot requests = await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .get();

      return {
        'totalDonations': donations.size,
        'totalRequests': requests.size,
        'fulfillmentRate': (donations.size / (requests.size + 1) * 100)
            .toStringAsFixed(2),
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Error getting donation statistics: $e');
    }
  }

  /// Get blood group statistics
  Future<Map<String, int>> getBloodGroupDemand() async {
    try {
      Map<String, int> bloodGroupDemand = {};

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.bloodRequestsCollection)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in snapshot.docs) {
        BloodRequestModel request = BloodRequestModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        bloodGroupDemand[request.bloodGroup] =
            (bloodGroupDemand[request.bloodGroup] ?? 0) + request.unitsRequired;
      }

      return bloodGroupDemand;
    } catch (e) {
      throw Exception('Error getting blood group demand: $e');
    }
  }

  // ==================== Helper Methods ====================

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Kilometers
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}
>>>>>>> 6a6249e (first commit)
