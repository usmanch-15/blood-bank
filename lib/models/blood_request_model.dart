/// Blood request model
class BloodRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String bloodGroup;
  final int quantity; // in units
  final String hospitalName;
  final String location;
  final double? latitude;
  final double? longitude;
  final String urgency; // normal, urgent, emergency
  final String status; // pending, fulfilled, cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final List<String> notifiedDonors; // List of donor UIDs who were notified

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    required this.bloodGroup,
    required this.quantity,
    required this.hospitalName,
    required this.location,
    this.latitude,
    this.longitude,
    this.urgency = 'normal',
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    this.fulfilledAt,
    this.notifiedDonors = const [],
  });

  /// Create BloodRequestModel from Firestore document
  factory BloodRequestModel.fromFirestore(Map<String, dynamic> json, String id) {
    return BloodRequestModel(
      id: id,
      requesterId: json['requesterId'] ?? '',
      requesterName: json['requesterName'] ?? '',
      requesterPhone: json['requesterPhone'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      quantity: json['quantity'] ?? 1,
      hospitalName: json['hospitalName'] ?? '',
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      urgency: json['urgency'] ?? 'normal',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      fulfilledAt: json['fulfilledAt']?.toDate(),
      notifiedDonors: List<String>.from(json['notifiedDonors'] ?? []),
    );
  }

  /// Convert BloodRequestModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'bloodGroup': bloodGroup,
      'quantity': quantity,
      'hospitalName': hospitalName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'urgency': urgency,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
      'fulfilledAt': fulfilledAt,
      'notifiedDonors': notifiedDonors,
    };
  }
}
