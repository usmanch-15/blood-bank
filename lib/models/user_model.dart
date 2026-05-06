/// User model for the application
class UserModel {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String name;
  final String role; // donor, receiver, admin
  final String? bloodGroup;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? profileImageUrl;
  final int rewardPoints;
  final DateTime createdAt;
  final DateTime? lastDonationDate;
  final bool isEligible;
  final String status; // 'pending', 'approved', 'rejected'

  UserModel({
    required this.uid,
    required this.email,
    this.phoneNumber,
    required this.name,
    required this.role,
    this.bloodGroup,
    this.location,
    this.latitude,
    this.longitude,
    this.profileImageUrl,
    this.rewardPoints = 0,
    required this.createdAt,
    this.lastDonationDate,
    this.isEligible = true,
    this.status = 'pending', // ← naya field
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      name: json['name'] ?? '',
      role: json['role'] ?? 'donor',
      bloodGroup: json['bloodGroup'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      profileImageUrl: json['profileImageUrl'],
      rewardPoints: json['rewardPoints'] ?? 0,
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      lastDonationDate: json['lastDonationDate']?.toDate(),
      isEligible: json['isEligible'] ?? true,
      status: json['status'] ?? 'pending', // ← naya field
    );
  }

  /// Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'name': name,
      'role': role,
      'bloodGroup': bloodGroup,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'profileImageUrl': profileImageUrl,
      'rewardPoints': rewardPoints,
      'createdAt': createdAt,
      'lastDonationDate': lastDonationDate,
      'isEligible': isEligible,
      'status': status, // ← naya field
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? name,
    String? role,
    String? bloodGroup,
    String? location,
    double? latitude,
    double? longitude,
    String? profileImageUrl,
    int? rewardPoints,
    DateTime? createdAt,
    DateTime? lastDonationDate,
    bool? isEligible,
    String? status, // ← naya field
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      role: role ?? this.role,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      createdAt: createdAt ?? this.createdAt,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      isEligible: isEligible ?? this.isEligible,
      status: status ?? this.status, // ← naya field
    );
  }
}