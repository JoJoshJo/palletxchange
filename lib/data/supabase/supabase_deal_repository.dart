import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/deal.dart';
import '../repositories/deal_repository.dart';

/// Real [DealRepository]. The deal state machine + reserve-on-accept inventory
/// and completed_at stamping are enforced by DB triggers (BRAIN §7) — this
/// repo only reads and writes deal rows; it never does inventory math.
class SupabaseDealRepository implements DealRepository {
  SupabaseClient get _c => Supabase.instance.client;

  /// Guard against string-built filters: the id must be a valid UUID.
  static final _uuidRe = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  @override
  Future<List<Deal>> getDealsForUser(String userId,
      {int limit = 25, int offset = 0}) async {
    if (!_uuidRe.hasMatch(userId)) return const [];
    final rows = await _c
        .from('deals')
        .select()
        .or('buyer_id.eq.$userId,seller_id.eq.$userId,driver_id.eq.$userId')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List).map((r) => Deal.fromJson(r)).toList();
  }

  @override
  Future<List<Deal>> getAllDeals({int limit = 25, int offset = 0}) async {
    final rows = await _c
        .from('deals')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List).map((r) => Deal.fromJson(r)).toList();
  }

  @override
  Future<Deal?> getDealById(String id) async {
    final row = await _c.from('deals').select().eq('id', id).maybeSingle();
    return row == null ? null : Deal.fromJson(row);
  }

  @override
  Future<Deal> createDeal(Deal deal) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');
    final payload = deal.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('total_price'); // computed by trigger
    payload['buyer_id'] = uid; // trust the session
    final row = await _c.from('deals').insert(payload).select().single();
    return Deal.fromJson(row);
  }

  @override
  Future<int> activeDealCountForListing(String listingId) async {
    final rows = await _c
        .from('deals')
        .select('id')
        .eq('listing_id', listingId)
        .inFilter('deal_status', ['pending', 'accepted']);
    return (rows as List).length;
  }

  @override
  Future<Deal> updateDeal(Deal deal) async {
    final payload = deal.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('total_price'); // trigger recomputes
    final row = await _c
        .from('deals')
        .update(payload)
        .eq('id', deal.id)
        .select()
        .maybeSingle();
    return row == null ? deal : Deal.fromJson(row);
  }
}
