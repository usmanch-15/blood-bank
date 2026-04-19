/// Notification model for push notifications and blood drive alerts
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // blood_request, blood_drive, eligibility, reward
  final String? relatedId; // ID of related blood request/drive/etc
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Extra payload

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  /// Create NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(Map<String, dynamic> json, String id) {
    return NotificationModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'notification',
      relatedId: json['relatedId'],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  /// Convert NotificationModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'createdAt': createdAt,
      'isRead': isRead,
      'data': data,
    };
  }

  /// Copy with new values
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? relatedId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

/// Blood drive model for scheduled donation drives
class BloodDriveModel {
  final String id;
  final String title;
  final String description;
  final String? organizerName;
  final String? organizerPhone;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final List<String> bloodGroupsNeeded;
  final int targetDonations;
  final int currentDonations;

  BloodDriveModel({
    required this.id,
    required this.title,
    required this.description,
    this.organizerName,
    this.organizerPhone,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    required this.bloodGroupsNeeded,
    this.targetDonations = 100,
    this.currentDonations = 0,
  });

  /// Create BloodDriveModel from Firestore document
  factory BloodDriveModel.fromFirestore(Map<String, dynamic> json, String id) {
    return BloodDriveModel(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      organizerName: json['organizerName'],
      organizerPhone: json['organizerPhone'],
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      startDate: json['startDate']?.toDate() ?? DateTime.now(),
      endDate: json['endDate']?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'],
      bloodGroupsNeeded:
          List<String>.from(json['bloodGroupsNeeded'] ?? ['O+', 'O-', 'A+']),
      targetDonations: json['targetDonations'] ?? 100,
      currentDonations: json['currentDonations'] ?? 0,
    );
  }

  /// Convert BloodDriveModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'organizerName': organizerName,
      'organizerPhone': organizerPhone,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': startDate,
      'endDate': endDate,
      'imageUrl': imageUrl,
      'bloodGroupsNeeded': bloodGroupsNeeded,
      'targetDonations': targetDonations,
      'currentDonations': currentDonations,
    };
  }
}
