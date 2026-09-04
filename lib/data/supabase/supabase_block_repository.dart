import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/block_repository.dart';

/// Real [BlockRepository] over the `blocks` table (RLS: blocker-only).
class SupabaseBlockRepository implements BlockRepository {
  SupabaseClient get _c => Supabase.instance.client;

  String get _uid => _c.auth.currentUser?.id ?? '';

  @override
  Future<List<String>> getMyBlockedIds() async {
    final rows = await _c
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', _uid);
    return (rows as List).map((r) => r['blocked_id'] as String).toList();
  }

  @override
  Future<void> block(String userId) async {
    await _c.from('blocks').upsert(
      {'blocker_id': _uid, 'blocked_id': userId},
      onConflict: 'blocker_id,blocked_id',
    );
  }

  @override
  Future<void> unblock(String userId) async {
    await _c
        .from('blocks')
        .delete()
        .eq('blocker_id', _uid)
        .eq('blocked_id', userId);
  }
}
