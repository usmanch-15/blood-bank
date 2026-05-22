import 'user_model.dart';

class DonorModel extends UserModel {
  DonorModel({
    required super.uid,
    required super.email,
    super.phoneNumber,
    required super.name,
    required super.role,
    super.bloodGroup,
    super.location,
    super.latitude,
    super.longitude,
    super.profileImageUrl,
    super.rewardPoints,
    required super.createdAt,
    super.lastDonationDate,
    super.isEligible,
    super.status,
  });

  factory DonorModel.fromFirestore(Map<String, dynamic> json, String uid) {
    return DonorModel(
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
      status: json['status'] ?? 'pending',
    );
  }

  @override
  DonorModel copyWith({
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
    String? status,
  }) {
    return DonorModel(
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
      status: status ?? this.status,
    );
  }
}