import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AdminController extends ChangeNotifier {
  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  int _totalDonors = 0;
  int _totalReceivers = 0;
  int _totalRequests = 0;
  int _totalDonations = 0;

  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  int get totalDonors => _totalDonors;
  int get totalReceivers => _totalReceivers;
  int get totalRequests => _totalRequests;
  int get totalDonations => _totalDonations;

  Future<void> loadStats(dynamic AppConstants) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .get();
      _totalDonors =
          snapshot.docs.where((d) => d.data()['isDonor'] == true).length;
      _totalReceivers =
          snapshot.docs.where((d) => d.data()['isReceiver'] == true).length;

      final requests = await FirebaseFirestore.instance
          .collection(AppConstants.bloodRequestsCollection)
          .get();
      _totalRequests = requests.size;

      final donations = await FirebaseFirestore.instance
          .collection(AppConstants.donationsCollection)
          .get();
      _totalDonations = donations.size;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .get();
      _allUsers = snapshot.docs
          .map((d) => UserModel.fromFirestore(d.data(), d.id))
          .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveUser(String uid) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'status': 'approved'});
    await loadAllUsers();
  }

  Future<void> suspendUser(String uid) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'status': 'rejected'});
    await loadAllUsers();
  }

  Future<void> deleteUser(String uid) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
    await loadAllUsers();
  }
}