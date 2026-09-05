import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../models/enums.dart';
import '../../../models/profile.dart';

/// Warehouses awaiting the verified badge.
class AdminVerificationTab extends ConsumerWidget {
  const AdminVerificationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allProfilesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Couldn't load")),
      data: (all) {
        final pending = all
            .where((p) =>
                p.accountType == AccountType.warehouse && !p.verifiedStatus)
            .toList();
        if (pending.isEmpty) {
          return const Center(
            child: Text('No businesses awaiting verification.',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _VerifyRow(profile: pending[i]),
        );
      },
    );
  }
}

class _VerifyRow extends ConsumerStatefulWidget {
  const _VerifyRow({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_VerifyRow> createState() => _VerifyRowState();
}

class _VerifyRowState extends ConsumerState<_VerifyRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text('${p.city ?? ''}${p.state != null ? ', ${p.state}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2))
              : ElevatedButton(
                  onPressed: _verify,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(96, 40)),
                  child: const Text('Verify'),
                ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminServiceProvider).toggleVerified(widget.profile);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed — try again')),
        );
      }
    }
  }
}
