import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/providers.dart';
import '../../models/conversation.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myConversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't load chats")),
        data: (convos) {
          if (convos.isEmpty) return const _EmptyChats();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myConversationsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: convos.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (context, i) => _ConversationRow(convo: convos[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.convo});

  final Conversation convo;

  @override
  Widget build(BuildContext context) {
    final other = convo.otherParty;
    final unread = convo.unreadCount > 0;
    return InkWell(
      onTap: () => context.push('/chat/thread/${convo.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.navy,
              child: Text(
                other.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          other.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (other.verifiedStatus) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 15, color: AppColors.green),
                      ],
                      const Spacer(),
                      Text(
                        shortTimestamp(convo.lastMessage?.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: unread ? AppColors.orange : AppColors.textMuted,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    convo.contextLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.lastMessage?.body ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: unread
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.chat_bubble_outline, size: 56, color: AppColors.textMuted),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'Threads open from a deal or a request.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
