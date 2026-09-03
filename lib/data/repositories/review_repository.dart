import '../../models/review.dart';

abstract interface class ReviewRepository {
  /// Whether [reviewerId] has already reviewed [dealId] (one review per user
  /// per deal — BRAIN §7).
  Future<bool> hasReviewed({required String dealId, required String reviewerId});

  Future<Review> createReview(Review review);

  Future<List<Review>> getReviewsForUser(String userId);
}
