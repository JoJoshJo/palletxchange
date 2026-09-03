import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation.dart';
import '../../models/deal.dart';
import '../../models/message.dart';
import '../../models/profile.dart';
import '../../models/request.dart';
import '../fake/fake_message_repository.dart';
import '../providers.dart';

class MessageService {
  MessageService(this.ref);

  final Ref ref;

  /// Ensures a chat thread exists for [deal] and returns its conversation id.
  /// Threads tie to the deal — never a bare DM (BRAIN §5).
  Future<String> openDealThread(Deal deal) async {
    final me = ref.read(currentUserProvider);
    final convId = FakeMessageRepository.convIdForDeal(deal.id);

    final existing =
        await ref.read(messageRepositoryProvider).getConversationById(convId);
    if (existing != null) return convId;

    final otherId = deal.buyerId == me.id ? deal.sellerId : deal.buyerId;
    final other =
        await ref.read(profileRepositoryProvider).getProfileById(otherId);
    final listing =
        await ref.read(listingRepositoryProvider).getListingById(deal.listingId);

    await ref.read(messageRepositoryProvider).ensureConversation(
          Conversation(
            id: convId,
            context: ConversationContext.deal,
            dealId: deal.id,
            otherParty: other!,
            contextLabel: 'Deal · ${listing?.title ?? 'Listing'}',
          ),
        );
    ref.invalidate(myConversationsProvider);
    return convId;
  }

  /// Opens a thread for a targeted Special Request (keyed by requestId), tied
  /// to the request — consistent with the no-bare-DMs rule (BRAIN §5).
  Future<String> openRequestThread(
    PalletRequest request,
    Profile seller,
  ) async {
    final convId = FakeMessageRepository.convIdForRequest(request.id);
    final existing =
        await ref.read(messageRepositoryProvider).getConversationById(convId);
    if (existing != null) return convId;

    await ref.read(messageRepositoryProvider).ensureConversation(
          Conversation(
            id: convId,
            context: ConversationContext.request,
            requestId: request.id,
            otherParty: seller,
            contextLabel:
                'Request · ${request.quantityNeeded}× ${request.palletTypeNeeded?.label ?? 'pallets'}',
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
