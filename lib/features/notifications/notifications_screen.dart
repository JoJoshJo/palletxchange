import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../models/app_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fresh on open.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(notificationServiceProvider).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myNotificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationServiceProvider).markAllRead(),
            child: const Text('Mark all read',
                style: TextStyle(color: AppColors.onDark)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text("Couldn't load notifications")),
        data: (items) {
          if (items.isEmpty) return const _Empty();
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(notificationServiceProvider).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
              itemBuilder: (context, i) => _NotificationRow(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !item.read;
    return InkWell(
      onTap: () async {
        await ref.read(notificationServiceProvider).markRead(item.id);
        if (!context.mounted) return;
        _openTarget(context);
      },
      child: Container(
        color: unread ? AppColors.orange.withValues(alpha: 0.05) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _color(item.type).withValues(alpha: 0.12),
              child: Icon(_icon(item.type), size: 18, color: _color(item.type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        shortTimestamp(item.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
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
      ),
    );
  }

  void _openTarget(BuildContext context) {
    if (item.dealId != null) {
      context.push('/deals/deal/${item.dealId}');
    } else if (item.conversationId != null) {
      context.push('/chat/thread/${item.conversationId}');
    } else if (item.requestId != null) {
      context.push('/request/matches/${item.requestId}');
    }
  }

  static IconData _icon(String type) => switch (type) {
        'deal_requested' => Icons.handshake_outlined,
        'deal_accepted' => Icons.check_circle_outline,
        'deal_completed' => Icons.verified_outlined,
        'deal_update' => Icons.info_outline,
        'new_message' => Icons.chat_bubble_outline,
        'new_match' => Icons.auto_awesome,
        'review_received' => Icons.star_outline,
        'delivery_update' => Icons.local_shipping_outlined,
        _ => Icons.notifications_none,
      };

  static Color _color(String type) => switch (type) {
        'deal_accepted' || 'deal_completed' => AppColors.green,
        'new_message' => AppColors.teal,
        'review_received' => AppColors.orange,
        _ => AppColors.orange,
      };
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.notifications_none, size: 56, color: AppColors.textMuted),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No notifications yet',
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
            "Deal activity, messages and reviews will show up here.",
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Bell + unread badge for an app bar.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => context.push('/notifications'),
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
