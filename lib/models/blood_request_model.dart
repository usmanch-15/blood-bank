class BloodRequestModel {
  final String id;
  final String requesterId;

  final String requesterName;
  final String requesterPhone;

  final String patientName;
  final int patientAge;
  final String patientGender;

  final String bloodGroup;
  final int unitsRequired;

  final String hospitalName;
  final String hospitalAddress;

  final String location;
  final double? latitude;
  final double? longitude;

  final String urgency; // normal, urgent, emergency
  final String status; // pending, fulfilled, cancelled

  final String reason;
  final String contactNumber;

  final DateTime requiredBy;
  final DateTime createdAt;
  final DateTime? fulfilledAt;

  final String? notes;
  final List<String> notifiedDonors;

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,

    required this.patientName,
    required this.patientAge,
    required this.patientGender,

    required this.bloodGroup,
    required this.unitsRequired,

    required this.hospitalName,
    required this.hospitalAddress,

    required this.location,
    this.latitude,
    this.longitude,

    this.urgency = 'normal',
    this.status = 'pending',

    required this.reason,
    required this.contactNumber,
    required this.requiredBy,

    required this.createdAt,
    this.fulfilledAt,

    this.notes,
    this.notifiedDonors = const [],
  });

  factory BloodRequestModel.fromFirestore(
      Map<String, dynamic> json, String id) {
    return BloodRequestModel(
      id: id,
      requesterId: json['requesterId'] ?? '',
      requesterName: json['requesterName'] ?? '',
      requesterPhone: json['requesterPhone'] ?? '',

      patientName: json['patientName'] ?? '',
      patientAge: json['patientAge'] ?? 0,
      patientGender: json['patientGender'] ?? '',

      bloodGroup: json['bloodGroup'] ?? '',
      unitsRequired: json['unitsRequired'] ?? 1,

      hospitalName: json['hospitalName'] ?? '',
      hospitalAddress: json['hospitalAddress'] ?? '',

      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),

      urgency: json['urgency'] ?? 'normal',
      status: json['status'] ?? 'pending',

      reason: json['reason'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      requiredBy: json['requiredBy']?.toDate() ?? DateTime.now(),

      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      fulfilledAt: json['fulfilledAt']?.toDate(),

      notes: json['notes'],
      notifiedDonors: List<String>.from(json['notifiedDonors'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,

      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,

      'bloodGroup': bloodGroup,
      'unitsRequired': unitsRequired,

      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,

      'location': location,
      'latitude': latitude,
      'longitude': longitude,

      'urgency': urgency,
      'status': status,

      'reason': reason,
      'contactNumber': contactNumber,
      'requiredBy': requiredBy,

      'createdAt': createdAt,
      'fulfilledAt': fulfilledAt,

      'notes': notes,
      'notifiedDonors': notifiedDonors,
    };
  }

  BloodRequestModel copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? bloodGroup,
    int? unitsRequired,
    String? hospitalName,
    String? hospitalAddress,
    String? location,
    double? latitude,
    double? longitude,
    String? urgency,
    String? status,
    String? reason,
    String? contactNumber,
    DateTime? requiredBy,
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
      unitsRequired: unitsRequired ?? this.unitsRequired,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      contactNumber: contactNumber ?? this.contactNumber,
      requiredBy: requiredBy ?? this.requiredBy,
      createdAt: createdAt ?? this.createdAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      notes: notes ?? this.notes,
      notifiedDonors: notifiedDonors ?? this.notifiedDonors,
    );
  }
}