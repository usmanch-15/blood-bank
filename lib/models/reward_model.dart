/// Reward and certificate model
class RewardModel {
  final String id;
  final String donorId;
  final int totalPoints;
  final List<Certificate> certificates;
  final DateTime lastUpdated;
  final String tier; // bronze, silver, gold, platinum

  RewardModel({
    required this.id,
    required this.donorId,
    required this.totalPoints,
    required this.certificates,
    required this.lastUpdated,
    this.tier = 'bronze',
  });

  /// Determine tier based on points
  static String getTierFromPoints(int points) {
    if (points >= 5000) return 'platinum';
    if (points >= 3000) return 'gold';
    if (points >= 1000) return 'silver';
    return 'bronze';
  }

  /// Create RewardModel from Firestore document
  factory RewardModel.fromFirestore(Map<String, dynamic> json, String id) {
    return RewardModel(
      id: id,
      donorId: json['donorId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      certificates: (json['certificates'] as List?)
              ?.map((cert) => Certificate.fromMap(cert))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated']?.toDate() ?? DateTime.now(),
      tier: json['tier'] ?? 'bronze',
    );
  }

  /// Convert RewardModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'totalPoints': totalPoints,
      'certificates': certificates.map((cert) => cert.toMap()).toList(),
      'lastUpdated': lastUpdated,
      'tier': tier,
    };
  }
}

/// Certificate model for achievements
class Certificate {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime issuedDate;
  final String criteria; // e.g., "5 donations", "100 points"

  Certificate({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.issuedDate,
    required this.criteria,
  });

  /// Create Certificate from map
  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      issuedDate: map['issuedDate']?.toDate() ?? DateTime.now(),
      criteria: map['criteria'] ?? '',
    );
  }

  /// Convert Certificate to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'issuedDate': issuedDate,
      'criteria': criteria,
    };
  }
}
