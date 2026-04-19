/// Donation history model
class DonationModel {
  final String id;
  final String donorId;
  final String donorName;
  final String bloodGroup;
  final String? requestId; // If donation was for a specific request
  final DateTime donationDate;
  final String location;
  final int pointsEarned;
  final String? certificateUrl;
  final Map<String, dynamic>? healthCheckData; // BP, hemoglobin, etc.

  DonationModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.bloodGroup,
    this.requestId,
    required this.donationDate,
    required this.location,
    this.pointsEarned = 50, // Default points per donation
    this.certificateUrl,
    this.healthCheckData,
  });

  /// Create DonationModel from Firestore document
  factory DonationModel.fromFirestore(Map<String, dynamic> json, String id) {
    return DonationModel(
      id: id,
      donorId: json['donorId'] ?? '',
      donorName: json['donorName'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      requestId: json['requestId'],
      donationDate: json['donationDate']?.toDate() ?? DateTime.now(),
      location: json['location'] ?? '',
      pointsEarned: json['pointsEarned'] ?? 50,
      certificateUrl: json['certificateUrl'],
      healthCheckData: json['healthCheckData'],
    );
  }

  /// Convert DonationModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'bloodGroup': bloodGroup,
      'requestId': requestId,
      'donationDate': donationDate,
      'location': location,
      'pointsEarned': pointsEarned,
      'certificateUrl': certificateUrl,
      'healthCheckData': healthCheckData,
    };
  }
}
