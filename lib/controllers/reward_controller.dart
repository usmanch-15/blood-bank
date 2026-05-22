import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';
import '../services/certificate_service.dart';
import '../constants/app_constants.dart';

class RewardController extends ChangeNotifier {
  final CertificateService _certificateService = CertificateService();

  RewardModel? _reward;
  bool _isLoading = false;

  RewardModel? get reward => _reward;
  bool get isLoading => _isLoading;
  int get totalPoints => _reward?.totalPoints ?? 0;
  String get tier => _reward?.tier ?? 'bronze';

  Future<void> loadReward(String donorId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rewards')
          .where('donorId', isEqualTo: donorId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final d = snapshot.docs.first;
        _reward = RewardModel.fromFirestore(d.data(), d.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRewardForDonation({
    required String donorId,
    required String donorName,
    required String bloodGroup,
    required String donationId,
    required String donationDate,
    int points = 50,
  }) async {
    final certificateUrl = await _certificateService.generateAndUpload(
      donorName: donorName,
      bloodGroup: bloodGroup,
      donationDate: donationDate,
      donorId: donorId,
      donationId: donationId,
    );

    final existing = await FirebaseFirestore.instance
        .collection('rewards')
        .where('donorId', isEqualTo: donorId)
        .limit(1)
        .get();

    final newPoints = totalPoints + points;
    final newTier = RewardModel.getTierFromPoints(newPoints);
    final newCert = Certificate(
      id: donationId,
      title: 'Donation Certificate',
      description: 'Blood Group: $bloodGroup',
      imageUrl: certificateUrl,
      issuedDate: DateTime.now(),
      criteria: '1 donation',
    );

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final current = RewardModel.fromFirestore(doc.data(), doc.id);
      await FirebaseFirestore.instance
          .collection('rewards')
          .doc(doc.id)
          .update({
        'totalPoints': newPoints,
        'tier': newTier,
        'certificates': [
          ...current.certificates.map((c) => c.toMap()),
          newCert.toMap()
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance.collection('rewards').add({
        'donorId': donorId,
        'totalPoints': points,
        'tier': newTier,
        'certificates': [newCert.toMap()],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(donorId)
        .update({'rewardPoints': FieldValue.increment(points)});

    await loadReward(donorId);
  }
}