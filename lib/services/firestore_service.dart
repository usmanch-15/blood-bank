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
