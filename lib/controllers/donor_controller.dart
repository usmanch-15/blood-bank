import 'package:firebase_auth/firebase_auth.dart';
import '../utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ NEW — confirmDonation Cloud Function
import '../models/donor_model.dart';
import '../models/donation_model.dart';
import '../utils/date_utils.dart';
import '../utils/location_helper.dart';
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
      final doc =
          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .get();
      if (doc.exists) {
        _donor = DonorModel.fromFirestore(doc.data()!, doc.id);
        _isAvailable = doc.data()?['isAvailable'] == true;
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
    }
  }

  /// ⚠️ SECURITY FIX: this method used to write `phoneNumber`, `latitude`,
  /// and `longitude` straight onto the top-level `users/{uid}` doc — which
  /// `firestore.rules` allows ANY signed-in user to read
  /// (`allow read: if isSignedIn();`). That would have leaked every donor's
  /// phone number the moment this method was ever wired up.
  ///
  /// Fixed to follow the same secure split used everywhere else in the app:
  ///   • phoneNumber → users/{uid}/private/contact (owner/admin read-only)
  ///   • latitude/longitude → top-level doc, but rounded to
  ///     [LocationHelper.privacyDecimalPlaces] so exact home address is
  ///     never stored (see LocationHelper.roundForPrivacy). This field is
  ///     intentionally public-but-approximate: it's what powers
  ///     findNearbyDonors() / the donor discovery map.
  ///   • name/bloodGroup/location(text) → top-level doc, unchanged
  ///     (never sensitive).
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? bloodGroup,
    double? latitude,
    double? longitude,
    String? location,
    String? address,
    String? cnic,
  }) async {
    final userRef = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid);

    if (name != null && AppValidators.validateName(name) != null) {
      throw ArgumentError(AppValidators.validateName(name));
    }
    if (phoneNumber != null) {
      throw StateError('Use phone verification to change your number.');
    }
    if (latitude != null || longitude != null) {
      final data = (await userRef.get()).data();
      if (data?['locationSharingEnabled'] != true) {
        throw StateError('Enable location sharing in Settings first.');
      }
    }
    final publicUpdates = <String, dynamic>{
      if (name != null) 'name': name,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (latitude != null)
        AppConstants.fieldLatitude: LocationHelper.roundForPrivacy(latitude),
      if (longitude != null)
        AppConstants.fieldLongitude: LocationHelper.roundForPrivacy(longitude),
      if (latitude != null || longitude != null)
        AppConstants.fieldLocationUpdatedAt: FieldValue.serverTimestamp(),
    };
    final batch = FirebaseFirestore.instance.batch();
    if (publicUpdates.isNotEmpty) batch.update(userRef, publicUpdates);
    if (cnic != null) {
      batch.set(userRef.collection('private').doc('contact'), {
        'cnic': cnic,
      }, SetOptions(merge: true));
    }
    await batch.commit();

    await loadDonor(uid);
  }

  Future<void> toggleAvailability() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in.');
    final next = !_isAvailable;
    await FirebaseFirestore.instance.doc('users/$uid').update({
      'isAvailable': next,
    });
    _isAvailable = next;
    notifyListeners();
  }

  Future<void> acceptRequest(String requestId) async {
    await FirebaseFunctions.instance.httpsCallable('acceptDonation').call({
      'requestId': requestId,
    });
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
      final callable = FirebaseFunctions.instance.httpsCallable(
        'confirmDonation',
      );
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
