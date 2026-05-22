import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}