import '../services/workflow_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/blood_request_model.dart';
import '../models/donor_model.dart';
import '../services/workflow_service.dart';
import '../constants/app_constants.dart';

class ReceiverController extends ChangeNotifier {
  List<BloodRequestModel> _myRequests = [];
  final List<DonorModel> _nearbyDonors = [];
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
      if (latitude.abs() > 90 || longitude.abs() > 180) {
        throw ArgumentError('A valid hospital pin is required.');
      }
      final result = await WorkflowService.call('createBloodRequest', {
        'requestId':
            FirebaseFirestore.instance.collection('blood_requests').doc().id,
        'bloodGroup': bloodGroup,
        'urgency': urgency,
        'hospitalName': hospitalName,
        'hospitalAddress': location,
        'latitude': latitude,
        'longitude': longitude,
        'quantity': quantity,
        'requiredBy':
            DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
        'contactNumber': '',
      });
      if (result['id'] == null) throw StateError('Request was not created.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> sendSosAlert({
    required String receiverId,
    required String bloodGroup,
    String urgency = 'critical',
    required double latitude,
    required double longitude,
    required String hospitalName,
    required String contactNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await WorkflowService.call('createSosAlert', {
        'bloodGroup': bloodGroup,
        'latitude': latitude,
        'longitude': longitude,
        'urgency': urgency,
        'hospitalName': hospitalName,
        'contactNumber': contactNumber,
      });
      _sosSent = true;
      return result['requestId'] as String;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
