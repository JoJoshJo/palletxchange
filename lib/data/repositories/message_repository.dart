import '../../models/conversation.dart';
import '../../models/message.dart';

abstract interface class MessageRepository {
  /// Thread summaries visible to [userId], newest activity first.
  Future<List<Conversation>> getConversationsForUser(String userId);

  Future<Conversation?> getConversationById(String conversationId);

  /// The conversation attached to a deal, if one exists.
  Future<Conversation?> getConversationForDeal(String dealId);

  /// Creates the conversation if it doesn't exist yet (opened from a deal's
  /// Message button), else returns the existing one.
  Future<Conversation> ensureConversation(Conversation conversation);

  Future<List<Message>> getMessages(String conversationId);

  /// Appends a message and returns the stored copy.
  Future<Message> sendMessage(Message message);

  /// Marks every message in the thread addressed to [userId] as read.
  Future<void> markRead({
    required String conversationId,
    required String userId,
  });
}
