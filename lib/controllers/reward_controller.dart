import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';
import '../services/certificate_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Rewards are awarded by the confirmation transaction, never by the client.
class RewardController extends ChangeNotifier {
  RewardModel? _reward;
  DocumentSnapshot<Map<String, dynamic>>? _lastDonation;
  bool hasMore = true;
  bool loadingMore = false;
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
    _lastDonation = null;
    hasMore = true;
    notifyListeners();
    try {
      final db = FirebaseFirestore.instance;
      final user = await db.collection('users').doc(donorId).get();
      final legacy =
          await db
              .collection('rewards')
              .where('donorId', isEqualTo: donorId)
              .limit(1)
              .get();
      final donations =
          await db
              .collection('donations')
              .where('donorId', isEqualTo: donorId)
              .orderBy('donationDate', descending: true)
              .limit(30)
              .get();
      _lastDonation = donations.docs.isEmpty ? null : donations.docs.last;
      hasMore = donations.size == 30;
      final certificates = <String, Certificate>{};
      for (final doc in legacy.docs) {
        for (final cert
            in RewardModel.fromFirestore(doc.data(), doc.id).certificates) {
          certificates[cert.id] = cert;
        }
      }
      for (final doc in donations.docs) {
        final data = doc.data();
        certificates[doc.id] = Certificate(
          id: doc.id,
          title: 'Donation Certificate',
          description: 'Blood Group: ${data['bloodGroup'] ?? ''}',
          imageUrl: data['certificateUrl'] as String?,
          issuedDate: (data['donationDate'] as Timestamp).toDate(),
          criteria: 'Confirmed donation',
          pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
        );
      }
      final points = (user.data()?['rewardPoints'] as num?)?.toInt() ?? 0;
      _reward = RewardModel(
        id: donorId,
        donorId: donorId,
        totalPoints: points,
        certificates: certificates.values.toList(),
        lastUpdated: DateTime.now(),
        tier: RewardModel.getTierFromPoints(points),
      );
    } catch (_) {
      _error = 'Unable to load rewards. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _reward == null || !hasMore || loadingMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      var query = FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: uid)
          .orderBy('donationDate', descending: true)
          .limit(30);
      if (_lastDonation != null)
        query = query.startAfterDocument(_lastDonation!);
      final page = await query.get();
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      final certificates = [..._reward!.certificates];
      for (final doc in page.docs) {
        final d = doc.data();
        certificates.add(
          Certificate(
            id: doc.id,
            title: 'Donation acknowledgement',
            description: 'Blood group: ${d['bloodGroup']}',
            imageUrl: d['certificateUrl'] as String?,
            issuedDate: (d['donationDate'] as Timestamp).toDate(),
            criteria: 'Confirmed donation',
            pointsEarned: (d['pointsEarned'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      if (page.docs.isNotEmpty) _lastDonation = page.docs.last;
      hasMore = page.size == 30;
      _reward = RewardModel(
        id: uid,
        donorId: uid,
        totalPoints: totalPoints,
        certificates: certificates,
        lastUpdated: DateTime.now(),
        tier: tier,
      );
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> generateCertificate(String donationId) async {
    if (!_generating.add(donationId)) return;
    notifyListeners();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('Sign in to generate a certificate.');
      final ref = FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId);
      final data = (await ref.get()).data();
      if (data == null || data['donorId'] != uid) {
        throw StateError('This donation does not belong to your account.');
      }
      final date = (data['donationDate'] as Timestamp).toDate();
      final url = await CertificateService().generateAndUpload(
        donorName: data['donorName'] as String? ?? '',
        bloodGroup: data['bloodGroup'] as String? ?? '',
        donationDate: '${date.day}/${date.month}/${date.year}',
        donorId: uid,
        donationId: donationId,
      );
      await ref.update({'certificateUrl': url});
      await loadReward(uid);
    } finally {
      _generating.remove(donationId);
      notifyListeners();
    }
  }
}
