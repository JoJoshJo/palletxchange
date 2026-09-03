import '../../models/review.dart';
import '../repositories/review_repository.dart';

class FakeReviewRepository implements ReviewRepository {
  final List<Review> _reviews = [];
  int _idSeq = 1;

  @override
  Future<bool> hasReviewed({
    required String dealId,
    required String reviewerId,
  }) async {
    return _reviews
        .any((r) => r.dealId == dealId && r.reviewerId == reviewerId);
  }

  @override
  Future<Review> createReview(Review review) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final stored = review.copyWith(
      id: 'rev_${_idSeq++}',
      createdAt: DateTime.now(),
    );
    _reviews.add(stored);
    return stored;
  }

  @override
  Future<List<Review>> getReviewsForUser(String userId) async {
    return _reviews.where((r) => r.reviewedUserId == userId).toList();
  }
}
