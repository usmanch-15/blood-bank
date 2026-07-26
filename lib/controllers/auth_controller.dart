import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isDonor => _currentUser?.role == 'donor';
  bool get isReceiver => _currentUser?.role == 'receiver';
  bool get isAdmin => _currentUser?.role == 'admin';

  /// ✅ NEW — keeps this controller in sync automatically.
  /// ----------------------------------------------------------------------
  /// login_screen.dart / signup_screen.dart / role_selection_screen.dart
  /// all sign the user in via AuthService directly, WITHOUT calling
  /// AuthController.login() — so without this listener, currentUser would
  /// stay null forever even after a successful login, and anything reading
  /// this controller (e.g. AppDrawer's auth.isDonor/isReceiver) would be
  /// silently wrong. Listening to FirebaseAuth.authStateChanges() means
  /// this stays correct no matter which screen performed the sign-in.
  AuthController() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    try {
      final data = await _authService.getUserData(firebaseUser.uid);
      if (data != null) {
        _currentUser = UserModel.fromFirestore(data, firebaseUser.uid);
        notifyListeners();
      }
    } catch (e) {
      // Network hiccup etc. — don't clear a possibly-valid currentUser
      // over a transient read failure; just log it.
      debugPrint('AuthController: failed to sync user data — $e');
    }
  }

  void _setLoading(bool val) { _isLoading = val; notifyListeners(); }
  void _setError(String? msg) { _errorMessage = msg; notifyListeners(); }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authService.signInWithEmailPassword(
          email: email, password: password);
      final data = await _authService.getUserData(credential.user!.uid);
      if (data != null) {
        _currentUser = UserModel.fromFirestore(data, credential.user!.uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String bloodGroup,
    required String role,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signupWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phone,
        bloodGroup: bloodGroup,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await NotificationService().clearDeviceToken(); // ✅ FIX: token cleanup
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}