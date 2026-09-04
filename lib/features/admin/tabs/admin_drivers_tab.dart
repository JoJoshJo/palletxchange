import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../models/profile.dart';
import '../../common/proof_image.dart';

class AdminDriversTab extends ConsumerWidget {
  const AdminDriversTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingDriversProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Couldn't load drivers")),
      data: (drivers) {
        if (drivers.isEmpty) {
          return const Center(
            child: Text('No drivers pending approval.',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _DriverReviewCard(driver: drivers[i]),
        );
      },
    );
  }
}

class _DriverReviewCard extends ConsumerStatefulWidget {
  const _DriverReviewCard({required this.driver});
  final Profile driver;

  @override
  ConsumerState<_DriverReviewCard> createState() => _DriverReviewCardState();
}

class _DriverReviewCardState extends ConsumerState<_DriverReviewCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.driver;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.name.isEmpty ? 'Driver' : d.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (d.city != null)
            Text('${d.city}, ${d.state ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Doc(label: 'License', path: d.driverLicenseUrl),
              const SizedBox(width: 12),
              _Doc(label: 'Insurance', path: d.driverInsuranceUrl),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _set(true),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _set(bool approved, {String? reason}) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminServiceProvider).setDriverApproved(
            widget.driver.id,
            approved: approved,
            reason: reason,
          );
      ref.invalidate(pendingDriversProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approved ? 'Driver approved' : 'Driver rejected')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action failed — try again")),
        );
      }
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject driver'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await _set(false, reason: reason.isEmpty ? null : reason);
  }
}

class _Doc extends StatelessWidget {
  const _Doc({required this.label, required this.path});
  final String label;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (path != null && path!.isNotEmpty)
          ProofImage(bucket: StorageBuckets.driverDocs, path: path!, size: 80)
        else
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.textMuted),
          ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
