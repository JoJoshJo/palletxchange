import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/request.dart';
import '../repositories/request_repository.dart';

/// Real [RequestRepository] over the `requests` table.
class SupabaseRequestRepository implements RequestRepository {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Future<List<PalletRequest>> getOpenRequests() async {
    final rows = await _c
        .from('requests')
        .select()
        .isFilter('target_seller_id', null)
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => PalletRequest.fromJson(r)).toList();
  }

  @override
  Future<List<PalletRequest>> getRequestsByBuyer(String buyerId) async {
    final rows = await _c
        .from('requests')
        .select()
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => PalletRequest.fromJson(r)).toList();
  }

  @override
  Future<PalletRequest?> getRequestById(String id) async {
    final row =
        await _c.from('requests').select().eq('id', id).maybeSingle();
    return row == null ? null : PalletRequest.fromJson(row);
  }

  @override
  Future<PalletRequest> createRequest(PalletRequest request) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');
    final payload = request.toJson()
      ..remove('id')
      ..remove('created_at');
    payload['buyer_id'] = uid;
    final row =
        await _c.from('requests').insert(payload).select().single();
    return PalletRequest.fromJson(row);
  }
}
