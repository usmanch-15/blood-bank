import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ── Dual-role support ──────────────────────────────────────────────
  // `role` field ab sirf "abhi kis mode mein hai" (active/UI mode) batata hai.
  // isDonor / isReceiver capability flags hain jo ek dafa true hone ke
  // baad wapis false nahi hote — is se user donor + receiver dono ban
  // sakta hai aur role switch karne par donor search se gayab nahi hota.
  final bool isDonor;
  final bool isReceiver;

  // Donor availability toggle — ab Firestore mein persist hota hai.
  final bool isAvailable;

  // Query-time eligibility ke liye stored timestamp (90-day rule).
  // Client ke app kholne ka intezar nahi karna padta — seedha
  // `where('nextEligibleDate', isLessThanOrEqualTo: now)` query chalti hai.
  final DateTime? nextEligibleDate;

  final bool phoneVerified;

  // ✅ NEW — admin approval on signup was removed; this is how admins now
  // see genuine activity instead (set by AuthService on every successful
  // login). Null means the account has never logged in yet.
  final DateTime? lastLoginAt;

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
    this.isDonor = false,
    this.isReceiver = false,
    this.isAvailable = true,
    this.nextEligibleDate,
    this.phoneVerified = false,
    this.lastLoginAt,
  });

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
      isDonor: json['isDonor'] ?? (json['role'] == 'donor'),
      isReceiver: json['isReceiver'] ?? (json['role'] == 'receiver'),
      isAvailable: json['isAvailable'] ?? true,
      nextEligibleDate: (json['nextEligibleDate'] as Timestamp?)?.toDate(),
      phoneVerified: json['phoneVerified'] ?? false,
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
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
      'isDonor': isDonor,
      'isReceiver': isReceiver,
      'isAvailable': isAvailable,
      'nextEligibleDate': nextEligibleDate,
      'phoneVerified': phoneVerified,
      'lastLoginAt': lastLoginAt,
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
    bool? isDonor,
    bool? isReceiver,
    bool? isAvailable,
    DateTime? nextEligibleDate,
    bool? phoneVerified,
    DateTime? lastLoginAt,
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
      isDonor: isDonor ?? this.isDonor,
      isReceiver: isReceiver ?? this.isReceiver,
      isAvailable: isAvailable ?? this.isAvailable,
      nextEligibleDate: nextEligibleDate ?? this.nextEligibleDate,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}