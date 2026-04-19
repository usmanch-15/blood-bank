/// Misuse report model for admin handling
class MisuseReportModel {
  final String id;
  final String reporterId;
  final String? reportedUserId; // User being reported, if applicable
  final String reportType; // fraud, misuse, fake_profile, other
  final String title;
  final String description;
  final String? evidence; // URI or document reference
  final DateTime reportedAt;
  final String status; // pending, investigating, resolved, dismissed
  final String? adminNotes;
  final String? adminReviewedBy;
  final DateTime? resolvedAt;

  MisuseReportModel({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    required this.reportType,
    required this.title,
    required this.description,
    this.evidence,
    required this.reportedAt,
    this.status = 'pending',
    this.adminNotes,
    this.adminReviewedBy,
    this.resolvedAt,
  });

  /// Create MisuseReportModel from Firestore document
  factory MisuseReportModel.fromFirestore(Map<String, dynamic> json, String id) {
    return MisuseReportModel(
      id: id,
      reporterId: json['reporterId'] ?? '',
      reportedUserId: json['reportedUserId'],
      reportType: json['reportType'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      evidence: json['evidence'],
      reportedAt: json['reportedAt']?.toDate() ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      adminReviewedBy: json['adminReviewedBy'],
      resolvedAt: json['resolvedAt']?.toDate(),
    );
  }

  /// Convert MisuseReportModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportType': reportType,
      'title': title,
      'description': description,
      'evidence': evidence,
      'reportedAt': reportedAt,
      'status': status,
      'adminNotes': adminNotes,
      'adminReviewedBy': adminReviewedBy,
      'resolvedAt': resolvedAt,
    };
  }

  /// Copy with new values
  MisuseReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? reportType,
    String? title,
    String? description,
    String? evidence,
    DateTime? reportedAt,
    String? status,
    String? adminNotes,
    String? adminReviewedBy,
    DateTime? resolvedAt,
  }) {
    return MisuseReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportType: reportType ?? this.reportType,
      title: title ?? this.title,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      adminReviewedBy: adminReviewedBy ?? this.adminReviewedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
