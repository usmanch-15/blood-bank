import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ReceiverModel extends UserModel {
  ReceiverModel({
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
    super.isDonor,
    super.isReceiver,
    super.isAvailable,
    super.nextEligibleDate,
    super.phoneVerified,
  });

  factory ReceiverModel.fromFirestore(Map<String, dynamic> json, String uid) {
    return ReceiverModel(
      uid: uid,
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      name: json['name'] ?? '',
      role: json['role'] ?? 'receiver',
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
      isDonor: json['isDonor'] ?? false,
      isReceiver: json['isReceiver'] ?? (json['role'] == 'receiver'),
      isAvailable: json['isAvailable'] ?? true,
      nextEligibleDate: (json['nextEligibleDate'] as Timestamp?)?.toDate(),
      phoneVerified: json['phoneVerified'] ?? false,
    );
  }
}