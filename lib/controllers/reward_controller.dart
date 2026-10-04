import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';
import '../services/certificate_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Rewards are awarded by the confirmation transaction, never by the client.
class RewardController extends ChangeNotifier {
  RewardModel? _reward;
  bool _isLoading = false;
  String? _error;
  final Set<String> _generating = {};
  bool generating(String id) => _generating.contains(id);
  RewardModel? get reward => _reward;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalPoints => _reward?.totalPoints ?? 0;
  String get tier => _reward?.tier ?? 'bronze';

  Future<void> loadReward(String donorId) async {
    _isLoading = true;
    _error = null;
    _reward = null;
    notifyListeners();
    try {
      final db = FirebaseFirestore.instance;
      final user = await db.collection('users').doc(donorId).get();
      final legacy = await db.collection('rewards')
          .where('donorId', isEqualTo: donorId).limit(1).get();
      final donations = await db.collection('donations')
          .where('donorId', isEqualTo: donorId)
          .orderBy('donationDate', descending: true).limit(100).get();
      final certificates = <String, Certificate>{};
      for (final doc in legacy.docs) {
        for (final cert in RewardModel.fromFirestore(doc.data(), doc.id).certificates) {
          certificates[cert.id] = cert;
        }
      }
      for (final doc in donations.docs) {
        final data = doc.data();
          certificates[doc.id] = Certificate(
            id: doc.id, title: 'Donation Certificate',
            description: 'Blood Group: ${data['bloodGroup'] ?? ''}',
            imageUrl: data['certificateUrl'] as String?,
            issuedDate: (data['donationDate'] as Timestamp).toDate(),
            criteria: 'Confirmed donation',
            pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
          );
      }
      final points = (user.data()?['rewardPoints'] as num?)?.toInt() ?? 0;
      _reward = RewardModel(id: donorId, donorId: donorId,
          totalPoints: points, certificates: certificates.values.toList(),
          lastUpdated: DateTime.now(), tier: RewardModel.getTierFromPoints(points));
    } catch (_) {
      _error = 'Unable to load rewards. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateCertificate(String donationId) async {
    if (!_generating.add(donationId)) return;
    notifyListeners();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('Sign in to generate a certificate.');
      final ref = FirebaseFirestore.instance.collection('donations').doc(donationId);
      final data = (await ref.get()).data();
      if (data == null || data['donorId'] != uid) {
        throw StateError('This donation does not belong to your account.');
      }
      final date = (data['donationDate'] as Timestamp).toDate();
      final url = await CertificateService().generateAndUpload(
        donorName: data['donorName'] as String? ?? '',
        bloodGroup: data['bloodGroup'] as String? ?? '',
        donationDate: '${date.day}/${date.month}/${date.year}',
        donorId: uid, donationId: donationId,
      );
      await ref.update({'certificateUrl': url});
      await loadReward(uid);
    } finally {
      _generating.remove(donationId);
      notifyListeners();
    }
  }
}
