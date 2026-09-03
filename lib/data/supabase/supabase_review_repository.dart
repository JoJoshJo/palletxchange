import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/review.dart';
import '../repositories/review_repository.dart';

/// Real [ReviewRepository]. One review per user per deal is enforced by the
/// DB unique constraint; profiles.rating recompute is a DB trigger.
class SupabaseReviewRepository implements ReviewRepository {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Future<bool> hasReviewed({
    required String dealId,
    required String reviewerId,
  }) async {
    final rows = await _c
        .from('reviews')
        .select('id')
        .eq('deal_id', dealId)
        .eq('reviewer_id', reviewerId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  @override
  Future<Review> createReview(Review review) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');
    final payload = review.toJson()
      ..remove('id')
      ..remove('created_at');
    payload['reviewer_id'] = uid;
    final row = await _c.from('reviews').insert(payload).select().single();
    return Review.fromJson(row);
  }

  @override
  Future<List<Review>> getReviewsForUser(String userId) async {
    final rows = await _c
        .from('reviews')
        .select()
        .eq('reviewed_user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Review.fromJson(r)).toList();
  }
}
