/// A review left after a completed deal (BRAIN §6). Four category ratings plus
/// an overall rating (1–5).
class Review {
  const Review({
    required this.id,
    required this.dealId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    this.communicationRating,
    this.accuracyRating,
    this.deliveryRating,
    this.reviewText,
    this.createdAt,
  });

  final String id;
  final String dealId;
  final String reviewerId;
  final String reviewedUserId;
  final int rating;
  final int? communicationRating;
  final int? accuracyRating;
  final int? deliveryRating;
  final String? reviewText;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        dealId: json['deal_id'] as String,
        reviewerId: json['reviewer_id'] as String,
        reviewedUserId: json['reviewed_user_id'] as String,
        rating: json['rating'] as int? ?? 0,
        communicationRating: json['communication_rating'] as int?,
        accuracyRating: json['accuracy_rating'] as int?,
        deliveryRating: json['delivery_rating'] as int?,
        reviewText: json['review_text'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deal_id': dealId,
        'reviewer_id': reviewerId,
        'reviewed_user_id': reviewedUserId,
        'rating': rating,
        'communication_rating': communicationRating,
        'accuracy_rating': accuracyRating,
        'delivery_rating': deliveryRating,
        'review_text': reviewText,
        'created_at': createdAt?.toIso8601String(),
      };

  Review copyWith({
    String? id,
    String? dealId,
    String? reviewerId,
    String? reviewedUserId,
    int? rating,
    int? communicationRating,
    int? accuracyRating,
    int? deliveryRating,
    String? reviewText,
    DateTime? createdAt,
  }) =>
      Review(
        id: id ?? this.id,
        dealId: dealId ?? this.dealId,
        reviewerId: reviewerId ?? this.reviewerId,
        reviewedUserId: reviewedUserId ?? this.reviewedUserId,
        rating: rating ?? this.rating,
        communicationRating: communicationRating ?? this.communicationRating,
        accuracyRating: accuracyRating ?? this.accuracyRating,
        deliveryRating: deliveryRating ?? this.deliveryRating,
        reviewText: reviewText ?? this.reviewText,
        createdAt: createdAt ?? this.createdAt,
      );
}
