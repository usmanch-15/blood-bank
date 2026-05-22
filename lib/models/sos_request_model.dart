class SosRequestModel {
  final String id;
  final String receiverId;
  final String bloodGroup;
  final double latitude;
  final double longitude;
  final DateTime triggerTime;
  final bool isResolved;
  final List<String> notifiedDonors;

  SosRequestModel({
    required this.id,
    required this.receiverId,
    required this.bloodGroup,
    required this.latitude,
    required this.longitude,
    required this.triggerTime,
    this.isResolved = false,
    this.notifiedDonors = const [],
  });

  factory SosRequestModel.fromFirestore(Map<String, dynamic> json, String id) {
    return SosRequestModel(
      id: id,
      receiverId: json['receiverId'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      triggerTime: json['triggerTime']?.toDate() ?? DateTime.now(),
      isResolved: json['isResolved'] ?? false,
      notifiedDonors: List<String>.from(json['notifiedDonors'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'receiverId': receiverId,
      'bloodGroup': bloodGroup,
      'latitude': latitude,
      'longitude': longitude,
      'triggerTime': triggerTime,
      'isResolved': isResolved,
      'notifiedDonors': notifiedDonors,
    };
  }

  SosRequestModel copyWith({bool? isResolved, List<String>? notifiedDonors}) {
    return SosRequestModel(
      id: id,
      receiverId: receiverId,
      bloodGroup: bloodGroup,
      latitude: latitude,
      longitude: longitude,
      triggerTime: triggerTime,
      isResolved: isResolved ?? this.isResolved,
      notifiedDonors: notifiedDonors ?? this.notifiedDonors,
    );
  }
}