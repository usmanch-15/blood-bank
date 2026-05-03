/// Blood request model
class BloodRequestModel {
  final String id;
  final String requesterId;
  final String? requesterName;
  final String? requesterPhone;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final String bloodGroup;
  final int quantity;
  final int? unitsRequired;
  final String hospitalName;
  final String? hospitalAddress;
  final String location;
  final double? latitude;
  final double? longitude;
  final String urgency;
  final String? reason;
  final String? contactNumber;
  final DateTime? requiredBy;
  final String status;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final String? notes;
  final List<String> notifiedDonors;

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    this.requesterName,
    this.requesterPhone,
    this.patientName,
    this.patientAge,
    this.patientGender,
    required this.bloodGroup,
    this.quantity = 1,
    this.unitsRequired,
    required this.hospitalName,
    this.hospitalAddress,
    required this.location,
    this.latitude,
    this.longitude,
    this.urgency = 'normal',
    this.reason,
    this.contactNumber,
    this.requiredBy,
    this.status = 'pending',
    required this.createdAt,
    this.fulfilledAt,
    this.notes,
    this.notifiedDonors = const [],
  });

  /// Create BloodRequestModel from Firestore document
  factory BloodRequestModel.fromFirestore(Map<String, dynamic> json, String id) {
    return BloodRequestModel(
      id: id,
      requesterId: json['requesterId'] ?? '',
      requesterName: json['requesterName'],
      requesterPhone: json['requesterPhone'],
      patientName: json['patientName'],
      patientAge: json['patientAge'],
      patientGender: json['patientGender'],
      bloodGroup: json['bloodGroup'] ?? '',
      quantity: json['quantity'] ?? json['unitsRequired'] ?? 1,
      unitsRequired: json['unitsRequired'],
      hospitalName: json['hospitalName'] ?? '',
      hospitalAddress: json['hospitalAddress'],
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      urgency: json['urgency'] ?? 'normal',
      reason: json['reason'],
      contactNumber: json['contactNumber'],
      requiredBy: json['requiredBy']?.toDate(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      fulfilledAt: json['fulfilledAt']?.toDate(),
      notes: json['notes'],
      notifiedDonors: List<String>.from(json['notifiedDonors'] ?? []),
    );
  }

  /// Convert BloodRequestModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'bloodGroup': bloodGroup,
      'quantity': quantity,
      'unitsRequired': unitsRequired,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'urgency': urgency,
      'reason': reason,
      'contactNumber': contactNumber,
      'requiredBy': requiredBy,
      'status': status,
      'createdAt': createdAt,
      'fulfilledAt': fulfilledAt,
      'notes': notes,
      'notifiedDonors': notifiedDonors,
    };
  }

  /// Copy with method for updating
  BloodRequestModel copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? bloodGroup,
    int? quantity,
    int? unitsRequired,
    String? hospitalName,
    String? hospitalAddress,
    String? location,
    double? latitude,
    double? longitude,
    String? urgency,
    String? reason,
    String? contactNumber,
    DateTime? requiredBy,
    String? status,
    DateTime? createdAt,
    DateTime? fulfilledAt,
    String? notes,
    List<String>? notifiedDonors,
  }) {
    return BloodRequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      quantity: quantity ?? this.quantity,
      unitsRequired: unitsRequired ?? this.unitsRequired,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      urgency: urgency ?? this.urgency,
      reason: reason ?? this.reason,
      contactNumber: contactNumber ?? this.contactNumber,
      requiredBy: requiredBy ?? this.requiredBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      notes: notes ?? this.notes,
      notifiedDonors: notifiedDonors ?? this.notifiedDonors,
    );
  }
}