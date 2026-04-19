import '../models/user_model.dart';

/// Mock authentication service - replaces Firebase Auth for frontend testing
class MockAuthService {
  // Mock current user
  UserModel? _currentUser;
  
  // Mock users database
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'uid': '1',
      'email': 'donor@example.com',
      'password': '123456',
      'name': 'John Doe',
      'role': 'donor',
      'bloodGroup': 'O+',
      'phoneNumber': '+1234567890',
      'location': 'New York',
      'rewardPoints': 150,
      'isEligible': true,
    },
    {
      'uid': '2',
      'email': 'receiver@example.com',
      'password': '123456',
      'name': 'Jane Smith',
      'role': 'receiver',
      'bloodGroup': 'A+',
      'phoneNumber': '+1234567891',
      'location': 'Los Angeles',
      'rewardPoints': 0,
      'isEligible': true,
    },
    {
      'uid': '3',
      'email': 'admin@example.com',
      'password': '123456',
      'name': 'Admin User',
      'role': 'admin',
      'bloodGroup': 'B+',
      'phoneNumber': '+1234567892',
      'location': 'Chicago',
      'rewardPoints': 0,
      'isEligible': true,
    },
  ];

  /// Get current user
  UserModel? get currentUser => _currentUser;

  /// Sign in with email and password (mock)
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final userData = _mockUsers.firstWhere(
      (user) => user['email'] == email && user['password'] == password,
      orElse: () => {},
    );

    if (userData.isEmpty) {
      throw Exception('Invalid email or password');
    }

    _currentUser = UserModel(
      uid: userData['uid'] as String,
      email: userData['email'] as String,
      phoneNumber: userData['phoneNumber'] as String?,
      name: userData['name'] as String,
      role: userData['role'] as String,
      bloodGroup: userData['bloodGroup'] as String?,
      location: userData['location'] as String?,
      rewardPoints: userData['rewardPoints'] as int? ?? 0,
      createdAt: DateTime.now(),
      isEligible: userData['isEligible'] as bool? ?? true,
    );

    return true;
  }

  /// Sign up with email and password (mock)
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? bloodGroup,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if email already exists
    if (_mockUsers.any((user) => user['email'] == email)) {
      throw Exception('Email already in use');
    }

    final newUserId = (_mockUsers.length + 1).toString();

    final newUser = {
      'uid': newUserId,
      'email': email,
      'password': password,
      'name': name,
      'role': role,
      'bloodGroup': bloodGroup,
      'phoneNumber': phoneNumber,
      'location': '',
      'rewardPoints': 0,
      'isEligible': true,
    };

    _mockUsers.add(newUser);

    _currentUser = UserModel(
      uid: newUserId,
      email: email,
      phoneNumber: phoneNumber,
      name: name,
      role: role,
      bloodGroup: bloodGroup,
      location: '',
      rewardPoints: 0,
      createdAt: DateTime.now(),
      isEligible: true,
    );

    return true;
  }

  /// Get user data (mock)
  Future<UserModel?> getUserData(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }

  /// Update user data (mock)
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: data['name'] ?? _currentUser!.name,
        phoneNumber: data['phoneNumber'] ?? _currentUser!.phoneNumber,
        location: data['location'] ?? _currentUser!.location,
        role: data['role'] ?? _currentUser!.role,
        rewardPoints: data['rewardPoints'] ?? _currentUser!.rewardPoints,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// Reset password (mock)
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock implementation - just return success
  }
}
