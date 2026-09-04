import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/image_pick.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../core/widgets/trust_widgets.dart';
import '../../data/providers.dart';
import '../../models/delivery.dart';
import 'widgets/route_line.dart';

class DriverJobsScreen extends ConsumerWidget {
  const DriverJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (!me.driverApproved) {
      return Scaffold(
        appBar: AppBar(title: const BrandWordmark()),
        body: const _PendingApproval(),
      );
    }
    final jobsAsync = ref.watch(openJobsProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: Column(
        children: [
          const _Header(),
          const Divider(height: 1),
          Expanded(
            child: jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text("Couldn't load jobs")),
              data: (jobs) {
                if (jobs.isEmpty) return const _EmptyJobs();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(openJobsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _JobCard(job: jobs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApproval extends ConsumerStatefulWidget {
  const _PendingApproval();

  @override
  ConsumerState<_PendingApproval> createState() => _PendingApprovalState();
}

class _PendingApprovalState extends ConsumerState<_PendingApproval> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final hasLicense =
        me.driverLicenseUrl != null && me.driverLicenseUrl!.isNotEmpty;
    final hasInsurance =
        me.driverInsuranceUrl != null && me.driverInsuranceUrl!.isNotEmpty;
    final submitted = hasLicense && hasInsurance;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined,
                size: 40, color: AppColors.teal),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Get approved to drive',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your license and insurance. An admin reviews them before you '
          'can claim jobs.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 24),
        _DocRow(
          label: 'Driver license',
          done: hasLicense,
          onTap: _busy ? null : () => _upload('license'),
        ),
        const SizedBox(height: 12),
        _DocRow(
          label: 'Insurance',
          done: hasInsurance,
          onTap: _busy ? null : () => _upload('insurance'),
        ),
        const SizedBox(height: 20),
        if (submitted)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_top, size: 18, color: AppColors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Submitted — pending review.',
                      style: TextStyle(color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _upload(String kind) async {
    final picked = await pickImage(context);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(driverServiceProvider).submitDoc(
            kind: kind,
            bytes: picked.bytes,
            fileExtension: picked.fileExtension,
            contentType: picked.contentType,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$kind uploaded')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't upload — try again")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.label, required this.done, required this.onTap});

  final String label;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.description_outlined,
              color: done ? AppColors.green : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(done ? 'Replace' : 'Upload'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: const Text(
        'Available jobs',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job});

  final Delivery job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RouteLine(
              from: job.pickupCity ?? '—',
              to: job.dropoffCity ?? '—',
            ),
            const SizedBox(height: 10),
            Text(
              job.listingTitle ?? 'Pallet delivery',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MetaTag(
                  icon: Icons.inventory_2_outlined,
                  label: '${job.quantity ?? 0} pallets',
                ),
                const SizedBox(width: 14),
                if (job.legMiles != null)
                  MetaTag(
                    icon: Icons.straighten,
                    label: distanceLabel(job.legMiles),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Text(
                  'Delivery fee',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(width: 6),
                Text(
                  moneyWhole(job.deliveryFee),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(deliveryServiceProvider).claim(job);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job claimed — see My Deliveries'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
                  child: const Text('Claim job'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.local_shipping_outlined, size: 56, color: AppColors.textMuted),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No open jobs right now',
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
            'New delivery jobs will appear here.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
