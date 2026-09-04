import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';

/// Confirms then blocks [userId]. One-directional; no notice to the other user.
Future<void> confirmBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  String? name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Block ${name ?? 'this user'}?'),
      content: const Text(
        "They won't appear in your marketplace, and you can't start new deals "
        'or messages with them. Existing history stays. They are not notified.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC0392B),
            minimumSize: const Size(88, 44),
          ),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(blockServiceProvider).block(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blocked ${name ?? 'user'}')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't block — try again")),
      );
    }
  }
}

Future<void> unblockUser(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  String? name,
}) async {
  try {
    await ref.read(blockServiceProvider).unblock(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unblocked ${name ?? 'user'}')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't unblock — try again")),
      );
    }
  }
}

/// A banner shown on a blocked user's storefront in place of their listings.
class BlockedNotice extends StatelessWidget {
  const BlockedNotice({super.key, required this.onUnblock});

  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.block, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            "You've blocked this user",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Their listings are hidden and you can't contact them.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onUnblock,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
