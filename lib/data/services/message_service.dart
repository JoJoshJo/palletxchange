import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation.dart';
import '../../models/deal.dart';
import '../../models/listing.dart';
import '../../models/message.dart';
import '../../models/profile.dart';
import '../../models/request.dart';
import '../chat_ids.dart';
import '../providers.dart';

/// Thread helpers. A thread is keyed to the deal/request that opened it; its
/// metadata is derived from that id, so opening a thread is just returning the
/// deterministic conversation id — no bare DMs (BRAIN §5).
class MessageService {
  MessageService(this.ref);

  final Ref ref;

  Future<String> openDealThread(Deal deal) async {
    ref.invalidate(myConversationsProvider);
    return convIdForDeal(deal.id);
  }

  /// First message that opens a deal's thread.
  Future<void> sendDealOpener(Deal deal, Listing listing) async {
    final me = ref.read(currentUserProvider);
    await ref.read(messageRepositoryProvider).sendMessage(
          Message(
            id: 'pending',
            conversationId: convIdForDeal(deal.id),
            senderId: me.id,
            receiverId: deal.sellerId,
            dealId: deal.id,
            body: 'Hi — I\'d like ${deal.quantity} of "${listing.title}". '
                'Can we set this up?',
          ),
        );
    ref.invalidate(myConversationsProvider);
    ref.invalidate(messagesProvider(convIdForDeal(deal.id)));
  }

  /// Opens a thread for a targeted Special Request with an initial message.
  Future<String> openRequestThread(
    PalletRequest request,
    Profile seller,
  ) async {
    final me = ref.read(currentUserProvider);
    final convId = convIdForRequest(request.id);
    await ref.read(messageRepositoryProvider).sendMessage(
          Message(
            id: 'pending',
            conversationId: convId,
            senderId: me.id,
            receiverId: seller.id,
            requestId: request.id,
            body: 'Special request: ${request.quantityNeeded}× '
                '${request.palletTypeNeeded?.label ?? 'pallets'}. '
                'Do you have these?',
          ),
        );
    ref.invalidate(myConversationsProvider);
    return convId;
  }

  Future<void> send({
    required Conversation conversation,
    required String body,
  }) async {
    final me = ref.read(currentUserProvider);
    await ref.read(messageRepositoryProvider).sendMessage(
          Message(
            id: 'pending',
            conversationId: conversation.id,
            senderId: me.id,
            receiverId: conversation.otherParty.id,
            dealId: conversation.dealId,
            requestId: conversation.requestId,
            body: body,
          ),
        );
    ref.invalidate(messagesProvider(conversation.id));
    ref.invalidate(myConversationsProvider);
  }

  Future<void> markRead(String conversationId) async {
    final me = ref.read(currentUserProvider);
    await ref
        .read(messageRepositoryProvider)
        .markRead(conversationId: conversationId, userId: me.id);
    ref.invalidate(myConversationsProvider);
    ref.invalidate(conversationByIdProvider(conversationId));
  }
}
