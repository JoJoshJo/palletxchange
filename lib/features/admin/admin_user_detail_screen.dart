import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';
import '../../models/profile.dart';

/// Deals involving a given user (admin view).
final _userDealCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final deals = await ref.watch(dealRepositoryProvider).getDealsForUser(userId);
  return deals.length;
});

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profileByIdProvider(widget.userId));
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't load user")),
        data: (p) =>
            p == null ? const Center(child: Text('Not found')) : _body(p),
      ),
    );
  }

  Widget _body(Profile p) {
    final listings = ref.watch(sellerActiveListingsProvider(p.id));
    final deals = ref.watch(_userDealCountProvider(p.id));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.navy,
              child: Text(
                p.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.onDark, fontWeight: FontWeight.w700, fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(p.displayName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                      ),
                      if (p.verifiedStatus) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            size: 16, color: AppColors.green),
                      ],
                    ],
                  ),
                  Text('${p.accountType.label}${p.email != null ? ' · ${p.email}' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  if (p.banned)
                    const Text('SUSPENDED',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC0392B))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _stat('Active listings', listings.valueOrNull?.length.toString() ?? '—'),
            const SizedBox(width: 10),
            _stat('Deals', deals.valueOrNull?.toString() ?? '—'),
            const SizedBox(width: 10),
            _stat('Joined',
                p.createdAt == null ? '—' : DateFormat('MMM y').format(p.createdAt!)),
          ],
        ),
        const SizedBox(height: 24),
        if (p.accountType == AccountType.warehouse)
          _actionButton(
            label: p.verifiedStatus ? 'Remove verified badge' : 'Verify business',
            icon: Icons.verified_outlined,
            onTap: () => _toggleVerify(p),
          ),
        const SizedBox(height: 10),
        _actionButton(
          label: p.banned ? 'Unban user' : 'Ban user',
          icon: p.banned ? Icons.lock_open_outlined : Icons.block,
          danger: !p.banned,
          onTap: () => p.banned ? _setBanned(p, false) : _banWithReason(p),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      );

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: danger ? const Color(0xFFC0392B) : AppColors.textPrimary,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _toggleVerify(Profile p) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminServiceProvider).toggleVerified(p);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setBanned(Profile p, bool banned, {String? reason}) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminServiceProvider).setBanned(p.id, banned: banned, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(banned ? 'User banned' : 'User unbanned')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action failed — try again')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _banWithReason(Profile p) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ban ${p.displayName}?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await _setBanned(p, true, reason: reason.isEmpty ? null : reason);
  }
}
