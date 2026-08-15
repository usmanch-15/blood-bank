import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ NEW — confirmDonation Cloud Function
import '../models/donor_model.dart';
import '../models/donation_model.dart';
import '../utils/date_utils.dart';
import '../constants/app_constants.dart';

class DonorController extends ChangeNotifier {
  DonorModel? _donor;
  List<DonationModel> _donationHistory = [];
  bool _isLoading = false;
  bool _isAvailable = true;

  DonorModel? get donor => _donor;
  List<DonationModel> get donationHistory => _donationHistory;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  bool get isEligible => _donor?.isEligible ?? false;

  Future<void> loadDonor(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        _donor = DonorModel.fromFirestore(doc.data()!, doc.id);
        await _checkAndUpdateEligibility(uid);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndUpdateEligibility(String uid) async {
    if (_donor == null) return;
    final eligible = AppDateUtils.isEligible(_donor!.lastDonationDate);
    if (eligible != _donor!.isEligible) {
      _donor = _donor!.copyWith(isEligible: eligible);
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'isEligible': eligible});
    }
  }

  Future<void> loadDonationHistory(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.donationsCollection)
          .where('donorId', isEqualTo: uid)
          .orderBy('donationDate', descending: true)
          .get();
      _donationHistory = snapshot.docs
          .map((d) => DonationModel.fromFirestore(d.data(), d.id))
          .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? bloodGroup,
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (location != null) 'location': location,
    });
    await loadDonor(uid);
  }

  void toggleAvailability() {
    _isAvailable = !_isAvailable;
    notifyListeners();
  }

  DateTime? get nextEligibleDate {
    if (_donor?.lastDonationDate == null) return null;
    return AppDateUtils.nextEligibleDate(_donor!.lastDonationDate!);
  }

  int get daysRemaining {
    if (_donor?.lastDonationDate == null) return 0;
    return AppDateUtils.daysRemaining(_donor!.lastDonationDate!);
  }

  /// ✅ REWRITTEN — this used to write directly to Firestore from the
  /// client (update rewardPoints/lastDonationDate on the DONOR's doc,
  /// while the caller is the RECEIVER) — exactly what our Firestore
  /// security rules are designed to block (isOwner-only updates on
  /// rewardPoints), so this call would have failed with
  /// permission-denied the moment it was ever wired into a reachable
  /// screen. It also duplicated logic that already exists correctly,
  /// server-side, in the `confirmDonation` Cloud Function (functions/index.js).
  ///
  /// Now this just calls that Cloud Function via `cloud_functions`
  /// (already in pubspec.yaml, previously unused). The function requires
  /// EITHER the donor themself, or the requester of `requestId`, to be
  /// the one calling it — so `requestId` must be passed whenever this is
  /// called from a specific blood request's "Find Donors" flow.
  Future<void> confirmDonation({
    required String donorId,
    required String bloodGroup,
    String? requestId,
  }) async {
    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('confirmDonation');
      await callable.call({
        'donorId': donorId,
        'bloodGroup': bloodGroup,
        if (requestId != null) 'requestId': requestId,
      });
      notifyListeners();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to confirm donation');
    } catch (e) {
      throw Exception('Failed to confirm donation: $e');
    }
  }

  /// ✅ NEW — lets a donor decline an incoming blood request from their
  /// own dashboard. Donors have no write access to other users'
  /// `blood_requests` docs (only the requester or admin can update those —
  /// see firestore.rules), so this can't set a status on the request
  /// itself. Instead it records the decline on the donor's OWN user doc
  /// (which they're allowed to update), and the dashboard filters out any
  /// request id present in this list so declined requests stop showing
  /// up for this donor, on this and future sessions.
  Future<void> declineRequest({
    required String donorId,
    required String requestId,
  }) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(donorId)
        .update({
      'declinedRequestIds': FieldValue.arrayUnion([requestId]),
    });
    notifyListeners();
  }
}