import 'enums.dart';

/// A user/listing/deal report (BRAIN §6). Insertable by any authed user;
/// resolved by an admin.
class Report {
  const Report({
    required this.id,
    required this.reportedBy,
    this.reportedUser,
    this.listingId,
    this.dealId,
    required this.reason,
    this.description,
    this.status = ReportStatus.open,
    this.adminNotes,
    this.createdAt,
    // UI-only.
    this.subjectLabel,
  });

  final String id;
  final String reportedBy;
  final String? reportedUser;
  final String? listingId;
  final String? dealId;
  final String reason;
  final String? description;
  final ReportStatus status;
  final String? adminNotes;
  final DateTime? createdAt;

  /// A human label for what was reported (e.g. the listing title).
  final String? subjectLabel;

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reportedBy: json['reported_by'] as String,
        reportedUser: json['reported_user'] as String?,
        listingId: json['listing_id'] as String?,
        dealId: json['deal_id'] as String?,
        reason: json['reason'] as String? ?? '',
        description: json['description'] as String?,
        status: ReportStatus.fromValue(json['status'] as String?) ??
            ReportStatus.open,
        adminNotes: json['admin_notes'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reported_by': reportedBy,
        'reported_user': reportedUser,
        'listing_id': listingId,
        'deal_id': dealId,
        'reason': reason,
        'description': description,
        'status': status.value,
        'admin_notes': adminNotes,
        'created_at': createdAt?.toIso8601String(),
      };

  Report copyWith({
    ReportStatus? status,
    String? adminNotes,
    String? subjectLabel,
  }) =>
      Report(
        id: id,
        reportedBy: reportedBy,
        reportedUser: reportedUser,
        listingId: listingId,
        dealId: dealId,
        reason: reason,
        description: description,
        status: status ?? this.status,
        adminNotes: adminNotes ?? this.adminNotes,
        createdAt: createdAt,
        subjectLabel: subjectLabel ?? this.subjectLabel,
      );
}
