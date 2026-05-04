import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/mock_auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final MockAuthService _mockAuth = MockAuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get userRole => _user?.role ?? '';

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _mockAuth.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _user = _mockAuth.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? bloodGroup,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _mockAuth.signUpWithEmailPassword(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        bloodGroup: bloodGroup,
      );
      _user = _mockAuth.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _mockAuth.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
