import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';
import 'widgets/route_line.dart';

class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(driverEarningsProvider);
    final deliveriesAsync = ref.watch(myDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total earned',
                  style: TextStyle(color: AppColors.onDarkMuted, fontSize: 14),
                ),
                const SizedBox(height: 6),
                earningsAsync.when(
                  loading: () => const Text(
                    '—',
                    style: TextStyle(
                      color: AppColors.onDark,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  error: (_, _) => const Text('—'),
                  data: (total) => Text(
                    moneyWhole(total),
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'From completed deliveries',
                  style: TextStyle(color: AppColors.onDarkMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Completed deliveries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          deliveriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Text("Couldn't load"),
            data: (items) {
              final completed = items
                  .where((d) => d.deliveryStatus == DeliveryStatus.completed)
                  .toList();
              if (completed.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No completed deliveries yet.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final d in completed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RouteLine(
                              from: d.pickupCity ?? '—',
                              to: d.dropoffCity ?? '—',
                              bold: false,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            moneyWhole(d.deliveryFee),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
