import '../../models/conversation.dart';
import '../../models/message.dart';
import '../repositories/message_repository.dart';
import 'fake_seed.dart';

/// In-memory [MessageRepository], seeded with a couple of threads matching the
/// seed deals. Conversation id convention: `conv_deal_<dealId>`.
class FakeMessageRepository implements MessageRepository {
  FakeMessageRepository() {
    _seed();
  }

  final Map<String, Conversation> _conversations = {};
  final List<Message> _messages = [];
  int _idSeq = 1;

  static String convIdForDeal(String dealId) => 'conv_deal_$dealId';

  void _seed() {
    final now = DateTime(2026, 8, 25, 9);

    // Thread on deal d2: me (buyer) ↔ Sunbelt Goods (s1), pickup coordination.
    final s1 = FakeSeed.sellerById('s1')!;
    final c2 = convIdForDeal('d2');
    _conversations[c2] = Conversation(
      id: c2,
      context: ConversationContext.deal,
      dealId: 'd2',
      otherParty: s1,
      contextLabel: 'Deal · Grade-A 48×40 GMA pallets',
    );
    _messages.addAll([
      Message(
        id: 'm_${_idSeq++}',
        conversationId: c2,
        senderId: 'me',
        receiverId: 's1',
        dealId: 'd2',
        body: 'Hi — confirming pickup for the 20 pallets. When works?',
        readStatus: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        id: 'm_${_idSeq++}',
        conversationId: c2,
        senderId: 's1',
        receiverId: 'me',
        dealId: 'd2',
        body: 'Thursday 8am, dock 4. Bring your own straps.',
        readStatus: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
      Message(
        id: 'm_${_idSeq++}',
        conversationId: c2,
        senderId: 'me',
        receiverId: 's1',
        dealId: 'd2',
        body: 'Perfect, see you then.',
        readStatus: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // Thread on deal d4: me (seller) ↔ Gwinnett Pallet Co. (s3), delivery Q.
    final s3 = FakeSeed.sellerById('s3')!;
    final c4 = convIdForDeal('d4');
    _conversations[c4] = Conversation(
      id: c4,
      context: ConversationContext.deal,
      dealId: 'd4',
      otherParty: s3,
      contextLabel: 'Deal · Standard 48x40 pallets',
    );
    _messages.add(
      Message(
        id: 'm_${_idSeq++}',
        conversationId: c4,
        senderId: 's3',
        receiverId: 'me',
        dealId: 'd4',
        body: 'Can you deliver the 15 pallets by Friday? Quote for delivery?',
        readStatus: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    );
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 120));

  Message? _lastMessage(String conversationId) {
    final msgs = _messages
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0))
          .compareTo(b.createdAt ?? DateTime(0)));
    return msgs.isEmpty ? null : msgs.last;
  }

  int _unread(String conversationId, String userId) => _messages
      .where((m) =>
          m.conversationId == conversationId &&
          m.receiverId == userId &&
          !m.readStatus)
      .length;

  Conversation _hydrate(Conversation c, String userId) => c.copyWith(
        lastMessage: _lastMessage(c.id),
        unreadCount: _unread(c.id, userId),
      );

  @override
  Future<List<Conversation>> getConversationsForUser(String userId) async {
    await _latency();
    final list =
        _conversations.values.map((c) => _hydrate(c, userId)).toList();
    list.sort((a, b) => (b.lastMessage?.createdAt ?? DateTime(0))
        .compareTo(a.lastMessage?.createdAt ?? DateTime(0)));
    return list;
  }

  @override
  Future<Conversation?> getConversationById(String conversationId) async {
    await _latency();
    final c = _conversations[conversationId];
    return c == null ? null : _hydrate(c, 'me');
  }

  @override
  Future<Conversation?> getConversationForDeal(String dealId) async {
    return getConversationById(convIdForDeal(dealId));
  }

  @override
  Future<Conversation> ensureConversation(Conversation conversation) async {
    await _latency();
    _conversations.putIfAbsent(conversation.id, () => conversation);
    return _hydrate(_conversations[conversation.id]!, 'me');
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    await _latency();
    return _messages
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0))
          .compareTo(b.createdAt ?? DateTime(0)));
  }

  @override
  Future<Message> sendMessage(Message message) async {
    await _latency();
    final stored = message.copyWith(
      id: 'm_${_idSeq++}',
      createdAt: DateTime.now(),
    );
    _messages.add(stored);
    return stored;
  }

  @override
  Future<void> markRead({
    required String conversationId,
    required String userId,
  }) async {
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.conversationId == conversationId &&
          m.receiverId == userId &&
          !m.readStatus) {
        _messages[i] = m.copyWith(readStatus: true);
      }
    }
  }
}
