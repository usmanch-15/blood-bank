import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blood_request_model.dart';
import '../models/donor_model.dart';
import '../services/geo_location_service.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';

class ReceiverController extends ChangeNotifier {
  final GeoLocationService _geoService = GeoLocationService();
  final NotificationService _notifService = NotificationService();

  List<BloodRequestModel> _myRequests = [];
  List<DonorModel> _nearbyDonors = [];
  bool _isLoading = false;
  bool _sosSent = false;

  List<BloodRequestModel> get myRequests => _myRequests;
  List<DonorModel> get nearbyDonors => _nearbyDonors;
  bool get isLoading => _isLoading;
  bool get sosSent => _sosSent;

  Future<void> submitBloodRequest({
    required String receiverId,
    required String bloodGroup,
    required String urgency,
    required String hospitalName,
    required String location,
    required double latitude,
    required double longitude,
    int quantity = 1,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final ref = FirebaseFirestore.instance
          .collection(AppConstants.bloodRequestsCollection)
          .doc();
      await ref.set({
        'id': ref.id,
        'requesterId': receiverId,
        'bloodGroup': bloodGroup,
        'urgency': urgency,
        'hospitalName': hospitalName,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'quantity': quantity,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'notifiedDonors': [],
      });

      final donors = await _geoService.findNearbyDonors(
        receiverLat: latitude,
        receiverLng: longitude,
        bloodGroup: bloodGroup,
      );

      if (donors.isNotEmpty) {
        await _notifService.sendToUsers(
          userIds: donors.map((d) => d.uid).toList(),
          title: 'Blood Needed: $bloodGroup',
          body: 'A patient at $hospitalName needs $bloodGroup blood.',
          type: 'blood_request',
          relatedId: ref.id,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendSosAlert({
    required String receiverId,
    required String bloodGroup,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final position = await _geoService.getCurrentLocation();

      _nearbyDonors = await _geoService.findNearbyDonors(
        receiverLat: position.latitude,
        receiverLng: position.longitude,
        bloodGroup: bloodGroup,
        radiusKm: AppConstants.nearbyRadius,
      );

      if (_nearbyDonors.isEmpty) {
        _nearbyDonors = await _geoService.findNearbyDonors(
          receiverLat: position.latitude,
          receiverLng: position.longitude,
          bloodGroup: bloodGroup,
          radiusKm: 30.0,
        );
      }

      final ref = FirebaseFirestore.instance.collection('sosRequests').doc();
      await ref.set({
        'id': ref.id,
        'receiverId': receiverId,
        'bloodGroup': bloodGroup,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'triggerTime': FieldValue.serverTimestamp(),
        'isResolved': false,
        'notifiedDonors': _nearbyDonors.map((d) => d.uid).toList(),
      });

      if (_nearbyDonors.isNotEmpty) {
        await _notifService.sendToUsers(
          userIds: _nearbyDonors.map((d) => d.uid).toList(),
          title: '🚨 URGENT: Blood Needed!',
          body: 'Emergency $bloodGroup blood required near you!',
          type: 'blood_request',
          relatedId: ref.id,
        );
      }

      _sosSent = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyRequests(String receiverId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.bloodRequestsCollection)
        .where('requesterId', isEqualTo: receiverId)
        .orderBy('createdAt', descending: true)
        .get();
    _myRequests = snapshot.docs
        .map((d) => BloodRequestModel.fromFirestore(d.data(), d.id))
        .toList();
    notifyListeners();
  }
}