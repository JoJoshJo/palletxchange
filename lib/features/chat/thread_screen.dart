import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../common/block_user.dart';
import '../common/report_user.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark the thread read once it opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageServiceProvider).markRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final convoAsync = ref.watch(conversationByIdProvider(widget.conversationId));
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

    final convo = convoAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(convo?.otherParty.displayName ?? 'Chat'),
        actions: [
          if (convo != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'report':
                    showReportUserSheet(context, ref,
                        reportedUserId: convo.otherParty.id,
                        subjectLabel: convo.otherParty.displayName);
                  case 'block':
                    confirmBlockUser(context, ref,
                        userId: convo.otherParty.id,
                        name: convo.otherParty.displayName);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report user')),
                PopupMenuItem(value: 'block', child: Text('Block user')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (convo != null) _ContextHeader(convo: convo),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text("Couldn't load messages")),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Say hello 👋',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    return _Bubble(message: m, mine: m.senderId == me.id);
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _input,
            sending: _sending,
            onSend: convo == null ? null : () => _send(convo),
          ),
        ],
      ),
    );
  }

  Future<void> _send(Conversation convo) async {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    _input.clear();
    await ref.read(messageServiceProvider).send(conversation: convo, body: body);
    if (mounted) setState(() => _sending = false);
  }
}

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({required this.convo});

  final Conversation convo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: convo.dealId == null
            ? null
            : () => context.push('/deals/deal/${convo.dealId}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.push_pin_outlined,
                  size: 15, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  convo.contextLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ),
              if (convo.dealId != null)
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : AppColors.bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: mine ? AppColors.onDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              clockTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine ? AppColors.onDarkMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend?.call(),
              decoration: const InputDecoration(
                hintText: 'Message',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            height: 52,
            child: ElevatedButton(
              onPressed: sending ? null : onSend,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(52, 52),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.arrow_upward, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
