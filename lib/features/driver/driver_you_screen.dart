import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/auth/app_auth.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';

class DriverYouScreen extends ConsumerWidget {
  const DriverYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = ref.watch(currentDriverProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.navy,
                child: Text(
                  driver.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (driver.rating != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.orange),
                          Text(
                            driver.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text(
                      'Driver',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _DriverDashboard(),
          const SizedBox(height: 24),
          if (driver.driverApproved)
            Row(
              children: const [
                Icon(Icons.verified, size: 18, color: AppColors.green),
                SizedBox(width: 8),
                Text('Approved driver',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            )
          else
            Row(
              children: const [
                Icon(Icons.hourglass_top, size: 18, color: AppColors.teal),
                SizedBox(width: 8),
                Text('Approval pending',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await appAuth.signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

/// Driver's own numbers, from real data.
class _DriverDashboard extends ConsumerWidget {
  const _DriverDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(openJobsProvider).valueOrNull?.length ?? 0;
    final deliveries = ref.watch(myDeliveriesProvider).valueOrNull ?? const [];
    final earnings = ref.watch(driverEarningsProvider).valueOrNull ?? 0;

    final active = deliveries
        .where((d) =>
            d.deliveryStatus != DeliveryStatus.completed &&
            d.deliveryStatus != DeliveryStatus.cancelled)
        .length;
    final completed = deliveries
        .where((d) => d.deliveryStatus == DeliveryStatus.completed)
        .length;

    return Column(
      children: [
        Row(
          children: [
            _DStat(value: '$jobs', label: 'Open jobs', icon: Icons.local_shipping_outlined, color: AppColors.orange),
            const SizedBox(width: 10),
            _DStat(value: '$active', label: 'Active', icon: Icons.route_outlined, color: AppColors.teal),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _DStat(value: '$completed', label: 'Completed', icon: Icons.check_circle_outline, color: AppColors.green),
            const SizedBox(width: 10),
            _DStat(value: moneyWhole(earnings), label: 'Earnings', icon: Icons.payments_outlined, color: AppColors.teal),
          ],
        ),
      ],
    );
  }
}

class _DStat extends StatelessWidget {
  const _DStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
