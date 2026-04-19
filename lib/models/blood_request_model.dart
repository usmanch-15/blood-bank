/// Blood request model
class BloodRequestModel {
  final String id;
  final String requesterId;
<<<<<<< HEAD
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
=======
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String bloodGroup;
  final int unitsRequired;
  final String hospitalName;
  final String hospitalAddress;
  final String urgency;
  final String reason;
  final String contactNumber;
  final DateTime requiredBy;
  final String status;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final String location;
  final List<String> notifiedDonors;
>>>>>>> 6a6249e (first commit)

  BloodRequestModel({
    required this.id,
    required this.requesterId,
<<<<<<< HEAD
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
=======
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.bloodGroup,
    required this.unitsRequired,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.urgency,
    required this.reason,
    required this.contactNumber,
    required this.requiredBy,
    this.status = 'pending',
    required this.createdAt,
    this.fulfilledAt,
    this.location = '',
>>>>>>> 6a6249e (first commit)
    this.notifiedDonors = const [],
  });

  /// Create BloodRequestModel from Firestore document
  factory BloodRequestModel.fromFirestore(Map<String, dynamic> json, String id) {
    return BloodRequestModel(
      id: id,
      requesterId: json['requesterId'] ?? '',
<<<<<<< HEAD
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
=======
      patientName: json['patientName'] ?? '',
      patientAge: json['patientAge'] ?? 0,
      patientGender: json['patientGender'] ?? 'Male',
      bloodGroup: json['bloodGroup'] ?? '',
      unitsRequired: json['unitsRequired'] ?? 1,
      hospitalName: json['hospitalName'] ?? '',
      hospitalAddress: json['hospitalAddress'] ?? '',
      urgency: json['urgency'] ?? 'Normal',
      reason: json['reason'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      requiredBy: json['requiredBy']?.toDate() ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      fulfilledAt: json['fulfilledAt']?.toDate(),
      location: json['location'] ?? '',
>>>>>>> 6a6249e (first commit)
      notifiedDonors: List<String>.from(json['notifiedDonors'] ?? []),
    );
  }

  /// Convert BloodRequestModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
<<<<<<< HEAD
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
=======
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'bloodGroup': bloodGroup,
      'unitsRequired': unitsRequired,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'urgency': urgency,
      'reason': reason,
      'contactNumber': contactNumber,
      'requiredBy': requiredBy,
      'status': status,
      'createdAt': createdAt,
      'fulfilledAt': fulfilledAt,
      'location': location,
      'notifiedDonors': notifiedDonors,
    };
  }

  /// Copy with method for updating
  BloodRequestModel copyWith({
    String? id,
    String? requesterId,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? bloodGroup,
    int? unitsRequired,
    String? hospitalName,
    String? hospitalAddress,
    String? urgency,
    String? reason,
    String? contactNumber,
    DateTime? requiredBy,
    String? status,
    DateTime? createdAt,
    DateTime? fulfilledAt,
    String? location,
    List<String>? notifiedDonors,
  }) {
    return BloodRequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsRequired: unitsRequired ?? this.unitsRequired,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      urgency: urgency ?? this.urgency,
      reason: reason ?? this.reason,
      contactNumber: contactNumber ?? this.contactNumber,
      requiredBy: requiredBy ?? this.requiredBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      location: location ?? this.location,
      notifiedDonors: notifiedDonors ?? this.notifiedDonors,
    );
  }
>>>>>>> 6a6249e (first commit)
}
