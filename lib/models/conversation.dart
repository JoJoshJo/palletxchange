import 'message.dart';
import 'profile.dart';

/// The context a thread hangs off — a deal or a request (never a bare DM).
enum ConversationContext { deal, request }

/// A chat thread summary derived from its messages (UI convenience; in Supabase
/// this is a query over `messages`). Keyed by [id] == conversation_id.
class Conversation {
  const Conversation({
    required this.id,
    required this.context,
    this.dealId,
    this.requestId,
    required this.otherParty,
    required this.contextLabel,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final ConversationContext context;
  final String? dealId;
  final String? requestId;

  /// The counterparty from the current user's perspective.
  final Profile otherParty;

  /// Short label shown on the row, e.g. "Deal · Grade-A 48×40".
  final String contextLabel;

  final Message? lastMessage;
  final int unreadCount;

  Conversation copyWith({
    Message? lastMessage,
    int? unreadCount,
  }) =>
      Conversation(
        id: id,
        context: context,
        dealId: dealId,
        requestId: requestId,
        otherParty: otherParty,
        contextLabel: contextLabel,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}
