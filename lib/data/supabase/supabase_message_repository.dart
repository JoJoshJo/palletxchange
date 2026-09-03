import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/profile.dart';
import '../chat_ids.dart';
import '../repositories/message_repository.dart';

/// Real [MessageRepository]. There is no `conversations` table — a thread is
/// derived from the deal/request encoded in its conversation_id, while the
/// `messages` table supplies the last message + unread count.
class SupabaseMessageRepository implements MessageRepository {
  SupabaseClient get _c => Supabase.instance.client;

  String get _uid => _c.auth.currentUser?.id ?? '';

  static const _pf =
      'id,name,business_name,verified_status,rating,account_type,email';

  // ── Messages ──

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final rows = await _c
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (rows as List).map((r) => Message.fromJson(r)).toList();
  }

  @override
  Future<Message> sendMessage(Message message) async {
    final payload = message.toJson()
      ..remove('id')
      ..remove('created_at');
    payload['sender_id'] = _uid; // trust the session
    final row =
        await _c.from('messages').insert(payload).select().single();
    return Message.fromJson(row);
  }

  @override
  Future<void> markRead({
    required String conversationId,
    required String userId,
  }) async {
    await _c
        .from('messages')
        .update({'read_status': true})
        .eq('conversation_id', conversationId)
        .eq('receiver_id', userId)
        .eq('read_status', false);
  }

  // ── Conversations (derived) ──

  @override
  Future<Conversation?> getConversationById(String conversationId) async {
    final meta = await _resolveMeta(conversationId);
    if (meta == null) return null;
    final msgs = await getMessages(conversationId);
    final unread =
        msgs.where((m) => m.receiverId == _uid && !m.readStatus).length;
    return meta.copyWith(
      lastMessage: msgs.isEmpty ? null : msgs.last,
      unreadCount: unread,
    );
  }

  @override
  Future<Conversation?> getConversationForDeal(String dealId) =>
      getConversationById(convIdForDeal(dealId));

  @override
  Future<Conversation> ensureConversation(Conversation conversation) async {
    // Nothing to persist — metadata is derived. Return as given.
    return conversation;
  }

  @override
  Future<List<Conversation>> getConversationsForUser(String userId) async {
    final rows = await _c
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    // Group by conversation_id; the first row per group is the latest message.
    final latest = <String, Message>{};
    final unread = <String, int>{};
    for (final r in (rows as List)) {
      final m = Message.fromJson(r);
      latest.putIfAbsent(m.conversationId, () => m);
      if (m.receiverId == userId && !m.readStatus) {
        unread[m.conversationId] = (unread[m.conversationId] ?? 0) + 1;
      }
    }

    final result = <Conversation>[];
    for (final entry in latest.entries) {
      final meta = await _resolveMeta(entry.key);
      if (meta == null) continue;
      result.add(meta.copyWith(
        lastMessage: entry.value,
        unreadCount: unread[entry.key] ?? 0,
      ));
    }
    return result;
  }

  /// Builds the party + label for a conversation from the deal/request it is
  /// keyed to. Returns null if the referenced deal/request is gone.
  Future<Conversation?> _resolveMeta(String conversationId) async {
    final dealId = dealIdFromConv(conversationId);
    if (dealId != null) {
      final row = await _c
          .from('deals')
          .select(
              'id,buyer_id,seller_id,buyer:profiles!deals_buyer_id_fkey($_pf),'
              'seller:profiles!deals_seller_id_fkey($_pf),listing:listings(title)')
          .eq('id', dealId)
          .maybeSingle();
      if (row == null) return null;
      final other = row['buyer_id'] == _uid ? row['seller'] : row['buyer'];
      final title = (row['listing'] as Map?)?['title'] as String? ?? 'Listing';
      return Conversation(
        id: conversationId,
        context: ConversationContext.deal,
        dealId: dealId,
        otherParty: Profile.fromJson(other as Map<String, dynamic>),
        contextLabel: 'Deal · $title',
      );
    }

    final reqId = requestIdFromConv(conversationId);
    if (reqId != null) {
      final row = await _c
          .from('requests')
          .select(
              'id,buyer_id,target_seller_id,quantity_needed,pallet_type_needed,'
              'buyer:profiles!requests_buyer_id_fkey($_pf),'
              'seller:profiles!requests_target_seller_id_fkey($_pf)')
          .eq('id', reqId)
          .maybeSingle();
      if (row == null) return null;
      final other = row['buyer_id'] == _uid ? row['seller'] : row['buyer'];
      if (other == null) return null;
      final qty = row['quantity_needed'];
      final type = row['pallet_type_needed'] ?? 'pallets';
      return Conversation(
        id: conversationId,
        context: ConversationContext.request,
        requestId: reqId,
        otherParty: Profile.fromJson(other as Map<String, dynamic>),
        contextLabel: 'Request · $qty× $type',
      );
    }

    return null;
  }
}
